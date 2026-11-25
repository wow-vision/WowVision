-- Headless only (tools/headless-tests.lua loads module.lua against a stand-in
-- module and hands it over here): what the key and the events say, over a
-- game whose pet health is a secret.
local testRunner = WowVision.testing.testRunner
local harness = WowVision.petHealth._moduleTestHarness
local module = harness.module

-- A hidden value: joining it into text works, anything else throws.
local function secret(text)
    local value = {}
    local function refuse()
        error("a secret value was looked at", 2)
    end
    return setmetatable(value, {
        __concat = function(a, b)
            if a == value then
                return text .. b
            end
            return a .. text
        end,
        __eq = refuse,
        __lt = refuse,
        __le = refuse,
        __add = refuse,
        __sub = refuse,
        __mul = refuse,
        __div = refuse,
        __len = refuse,
        __tostring = refuse,
    })
end

-- A fight with a pet. world: exists, dead, health (the percent the curve
-- yields, hidden), inCombat, now, idle. `said` collects what is spoken.
local function withPet(test)
    local world = { exists = true, dead = false, health = "45", inCombat = true, now = 100, idle = true, curves = 0 }
    local said = {}
    local names = {
        "UnitExists",
        "UnitIsDeadOrGhost",
        "UnitHealthPercent",
        "InCombatLockdown",
        "GetTime",
        "C_CurveUtil",
        "Enum",
        "issecretvalue",
    }
    local saved = {}
    for _, name in ipairs(names) do
        saved[name] = _G[name]
    end
    local savedSpeak, savedBase = WowVision.speak, WowVision.base
    local hidden = {}
    UnitExists = function(unit)
        return unit == "pet" and world.exists
    end
    UnitIsDeadOrGhost = function(unit)
        if world.deadHidden then
            local value = {}
            hidden[value] = true
            return value
        end
        return unit == "pet" and world.dead
    end
    UnitHealthPercent = function(unit, predicted, curve)
        if unit ~= "pet" or curve == nil or world.health == nil then
            error("refused")
        end
        world.curve = curve
        local value = secret(world.health)
        hidden[value] = true
        return value
    end
    issecretvalue = function(value)
        return type(value) == "table" and hidden[value] == true
    end
    InCombatLockdown = function()
        return world.inCombat
    end
    GetTime = function()
        return world.now
    end
    Enum = { LuaCurveType = { Step = 1 } }
    C_CurveUtil = {
        CreateCurve = function()
            world.curves = world.curves + 1
            local curve = { points = 0 }
            function curve:SetType(kind)
                self.kind = kind
            end
            function curve:AddPoint()
                self.points = self.points + 1
            end
            return curve
        end,
    }
    WowVision.speak = function(_, text)
        tinsert(said, text)
    end
    WowVision.base = {
        speech = {
            idle = function()
                return world.idle
            end,
        },
    }
    local defaults = {}
    for _, key in ipairs({ "automatic", "outOfCombat", "interval", "step" }) do
        defaults[key] = module.settings[key]
    end
    module:onEnable()
    local ok, err = pcall(test, world, said)
    for key, value in pairs(defaults) do
        module.settings[key] = value
    end
    for _, name in ipairs(names) do
        _G[name] = saved[name]
    end
    WowVision.speak, WowVision.base = savedSpeak, savedBase
    if not ok then
        error(err, 0)
    end
end

local function binding(key)
    for _, info in ipairs(harness.bindings) do
        if info.key == key then
            return info
        end
    end
    return nil
end

-- A health event of the pet, then the update that follows it.
local function hit(world)
    module:onEvent("UNIT_HEALTH", "pet")
    world.now = world.now + 0.3
    module:check()
end

testRunner:addSuite("PetHealthModule", {
    ["it watches the pet's health only"] = function(t)
        local found = false
        for _, event in ipairs(harness.events) do
            if event[2] == "UNIT_HEALTH" then
                found = true
                t:assertEqual(event[1], "unit")
                t:assertEqual(event[3], "pet")
            end
        end
        t:assertTrue(found)
    end,

    ["automatic announcements are off until the player turns them on"] = function(t)
        withPet(function(world, said)
            t:assertFalse(module.settings.automatic)
            hit(world)
            module:onEvent("PLAYER_REGEN_ENABLED")
            world.dead = true
            hit(world)
            t:assertEqual(#said, 0)
        end)
    end,

    ["the key says the hidden percentage, also with the announcements off"] = function(t)
        withPet(function(world, said)
            local key = binding("petHealth/speak")
            t:assertEqual(key.inputs[1], "ALT-SHIFT-H")
            key.func()
            t:assertEqual(said[1], "Pet 45 percent")
        end)
    end,

    ["the key explains why there is nothing to say"] = function(t)
        withPet(function(world, said)
            world.exists = false
            module:sayHealth(false)
            world.exists, world.dead = true, true
            module:sayHealth(false)
            world.dead, world.health = false, nil
            module:sayHealth(false)
            t:assertEqual(said[1], "No pet")
            t:assertEqual(said[2], "Pet dead")
            t:assertEqual(said[3], "Pet health unavailable here")
        end)
    end,

    ["an announcement nobody asked for stays silent when there is nothing to tell"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            world.health = nil
            hit(world)
            world.exists = false
            module:sayHealth(true)
            t:assertEqual(#said, 0)
        end)
    end,

    ["in a fight a change is said, at most every interval"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            hit(world)
            t:assertEqual(#said, 1)
            hit(world)
            t:assertEqual(#said, 1)
            world.health = "30"
            world.now = world.now + 3
            module:check()
            t:assertEqual(said[2], "Pet 30 percent")
        end)
    end,

    ["a change waits while WowVision is speaking"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            world.idle = false
            hit(world)
            t:assertEqual(#said, 0)
            world.idle = true
            world.now = world.now + 0.3
            module:check()
            t:assertEqual(#said, 1)
        end)
    end,

    ["out of combat nothing is said unless asked for"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            world.inCombat = false
            hit(world)
            t:assertEqual(#said, 0)
            module.settings.outOfCombat = true
            hit(world)
            t:assertEqual(#said, 1)
        end)
    end,

    ["the end of a fight gives the last word"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            hit(world)
            world.health = "20"
            module:onEvent("UNIT_HEALTH", "pet")
            world.inCombat = false
            module:onEvent("PLAYER_REGEN_ENABLED")
            t:assertEqual(said[2], "Pet 20 percent")
        end)
    end,

    ["the pet's death is said at once and once"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            world.idle = false
            world.dead = true
            module:onEvent("UNIT_HEALTH", "pet")
            module:onEvent("UNIT_HEALTH", "pet")
            module:onEvent("PLAYER_REGEN_ENABLED")
            t:assertEqual(#said, 1)
            t:assertEqual(said[1], "Pet dead")
        end)
    end,

    ["a death the game hides is not taken for one"] = function(t)
        withPet(function(world, said)
            world.deadHidden = true
            module:sayHealth(false)
            t:assertEqual(said[1], "Pet 45 percent")
        end)
    end,

    ["the percentage goes through a step curve of the chosen step"] = function(t)
        withPet(function(world)
            module.settings.step = 10
            module:sayHealth(false)
            t:assertEqual(world.curve.kind, Enum.LuaCurveType.Step)
            t:assertEqual(world.curve.points, 11)
        end)
    end,

    ["the key explains also when the pet is gone"] = function(t)
        withPet(function(world, said)
            world.exists = false
            binding("petHealth/speak").func()
            t:assertEqual(said[1], "No pet")
        end)
    end,

    ["the end of a fight says nothing about a pet that is gone"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            module:onEvent("UNIT_HEALTH", "pet")
            world.exists = false
            module:onEvent("PLAYER_REGEN_ENABLED")
            t:assertEqual(#said, 0)
        end)
    end,

    ["enabling gives the module an update that makes the announcements"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            module:onEvent("UNIT_HEALTH", "pet")
            module.update(module)
            t:assertEqual(#said, 1)
        end)
    end,

    ["it looks for a due announcement four times a second"] = function(t)
        withPet(function(world, said)
            module.settings.automatic = true
            world.idle = false
            module:onEvent("UNIT_HEALTH", "pet")
            module:check()
            world.idle = true
            world.now = world.now + 0.1
            module:check()
            t:assertEqual(#said, 0)
            world.now = world.now + 0.2
            module:check()
            t:assertEqual(#said, 1)
        end)
    end,

    ["one curve is built per step"] = function(t)
        withPet(function(world)
            module.settings.step = 20
            module:sayHealth(false)
            module:sayHealth(false)
            local built = world.curves
            module:sayHealth(false)
            t:assertEqual(world.curves, built)
            t:assertTrue(built <= 1)
        end)
    end,
})
