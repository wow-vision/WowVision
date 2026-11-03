local testRunner = WowVision.testing.testRunner
local enemyCount = WowVision.enemyCount

local SECRET = setmetatable({}, { __tostring = function()
    return "secret"
end })

-- A world standing in for the game's. plates: token -> enemy, where an
-- enemy is { reaction, dead, class, threat = { member = status } }.
local function world(plates, group)
    group = group or { "player", "pet" }
    local present = {}
    for _, member in ipairs(group) do
        present[member] = true
    end
    return {
        plates = function()
            local units = {}
            for unit in pairs(plates) do
                table.insert(units, unit)
            end
            table.sort(units)
            return units
        end,
        group = function()
            return group
        end,
        exists = function(unit)
            return present[unit] == true or plates[unit] ~= nil
        end,
        reaction = function(unit)
            return plates[unit].reaction
        end,
        isDead = function(unit)
            return plates[unit].dead == true
        end,
        inCombat = function(unit)
            return plates[unit].idle ~= true
        end,
        classification = function(unit)
            return plates[unit].class or "normal"
        end,
        threat = function(member, unit)
            local threat = plates[unit].threat or {}
            return threat[member]
        end,
        isSecret = function(value)
            return value == SECRET
        end,
        controlCount = function(unit)
            return plates[unit].loc
        end,
        controlAuras = function(unit)
            return plates[unit].ccAuras
        end,
        controlText = function(unit)
            return plates[unit].text
        end,
    }
end

local function enemy(threat, extra)
    local e = { reaction = 2, threat = threat }
    for k, v in pairs(extra or {}) do
        e[k] = v
    end
    return e
end

testRunner:addSuite("EnemyCount", {
    ["counts enemies the group is fighting"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }),
            nameplate2 = enemy({ pet = 1 }),
            nameplate3 = enemy(nil),
        })
        t:assertEqual(enemyCount.count(api, "group", false), 2)
    end,

    ["a fight without you still counts in group mode"] = function(t)
        local api = world({
            nameplate1 = enemy({ party1 = 3 }),
        }, { "player", "pet", "party1" })
        t:assertEqual(enemyCount.count(api, "group", false), 1)
        t:assertEqual(enemyCount.count(api, "player", false), 0)
    end,

    ["player mode counts only enemies you hold aggro of"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }),
            nameplate2 = enemy({ player = 2 }),
            nameplate3 = enemy({ player = 1 }),
            nameplate4 = enemy({ player = 0 }),
        })
        t:assertEqual(enemyCount.count(api, "player", false), 2)
    end,

    ["friendly, dead and missing members are left out"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }, { reaction = 5 }),
            nameplate2 = enemy({ player = 3 }, { dead = true }),
            nameplate3 = enemy({ party2 = 3 }),
        })
        t:assertEqual(enemyCount.count(api, "group", false), 0)
    end,

    ["an enemy out of combat is left out"] = function(t)
        local api = world({ nameplate1 = enemy({ player = 3 }, { idle = true }) })
        t:assertEqual(enemyCount.count(api, "group", false), 0)
        t:assertEqual(enemyCount.count(api, "player", false), 0)
    end,

    ["neutral enemies count"] = function(t)
        local api = world({ nameplate1 = enemy({ player = 3 }, { reaction = 4 }) })
        t:assertEqual(enemyCount.count(api, "group", false), 1)
    end,

    ["elite only keeps elites, rare elites and world bosses"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }, { class = "elite" }),
            nameplate2 = enemy({ player = 3 }, { class = "rareelite" }),
            nameplate3 = enemy({ player = 3 }, { class = "worldboss" }),
            nameplate4 = enemy({ player = 3 }, { class = "rare" }),
            nameplate5 = enemy({ player = 3 }),
        })
        t:assertEqual(enemyCount.count(api, "group", true), 3)
        t:assertEqual(enemyCount.count(api, "group", false), 5)
    end,

    ["a secret threat answer counts"] = function(t)
        local api = world({ nameplate1 = enemy({ player = SECRET }) })
        t:assertEqual(enemyCount.count(api, "group", false), 1)
        t:assertEqual(enemyCount.count(api, "player", false), 1)
    end,

    ["a secret reaction does not count"] = function(t)
        local api = world({ nameplate1 = enemy({ player = 3 }, { reaction = SECRET }) })
        t:assertEqual(enemyCount.count(api, "group", false), 0)
    end,

    ["the plate being removed is skipped"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }),
            nameplate2 = enemy({ player = 3 }),
        })
        t:assertEqual(enemyCount.count(api, "group", false, "nameplate2"), 1)
    end,

    ["a new count is said once it held"] = function(t)
        local settler = enemyCount.Settler:new(0.5)
        t:assertEqual(settler:update(2, 10), nil)
        t:assertEqual(settler:update(2, 10.3), nil)
        t:assertEqual(settler:update(2, 10.5), 2)
        t:assertEqual(settler:update(2, 11), nil)
    end,

    ["a blink back to the said count says nothing"] = function(t)
        local settler = enemyCount.Settler:new(0.5)
        settler:update(1, 0)
        t:assertEqual(settler:update(1, 1), 1)
        t:assertEqual(settler:update(0, 2), nil)
        t:assertEqual(settler:update(1, 2.2), nil)
        t:assertEqual(settler:update(1, 3), nil)
    end,

    ["a count that changes again restarts the wait"] = function(t)
        local settler = enemyCount.Settler:new(0.5)
        settler:update(1, 0)
        t:assertEqual(settler:update(2, 0.4), nil)
        t:assertEqual(settler:update(2, 0.7), nil)
        t:assertEqual(settler:update(2, 0.9), 2)
    end,

    ["the last enemy gone says zero"] = function(t)
        local settler = enemyCount.Settler:new(0.5)
        settler:update(3, 0)
        settler:update(3, 1)
        settler:update(0, 5)
        t:assertEqual(settler:update(0, 5.5), 0)
    end,
})

-- Crowd control --------------------------------------------------------------

local function plain(parts, separator)
    return table.concat(parts, separator)
end

-- What the tracker would have said for a fight state: free and controlled
-- plate tokens, texts by token.
local function step(tracker, free, controlled, texts)
    local message = tracker:change(free, controlled, function(unit)
        return texts and texts[unit]
    end)
    if message == nil then
        return "silent"
    end
    local words = enemyCount.controlWords(message, "controlled", plain) or ""
    if message.ended then
        words = "sound " .. words
    end
    return words
end

testRunner:addSuite("EnemyCountControl", {
    ["a readable loss-of-control count marks a plate controlled"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }, { loc = 1 }),
            nameplate2 = enemy({ player = 3 }, { loc = 0 }),
            nameplate3 = enemy({ player = 3 }),
        })
        local free, controlled = enemyCount.scan(api, "group", false)
        t:assertEqual(#free, 2)
        t:assertEqual(controlled[1], "nameplate1")
    end,

    ["a secret count falls back to the crowd control auras"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }, { loc = SECRET, ccAuras = 1 }),
            nameplate2 = enemy({ player = 3 }, { loc = SECRET }),
        })
        local free, controlled = enemyCount.scan(api, "group", false)
        t:assertEqual(#free, 1)
        t:assertEqual(#controlled, 1)
    end,

    ["the scan keeps the count rules"] = function(t)
        local api = world({
            nameplate1 = enemy({ player = 3 }, { loc = 1, dead = true }),
            nameplate2 = enemy(nil, { loc = 1 }),
            nameplate3 = enemy({ player = 3 }, { reaction = 5 }),
        })
        local free, controlled = enemyCount.scan(api, "group", false)
        t:assertEqual(#free + #controlled, 0)
    end,

    ["the key changes when a control swaps plates at the same count"] = function(t)
        local a = enemyCount.controlKey({ "nameplate2" }, { "nameplate1" })
        local b = enemyCount.controlKey({ "nameplate1" }, {})
        t:assertEqual(a == b, false)
        t:assertEqual(enemyCount.controlKey({}, {}), enemyCount.CONTROL_IDLE)
    end,

    ["sheep one, kill the rest, then the sheep"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        local texts = { nameplate1 = "Polymorphed" }
        t:assertEqual(step(tracker, { "nameplate1", "nameplate2", "nameplate3" }, {}), "3")
        t:assertEqual(step(tracker, { "nameplate2", "nameplate3" }, { "nameplate1" }, texts), "Polymorphed")
        t:assertEqual(step(tracker, { "nameplate3" }, { "nameplate1" }, texts), "1")
        t:assertEqual(step(tracker, {}, { "nameplate1" }, texts), "0, Polymorphed")
        t:assertEqual(step(tracker, { "nameplate1" }, {}, texts), "sound 1")
        t:assertEqual(step(tracker, {}, {}), "0")
    end,

    ["a break while the other dies plays the sound at the same number"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate2" }, {})
        step(tracker, { "nameplate2" }, { "nameplate1" }, { nameplate1 = "Polymorphed" })
        t:assertEqual(step(tracker, { "nameplate1" }, {}), "sound 1")
    end,

    ["a controlled enemy that dies says nothing"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2" }, {})
        step(tracker, { "nameplate2" }, { "nameplate1" }, { nameplate1 = "Stunned" })
        t:assertEqual(step(tracker, { "nameplate2" }, {}), "silent")
    end,

    ["the last free enemy controlled says zero and what is left"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2" }, {})
        step(tracker, { "nameplate2" }, { "nameplate1" }, { nameplate1 = "Polymorphed" })
        t:assertEqual(step(tracker, {}, { "nameplate1", "nameplate2" }, { nameplate1 = "Polymorphed", nameplate2 = "Stunned" }),
            "0, Polymorphed, Stunned")
    end,

    ["a kill in the same moment as a control says the number too"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2", "nameplate3" }, {})
        t:assertEqual(step(tracker, { "nameplate3" }, { "nameplate1" }, { nameplate1 = "Feared" }), "1, Feared")
    end,

    ["a control without a readable text says the fallback word"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2" }, {})
        t:assertEqual(step(tracker, { "nameplate2" }, { "nameplate1" }), "controlled")
    end,

    ["a forgotten plate token starts fresh"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2" }, {})
        step(tracker, { "nameplate2" }, { "nameplate1" }, { nameplate1 = "Stunned" })
        tracker:forget("nameplate1")
        -- The token now shows a new, free enemy: no "ended" sound.
        t:assertEqual(step(tracker, { "nameplate1", "nameplate2" }, {}), "2")
    end,

    ["the control settler starts idle"] = function(t)
        local settler = enemyCount.Settler:new(0.5, enemyCount.CONTROL_IDLE)
        t:assertEqual(settler:update(enemyCount.CONTROL_IDLE, 0), nil)
        settler:update("2|", 1)
        t:assertEqual(settler:update("2|", 1.5), "2|")
    end,
})
