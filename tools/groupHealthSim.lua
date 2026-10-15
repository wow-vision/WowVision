-- Offline simulation of the group health monitor with the health readback
-- (retail/groupHealth/readback.lua): a party of 5 or a raid of 10, scripted
-- health, a simulated speech engine, the monitor in miniature (speak first,
-- check afterwards: a health event sends the number gated by the quiet band
-- at once, carried by a sample). The readback code, the rule
-- (GroupHealth.judge) and the gate (GroupHealth.gatePoints' band) are the
-- real ones. It is scored against Sku's rule run on the true health: an
-- announcement whenever health moved the role's minimum change since the
-- last one, heard below the role's "Speak Below" or at full health.
--
-- The engine copies what was measured on WoW: Forever (2026-10-13):
-- - a start comes 34 to 56 ms after the call, events land on frames;
-- - an utterance 'a<silence msec="s"/>' at rate 10 plays 190 + 0.3314 * s ms
--   (opts.baseMs and opts.slope replace the two numbers, for another
--   voice), plus Sim.LATE_MS and a spread of Sim.SPREAD_MS (below);
--   utterances overlap freely;
-- - other WowVision speech plays beside ours; now and then a stop of all
--   speech (hooked, like C_VoiceChat.StopSpeakingText: the readback purges,
--   reads everyone again and hands back cut numbers), a stop followed by
--   new speech in the same frame (WowVision's interrupting alerts and UI
--   keys, hooked too) or an interrupting call (no hook: everything ends,
--   the new speech starts) cuts samples, and the numbers playing with them.
-- Not known yet, so not modelled: an engine limit on overlapping utterances.
--
-- Used by tools/groupHealthSimTests.lua (headless suite) and
-- tools/group-health-sim.lua (printed report).

local GroupHealth = WowVision.groupHealth
local R = GroupHealth.readbackConstants

local Sim = {}

-- The monitor's role defaults (retail/groupHealth/module.lua), thresholds in percent.
Sim.ROLES = {
    TANK = { start = 90, urgent = 50, minChange = 5, minPitchSteps = 1 },
    HEALER = { start = 80, urgent = 40, minChange = 10, minPitchSteps = 1 },
    DAMAGER = { start = 70, urgent = 35, minChange = 20, minPitchSteps = 2 },
}
-- The pitch levels of the fallback voice (Hedda).
Sim.LEVELS = GroupHealth.pitchLevels(GroupHealth.voices.fallback)

-- Which pitch level a health sounds at.
local function levelOf(health)
    for i, level in ipairs(Sim.LEVELS) do
        if health >= level[1] and health < level[2] then
            return i
        end
    end
    return #Sim.LEVELS
end
-- The spread of the played times, from 192 single utterances on the
-- user's machine (a developer probe, 2026-10-14, Sound in Background on,
-- game in front): off a level median 0.10, 90 percent within 0.26, 99
-- within 0.41, worst 0.47, 0.04 late on average, 1 of 192 thrown away.
-- The simulated probe (frames at 60 fps, these two values) gives about
-- 0.12, 0.25, 0.38, and 0.5 percent thrown away.
Sim.LATE_MS = 4
Sim.SPREAD_MS = 13
Sim.SPACING = 0.2
-- Preparing one utterance in the engine, ms (see engineSpeak).
Sim.ENGINE_MS = { 33, 40 }
-- From the call to the number being heard (the engine's start).
Sim.START_S = 0.045
Sim.ANNOUNCE_MS = 700
-- A number cut by a stop sooner than this after its start was not heard:
-- both copies of the number (logic.lua; the second may be the audible
-- one). Rough, not measured.
Sim.NUMBER_HEARD_MS = 400

-- Deterministic random numbers (a plain LCG), so every run is the same.
local function rng(seed)
    local state = seed
    local r = {}
    function r.next()
        state = (state * 1103515245 + 12345) % 2147483648
        return state / 2147483648
    end
    function r.range(a, b)
        return a + (b - a) * r.next()
    end
    function r.normal(sd)
        local u1, u2 = math.max(r.next(), 1e-9), r.next()
        return sd * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    end
    return r
end

local function evalPoints(points, x)
    local y = points[1][2]
    for _, p in ipairs(points) do
        if x >= p[1] then
            y = p[2]
        end
    end
    return y
end

-- Health scripts: each member gets a list of { t (seconds), health (0..1) }.
local function clamp(h, lo, hi)
    return math.max(lo, math.min(hi, h))
end

-- Strong hits and big heals, health changing every second or so.
function Sim.spikes(r, duration)
    local events = {}
    local h = 1.0
    local nextHit, nextHeal = r.range(0.5, 1.2), r.range(1.0, 2.0)
    while true do
        local t = math.min(nextHit, nextHeal)
        if t > duration then
            break
        end
        if nextHit <= nextHeal then
            h = clamp(h - r.range(0.10, 0.30), 0.03, 1)
            nextHit = t + r.range(0.8, 1.6)
        else
            h = clamp(h + r.range(0.15, 0.35), 0.03, 1)
            nextHeal = t + r.range(1.2, 2.4)
        end
        tinsert(events, { t, h })
    end
    return events
end

-- Moderate damage and healing, as in the first party fight logged in game
-- (2026-10-14: the player went from 77 to 13 percent in about 27 seconds):
-- hits of 5 to 15 percent every 1 to 3 seconds, heals of 5 to 20 every 2
-- to 4.
function Sim.moderate(r, duration)
    local events = {}
    local h = 1.0
    local nextHit, nextHeal = r.range(0.5, 3), r.range(1, 4)
    while true do
        local t = math.min(nextHit, nextHeal)
        if t > duration then
            break
        end
        if nextHit <= nextHeal then
            h = clamp(h - r.range(0.05, 0.15), 0.03, 1)
            nextHit = t + r.range(1, 3)
        else
            h = clamp(h + r.range(0.05, 0.20), 0.03, 1)
            nextHeal = t + r.range(2, 4)
        end
        tinsert(events, { t, h })
    end
    return events
end

-- A slow change: a tick every `every` seconds by `step` (negative drains).
function Sim.drift(start, step, every, duration)
    local events = {}
    local h = start
    local t = every
    while t <= duration do
        h = clamp(h + step, 0.01, 1)
        tinsert(events, { t, h })
        t = t + every
    end
    return events
end

-- Small wobble that stays inside one step: events, but nothing meaningful.
function Sim.wobble(r, base, duration)
    local events = {}
    local stepLow = math.floor(base * 10) / 10
    local t = r.range(1, 4)
    while t <= duration do
        tinsert(events, { t, clamp(base + r.range(-0.03, 0.03), stepLow + 0.005, stepLow + 0.095) })
        t = t + r.range(2, 5)
    end
    return events
end

-- The simulation -----------------------------------------------------------------

local function newWorld(opts)
    local world = {
        now = 0,
        timers = {},
        seq = 0,
        fps = opts.fps or 60,
        r = rng(opts.seed or 1),
        nextId = 1000,
        active = {},
        log = {},
    }
    world.phase = world.r.range(0, 1000 / world.fps)
    function world.after(seconds, fn)
        world.seq = world.seq + 1
        tinsert(world.timers, { at = world.now + seconds * 1000, seq = world.seq, fn = fn })
    end
    function world.at(ms, fn)
        world.after((ms - world.now) / 1000, fn)
    end
    -- The next frame boundary at or after t.
    function world.frame(t)
        local f = 1000 / world.fps
        return world.phase + math.ceil((t - world.phase) / f) * f
    end
    function world.run(untilMs)
        while true do
            local best, bestIndex = nil, nil
            for i, timer in ipairs(world.timers) do
                if best == nil or timer.at < best.at or (timer.at == best.at and timer.seq < best.seq) then
                    best, bestIndex = timer, i
                end
            end
            if best == nil or best.at > untilMs then
                break
            end
            tremove(world.timers, bestIndex)
            world.now = math.max(world.now, best.at)
            best.fn()
        end
        world.now = untilMs
    end
    return world
end

-- The engine: utterances with ids, start and finish events on frames.
-- The engine is one line (flood probe, 2026-10-13: 20, 40, 80 silent
-- utterances in one frame all played, started one after another about 36
-- ms apart, the first 34 to 56 ms after the call): each utterance is
-- prepared after the one before has started, for ENGINE_MS.
-- `owner`: who called, as WowVision's speech module sees it ("aside" for
-- the monitor, "queue" for WowVision's own speech, nil for speech it
-- cannot see: Blizzard's Combat Audio Alerts).
local function engineSpeak(world, playedMs, handlers, owner)
    if handlers.called ~= nil then
        handlers.called(owner)
    end
    world.nextId = world.nextId + 1
    local id = world.nextId
    local callMs = world.now
    local begin = math.max(callMs, world.engineFreeAt or 0)
    local startMs = begin + world.r.range(Sim.ENGINE_MS[1], Sim.ENGINE_MS[2])
    world.engineFreeAt = startMs
    local u = { id = id }
    world.active[id] = u
    world.at(world.frame(startMs), function()
        -- Stopped before it started: it never starts.
        if world.active[id] == u then
            u.startedAt = world.now
            handlers.started(id)
        end
    end)
    u.finishTimer = world.frame(startMs + playedMs)
    world.at(u.finishTimer, function()
        if world.active[id] == u then
            world.active[id] = nil
            handlers.finished(id)
        end
    end)
    return id
end

-- Ends every utterance at once (the stop of all speech). A stopped
-- utterance never reports its end (Blizzard's TextToSpeechFrame.lua:
-- "Purged utterances never signal VOICE_CHAT_TTS_PLAYBACK_FINISHED").
local function engineStopAll(world, handlers)
    for id, u in pairs(world.active) do
        world.active[id] = nil
        handlers.cut(id, u.startedAt)
    end
    world.engineFreeAt = world.now
end

-- Sku's rule on the true health: the announcements a monitor that could
-- read health would make, each with the health it moved to: moved the
-- minimum change and the minimum pitch steps.
function Sim.ideal(m)
    local role = Sim.ROLES[m.role]
    local a = role.minChange / 100
    local list = {}
    local ref = m.health
    for _, ev in ipairs(m.script) do
        local h = ev[2]
        if math.abs(h - ref) >= a - 1e-9 and math.abs(levelOf(h) - levelOf(ref)) >= role.minPitchSteps then
            local audible = h < role.start / 100 or h >= 1
            tinsert(list, { t = ev[1], health = h, audible = audible })
            -- The reference is what the player last heard.
            if audible then
                ref = h
            end
        end
    end
    return list
end

function Sim.run(opts)
    local world = newWorld(opts)
    local duration = opts.duration
    local members = {}
    local byUnit = {}
    for _, spec in ipairs(opts.members) do
        local m = {
            unit = spec.unit,
            number = spec.number,
            role = spec.role,
            health = spec.health,
            startHealth = spec.health,
            script = spec.script or {},
            subject = spec.subject,
            calls = {},
            readings = 0,
            misreads = 0,
            triggers = {},
            announcements = {},
        }
        m.ideal = Sim.ideal(m)
        tinsert(members, m)
        byUnit[m.unit] = m
    end
    local result = { members = members, opts = opts, respoken = 0, foreignCalls = {}, foreignDelays = {}, heardIds = {} }
    local counter = 0
    local readback
    local handlers = {}
    -- Heard: below the role's "Speak Below" or at full health, and outside
    -- the quiet band the number went out behind.
    local function audible(m, quiet)
        local role = Sim.ROLES[m.role]
        local h = m.health
        if h >= quiet[1] and h < quiet[2] then
            return false
        end
        return h < role.start / 100 or h >= 1
    end

    -- Each run its own slot line: the addon's shared one would carry the
    -- times of an earlier run.
    local line = GroupHealth.newReadbackLine()
    local startOwner
    local function speakSample(text)
        local silence = tonumber(text:match('msec="(%d+)"'))
        local played = (opts.baseMs or 190) + (opts.slope or 0.3314) * silence + (opts.lateMs or Sim.LATE_MS) + world.r.normal(opts.noiseMs or Sim.SPREAD_MS)
        engineSpeak(world, played, handlers, "aside")
    end
    -- The monitor's real checks (retail/groupHealth/checks.lua) on the
    -- simulated engine.
    local checks = GroupHealth.Checks:new({
        line = line,
        members = function()
            return byUnit
        end,
        memberFor = function(unit)
            return byUnit[unit]
        end,
        threshold = function(m)
            return Sim.ROLES[m.role].minChange
        end,
        pitchQuiet = function(m)
            return GroupHealth.pitchQuiet(Sim.LEVELS, m.reference, Sim.ROLES[m.role].minPitchSteps)
        end,
        urgent = function(m)
            return Sim.ROLES[m.role].urgent
        end,
        speakBelow = function(m)
            return Sim.ROLES[m.role].start / 100
        end,
        -- opts.hold = { units = { [unit] = true }, ms }: checks of those
        -- members wait that long after their health event.
        holdMs = opts.hold ~= nil and function(m)
            return opts.hold.units[m.unit] and opts.hold.ms or 0
        end or nil,
        -- As the module: the number with "<number> full" in one utterance,
        -- before the digits, heard from its start.
        carry = function(m, quiet)
            -- Remembered to check that the gate and the judge agree.
            m.carries = m.carries or {}
            m.carries[world.now] = audible(m, quiet)
            local heard = nil
            if audible(m, quiet) then
                heard = { health = m.health, lane = "change", eventAt = m.eventAt }
                tinsert(m.announcements, heard)
            end
            m.eventAt = nil
            local id = engineSpeak(world, Sim.ANNOUNCE_MS, handlers, "aside")
            if heard ~= nil then
                result.heardIds[id] = heard
            end
            return 1
        end,
        now = function()
            return world.now
        end,
        after = world.after,
        speak = speakSample,
        through = function(unit, points)
            local m = byUnit[unit]
            -- The engine reads the health at the call: the truth for the
            -- reading of this sample, found again by its call time.
            m.calls[world.now] = m.health
            return evalPoints(points, m.health)
        end,
        nextCount = function()
            counter = counter + 1
            return counter
        end,
        frameMs = function()
            return 1000 / world.fps
        end,
        startOwner = function(id)
            return startOwner(id)
        end,
        onFailing = function()
            result.failingSaid = (result.failingSaid or 0) + 1
        end,
        onError = function(err)
            error(err)
        end,
        trace = function(m, what)
            if what == "respeak" then
                result.respoken = result.respoken + 1
            end
        end,
    })
    readback = checks.readback
    -- Every reading scored against the truth, around the real handling.
    function checks:onReading(unit, reading)
        local m = byUnit[unit]
        m.readings = m.readings + 1
        -- Truth: the band the health was in when the sample was called.
        if reading.value ~= evalPoints(reading.plan.points, m.calls[reading.calledMs]) then
            m.misreads = m.misreads + 1
        end
        local before = { reference = m.reference }
        local moved = GroupHealth.Checks.onReading(self, unit, reading)
        -- The gate (heard or not) and the judge must agree, else the
        -- reference stays after a heard number and the next repeats it.
        if reading.carried and not reading.recheck and m.carries ~= nil and m.carries[reading.calledMs] ~= nil then
            result.carried = (result.carried or 0) + 1
            if m.carries[reading.calledMs] ~= moved then
                result.gateMismatches = (result.gateMismatches or 0) + 1
            end
        end
        if moved then
            tinsert(m.triggers, { t = world.now / 1000, reference = m.reference, health = m.calls[reading.calledMs], plan = reading.plan, band = reading.plan.intervals[reading.value], before = before, calledMs = reading.calledMs, carried = reading.carried })
        end
        return moved
    end
    local function check(m)
        m.eventAt = m.eventAt or world.now / 1000
        checks:onEvent(m.unit)
    end

    -- A second reader on the subjects, woken by the same events (its
    -- default plan, zooming into 0 to 100): on the shared line, or (the
    -- bug seen in game) on a line of its own.
    local second
    if opts.secondReader then
        result.second = { readings = 0, misreads = 0 }
        second = GroupHealth.Readback:new({
            line = opts.separateLines and GroupHealth.newReadbackLine() or line,
            now = function()
                return world.now
            end,
            after = world.after,
            speak = speakSample,
            through = function(unit, points)
                local m = byUnit[unit]
                m.secondCalls = m.secondCalls or {}
                m.secondCalls[world.now] = m.health
                return evalPoints(points, m.health)
            end,
            nextCount = function()
                counter = counter + 1
                return counter
            end,
            onReading = function(unit, reading)
                local m = byUnit[unit]
                result.second.readings = result.second.readings + 1
                if reading.value ~= evalPoints(reading.plan.points, m.secondCalls[reading.calledMs]) then
                    result.second.misreads = result.second.misreads + 1
                end
            end,
        })
    end
    local readers = { readback, second }
    -- WowVision's speech module, as retail/speech.lua: calls in order, each
    -- start matched to the oldest call (not sooner than 30 ms after it).
    local calls, owners = {}, {}
    handlers.called = function(owner)
        if owner ~= nil and not opts.noOwners then
            tinsert(calls, { owner = owner, atMs = world.now })
        end
    end
    handlers.stopped = function()
        calls = {}
    end
    local function resolve(id)
        if owners[id] == nil then
            while calls[1] ~= nil and world.now - calls[1].atMs > 2000 do
                tremove(calls, 1)
            end
            local head = calls[1]
            if head ~= nil and world.now - head.atMs >= 30 then
                owners[id] = tremove(calls, 1)
            else
                owners[id] = false
            end
        end
        return owners[id] or nil
    end
    startOwner = function(id)
        local entry = resolve(id)
        if entry == nil then
            return nil
        end
        return entry.owner, entry.atMs
    end
    handlers.started = function(id)
        resolve(id)
        if result.heardIds[id] ~= nil then
            result.heardIds[id].t = world.now / 1000
        end
        if result.foreignCalls[id] ~= nil then
            tinsert(result.foreignDelays, world.now - result.foreignCalls[id])
        end
        for _, reader in ipairs(readers) do
            reader:onStarted(id)
        end
    end
    -- A number stopped while it played: heard only when most of it was.
    handlers.cut = function(id, startedAt)
        local heard = result.heardIds[id]
        if heard ~= nil and startedAt ~= nil and world.now - startedAt < Sim.NUMBER_HEARD_MS then
            heard.cut = true
        end
    end
    handlers.finished = function(id)
        for _, reader in ipairs(readers) do
            reader:onFinished(id, false)
        end
    end

    local d = opts.disturb or {}
    -- Blizzard's Combat Audio Alerts on a member's health: spoken on the
    -- same health event as our check (same frame), before or after it (the
    -- order the game hands the event to the two frames), unseen by
    -- WowVision. d.caa = { units = { [unit] = true }, chance (per event),
    -- order = "before", "after" or "mixed" }.
    local caa = d.caa
    result.caa = 0
    local function caaSpeaks(m, when)
        if caa == nil or not caa.units[m.unit] then
            return
        end
        local order = caa.order
        if order == "mixed" then
            order = m.caaOrder
        end
        if order == when and world.r.next() < caa.chance then
            result.caa = result.caa + 1
            result.foreign = result.foreign + 1
            engineSpeak(world, world.r.range(600, 1500), handlers, nil)
        end
    end

    -- Health events (UNIT_HEALTH).
    for _, m in ipairs(members) do
        -- (Drawn only with the alerts on: the other scenarios keep their numbers.)
        if caa ~= nil then
            m.caaOrder = world.r.next() < 0.5 and "before" or "after"
        end
        for _, ev in ipairs(m.script) do
            world.after(ev[1], function()
                m.health = ev[2]
                caaSpeaks(m, "before")
                check(m)
                caaSpeaks(m, "after")
                if second ~= nil and m.subject then
                    second:request(m.unit)
                end
            end)
        end
    end

    -- Other speech: WowVision's queue beside us, stops of all speech, interrupts.
    local function every(range, fn)
        local function tick()
            if world.now / 1000 > duration then
                return
            end
            fn()
            world.after(world.r.range(range[1], range[2]), tick)
        end
        world.after(world.r.range(range[1], range[2]), tick)
    end
    result.stops, result.interrupts, result.foreign, result.stopSpeaks = 0, 0, 0, 0
    -- Other speech (WowVision's, Blizzard's alerts): how long after its
    -- call it starts, behind ours in the engine's line.
    if d.foreign then
        every(d.foreign, function()
            result.foreign = result.foreign + 1
            local id = engineSpeak(world, world.r.range(800, 2000), handlers, "queue")
            result.foreignCalls[id] = world.now
        end)
    end
    -- Speech WowVision cannot see (Blizzard's Combat Audio Alerts): it
    -- shifts the speech module's matching of starts to calls.
    if d.unseen then
        every(d.unseen, function()
            result.foreign = result.foreign + 1
            engineSpeak(world, world.r.range(600, 1500), handlers, nil)
        end)
    end
    if d.stops then
        every(d.stops, function()
            result.stops = result.stops + 1
            engineStopAll(world, handlers)
            handlers.stopped()
            for _, reader in ipairs(readers) do
                reader:onStop()
            end
        end)
    end
    -- WowVision's interrupting speech: its own stop (hooked), then the new
    -- speech in the same frame (UI_DELAY 0 on Retail and Forever).
    if d.stopSpeak then
        every(d.stopSpeak, function()
            result.stops = result.stops + 1
            result.stopSpeaks = result.stopSpeaks + 1
            engineStopAll(world, handlers)
            handlers.stopped()
            for _, reader in ipairs(readers) do
                reader:onStop()
            end
            local id = engineSpeak(world, world.r.range(600, 1500), handlers, "queue")
            result.foreignCalls[id] = world.now
        end)
    end
    if d.interrupts then
        every(d.interrupts, function()
            result.interrupts = result.interrupts + 1
            engineStopAll(world, handlers)
            engineSpeak(world, world.r.range(800, 2000), handlers)
        end)
    end

    -- The monitor reads everyone once at the start: the reference.
    checks:readNew()
    world.run(duration * 1000 + 3000)

    result.stats = readback.stats
    if second ~= nil then
        result.second.stats = second.stats
    end
    return Sim.score(result)
end

-- Scoring ------------------------------------------------------------------------

-- An ideal announcement (heard: below "Speak Below" or at full) whose
-- health held at least PERSIST seconds (the next ideal one came later) is
-- followed when one of ours is heard within MATCH seconds after it; the
-- delay is to the first, until the number starts. One of ours heard with
-- no ideal announcement in the MATCH seconds before it is extra.
Sim.PERSIST = 1.0
Sim.MATCH = 1.5

-- Precision as the player has it. The last number heard of a member is
-- OUT OF DATE while their true health would make Sku's rule speak against
-- it: moved the minimum change and the minimum pitch steps, and heard
-- (below "Speak Below", or full). Measured the same way for ours and for
-- Sku on the same health (Sim.sku), so "as precise as Sku" is a number.
-- (The "followed" count above asks for Sku's exact path; in fast fights
-- most of its misses are swings the player had already heard: a hit and a
-- heal within a third of a second, Sku saying both, ours the last.)
local function outOfDate(role, heardHealth, h)
    if not (h < role.start / 100 or h >= 1) then
        return false
    end
    return math.abs(h - heardHealth) >= role.minChange / 100 - 1e-9
        and math.abs(levelOf(h) - levelOf(heardHealth)) >= role.minPitchSteps
end

-- Seconds out of date in [0, duration], and each stretch's length.
function Sim.staleness(m, heard, duration)
    local role = Sim.ROLES[m.role]
    local points = {}
    for _, ev in ipairs(m.script) do
        tinsert(points, { t = ev[1], h = ev[2] })
    end
    for _, a in ipairs(heard) do
        tinsert(points, { t = a.t, b = a.health })
    end
    table.sort(points, function(x, y)
        return x.t < y.t
    end)
    local h, b = m.startHealth, m.startHealth
    local since, total, stretches = nil, 0, {}
    local function settle(t)
        local out = outOfDate(role, b, h)
        if out and since == nil then
            since = t
        elseif not out and since ~= nil then
            tinsert(stretches, t - since)
            total = total + t - since
            since = nil
        end
    end
    settle(0)
    for _, p in ipairs(points) do
        if p.t > duration then
            break
        end
        h = p.h or h
        b = p.b or b
        settle(p.t)
    end
    if since ~= nil then
        tinsert(stretches, duration - since)
        total = total + duration - since
    end
    return total, stretches
end

-- Sku on the same health: it reads plain health, so at every health event
-- its rule runs against the member's last announcement; a member found
-- moved goes into one queue (an entry already waiting keeps its place and
-- says the health of the moment it plays), one frame after the event at
-- the soonest and SKU_GAP after the number before. Sound files: no stop of
-- speech cuts them. "Speak Below" as ours (Sku has none): a number above
-- it is silent and takes no time.
Sim.SKU_GAP = 0.2

function Sim.sku(members, fps)
    local events = {}
    local heard, ref, health = {}, {}, {}
    for _, m in ipairs(members) do
        for _, ev in ipairs(m.script) do
            tinsert(events, { t = ev[1], m = m, h = ev[2] })
        end
        heard[m], ref[m], health[m] = {}, m.startHealth, m.startHealth
    end
    table.sort(events, function(x, y)
        return x.t < y.t
    end)
    local queue, queued = {}, {}
    local nextPlay = 0
    local frame = 1 / (fps or 60)
    local i = 1
    while true do
        local ev = events[i]
        local playAt = #queue > 0 and math.max(nextPlay, queue[1].at) or math.huge
        if ev == nil and playAt == math.huge then
            break
        end
        if ev ~= nil and ev.t <= playAt then
            local m, role = ev.m, Sim.ROLES[ev.m.role]
            health[m] = ev.h
            if math.abs(ev.h - ref[m]) >= role.minChange / 100 - 1e-9
                and math.abs(levelOf(ev.h) - levelOf(ref[m])) >= role.minPitchSteps and not queued[m] then
                queued[m] = true
                tinsert(queue, { m = m, at = ev.t + frame })
            end
            i = i + 1
        else
            local entry = tremove(queue, 1)
            local m, role = entry.m, Sim.ROLES[entry.m.role]
            queued[m] = nil
            local h = health[m]
            -- The reference is what the player last heard ("Speak Below"
            -- is ours; in Sku every move is heard).
            if h < role.start / 100 or h >= 1 then
                ref[m] = h
                tinsert(heard[m], { t = playAt, health = h })
                nextPlay = playAt + Sim.SKU_GAP
            end
        end
    end
    return heard
end

function Sim.score(result)
    -- A number stopped before it started, or cut early, was never heard.
    local cut = 0
    for _, m in ipairs(result.members) do
        local started = {}
        for _, a in ipairs(m.announcements) do
            if a.t ~= nil and not a.cut then
                tinsert(started, a)
            elseif a.t ~= nil then
                cut = cut + 1
            end
        end
        m.announcements = started
    end
    local total = { ideal = 0, followed = 0, missed = 0, extra = 0, latencies = {}, moves = {}, triggers = 0, misreads = 0, readings = 0, heard = 0, cut = cut, silentMoves = 0 }
    for _, m in ipairs(result.members) do
        m.followed, m.missed, m.extra, m.meaningful = 0, 0, 0, 0
        for i, ideal in ipairs(m.ideal) do
            local nextIdeal = m.ideal[i + 1]
            if ideal.audible and (nextIdeal == nil or nextIdeal.t - ideal.t >= Sim.PERSIST) then
                m.meaningful = m.meaningful + 1
                local hit = nil
                for _, heard in ipairs(m.announcements) do
                    if heard.t >= ideal.t and heard.t <= ideal.t + Sim.MATCH then
                        hit = heard
                        break
                    end
                end
                if hit ~= nil then
                    m.followed = m.followed + 1
                    tinsert(total.latencies, hit.t - ideal.t)
                else
                    m.missed = m.missed + 1
                end
            end
        end
        for _, heard in ipairs(m.announcements) do
            local cause = false
            for _, ideal in ipairs(m.ideal) do
                if ideal.t <= heard.t and ideal.t >= heard.t - Sim.MATCH then
                    cause = true
                    break
                end
            end
            if not cause then
                m.extra = m.extra + 1
            end
        end
        total.ideal = total.ideal + m.meaningful
        total.followed = total.followed + m.followed
        total.missed = total.missed + m.missed
        total.extra = total.extra + m.extra
        total.triggers = total.triggers + #m.triggers
        total.misreads = total.misreads + m.misreads
        total.readings = total.readings + m.readings
        total.heard = total.heard + #m.announcements
        -- A move of the reference to a health that is heard (below "Speak
        -- Below", or full) without a number heard near that health since
        -- the move before, nor any number of the member right after (a
        -- stop cut it and it was said again, at the health of then): the
        -- monitor counts it as said, so the member stays silent until the
        -- next minimum change.
        local role = Sim.ROLES[m.role]
        local previousT = -math.huge
        for _, trig in ipairs(m.triggers) do
            local h = trig.health
            if h ~= nil and (h < role.start / 100 or h >= 1) then
                local said = false
                for _, a in ipairs(m.announcements) do
                    local near = a.t > previousT - Sim.MATCH and a.t <= trig.t and math.abs(a.health - h) < role.minChange / 200
                    if near or (a.t > trig.t and a.t <= trig.t + Sim.MATCH) then
                        said = true
                        break
                    end
                end
                if not said then
                    total.silentMoves = total.silentMoves + 1
                end
            end
            previousT = trig.t
        end
        -- How far the true health moved between our reference moves, in
        -- thresholds (Sku's rule: 1 or more, ours a little either side).
        local a = Sim.ROLES[m.role].minChange / 100
        local last = m.startHealth
        for _, trig in ipairs(m.triggers) do
            if trig.health ~= nil then
                tinsert(total.moves, math.abs(trig.health - last) / a)
                last = trig.health
            end
        end
    end
    -- Out of date (ours and Sku's): seconds summed over members, and the
    -- stretches longer than a frame or two.
    local duration = result.opts.duration
    local skuHeard = Sim.sku(result.members, result.opts.fps)
    total.outdated, total.outdatedStretches = 0, {}
    total.skuOutdated, total.skuStretches, total.skuHeard = 0, {}, 0
    for _, m in ipairs(result.members) do
        local seconds, stretches = Sim.staleness(m, m.announcements, duration)
        total.outdated = total.outdated + seconds
        for _, s in ipairs(stretches) do
            tinsert(total.outdatedStretches, s)
        end
        seconds, stretches = Sim.staleness(m, skuHeard[m], duration)
        total.skuOutdated = total.skuOutdated + seconds
        for _, s in ipairs(stretches) do
            tinsert(total.skuStretches, s)
        end
        total.skuHeard = total.skuHeard + #skuHeard[m]
    end
    table.sort(total.outdatedStretches)
    table.sort(total.skuStretches)
    table.sort(total.moves)
    table.sort(total.latencies)
    result.total = total
    return result
end

local function percentile(list, p)
    if #list == 0 then
        return 0
    end
    local sorted = {}
    for i, x in ipairs(list) do
        sorted[i] = x
    end
    table.sort(sorted)
    return sorted[math.max(1, math.ceil(#sorted * p))]
end
Sim.percentile = percentile

local function counts(map)
    local parts = {}
    for why, n in pairs(map) do
        tinsert(parts, why .. " " .. n)
    end
    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

function Sim.report(result)
    local t = result.total
    local s = result.stats
    local lines = {}
    local function add(fmt, ...)
        tinsert(lines, string.format(fmt, ...))
    end
    add("%s: %d players, %d fps, %d seconds", result.opts.name, #result.members, result.opts.fps or 60, result.opts.duration)
    add("  Sku's rule on the true health: %d heard announcements that held %.0f s or more; ours heard %d of them, missed %d; %d of ours extra", t.ideal, Sim.PERSIST, t.followed, t.missed, t.extra)
    if #t.latencies > 0 then
        add("  from the health change until the number starts: median %.2f s, 90 percent within %.2f s, worst %.2f s", percentile(t.latencies, 0.5), percentile(t.latencies, 0.9), t.latencies[#t.latencies])
    end
    add("  bands read wrong: %d of %d readings; numbers heard %d, cut by a stop %d; moves taken as said without their number %d", t.misreads, t.readings, t.heard, t.cut, t.silentMoves)
    add("  last number heard out of date: ours %.1f s (stretches median %.2f s, 90 percent within %.2f s, longest %.2f s); Sku %.1f s (median %.2f, 90 percent %.2f, longest %.2f; %d numbers)",
        t.outdated, percentile(t.outdatedStretches, 0.5), percentile(t.outdatedStretches, 0.9), t.outdatedStretches[#t.outdatedStretches] or 0,
        t.skuOutdated, percentile(t.skuStretches, 0.5), percentile(t.skuStretches, 0.9), t.skuStretches[#t.skuStretches] or 0, t.skuHeard)
    if #t.moves > 0 then
        add("  health moved between our announcements, in minimum changes: least %.2f, median %.2f", t.moves[1], percentile(t.moves, 0.5))
    end
    add("  samples %d, used %d, thrown away: %s; most at once %d", s.samples, s.readings, counts(s.discarded), s.maxInflight)
    add("  disturbances: %d other utterances, %d stops of all speech (%d followed by speech), %d interrupts; purges: %s; own speech cut %d, spoken again %d", result.foreign + result.stopSpeaks, result.stops, result.stopSpeaks, result.interrupts, counts(s.purges), s.ownCut, result.respoken)
    for _, m in ipairs(result.members) do
        if m.subject or #m.triggers > 0 then
            local heard = {}
            for _, a in ipairs(m.announcements) do
                tinsert(heard, string.format("%.1fs %d%%", a.t, math.floor(a.health * 100 + 0.5)))
            end
            add("  %s (number %d, %s): %d to follow, %d followed, %d missed, %d extra; heard %d: %s", m.unit, m.number, m.role, m.meaningful, m.followed, m.missed, m.extra, #m.announcements, table.concat(heard, ", "))
        end
    end
    return lines
end

-- The scenarios --------------------------------------------------------------------

local PARTY = {
    { unit = "player", number = 1, role = "HEALER" },
    { unit = "party1", number = 2, role = "TANK" },
    { unit = "party2", number = 3, role = "DAMAGER" },
    { unit = "party3", number = 4, role = "DAMAGER" },
    { unit = "party4", number = 5, role = "DAMAGER" },
}

local RAID = {}
for i = 1, 10 do
    local role = (i <= 2 and "TANK") or (i <= 4 and "HEALER") or "DAMAGER"
    tinsert(RAID, { unit = "raid" .. i, number = i, role = role })
end

-- Background members sit in the middle of a step and wobble inside it.
local function group(base, r, duration, subjects)
    local list = {}
    for i, spec in ipairs(base) do
        local m = { unit = spec.unit, number = spec.number, role = spec.role }
        local subject = subjects[i]
        if subject ~= nil then
            m.subject = true
            m.health = subject.health
            m.script = subject.script
        else
            m.health = 0.85
            m.script = Sim.wobble(r, 0.85, duration)
        end
        tinsert(list, m)
    end
    return list
end

-- Health hovering across a line, up to `width` either side, flipping every second or so.
function Sim.hover(r, line, width, duration)
    local events = {}
    local t, up = 0.5, true
    while t <= duration do
        local h = up and r.range(line + 0.005, line + width) or r.range(line - width, line - 0.005)
        tinsert(events, { t, h })
        up = not up
        t = t + r.range(0.8, 1.5)
    end
    return events
end

local DISTURB = { foreign = { 3, 6 }, stops = { 15, 30 }, interrupts = { 20, 40 } }

-- The first party fight logged in game (WoW: Forever, 2026-10-14, 13:05:12
-- to 13:08:03, 171 s): 67 stops of all speech, each followed by
-- WowVision's speech (49 Target Change, 18 UI keys and windows), one every
-- 2.6 s on average. Other speech was not counted then: one every 1 to 3 s
-- is a guess from the samples it spoiled (later solo logs: one every 1 to
-- 2.5 s). Of it, speech WowVision cannot see (Blizzard's Combat Audio
-- Alerts) is not known; one every 4 to 8 s is a guess.
Sim.REAL_FIGHT = { stopSpeak = { 1.5, 3.5 }, foreign = { 1, 3 }, unseen = { 4, 8 } }

-- kind "spikes": one member (the first tank) takes strong hits and big heals.
-- kind "drift": two members change slowly, one drains, one regenerates.
-- kind "hover": the healer's health flips across the 50 percent line by up
--   to 3 percent, below their minimum change: nothing to say.
-- kind "stops": "spikes" with a stop of all speech every 1 to 3 seconds
--   (a player pressing Ctrl often, target changes).
-- kind "fight": everyone takes strong hits and big heals at once, with the
--   disturbances of the fight logged in game (Sim.REAL_FIGHT).
-- kind "party": everyone takes moderate damage and healing (Sim.moderate),
--   with the disturbances of the fight logged in game: that fight.
function Sim.scenario(kind, size, fps, seed)
    local r = rng(seed or 7)
    local base = size == 10 and RAID or PARTY
    local subjects = {}
    local duration = 60
    local disturb = DISTURB
    local name
    if kind == "spikes" or kind == "stops" then
        subjects[2] = { health = 1.0, script = Sim.spikes(r, duration) }
        name = "Strong hits and heals on one member"
        if kind == "stops" then
            disturb = { foreign = { 3, 6 }, stops = { 1, 3 }, interrupts = { 20, 40 } }
            name = name .. ", a stop of all speech every 1 to 3 seconds"
        end
    elseif kind == "fight" then
        for i = 1, #base do
            subjects[i] = { health = 1.0, script = Sim.spikes(r, duration) }
        end
        disturb = Sim.REAL_FIGHT
        name = "Everyone hit at once, disturbances as in the fight logged in game"
    elseif kind == "party" then
        for i = 1, #base do
            subjects[i] = { health = 1.0, script = Sim.moderate(r, duration) }
        end
        disturb = Sim.REAL_FIGHT
        name = "Everyone under moderate damage, disturbances as in the fight logged in game"
    elseif kind == "hover" then
        -- The healer: the party's first member, the raid's third.
        local index = size == 10 and 3 or 1
        subjects[index] = { health = 0.52, script = Sim.hover(r, 0.5, 0.03, duration) }
        name = "A healer hovering up to 3 percent around the 50 percent line"
    else
        duration = 90
        subjects[3] = { health = 0.98, script = Sim.drift(0.98, -0.012, 2, duration) }
        subjects[4] = { health = 0.32, script = Sim.drift(0.32, 0.010, 2, duration) }
        name = "Slow changes on two members"
    end
    return {
        name = name .. (size == 10 and ", raid of 10" or ", party of 5"),
        duration = duration,
        fps = fps or 60,
        seed = (seed or 7) + size,
        members = group(base, r, duration, subjects),
        disturb = disturb,
    }
end

Sim.KINDS = { "spikes", "drift", "hover", "stops", "fight", "party" }

return Sim
