-- Headless suite for the group health readback
-- (retail/groupHealth/readback.lua): its pure parts (plans, decoding, Sku's
-- rule), and the offline scenarios of tools/groupHealthSim.lua (party of 5
-- and raid of 10; strong hits on one member, slow changes on two, a healer
-- hovering at a line, stops of all speech, everyone hit hard, everyone
-- under moderate damage with the disturbances of the fight logged in game)
-- at 60 and 30 frames per second.
-- tools/group-health-sim.lua prints the same scenarios as a report.
--
-- The scenarios are judged by what the player has: how long the last
-- number heard of a member is out of date (Sim.staleness), set beside Sku
-- on the same health (Sim.sku). The bars below are what the monitor
-- reached on 2026-10-14 with some room: they keep it from getting worse.
-- Sku's own figures are in each message; the bar for "as precise as Sku"
-- is the user's to set.

local testRunner = WowVision.testing.testRunner
local GroupHealth = WowVision.groupHealth
local R = GroupHealth.readbackConstants
local Sim = loadfile("tools/groupHealthSim.lua")("WowVision", {})

local function played(level)
    -- The line measured on Forever, without noise.
    return 190 + 0.3314 * (R.SILENCE_OFFSET + level * R.LEVEL_SILENCE)
end

-- A plan of the caller's own: ten percent steps plus full, base 4.
local function stepPlan(layout)
    local points = {}
    for k = 0, 10 do
        tinsert(points, { k / 10, k })
    end
    return GroupHealth.readbackPlan("steps", 4, points, { layout = layout })
end

local function evaluate(points, x)
    local y = points[1][2]
    for _, point in ipairs(points) do
        if x >= point[1] then
            y = point[2]
        end
    end
    return y
end

-- What a sample of `health` reads under `plan`, through the fixed line.
local function readAt(plan, health)
    local times = {}
    for digit = 1, plan.digitCount do
        local level = (evaluate(plan.digitPoints[digit], health) - R.SILENCE_OFFSET) / R.LEVEL_SILENCE
        times[digit] = played(level)
    end
    return GroupHealth.readbackValue(plan, times[1], times[2])
end

-- A reading of a sample that carried a number (a health event's), and of
-- a plain one (a new member).
local function reading(plan, health)
    return { plan = plan, value = readAt(plan, health), carried = true }
end

local function plain(plan, health)
    return { plan = plan, value = readAt(plan, health) }
end

local levels = GroupHealth.pitchLevels(GroupHealth.voices.fallback)

local PLANS = {
    { "steps", stepPlan() },
    { "steps, two digits", stepPlan("pair") },
    { "locate", GroupHealth.locatePlan() },
    { "zoom, two digits", GroupHealth.zoomPlan(0, 100, "pair") },
}
for _, case in ipairs({ { 100, 5, 0.9 }, { 60, 10, 0.8 }, { 50, 20, 0.7 }, { 12, 10, 0.8 }, { 0, 10, 0.8 }, { 95, 30, 1 }, { 3, 2, 0.7 }, { 87, 5, 0.9, 1 } }) do
    local quiet = case[4] ~= nil and GroupHealth.pitchQuiet(levels, case[1], case[4]) or nil
    tinsert(PLANS, { "change " .. case[1] .. "/" .. case[2], GroupHealth.changePlan(case[1], case[2], quiet, case[3]) })
    tinsert(PLANS, { "unsure " .. case[1], GroupHealth.unsurePlan(case[1], case[3]) })
end

-- Pooled over the fights of a list.
local function pooled(list, key)
    local n = 0
    for _, result in ipairs(list) do
        n = n + result.total[key]
    end
    return n
end

-- Share of member-time the last number heard was out of date: ours, Sku's.
local function outdated(list)
    local seconds = 0
    for _, result in ipairs(list) do
        seconds = seconds + result.opts.duration * #result.members
    end
    return pooled(list, "outdated") / seconds, pooled(list, "skuOutdated") / seconds
end

-- Of the numbers heard, how many repeat the one before: health less than
-- half a minimum change away from the member's last heard number. Lost
-- checks (the number goes out again) and numbers cut by a stop do that.
local function repeatShare(list)
    local heard, repeats = 0, 0
    for _, one in ipairs(list) do
        for _, m in ipairs(one.members) do
            local a = Sim.ROLES[m.role].minChange / 100
            local last = nil
            for _, x in ipairs(m.announcements) do
                heard = heard + 1
                if last ~= nil and math.abs(x.health - last) < a / 2 then
                    repeats = repeats + 1
                end
                last = x.health
            end
        end
    end
    return heard > 0 and repeats / heard or 0
end

local results = {}
local function scenario(kind, size, fps, seed)
    local key = kind .. size .. ":" .. fps .. ":" .. tostring(seed)
    if results[key] == nil then
        results[key] = Sim.run(Sim.scenario(kind, size, fps, seed))
    end
    return results[key]
end

-- Three fights of a kind, judged together: one alone swings widely.
local function fights(kind, size, fps)
    local list = {}
    for seed = 7, 9 do
        tinsert(list, scenario(kind, size, fps, seed))
    end
    return list
end

local suite = {
    ["readback: the fixed values read every level back to itself"] = function(t)
        for level = 0, 16 do
            local raw = GroupHealth.readbackRaw(played(level))
            t:assertTrue(math.abs(raw - level) < 0.15, "level " .. level .. " reads " .. raw)
        end
    end,

    ["readback: under every plan each health reads back as the value of its band"] = function(t)
        for _, case in ipairs(PLANS) do
            local plan = case[2]
            for percent = 0, 100 do
                local health = percent / 100
                local value, why = readAt(plan, health)
                t:assertEqual(value, evaluate(plan.points, health), case[1] .. ", " .. percent .. " percent: " .. tostring(why))
                local band = plan.intervals[value]
                t:assertTrue(health >= band[1] - 1e-9 and health <= band[2] + 1e-9, case[1] .. ", " .. percent .. " percent outside its band")
            end
        end
    end,

    ["readback: one utterance plays under two seconds, \"moved less\" the shortest"] = function(t)
        for _, case in ipairs(PLANS) do
            for _, digits in ipairs(case[2].digitPoints) do
                for _, point in ipairs(digits) do
                    t:assertTrue(point[2] <= R.SILENCE_OFFSET + 16 * R.LEVEL_SILENCE, case[1])
                end
            end
        end
        t:assertTrue(played(16) < 1850)
        t:assertEqual(readAt(GroupHealth.changePlan(60, 10, nil, 0.8), 0.6), 0)
    end,

    ["readback: the background's fixed 462 ms is thrown away, not read as a level"] = function(t)
        for _, case in ipairs(PLANS) do
            local value, why = GroupHealth.readbackValue(case[2], 462, 461)
            t:assertNil(value, case[1])
            t:assertEqual(why, "game in the background")
        end
        -- A real level 2 pair is still read; one utterance has no level 2.
        t:assertEqual(GroupHealth.readbackValue(stepPlan("pair"), played(2), played(2)), 10)
        t:assertEqual(GroupHealth.readbackValue(stepPlan(), played(3)), 2)
    end,

    ["readback: two digits in the wrong order or between levels never pass"] = function(t)
        -- Under the step plan 0 and 3 is step 3; swapped it is out of range.
        local plan = stepPlan("pair")
        t:assertEqual(GroupHealth.readbackValue(plan, played(0), played(3)), 3)
        t:assertNil(GroupHealth.readbackValue(plan, played(3), played(0)))
        local value, why = GroupHealth.readbackValue(plan, played(1) + 50, played(0))
        t:assertNil(value)
        t:assertEqual(why, "between levels")
        value, why = GroupHealth.readbackValue(stepPlan(), played(4) + 50)
        t:assertNil(value)
        t:assertEqual(why, "between levels")
    end,

    ["readback: every padding has the same length and no two are alike"] = function(t)
        -- Characters, not bytes: a no-break space is two bytes, a space one.
        local function chars(s)
            return select(2, s:gsub("[^\128-\191]", ""))
        end
        local seen = {}
        local length = chars(GroupHealth.readbackPad(0))
        for n = 0, 2000 do
            local pad = GroupHealth.readbackPad(n)
            t:assertEqual(chars(pad), length)
            t:assertNil(seen[pad])
            seen[pad] = true
        end
    end,

    ["change plan: \"moved less\" is exactly the reference -/+ the threshold"] = function(t)
        local plan = GroupHealth.changePlan(60, 10, nil, 0.8)
        local middle = readAt(plan, 0.6)
        t:assertEqual(readAt(plan, 0.5), middle)
        t:assertEqual(readAt(plan, 0.699), middle)
        t:assertTrue(readAt(plan, 0.499) ~= middle)
        t:assertTrue(readAt(plan, 0.70) ~= middle)
    end,

    ["change plan: every heard band is narrow enough to place the member at once"] = function(t)
        for reference = 0, 100 do
            for _, threshold in ipairs({ 2, 5, 10, 20, 30, 50 }) do
                for _, speakBelow in ipairs({ 0.5, 0.7, 0.8, 0.9, 1 }) do
                    for steps = 0, 3 do
                        local quiet = GroupHealth.pitchQuiet(levels, reference, steps)
                        local plan = GroupHealth.changePlan(reference, threshold, quiet, speakBelow)
                        local where = reference .. "/" .. threshold .. "/" .. speakBelow .. "/" .. steps
                        t:assertTrue(#plan.points <= 16, where .. ": " .. #plan.points .. " bands")
                        for _, point in ipairs(plan.points) do
                            local band = plan.intervals[point[2]]
                            local heard = band[2] <= speakBelow + 1e-9
                            local outside = band[2] <= plan.quiet[1] + 1e-9 or band[1] >= plan.quiet[2] - 1e-9
                            -- At most 8 percent wide: the reference within 4 of
                            -- the heard health, finer than a pitch level (about 7).
                            if heard and outside then
                                t:assertTrue(band[2] - band[1] <= 0.08 + 1e-9, where .. ": band " .. band[1] .. " to " .. band[2])
                            end
                        end
                    end
                end
            end
        end
    end,

    ["change plan: health above Speak Below is one band, as a move there is silent"] = function(t)
        local plan = GroupHealth.changePlan(40, 20, nil, 0.7)
        t:assertEqual(readAt(plan, 0.71), readAt(plan, 0.99))
        t:assertTrue(readAt(plan, 0.69) ~= readAt(plan, 0.71))
    end,

    ["change plan: full health is a band of its own below a full reference"] = function(t)
        local plan = GroupHealth.changePlan(80, 10, nil, 0.9)
        local band = plan.intervals[readAt(plan, 1)]
        t:assertEqual(band[1], 1)
        t:assertEqual(band[2], 1)
        -- At a full reference full health is simply "moved less".
        local full = GroupHealth.changePlan(100, 10, nil, 0.9)
        t:assertEqual(readAt(full, 1), readAt(full, 0.95))
        -- "Moved less" reaching exactly 100 (a tank's pitch step from 87):
        -- the gate hears full health, so the plan must not call it "moved
        -- less" (seen in the simulation: "full" heard, the reference left).
        local tank = GroupHealth.changePlan(87, 5, GroupHealth.pitchQuiet(levels, 87, 1), 0.9)
        band = tank.intervals[readAt(tank, 1)]
        t:assertEqual(band[1], 1)
        t:assertEqual(evaluate(GroupHealth.gatePoints(1, 2, tank.quiet), 1), 100)
    end,

    ["unsure plan: no \"moved less\", the gate is open wherever the lane speaks"] = function(t)
        local plan = GroupHealth.unsurePlan(40, 0.8)
        local points = GroupHealth.gatePoints(0, 0.8, plan.quiet)
        for percent = 0, 79 do
            t:assertEqual(evaluate(points, percent / 100), 100, percent .. " percent")
        end
    end,

    ["gate: Sku's rule as a volume gate, silent exactly in the quiet band"] = function(t)
        local plan = GroupHealth.changePlan(60, 10, nil, 0.8)
        local points = GroupHealth.gatePoints(0, 0.8, plan.quiet)
        t:assertEqual(evaluate(points, 0.49), 100)
        t:assertEqual(evaluate(points, 0.5), 0)
        t:assertEqual(evaluate(points, 0.699), 0)
        t:assertEqual(evaluate(points, 0.7), 100)
        -- Above "Speak Below" silent anyway.
        t:assertEqual(evaluate(points, 0.85), 0)
        -- Full health: a gate of its own, heard only from far enough away.
        t:assertEqual(evaluate(GroupHealth.gatePoints(1, 2, plan.quiet), 1), 100)
        t:assertEqual(evaluate(GroupHealth.gatePoints(1, 2, GroupHealth.changePlan(95, 10).quiet), 1), 0)
    end,

    ["rule: the first reading only sets the reference; above Speak Below it is full"] = function(t)
        local member = {}
        t:assertFalse(GroupHealth.judge(member, plain(GroupHealth.locatePlan(), 0.6), 10, 0.8))
        t:assertTrue(math.abs(member.reference - 60) <= 3.2, "reference " .. member.reference)
        -- Nothing heard and above Speak Below: the player takes the member
        -- for healthy, as Sku starts everyone at full.
        member = {}
        t:assertFalse(GroupHealth.judge(member, plain(GroupHealth.locatePlan(), 0.86), 10, 0.8))
        t:assertEqual(member.reference, 100)
    end,

    ["rule: less than the minimum change says nothing, the minimum change announces"] = function(t)
        local member = { reference = 60 }
        t:assertFalse(GroupHealth.judge(member, reading(GroupHealth.changePlan(60, 10, nil, 0.8), 0.52), 10, 0.8))
        t:assertFalse(GroupHealth.judge(member, reading(GroupHealth.changePlan(60, 10, nil, 0.8), 0.68), 10, 0.8))
        t:assertEqual(member.reference, 60)
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.changePlan(60, 10, nil, 0.8), 0.49), 10, 0.8))
        -- The new reference: the middle of a narrow band.
        t:assertTrue(math.abs(member.reference - 49) <= 3, "reference " .. member.reference)
    end,

    ["rule: small moves add up, as in Sku"] = function(t)
        local member = { reference = 80 }
        for _, health in ipairs({ 0.77, 0.74, 0.72 }) do
            t:assertFalse(GroupHealth.judge(member, reading(GroupHealth.changePlan(member.reference, 10, nil, 0.9), health), 10, 0.9))
        end
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.changePlan(member.reference, 10, nil, 0.9), 0.69), 10, 0.9))
    end,

    ["rule: the reference is what the player last heard, a move above Speak Below leaves it"] = function(t)
        -- Heard at 40, healed to 85 (silent above 70), back down to 62:
        -- 22 percent from what the player heard, so it is said.
        local member = { reference = 40 }
        t:assertFalse(GroupHealth.judge(member, reading(GroupHealth.changePlan(40, 20, nil, 0.7), 0.85), 20, 0.7))
        t:assertEqual(member.reference, 40)
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.changePlan(40, 20, nil, 0.7), 0.62), 20, 0.7))
    end,

    ["rule: unsure, the next heard number sets the reference and ends it"] = function(t)
        local member = { reference = 40, unsure = true }
        -- Above Speak Below nothing is heard: still unsure.
        t:assertFalse(GroupHealth.judge(member, reading(GroupHealth.planFor(member, 10, nil, 0.8), 0.9), 10, 0.8))
        t:assertTrue(member.unsure)
        -- Heard right at the old reference: known again.
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.planFor(member, 10, nil, 0.8), 0.41), 10, 0.8))
        t:assertFalse(member.unsure)
        t:assertTrue(math.abs(member.reference - 41) <= 3, "reference " .. member.reference)
    end,

    ["rule: a plain sample never moves the reference"] = function(t)
        local member = { reference = 50 }
        t:assertFalse(GroupHealth.judge(member, plain(GroupHealth.changePlan(50, 10), 0.3), 10))
        t:assertEqual(member.reference, 50)
    end,

    ["rule: a carried sample is judged by the gate its number went out behind"] = function(t)
        -- The number went out around 60; another reading moved the
        -- reference to 50 meanwhile. 0.49 is outside 60 -/+ 10: heard.
        local member = { reference = 50 }
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.changePlan(60, 10), 0.49), 10))
    end,

    ["rule: with a pitch step, a tank's move inside one pitch level stays silent"] = function(t)
        local quiet = GroupHealth.pitchQuiet(levels, 61, 1)
        -- 61 to 66: five percent, the tank's minimum change, same pitch.
        local plan = GroupHealth.changePlan(61, 5, quiet, 0.9)
        t:assertFalse(GroupHealth.judge({ reference = 61 }, reading(plan, 0.66), 5, 0.9))
        -- 61 to 68: the next pitch level.
        t:assertTrue(GroupHealth.judge({ reference = 61 }, reading(plan, 0.68), 5, 0.9))
        -- 61 to 55: a lower level, and more than five percent.
        t:assertTrue(GroupHealth.judge({ reference = 61 }, reading(plan, 0.55), 5, 0.9))
        -- The gate keeps silent exactly what the judge calls "moved less".
        t:assertEqual(plan.quiet[2], quiet[2])
        t:assertTrue(math.abs(plan.quiet[1] - 0.56) < 1e-9)
    end,

    ["rule: after a death (reference 0) the resurrection announces"] = function(t)
        local member = { reference = 0 }
        t:assertTrue(GroupHealth.judge(member, reading(GroupHealth.changePlan(0, 10, nil, 0.8), 0.35), 10, 0.8))
    end,

    ["speak first: a hit on a quiet member is heard at once"] = function(t)
        local opts = Sim.scenario("hover", 5, 60)
        opts.disturb = {}
        for _, m in ipairs(opts.members) do
            m.subject = nil
            m.health = 1
            m.script = {}
        end
        local tank = opts.members[2]
        tank.subject = true
        tank.script = { { 5, 0.4 } }
        local result = Sim.run(opts)
        local heard = result.members[2].announcements
        t:assertEqual(#heard, 1)
        t:assertTrue(heard[1].t - 5 < 0.15, "heard after " .. (heard[1].t - 5))
    end,

    ["a voice that does not fit the fixed values: stuck purges, and the failure is said once"] = function(t)
        local opts = Sim.scenario("spikes", 5, 60)
        opts.baseMs = 290
        local result = Sim.run(opts)
        t:assertEqual(result.failingSaid, 1)
        t:assertTrue((result.stats.purges.stuck or 0) >= 1, "no stuck purge")
    end,

    -- Someone else's speech called just before our slot: its start comes
    -- sooner after our call than the engine ever starts ours, and ours come
    -- one engine step later than usual.
    ["a start too soon to be ours is left out, and ours may come one engine step later"] = function(t)
        local now, timers, silences, readings = 0, {}, {}, {}
        local owners = {}
        local readback = GroupHealth.Readback:new({
            line = GroupHealth.newReadbackLine(),
            now = function()
                return now
            end,
            after = function(seconds, fn)
                tinsert(timers, { at = now + seconds * 1000, fn = fn })
            end,
            speak = function(text)
                tinsert(silences, tonumber(text:match('msec="(%d+)"')))
            end,
            through = function(_, points)
                return evaluate(points, 0.55)
            end,
            nextCount = function()
                return #silences + 1
            end,
            frameMs = function()
                return 17
            end,
            startOwner = function(id)
                return owners[id], owners[id] ~= nil and 0 or nil
            end,
            onReading = function(_, reading)
                tinsert(readings, reading)
            end,
        })
        local function advance(to)
            while true do
                table.sort(timers, function(a, b)
                    return a.at < b.at
                end)
                local timer = timers[1]
                if timer == nil or timer.at > to then
                    break
                end
                tremove(timers, 1)
                now = math.max(now, timer.at)
                timer.fn()
            end
            now = to
        end
        readback:request("party1")
        t:assertEqual(#silences, 1)
        -- Not ours (no call matched), 10 ms after our call.
        advance(10)
        readback:onStarted(500)
        -- Ours, behind it: past the usual window (100 ms for one call).
        owners[501] = "aside"
        advance(115)
        readback:onStarted(501)
        local ends = 115 + 190 + 0.3314 * silences[1]
        advance(ends)
        readback:onFinished(501, false)
        advance(ends + 2000)
        t:assertEqual(#readings, 1)
        t:assertEqual(readings[1].value, readAt(GroupHealth.locatePlan(), 0.55))
        t:assertEqual(readback.stats.earlyStarts, 1)
    end,

    ["the log's description of a thrown-away slot"] = function(t)
        local slot = { t = 1000, expect = 2, why = "a start right after ours", seen = {
            { t = 1041, id = 11, owner = "aside" },
            { t = 1078, id = 12, owner = "aside" },
            { t = 1020, id = 10, owner = "unseen", early = true },
        }, after = { t = 1150, id = 13, owner = "unseen" } }
        t:assertEqual(GroupHealth.describeSlot(slot),
            "a start right after ours; 2 calls; starts: +20 ms id 0 not WowVision's too soon, +41 ms id 1, +78 ms id 2, +150 ms id 3 not WowVision's")
    end,

    -- Blizzard's Combat Audio Alerts speak on the same health event as our
    -- check, unseen by WowVision, before or after it: samples are lost,
    -- never misread (a party of two, as in the game 2026-10-14).
    ["Blizzard's alerts on the same health event: checks lost, nothing misread or swallowed"] = function(t)
        for _, order in ipairs({ "before", "after" }) do
            for seed = 1, 3 do
                local opts = Sim.scenario("party", 5, 60, seed * 11)
                opts.members = { opts.members[1], opts.members[2] }
                opts.disturb = { caa = { units = { player = true, party1 = true }, chance = 0.6, order = order } }
                for k, v in pairs(Sim.REAL_FIGHT) do
                    opts.disturb[k] = v
                end
                local result = Sim.run(opts)
                local total = result.total
                t:assertTrue(result.caa > 20, result.caa .. " alerts")
                t:assertTrue(total.misreads <= math.max(1, 0.005 * total.readings), total.misreads .. " misread of " .. total.readings .. ", " .. order)
                t:assertTrue((result.gateMismatches or 0) <= total.misreads, (result.gateMismatches or 0) .. " gate mismatches")
                t:assertTrue(total.silentMoves <= 2, total.silentMoves .. " moves taken as said without their number")
            end
        end
    end,

    ["the simulation runs the same every time"] = function(t)
        local a = Sim.run(Sim.scenario("party", 5, 60, 7)).total
        local b = Sim.run(Sim.scenario("party", 5, 60, 7)).total
        t:assertEqual(a.outdated, b.outdated)
        t:assertEqual(a.heard, b.heard)
    end,
}

-- Seen in game: a second readback beside the monitor, both woken by the
-- same health events, lost almost every sample as ambiguous while each had
-- its own slot line. On the shared line both read.
for _, kind in ipairs({ "spikes", "drift" }) do
    suite["two readbacks on the same member share the slot line: both read, " .. kind] = function(t)
        local opts = Sim.scenario(kind, 5, 60)
        opts.secondReader = true
        local result = Sim.run(opts)
        local second = result.second
        -- (A band off now and then: the spread measured in game.)
        t:assertTrue(result.total.misreads <= math.max(1, 0.005 * result.total.readings), result.total.misreads .. " misread of " .. result.total.readings)
        t:assertTrue(second.misreads <= math.max(1, 0.005 * second.readings), second.misreads .. " misread by the second")
        t:assertTrue(second.stats.readings >= second.stats.samples * 0.8, second.stats.readings .. " of " .. second.stats.samples .. " used")
    end
end

-- The bars per scenario (party of 5, raid of 10): out of date at most,
-- repeats at most. Measured 2026-10-14 at 60 / 30 fps, three fights each,
-- with the spread of the played times measured in game (Sim.SPREAD_MS;
-- Sku in brackets):
-- - party (the fight logged in game): 9.0 / 8.2 percent (0.8 / 1.2), raid
--   9.4 / 10.4 (1.3 / 1.6); repeats 31 to 40 percent.
-- - spikes: 6.8 / 7.7 (0.6 / 0.9), raid 3.8 / 4.0; repeats 4 to 9.
-- - stops: 7.5 / 7.8, raid 4.2 / 4.7; repeats 13 to 19.
-- - fight (everyone hit hard): 26.2 / 26.4 (9.3 / 10.1), raid 31.8 / 32.0
--   (25.0 / 25.2); repeats 22 to 27.
-- - drift: 0.6 / 0.6, raid 2.0 / 1.9; repeats up to 27.
-- (The code before 2026-10-14 had the party at 19.5 percent, raid 28.6,
-- with 15 and 37 moves taken as said without their number.)
local BARS = {
    party = { [5] = 0.10, [10] = 0.12, repeats = 0.45 },
    spikes = { [5] = 0.085, [10] = 0.05, repeats = 0.12 },
    stops = { [5] = 0.10, [10] = 0.06, repeats = 0.25 },
    fight = { [5] = 0.30, [10] = 0.36, repeats = 0.30 },
    drift = { [5] = 0.015, [10] = 0.03, repeats = 0.35 },
}

for _, fps in ipairs({ 60, 30 }) do
    for _, size in ipairs({ 5, 10 }) do
        local where = string.format("%d players, %d fps", size, fps)
        for kind, bar in pairs(BARS) do
            suite["scenario " .. kind .. ", " .. where .. ": nothing misread, nothing swallowed, not more out of date than measured"] = function(t)
                local list = fights(kind, size, fps)
                -- With the spread measured in game a reading is now and
                -- then one band off (beyond half a level): up to 0.3
                -- percent in the simulation, none of 192 in the probe.
                t:assertTrue(pooled(list, "misreads") <= 0.005 * pooled(list, "readings"), pooled(list, "misreads") .. " misread of " .. pooled(list, "readings"))
                -- The gate and the judge agree, but for a misread band.
                for _, result in ipairs(list) do
                    t:assertTrue((result.gateMismatches or 0) <= result.total.misreads, (result.gateMismatches or 0) .. " gate mismatches")
                end
                -- A move taken as said without its number: none, but for a
                -- number a stop cut again when it was said again.
                t:assertTrue(pooled(list, "silentMoves") <= 2, pooled(list, "silentMoves") .. " moves taken as said without their number")
                local ours, sku = outdated(list)
                t:assertTrue(ours <= bar[size], string.format("out of date %.1f percent of the time (Sku %.1f)", ours * 100, sku * 100))
                t:assertTrue(repeatShare(list) <= bar.repeats, string.format("repeats %.0f percent", repeatShare(list) * 100))
            end
        end
        suite["scenario hover, " .. where .. ": a healer hovering at a line, almost nothing said"] = function(t)
            local list = fights("hover", size, fps)
            t:assertTrue(pooled(list, "misreads") <= 0.005 * pooled(list, "readings"), pooled(list, "misreads") .. " misread")
            local ours = outdated(list)
            t:assertEqual(ours, 0)
            -- Sku says nothing; a number cut by a stop is said again.
            t:assertTrue(pooled(list, "heard") <= 12, pooled(list, "heard") .. " numbers in three fights")
        end
    end
end

testRunner:addSuite("GroupHealthReadback", suite)
