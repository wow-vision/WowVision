local testRunner = WowVision.testing.testRunner
local enemyCount = WowVision.enemyCount

local SECRET = setmetatable({}, { __tostring = function()
    return "secret"
end })

-- A world standing in for the game's. plates: token -> enemy, where an
-- enemy is { reaction, dead, class, threat = { member = status }, tapped }
-- (tapped: UnitIsTapDenied, true when left out). A group of more than
-- player and pet is a party. fighting: group units in combat (member ->
-- true or SECRET), by default all of them.
local function world(plates, group, fighting)
    group = group or { "player", "pet" }
    if fighting == nil then
        fighting = {}
        for _, member in ipairs(group) do
            fighting[member] = true
        end
    end
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
            if plates[unit] == nil then
                return fighting[unit] or false
            end
            return plates[unit].idle ~= true
        end,
        classification = function(unit)
            return plates[unit].class or "normal"
        end,
        threat = function(member, unit)
            local threat = plates[unit].threat or {}
            return threat[member]
        end,
        tapDenied = function(unit)
            local tapped = plates[unit].tapped
            if tapped == nil then
                return true
            end
            return tapped
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

    ["in a group, an enemy in combat nobody else tapped counts without its threat list"] = function(t)
        local party = { "player", "pet", "party1" }
        local api = world({
            nameplate1 = enemy(nil, { tapped = false }),
            nameplate2 = enemy(nil, { tapped = true }),
            nameplate3 = enemy(nil, { tapped = false, idle = true }),
            nameplate4 = enemy(nil, { tapped = SECRET }),
        }, party)
        t:assertEqual(enemyCount.count(api, "group", false), 1)
        t:assertEqual(enemyCount.count(api, "player", false), 0)
    end,

    ["in a group out of combat, an untapped enemy in combat does not count"] = function(t)
        local party = { "player", "pet", "party1" }
        local plates = { nameplate1 = enemy(nil, { tapped = false }) }
        t:assertEqual(enemyCount.count(world(plates, party, {}), "group", false), 0)
        t:assertEqual(enemyCount.count(world(plates, party, { party1 = SECRET }), "group", false), 0)
        t:assertEqual(enemyCount.count(world(plates, party, { party1 = true }), "group", false), 1)
        t:assertEqual(enemyCount.count(world(plates, party, { pet = true }), "group", false), 1)
    end,

    ["solo, an untapped enemy in combat needs you on its threat list"] = function(t)
        local api = world({ nameplate1 = enemy(nil, { tapped = false }) })
        t:assertEqual(enemyCount.count(api, "group", false), 0)
    end,

    ["a secret combat flag does not count by the group rule"] = function(t)
        local api = world({ nameplate1 = enemy(nil, { tapped = false }) }, { "player", "pet", "party1" })
        local inCombat = api.inCombat
        api.inCombat = function(unit)
            if unit == "nameplate1" then
                return SECRET
            end
            return inCombat(unit)
        end
        t:assertEqual(enemyCount.count(api, "group", false), 0)
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

local function wordOptions(names)
    return {
        names = names,
        noText = "controlled",
        join = plain,
        isSecret = function(value)
            return value == SECRET
        end,
    }
end

-- What the tracker would have said for a fight state: free and controlled
-- plate tokens, texts by token. `names` false: the no-names choice.
local function step(tracker, free, controlled, texts, names)
    local message = tracker:change(free, controlled, function(unit)
        return texts and texts[unit]
    end)
    if message == nil then
        return "silent"
    end
    local words = enemyCount.controlWords(message, wordOptions(names ~= false)) or ""
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

    ["three of the same name at once group by name"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        local nova = { nameplate1 = "Frost Nova", nameplate2 = "Frost Nova", nameplate3 = "Frost Nova" }
        step(tracker, { "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, {})
        t:assertEqual(step(tracker, { "nameplate4" }, { "nameplate1", "nameplate2", "nameplate3" }, nova), "3 Frost Nova")
    end,

    ["three different or secret names at once group by the word"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, {})
        t:assertEqual(step(tracker, { "nameplate4" }, { "nameplate1", "nameplate2", "nameplate3" },
            { nameplate1 = "Frost Nova", nameplate2 = "Polymorph", nameplate3 = "Frost Nova" }), "3 controlled")
        local secretTracker = enemyCount.ControlTracker:new()
        step(secretTracker, { "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, {})
        t:assertEqual(step(secretTracker, { "nameplate4" }, { "nameplate1", "nameplate2", "nameplate3" },
            { nameplate1 = SECRET, nameplate2 = SECRET, nameplate3 = SECRET }), "3 controlled")
    end,

    ["two at once still say both names"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        step(tracker, { "nameplate1", "nameplate2", "nameplate3" }, {})
        t:assertEqual(step(tracker, { "nameplate3" }, { "nameplate1", "nameplate2" },
            { nameplate1 = "Frost Nova", nameplate2 = "Frost Nova" }), "Frost Nova, Frost Nova")
    end,

    ["only many controlled left says zero and the group"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        local nova = { nameplate1 = "Frost Nova", nameplate2 = "Frost Nova", nameplate3 = "Frost Nova" }
        step(tracker, { "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, {})
        step(tracker, { "nameplate4" }, { "nameplate1", "nameplate2", "nameplate3" }, nova)
        t:assertEqual(step(tracker, {}, { "nameplate1", "nameplate2", "nameplate3" }, nova), "0, 3 Frost Nova")
    end,

    ["the no-names choice says the word, counted from two on"] = function(t)
        local tracker = enemyCount.ControlTracker:new()
        local texts = { nameplate1 = "Hammer of Justice", nameplate2 = "Polymorph", nameplate3 = "Polymorph" }
        step(tracker, { "nameplate1", "nameplate2", "nameplate3", "nameplate4" }, {})
        t:assertEqual(step(tracker, { "nameplate2", "nameplate3", "nameplate4" }, { "nameplate1" }, texts, false), "controlled")
        t:assertEqual(step(tracker, { "nameplate4" }, { "nameplate1", "nameplate2", "nameplate3" }, texts, false), "2 controlled")
        t:assertEqual(step(tracker, {}, { "nameplate1", "nameplate2", "nameplate3" }, texts, false), "0, 3 controlled")
    end,

    ["the control settler starts idle"] = function(t)
        local settler = enemyCount.Settler:new(0.5, enemyCount.CONTROL_IDLE)
        t:assertEqual(settler:update(enemyCount.CONTROL_IDLE, 0), nil)
        settler:update("2|", 1)
        t:assertEqual(settler:update("2|", 1.5), "2|")
    end,
})

-- Lost lines -------------------------------------------------------------------

testRunner:addSuite("EnemyCountLostLine", {
    ["a line the queue sent is not said again"] = function(t)
        local watch = enemyCount.LostLine:new()
        local queue, line = {}, {}
        table.insert(queue, line)
        watch:fired(queue, line, { count = 2 }, 0)
        table.remove(queue, 1)
        t:assertEqual(watch:check(queue, 1), nil)
        -- A stop after it was sent changes nothing.
        t:assertEqual(watch:check({}, 10), nil)
    end,

    ["a line thrown away by a stop is said again after 5 seconds, once"] = function(t)
        local watch = enemyCount.LostLine:new()
        local queue, line, message = {}, {}, { count = 3 }
        table.insert(queue, { "other speech" })
        table.insert(queue, line)
        watch:fired(queue, line, message, 10)
        local afterStop = {}
        t:assertEqual(watch:check(afterStop, 11), nil)
        t:assertEqual(watch:check(afterStop, 14.9), nil)
        t:assertEqual(watch:check(afterStop, 15), message)
        t:assertEqual(watch:check(afterStop, 16), nil)
    end,

    ["a newer number replaces the watch"] = function(t)
        local watch = enemyCount.LostLine:new()
        local queue, lost = {}, {}
        table.insert(queue, lost)
        watch:fired(queue, lost, { count = 3 }, 0)
        local afterStop = {}
        watch:fired(afterStop, nil, { count = 2 }, 2)
        t:assertEqual(watch:check({}, 10), nil)
    end,

    ["a lost number the count moved past is forgotten"] = function(t)
        local watch = enemyCount.LostLine:new()
        local queue, lost = {}, {}
        table.insert(queue, lost)
        watch:fired(queue, lost, { count = 3 }, 0)
        watch:forget()
        t:assertEqual(watch:check({}, 10), nil)
    end,

    ["a line still waiting is not said again"] = function(t)
        local watch = enemyCount.LostLine:new()
        local queue, line = {}, {}
        table.insert(queue, line)
        watch:fired(queue, line, { count = 1 }, 0)
        t:assertEqual(watch:check(queue, 30), nil)
    end,
})

-- Announcer ----------------------------------------------------------------------

-- A speech module standing in for tbc/, mists/, retail/ speech.lua: speak
-- queues a line behind one that plays (or sends it at once when idle), stop
-- replaces the queue table. fired: every message the alert fired, with
-- which outputs ("all" or "speech").
local function speechWorld(busy)
    local w = { queue = {}, time = 0, fired = {}, busy = busy ~= false, enabled = true, mode = "off" }
    function w.speak(text)
        if w.busy then
            table.insert(w.queue, { text = text })
        else
            w.busy = true
        end
    end
    function w.stop()
        w.queue = {}
        w.busy = false
    end
    w.announcer = enemyCount.Announcer:new({
        fire = function(message)
            table.insert(w.fired, { message = message, outputs = "all" })
            w.speak(tostring(message.count))
        end,
        fireSpeech = function(message)
            table.insert(w.fired, { message = message, outputs = "speech" })
            w.speak(tostring(message.count))
        end,
        queue = function()
            return w.queue
        end,
        now = function()
            return w.time
        end,
        enabled = function()
            return w.enabled
        end,
        mode = function()
            return w.mode
        end,
    })
    return w
end

local function settled(said)
    return { said = said, pending = nil }
end

testRunner:addSuite("EnemyCountAnnouncer", {
    ["a number queued behind other speech and thrown away by a stop is said again"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        w.stop()
        w.time = 5
        w.announcer:resay(settled(3), true)
        t:assertEqual(#w.fired, 2)
        t:assertEqual(w.fired[2].message.count, 3)
        t:assertEqual(w.fired[2].message.again, true)
    end,

    ["the repeat is the speech line alone: a voice pack number was never thrown away"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        w.stop()
        w.time = 5
        w.announcer:resay(settled(3), true)
        t:assertEqual(w.fired[1].outputs, "all")
        t:assertEqual(w.fired[2].outputs, "speech")
    end,

    ["a number the queue sent is not said again"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        table.remove(w.queue, 1)
        w.time = 10
        w.announcer:resay(settled(3), true)
        t:assertEqual(#w.fired, 1)
    end,

    ["a number sent at once is not watched"] = function(t)
        local w = speechWorld(false)
        w.announcer:say({ count = 2 })
        w.stop()
        w.time = 10
        w.announcer:resay(settled(2), true)
        t:assertEqual(#w.fired, 1)
    end,

    ["the queue is read before the fire: a stop during the fire leaves nothing to watch"] = function(t)
        local w = speechWorld()
        local fire = w.announcer.config.fire
        w.announcer.config.fire = function(message)
            fire(message)
            -- an interrupting output of the same alert
            w.stop()
        end
        w.announcer:say({ count = 4 })
        w.time = 10
        w.announcer:resay(settled(4), true)
        t:assertEqual(#w.fired, 1)
    end,

    ["the check recounts first: a lost number the count moved past is not said"] = function(t)
        local w = speechWorld()
        local active = settled(3)
        w.announcer:say({ count = 3 })
        w.stop()
        w.time = 6
        -- One enemy left quietly; the recount sees 2 and holds it to settle.
        w.announcer:tick(function()
            active.pending = 2
        end, active, true)
        t:assertEqual(#w.fired, 1)
    end,

    ["a lost number is forgotten while the alert is off"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        w.stop()
        w.time = 2
        w.enabled = false
        w.announcer:resay(settled(3), true)
        w.time = 60
        w.enabled = true
        w.announcer:resay(settled(3), true)
        t:assertEqual(#w.fired, 1)
    end,

    ["a lost number from before a crowd control mode switch is not said"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        w.stop()
        w.mode = "names"
        w.time = 10
        w.announcer:resay(settled(3), false)
        t:assertEqual(#w.fired, 1)
    end,

    ["crowd control: a quiet change keeps a lost number that still stands, without its old texts"] = function(t)
        local w = speechWorld()
        w.mode = "names"
        w.announcer:say({ count = 3, texts = { "Polymorph" }, textCount = 1 })
        w.stop()
        -- The polymorphed enemy dies: the free count stays 3.
        w.announcer:quietChange()
        w.time = 10
        w.announcer:resay(settled("3|"), false)
        t:assertEqual(#w.fired, 2)
        t:assertEqual(w.fired[2].message.count, 3)
        t:assertNil(w.fired[2].message.texts)
    end,

    ["no repeat while a newer number waits to settle"] = function(t)
        local w = speechWorld()
        w.announcer:say({ count = 3 })
        w.stop()
        w.time = 10
        w.announcer:resay({ said = 3, pending = 2 }, true)
        t:assertEqual(#w.fired, 1)
    end,
})
