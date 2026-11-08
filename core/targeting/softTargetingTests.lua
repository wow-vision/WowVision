local testRunner = WowVision.testing.testRunner
local soft = WowVision.softTargeting

-- A console variable store standing in for the game's. `secure` names are
-- refused in combat; `refuse` names are refused always.
local function cvars(values, options)
    options = options or {}
    local defaults = options.defaults or {}
    local state = { combat = false, writes = 0 }
    local api = {
        getCVar = function(name)
            return values[name]
        end,
        setCVar = function(name, value)
            state.writes = state.writes + 1
            if options.refuse and options.refuse[name] then
                return false
            end
            if state.combat and options.secure and options.secure[name] then
                error("ADDON_ACTION_BLOCKED")
            end
            values[name] = value
            return true
        end,
        getDefault = function(name)
            return defaults[name]
        end,
        isSecure = function(name)
            return options.secure ~= nil and options.secure[name] == true
        end,
        inCombat = function()
            return state.combat
        end,
    }
    return soft.Writer:new(api), state
end

testRunner:addSuite("SoftTargeting", {
    ["always allows soft targeting with any target"] = function(t)
        local withLocked, matchLocked = soft.lockValues("always", true, true, false)
        t:assertEqual(withLocked, 2)
        t:assertEqual(matchLocked, 0)
    end,

    ["no hard target suppresses with any target"] = function(t)
        local withLocked, matchLocked = soft.lockValues("noHardTarget", true, false, true)
        t:assertEqual(withLocked, 0)
        t:assertEqual(matchLocked, 1)
    end,

    ["attackable mode rests at 0 with no target"] = function(t)
        local withLocked, matchLocked = soft.lockValues("noAttackableHardTarget", false, false, false)
        t:assertEqual(withLocked, 0)
        t:assertEqual(matchLocked, 2)
    end,

    ["attackable mode suppresses for a living enemy"] = function(t)
        t:assertEqual(soft.lockValues("noAttackableHardTarget", true, true, false), 0)
    end,

    ["attackable mode allows for a corpse"] = function(t)
        t:assertEqual(soft.lockValues("noAttackableHardTarget", true, true, true), 2)
    end,

    ["attackable mode allows for a friendly target"] = function(t)
        t:assertEqual(soft.lockValues("noAttackableHardTarget", true, false, false), 2)
    end,

    ["an unknown mode leaves the game alone"] = function(t)
        t:assertNil(soft.lockValues(nil, true, true, false))
    end,

    ["the game default mode leaves the game alone"] = function(t)
        t:assertNil(soft.lockValues(soft.GAME_DEFAULT, true, true, false))
        t:assertNil(soft.lockValues(soft.GAME_DEFAULT, false, false, false))
        t:assertEqual(soft.lockModes[1], soft.GAME_DEFAULT)
    end,

    ["a normalised number counts as the same value"] = function(t)
        t:assertTrue(soft.sameValue("15.000000", "15"))
        t:assertFalse(soft.sameValue("15", "20"))
    end,

    ["an equal value is not written"] = function(t)
        local writer, state = cvars({ SoftTargetEnemy = "3" })
        t:assertEqual(writer:write("SoftTargetEnemy", 3), "same")
        t:assertEqual(state.writes, 0)
    end,

    ["out of combat a write lands"] = function(t)
        local values = { SoftTargetEnemy = "0" }
        local writer = cvars(values, { secure = { SoftTargetEnemy = true } })
        t:assertEqual(writer:write("SoftTargetEnemy", 3), "set")
        t:assertEqual(values.SoftTargetEnemy, "3")
    end,

    ["in combat a secure variable waits and is not tried"] = function(t)
        local values = { SoftTargetEnemy = "0" }
        local writer, state = cvars(values, { secure = { SoftTargetEnemy = true } })
        state.combat = true
        t:assertEqual(writer:write("SoftTargetEnemy", 3), "pending")
        t:assertEqual(state.writes, 0)
        t:assertEqual(writer.pending.SoftTargetEnemy, "3")
    end,

    ["in combat a variable that is not secure lands"] = function(t)
        local values = { SoftTargetWithLocked = "0" }
        local writer, state = cvars(values, { secure = { SoftTargetEnemy = true } })
        state.combat = true
        t:assertEqual(writer:write("SoftTargetWithLocked", 2), "set")
        t:assertEqual(values.SoftTargetWithLocked, "2")
    end,

    ["a waiting write lands on flush after combat"] = function(t)
        local values = { SoftTargetEnemy = "0" }
        local writer, state = cvars(values, { secure = { SoftTargetEnemy = true } })
        state.combat = true
        writer:write("SoftTargetEnemy", 3)
        state.combat = false
        writer:flush()
        t:assertEqual(values.SoftTargetEnemy, "3")
        t:assertNil(writer.pending.SoftTargetEnemy)
    end,

    ["a later wish for the current value drops the waiting write"] = function(t)
        local values = { SoftTargetEnemy = "0" }
        local writer, state = cvars(values, { secure = { SoftTargetEnemy = true } })
        state.combat = true
        writer:write("SoftTargetEnemy", 3)
        t:assertEqual(writer:write("SoftTargetEnemy", 0), "same")
        t:assertNil(writer.pending.SoftTargetEnemy)
    end,

    ["a refused write is checked by reading back and waits"] = function(t)
        local values = { SoftTargetForce = "1" }
        local writer = cvars(values, { refuse = { SoftTargetForce = true } })
        t:assertEqual(writer:write("SoftTargetForce", 0), "pending")
        t:assertEqual(values.SoftTargetForce, "1")
        t:assertEqual(writer.pending.SoftTargetForce, "0")
    end,

    ["restoring puts the game's own default back"] = function(t)
        local values = { SoftTargetEnemyArc = "2" }
        local writer = cvars(values, { defaults = { SoftTargetEnemyArc = "1" } })
        t:assertEqual(writer:restore("SoftTargetEnemyArc"), "set")
        t:assertEqual(values.SoftTargetEnemyArc, "1")
    end,

    ["restoring a secure variable in combat waits for the end of combat"] = function(t)
        local values = { SoftTargetForce = "1" }
        local writer, state = cvars(values, { secure = { SoftTargetForce = true }, defaults = { SoftTargetForce = "0" } })
        state.combat = true
        t:assertEqual(writer:restore("SoftTargetForce"), "pending")
        t:assertEqual(values.SoftTargetForce, "1")
        state.combat = false
        writer:flush()
        t:assertEqual(values.SoftTargetForce, "0")
    end,

    ["restoring a variable with no known default does nothing"] = function(t)
        local values = { SoftTargetEnemyArc = "2" }
        local writer, state = cvars(values)
        t:assertEqual(writer:restore("SoftTargetEnemyArc"), "missing")
        t:assertEqual(state.writes, 0)
    end,

    ["a variable this game lacks is reported missing"] = function(t)
        local writer, state = cvars({})
        t:assertEqual(writer:write("SoftTargetWithLocked", 0), "missing")
        t:assertEqual(state.writes, 0)
    end,
})

-- A soft target unit standing in for the game's: guid and name may be
-- secret ({ secret = value }), plate is a frame or nil.
local function unitApi(unit)
    return {
        UnitExists = function()
            return unit.exists ~= false and (unit.guid ~= nil or unit.exists == true)
        end,
        UnitGUID = function()
            return unit.guid
        end,
        UnitName = function()
            return unit.name
        end,
        nameplate = function()
            return unit.plate
        end,
        isSecret = function(value)
            return type(value) == "table" and value.secret ~= nil
        end,
    }
end

testRunner:addSuite("SoftTargetIdentity", {
    ["a readable GUID is the identity"] = function(t)
        t:assertEqual(soft.identity(unitApi({ guid = "Creature-1" }), "softenemy"), "Creature-1")
    end,

    ["no unit has no identity"] = function(t)
        t:assertNil(soft.identity(unitApi({ exists = false }), "softenemy"))
    end,

    ["a secret GUID gives the same identity on every read of the same unit"] = function(t)
        local plate = {}
        local unit = { guid = { secret = "Creature-1" }, plate = plate }
        local first = soft.identity(unitApi(unit), "softenemy")
        unit.guid = { secret = "Creature-1" }
        t:assertEqual(first, plate)
        t:assertEqual(soft.identity(unitApi(unit), "softenemy"), first)
    end,

    ["a secret GUID with another nameplate is a different unit"] = function(t)
        local a = soft.identity(unitApi({ guid = { secret = "1" }, plate = {} }), "softenemy")
        local b = soft.identity(unitApi({ guid = { secret = "2" }, plate = {} }), "softenemy")
        t:assertTrue(a ~= b)
    end,

    ["with no nameplate a readable name is the identity"] = function(t)
        local api = unitApi({ guid = { secret = "1" }, name = "Wolf" })
        t:assertEqual(soft.identity(api, "softenemy"), "name:Wolf")
    end,

    ["nothing readable gives one fixed identity"] = function(t)
        local api = unitApi({ guid = { secret = "1" }, name = { secret = "Wolf" } })
        t:assertEqual(soft.identity(api, "softenemy"), soft.UNREADABLE)
        t:assertEqual(soft.identity(api, "softenemy"), soft.identity(api, "softenemy"))
    end,
})

testRunner:addSuite("SoftTargetFlicker", {
    ["a new unit is announced once while it stays"] = function(t)
        local state = {}
        t:assertEqual(soft.track(state, "A", 1), "new")
        t:assertNil(soft.track(state, "A", 1.1))
    end,

    ["the same unit lost and back every frame is never announced again"] = function(t)
        local state = {}
        t:assertEqual(soft.track(state, "A", 0), "new")
        local now = 0
        for _ = 1, 50 do
            now = now + 0.02
            t:assertEqual(soft.track(state, nil, now), "lost")
            now = now + 0.03
            t:assertEqual(soft.track(state, "A", now), "back")
        end
    end,

    ["the same unit back after the hold is announced again"] = function(t)
        local state = {}
        soft.track(state, "A", 0)
        soft.track(state, nil, 1)
        t:assertEqual(soft.track(state, "A", 1 + soft.FLICKER_HOLD + 0.1), "new")
    end,

    ["another unit is announced at once, also within the hold"] = function(t)
        local state = {}
        soft.track(state, "A", 0)
        soft.track(state, nil, 1)
        t:assertEqual(soft.track(state, "B", 1.01), "new")
        t:assertEqual(soft.track(state, "B", 1.02), nil)
    end,

    ["losing a unit twice reports it lost once"] = function(t)
        local state = {}
        soft.track(state, "A", 0)
        t:assertEqual(soft.track(state, nil, 1), "lost")
        t:assertNil(soft.track(state, nil, 1.1))
    end,
})
