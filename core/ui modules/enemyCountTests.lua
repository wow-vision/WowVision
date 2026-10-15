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
