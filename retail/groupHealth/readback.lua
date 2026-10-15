-- Health readback for the group health monitor: which band of health a
-- member is in, learned from how long silent utterances play. A sighted
-- healer sees how far a bar moved at one look; the monitor uses this only
-- to decide WHEN to speak (the member's health moved far enough since the
-- last announcement, Sku's rule). WHAT it speaks still comes from the
-- secret health through the curves, so a misread costs one extra or one
-- missing announcement, never a wrong number. Only official API: curves of
-- ours, C_VoiceChat speech at volume 0, its playback events and
-- debugprofilestop().
--
-- How (measured on WoW: Forever 1.60.1, 2026-10-13, with a developer probe):
-- UnitHealthPercent(unit, true, curve) turns the health into a silence
-- length, 'a<silence msec="..."/>' is spoken at volume 0 and rate 10, and the
-- time from PLAYBACK_STARTED to PLAYBACK_FINISHED gives the length back:
-- - 74 clean samples over five runs lie on one line, played = 190 ms +
--   0.3314 * silence (rate 10 shortens the silence too); every sample was
--   within 0.27 of a level. Fixed values, no calibration; two more
--   machines' headsets and speakers timed the same. Measured on levels 0
--   to 3 (and 1500 ms of silence in the flood probe); the levels up to 16,
--   which one utterance now uses, read right too (2026-10-14: all 16, and
--   191 of 192 in a longer run; the developer probe is not part of this
--   change).
--   Offline (SAPI to a file, 2026-10-13) Hedda, Katja, Stefan and Zira all
--   shorten silence to exactly a third at rate 10, their "a" within 16 ms
--   of Hedda's; the simulation keeps reading up to about 20 ms off.
-- - msec="0" plays longer than 100 ms of silence, so level 0 is 100 ms.
-- - Events land on frames (about 17 ms at 60 fps), so a level is 300 ms of
--   silence, about 100 ms played.
-- - With the game in the background (alt-tab), every utterance plays 461
--   to 463 ms whatever its length, and starts about 71 ms after the call
--   (three probe runs, 2026-10-13; back in front the timing is right again
--   at once). Such readings are thrown away (BACKGROUND_MS).
-- - Volume 0 plays in real time; a secret works inside <silence msec>; ten
--   silent utterances side by side keep their timing.
-- - Other speech beside ours does no harm: WowVision's speech queue (on by
--   default) sends everything, Blizzard's too, with overlap allowed. A stop
--   of all speech (C_VoiceChat.StopSpeakingText, which takes no arguments:
--   nobody can stop only their own speech) cuts every utterance, which then
--   never reports its end; the hook below tells.
--
-- A sample is ONE utterance (R.LAYOUT "single"; "pair", two digits, is the
-- first form, kept as an option), called in the same frame as the number
-- it checks, so both read the same health. Its level is the value of the
-- band the health is in under the sample's PLAN. The events carry only an
-- utterance id; ids count up in call order (checked in game).
-- - change plan (the monitor): bands around the member's reference, the
--   health of the number the player last heard. The middle band is "moved
--   less than the threshold", its edges exactly reference -/+ threshold,
--   widened to the pitch levels within the minimum pitch steps (the game
--   evaluates the curve, so the edge is exact). Heard health outside it is
--   cut into narrow even bands (one reading always places the member: no
--   second reading to narrow it down); health above "Speak Below" is one
--   band, as a move there is silent; full health is a band of its own.
--   "moved less" plays shortest (0.22 s), the farther the band the longer.
-- - unsure plan: the change plan without "moved less", for a member whose
--   last heard number is not known; the number is heard wherever the lane
--   speaks.
-- - zoom plan: a band of health (whole percent) in equal parts. Reads a
--   member without a reference (0 to 100: about 6 percent parts). It never
--   announces by itself.
--
-- Every engine call of ours goes through one slot line (SLOT_MS apart, or
-- longer for a slot with more utterances: the engine prepares one after
-- another, so a slot is as long as its utterances need and we never pile
-- up a queue in front of other speech), so the starts of different slots
-- never share a window. Requests wait in a queue; when the line is free up
-- to BATCH_MAX members go out in one slot, the most urgent first (the
-- caller's priority): what they carry first, then each member's sample, all
-- one run of ids. A start beyond what the slot expects, a missing one, or
-- one right after the run that is not the next slot's own makes the slot
-- ambiguous and its samples are thrown away.
--
-- A stop of all speech purges what it cut: every sample out is dropped and
-- its member read again (once the speech that follows a stop has started),
-- and an announcement of ours cut by the stop is handed back to be spoken
-- again; so is word of a number cut after its sample had ended. A member
-- whose samples keep failing for long purges everything, and everyone is
-- read again. The caller hears that the readback fails only when it stays
-- bad: half a minute without any reading, or fewer than one in five of the
-- last 40 samples usable.
--
-- No WoW API in here: the caller hands in an environment (clock, timer,
-- speak, the health through a curve), so tools/groupHealthSim.lua runs it
-- against a simulated engine.

local GroupHealth = WowVision.groupHealth

local R = {
    RATE = 10,
    SILENCE_OFFSET = 100,
    LEVEL_SILENCE = 300,
    BASE_MS = 223,
    LEVEL_MS = 99.4,
    -- The shortest window for a slot (readbackWindow).
    START_WINDOW_MS = 100,
    -- The latest first start after the call seen in game (34 to 56 ms).
    FIRST_START_MAX_MS = 56,
    -- One frame when the caller cannot tell (60 fps).
    FRAME_MS = 17,
    -- The engine prepares utterances one after another, about this long
    -- each (flood probe, 2026-10-13: 20, 40, 80 silent utterances in one
    -- frame all played their length, started about 36 ms apart).
    ENGINE_MS = 37,
    -- After a slot's window: a start with the id right after the run in
    -- this time, not the next slot's own, means the run is one longer than
    -- ours (speech called just before ours took the engine, and our last
    -- start fell past the window).
    GRACE_MS = 80,
    -- The engine never starts an utterance sooner after its call.
    FIRST_START_MS = 30,
    -- Members read together in one slot at most (their utterances one run).
    -- Simulated with the engine as measured (three fights each): 3 per slot
    -- follows 88 percent of changes with 10 members under steady damage, 62
    -- with 20, 50 with 40 (one per slot: 57, 24, 11); 4 per slot no more,
    -- but other speech waits longer behind a slot and numbers overlap more.
    BATCH_MAX = 3,
    SLOT_MS = 120,
    -- After a stop of all speech, our next slot waits this long: whoever
    -- stopped mostly speaks at once (WowVision's interrupting alerts and
    -- keys), and that start must not fall into our window.
    POST_STOP_MS = 120,
    -- How long after a slot a start no call of ours matches makes it
    -- distrust what it left out as WowVision's speech (startEntry): the
    -- shift shows by the end of the run, well before a sample has played.
    SHIFT_MS = 1000,
    -- A number of the caller's (two copies and "full") plays well under
    -- this; a stop within it after the call may have cut it.
    NUMBER_MS = 1500,
    -- How a plan's value is played (newPlan). "single": one utterance whose
    -- level is the value, so a check is two engine starts with its number.
    -- The engine starts utterances one after another, about 27 a second
    -- for all speech, and in a fight that limits the checks, not how long
    -- they play (simulation, 2026-10-14: utterances half as long changed
    -- nothing, one start less per check did). "pair": two utterances in
    -- base 4 (the first form, checked in game).
    LAYOUT = "single",
    -- The levels a single utterance uses, value 0 first. Level 2 is left
    -- out: with the game in the background every utterance plays about
    -- 462 ms, 0.4 from level 2.
    SINGLE_LEVELS = { 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },
    -- The longest sample (a single utterance at level 16 plays 1.81 s, a
    -- late start) is under two seconds; a stopped utterance never reports
    -- its end (TextToSpeechFrame.lua), so this is how long a sample cut
    -- without our hook holds its member.
    TIMEOUT_SECONDS = 2.2,
    -- Clean samples land within 0.27 of a whole level; one further off was cut.
    MAX_OFF_LEVEL = 0.42,
    -- What every utterance plays with the game in the background.
    BACKGROUND_MS = { 455, 470 },
    -- An own utterance called this recently may be cut before it started.
    OWN_START_MS = 500,
    -- Own utterances that never reported their end are forgotten after this.
    OWN_FORGET_MS = 10000,
    -- Two quick retries, then one a second: a change must not get lost.
    QUICK_RETRIES = 2,
    RETRY_LATER_SECONDS = 1,
    -- A member whose samples have failed this long: purge and read everyone.
    STUCK_MS = 3000,
    -- No reading at all for this long, over at least FAIL_SAMPLES failed
    -- samples: the caller is told once.
    FAIL_MS = 30000,
    FAIL_SAMPLES = 20,
    -- Or of the last FAIL_WINDOW samples fewer than FAIL_RATIO usable: a
    -- voice that does not fit the fixed values still reads now and then,
    -- wrongly (simulation: 5 to 13 percent usable; heavy speech spam or 15
    -- fps still 28 percent). Said again only after it recovered to RECOVER.
    FAIL_WINDOW = 40,
    FAIL_RATIO = 0.2,
    RECOVER_RATIO = 0.5,
}
GroupHealth.readbackConstants = R

-- Plans --------------------------------------------------------------------------

local EPS = 1e-9

local VALUE_OF_LEVEL = {}
for value, level in ipairs(R.SINGLE_LEVELS) do
    VALUE_OF_LEVEL[level] = value - 1
end

-- A plan from its points ({ lower edge as a fraction, value }, rising): the
-- band of each value and the curves of its utterances (extra.layout, else
-- R.LAYOUT: one utterance, or two digits in `base`).
local function newPlan(kind, base, points, extra)
    local layout = extra ~= nil and extra.layout or R.LAYOUT
    local plan = { kind = kind, base = base, points = points, intervals = {}, layout = layout }
    local digits = layout == "single" and { {} } or { {}, {} }
    for i, point in ipairs(points) do
        local nextPoint = points[i + 1]
        plan.intervals[point[2]] = { point[1], nextPoint ~= nil and nextPoint[1] or 1 }
        if layout == "single" then
            tinsert(digits[1], { point[1], R.SILENCE_OFFSET + R.SINGLE_LEVELS[point[2] + 1] * R.LEVEL_SILENCE })
        else
            local high, low = math.floor(point[2] / base), point[2] % base
            tinsert(digits[1], { point[1], R.SILENCE_OFFSET + high * R.LEVEL_SILENCE })
            tinsert(digits[2], { point[1], R.SILENCE_OFFSET + low * R.LEVEL_SILENCE })
        end
    end
    plan.digitPoints = digits
    plan.digitCount = #digits
    for key, value in pairs(extra or {}) do
        plan[key] = value
    end
    return plan
end

-- A plan of the caller's own (kind, base, points as newPlan takes them).
GroupHealth.readbackPlan = newPlan

-- Plans are kept for reuse (and with them the game's curve objects, see
-- module.lua); past PLANS_MAX a cache starts afresh (samples out keep their
-- plan).
local PLANS_MAX = 512

local function newCache()
    return { plans = {}, count = 0 }
end

local function cached(cache, key)
    return cache.plans[key]
end

local function keep(cache, key, plan)
    if cache.count >= PLANS_MAX then
        cache.plans, cache.count = {}, 0
    end
    cache.plans[key] = plan
    cache.count = cache.count + 1
    return plan
end

-- The band from `lo` to `hi` percent in equal parts (16 less one for each
-- band outside it: below `lo` when lo > 0, above `hi` when hi < 100; at
-- 100 the top part includes full health). Edges round outward to whole
-- percent, so the plans (and the game's curve objects) stay few.
local zoomPlans = newCache()

function GroupHealth.zoomPlan(lo, hi, layout)
    lo, hi = math.max(0, math.floor(lo + EPS)), math.min(100, math.ceil(hi - EPS))
    if hi <= lo then
        hi = math.min(100, lo + 1)
        lo = hi - 1
    end
    layout = layout or R.LAYOUT
    local key = lo .. ":" .. hi .. ":" .. layout
    local plan = cached(zoomPlans, key)
    if plan ~= nil then
        return plan
    end
    local parts = 16 - (lo > 0 and 1 or 0) - (hi < 100 and 1 or 0)
    local points = {}
    if lo > 0 then
        tinsert(points, { 0, #points })
    end
    for k = 0, parts - 1 do
        tinsert(points, { (lo + k * (hi - lo) / parts) / 100, #points })
    end
    if hi < 100 then
        tinsert(points, { hi / 100, #points })
    end
    plan = newPlan("zoom", 4, points, { layout = layout })
    return keep(zoomPlans, key, plan)
end

-- The reading of a member without a reference.
function GroupHealth.locatePlan()
    return GroupHealth.zoomPlan(0, 100)
end

-- Values by how long they play, shortest first. One utterance: the value
-- is the level. Two digits in base 4: by the longer digit (0; then 1, 4,
-- 5; then 2, 6, 8, 9, 10; then the rest).
local CHANGE_BASE = 4
local BY_LENGTH = {}
for value = 0, CHANGE_BASE * CHANGE_BASE - 1 do
    tinsert(BY_LENGTH, value)
end
if R.LAYOUT ~= "single" then
    local function longer(value)
        return math.max(math.floor(value / CHANGE_BASE), value % CHANGE_BASE)
    end
    table.sort(BY_LENGTH, function(x, y)
        if longer(x) ~= longer(y) then
            return longer(x) < longer(y)
        end
        return x < y
    end)
end

local changePlans = newCache()

-- The bands around `reference` (whole percent) for a threshold in percent.
-- "Moved less" is reference -/+ threshold, widened to `pitchQuiet` when
-- given (Sku's two rules, both must pass to announce). Full health is a
-- band of its own below a full reference. The rest of 0 to 1 is cut into
-- bands: heard health (below `speakBelow`) into equal bands, as many as its
-- share of the room; health above it into one band per side, as a move
-- there is silent and changes nothing. A heard band is narrow enough to
-- settle the reference at its middle (a 10 percent threshold: about 5
-- percent wide, finer than a pitch level), so one reading always places
-- the member. (Narrow near the threshold and wide far out, as before
-- 2026-10-14, needed a second reading after a far move, and numbers were
-- held back meanwhile: in a simulated party fight a third of the time out
-- of date came from that.) Answers by distance from "moved less", nearest
-- first. `unsure`: no "moved less" (threshold 0, no pitch steps).
local function changePlanFor(reference, threshold, pitchQuiet, speakBelow, unsure)
    local r, a = reference / 100, threshold / 100
    local low, high = r - a, r + a
    if pitchQuiet ~= nil then
        low, high = math.min(low, pitchQuiet[1]), math.max(high, pitchQuiet[2])
    end
    local heardBelow = math.min(1, speakBelow or 1)
    local key = reference .. ":" .. threshold .. ":" .. low .. ":" .. high .. ":" .. heardBelow .. ":" .. tostring(unsure)
    local plan = cached(changePlans, key)
    if plan ~= nil then
        return plan
    end
    -- Stretches of 0 to 1 outside "moved less": { lo, hi, heard }.
    local stretches = {}
    local function add(lo, hi)
        lo, hi = math.max(0, lo), math.min(1, hi)
        if hi - lo <= EPS then
            return
        end
        if lo < heardBelow - EPS and hi > heardBelow + EPS then
            tinsert(stretches, { lo, heardBelow, true })
            tinsert(stretches, { heardBelow, hi, false })
        else
            tinsert(stretches, { lo, hi, hi <= heardBelow + EPS })
        end
    end
    add(0, low)
    add(high, 1)
    -- The gate's "moved less" is half open: full health right on its top
    -- edge is heard, so it needs its own band.
    local hasFull = reference < 100 and high <= 1 + EPS
    local room = CHANGE_BASE * CHANGE_BASE - 1 - (hasFull and 1 or 0)
    -- One band per stretch, then each band left to the heard stretch whose
    -- bands are widest: the widest heard band as narrow as can be.
    for _, stretch in ipairs(stretches) do
        stretch.n = 1
        room = room - 1
    end
    while room > 0 do
        local widest = nil
        for _, stretch in ipairs(stretches) do
            if stretch[3] and (widest == nil or (stretch[2] - stretch[1]) / stretch.n > (widest[2] - widest[1]) / widest.n) then
                widest = stretch
            end
        end
        if widest == nil then
            break
        end
        widest.n = widest.n + 1
        room = room - 1
    end
    -- { lo, hi, distance from "moved less" }
    local bands = {}
    for _, stretch in ipairs(stretches) do
        local n = stretch.n
        local width = (stretch[2] - stretch[1]) / n
        for k = 1, n do
            local lo, hi = stretch[1] + (k - 1) * width, stretch[1] + k * width
            local distance = hi <= low + EPS and low - hi or lo - high
            tinsert(bands, { lo, hi, distance })
        end
    end
    tinsert(bands, { math.max(0, low), math.min(1, high), -1 })
    if hasFull then
        tinsert(bands, { 1, 1, 1 - high })
    end
    table.sort(bands, function(x, y)
        if x[1] ~= y[1] then
            return x[1] < y[1]
        end
        return x[2] < y[2]
    end)
    local byDistance = {}
    for _, band in ipairs(bands) do
        tinsert(byDistance, band)
    end
    table.sort(byDistance, function(x, y)
        if x[3] ~= y[3] then
            return x[3] < y[3]
        end
        return x[1] < y[1]
    end)
    for i, band in ipairs(byDistance) do
        band.value = BY_LENGTH[i]
    end
    local points = {}
    for _, band in ipairs(bands) do
        tinsert(points, { band[1], band.value })
    end
    points[1][1] = 0
    plan = newPlan("change", CHANGE_BASE, points, {
        reference = reference,
        threshold = threshold,
        quiet = { low, high },
        heardBelow = heardBelow,
        unsure = unsure,
    })
    return keep(changePlans, key, plan)
end

function GroupHealth.changePlan(reference, threshold, pitchQuiet, speakBelow)
    return changePlanFor(reference, threshold, pitchQuiet, speakBelow, false)
end

-- The plan for a member whose last heard number is not known: no "moved
-- less" (empty at the reference), so the number is heard wherever the lane
-- speaks.
function GroupHealth.unsurePlan(reference, speakBelow)
    return changePlanFor(reference, 0, nil, speakBelow, true)
end

-- The plan of a member's next sample; `pitchQuiet` (optional) widens the
-- quiet band by the role's minimum pitch steps (GroupHealth.pitchQuiet),
-- `speakBelow` (optional, a fraction) is the role's "Speak Below".
function GroupHealth.planFor(member, threshold, pitchQuiet, speakBelow)
    if member.reference == nil then
        return GroupHealth.locatePlan()
    end
    -- Not known what the player last heard (a number cut by a stop): the
    -- next number is said wherever it is heard, and its reading sets the
    -- reference afresh.
    if member.unsure then
        return GroupHealth.unsurePlan(member.reference, speakBelow)
    end
    return GroupHealth.changePlan(member.reference, threshold, pitchQuiet, speakBelow)
end

-- Decoding -----------------------------------------------------------------------

-- A level as a fraction: played time back through the fixed line.
function GroupHealth.readbackRaw(playedMs)
    return (playedMs - R.BASE_MS) / R.LEVEL_MS
end

-- The plan's value from the played times (one, or two for a pair); nil and
-- the reason when they make none.
function GroupHealth.readbackValue(plan, firstMs, secondMs)
    local bg = R.BACKGROUND_MS
    if plan.digitCount == 1 then
        local raw = GroupHealth.readbackRaw(firstMs)
        if firstMs >= bg[1] and firstMs <= bg[2] then
            return nil, "game in the background", raw
        end
        local level = math.floor(raw + 0.5)
        if math.abs(raw - level) > R.MAX_OFF_LEVEL then
            return nil, "between levels", raw
        end
        local value = VALUE_OF_LEVEL[level]
        if value == nil or plan.intervals[value] == nil then
            return nil, "out of range", raw
        end
        return value, nil, raw
    end
    local rawHigh, rawLow = GroupHealth.readbackRaw(firstMs), GroupHealth.readbackRaw(secondMs)
    if firstMs >= bg[1] and firstMs <= bg[2] and secondMs >= bg[1] and secondMs <= bg[2] then
        return nil, "game in the background", rawHigh, rawLow
    end
    local high, low = math.floor(rawHigh + 0.5), math.floor(rawLow + 0.5)
    if math.abs(rawHigh - high) > R.MAX_OFF_LEVEL or math.abs(rawLow - low) > R.MAX_OFF_LEVEL then
        return nil, "between levels", rawHigh, rawLow
    end
    if high < 0 or low < 0 or high >= plan.base or low >= plan.base then
        return nil, "out of range", rawHigh, rawLow
    end
    local value = high * plan.base + low
    if plan.intervals[value] == nil then
        return nil, "out of range", rawHigh, rawLow
    end
    return value, nil, rawHigh, rawLow
end

-- The rule ------------------------------------------------------------------------

-- What a reading means for a member: true when the number it carried was
-- heard, moving member.reference (whole percent) to the middle of the band
-- read. The reference is the health of the number the player last heard.
-- Speak first, check afterwards: every move comes with a health event, and
-- every event sends a number, so only a sample that carried one (or a
-- re-check reading the very same health again) can tell a move.
-- - No reference yet: the reading sets it; above "Speak Below" the player
--   takes the member for healthy, as Sku starts everyone at full (100).
-- - Carried: heard exactly when the band lies outside the quiet band the
--   number went out behind (quietFor) and is heard health (below "Speak
--   Below", or full); a move above it was silent and leaves the reference.
-- - Unsure plan: heard wherever the band is heard health.
-- - A plain reading (no number) only sets a missing reference.
local function apart(lo, hi, band)
    return hi <= band[1] + EPS or lo >= band[2] - EPS
end

function GroupHealth.judge(member, reading, threshold, speakBelow)
    local plan = reading.plan
    local band = plan.intervals[reading.value]
    local lo, hi = band[1], band[2]
    local function settle(heard)
        member.reference = math.floor((lo + hi) * 50 + 0.5)
        return heard
    end
    if member.reference == nil then
        if speakBelow ~= nil and lo >= speakBelow - EPS then
            member.reference = 100
            return false
        end
        return settle(false)
    end
    if not reading.carried then
        return false
    end
    local heard = not (plan.heardBelow ~= nil and lo >= plan.heardBelow - EPS and lo < 1 - EPS)
    if plan.unsure then
        if heard then
            member.unsure = false
            return settle(true)
        end
        return false
    end
    if heard and apart(lo, hi, GroupHealth.quietFor(plan)) then
        return settle(true)
    end
    return false
end

-- The band a number carried by a sample of this plan stays silent in: the
-- change plan's "moved less". From the plan alone, so the gate and judge
-- always agree.
function GroupHealth.quietFor(plan)
    return plan.quiet
end

-- One slot line for every readback in the addon: two lines calling in the
-- same frame put both starts into each other's windows (seen in game: two
-- readbacks woken by the same health event lost 63 of 68 samples).
-- The line also records every start once, centrally: which slot's window it
-- fell into and as which start of that slot. Only as many starts as the slot
-- expects can be its own (two for a sample, one for the caller's speech);
-- any later one is foreign, whichever readback owns the slot.
function GroupHealth.newReadbackLine()
    return { nextSlotMs = 0, slots = {}, starts = {}, byId = {} }
end
GroupHealth.readbackLine = GroupHealth.newReadbackLine()

-- A thrown-away slot for the log: how many calls it made, why it was
-- thrown away, and every start seen from its call to the end of its grace,
-- in ms after the call, with the id counted from the lowest one seen and
-- who called it as WowVision's speech module matched it ("WowVision": its
-- speech queue; "not WowVision's": speech it cannot see, Blizzard's Combat
-- Audio Alerts; none: called beside the queue, ours as far as it knows;
-- "too soon": sooner than the engine starts anything, left out).
local OWNER_WORDS = { queue = "WowVision", unseen = "not WowVision's" }

function GroupHealth.describeSlot(slot)
    if slot == nil then
        return nil
    end
    local entries = {}
    for _, entry in ipairs(slot.seen or {}) do
        tinsert(entries, entry)
    end
    if slot.after ~= nil then
        local listed = false
        for _, entry in ipairs(entries) do
            listed = listed or entry == slot.after
        end
        if not listed then
            tinsert(entries, slot.after)
        end
    end
    local lowest = nil
    for _, entry in ipairs(entries) do
        lowest = lowest == nil and entry.id or math.min(lowest, entry.id)
    end
    table.sort(entries, function(a, b)
        return a.t < b.t
    end)
    local parts = {}
    for _, entry in ipairs(entries) do
        local words = { string.format("+%d ms id %d", math.floor(entry.t - slot.t + 0.5), entry.id - lowest) }
        local owner = OWNER_WORDS[entry.owner]
        if owner ~= nil then
            tinsert(words, owner)
        end
        if entry.early then
            tinsert(words, "too soon")
        elseif entry.queue then
            tinsert(words, "left out")
        end
        tinsert(parts, table.concat(words, " "))
    end
    return string.format("%s; %d calls; starts: %s", slot.why or "thrown away", slot.expect or 0,
        #parts > 0 and table.concat(parts, ", ") or "none")
end

-- Whether utterance `id` is one of the line's silent timing samples (not
-- a number carried with them, not our speech in a slot of its own): only
-- in a slot whose starts are all ours so far. Speech of someone else that
-- started in our window makes the slot ambiguous, and then none of its
-- utterances counts as silent.
function GroupHealth.isOwnSilent(id)
    local entry = GroupHealth.readbackLine.byId[id]
    local slot = entry ~= nil and entry.slot or nil
    return slot ~= nil and slot.samples ~= nil and not slot.ambiguous and not slot.broken
        and entry.order > slot.carried and entry.order <= slot.expect
end

local Readback = WowVision.Class("GroupHealthReadback")
GroupHealth.Readback = Readback

-- env: now() in ms; after(seconds, fn); speak(text) speaks at volume 0 and
-- R.RATE; through(unit, points, digit) the unit's health through a step
-- curve of those points (may be secret, nil when the game refuses the
-- unit); nextCount() a counter that never repeats, not even after a /reload;
-- onReading(unit, reading) with { value, plan, calledMs, rawHigh, rawLow,
-- playedHigh, playedLow, carried (the sample carried speech of the
-- caller's, see request) }. Optional: plan(unit) the plan of the
-- unit's next sample (default locatePlan); priority(unit) who goes first
-- when several wait (lower first); rerequest(unit)
-- when the readback wants the unit read again (a retry, a stop, a health
-- event while two samples were out; default a plain request);
-- onDiscard(unit, why, sample); onNumberCut(unit, sample) when a stop cut
-- the number of a sample that had already ended; onPurge(why) after a purge, to read
-- everyone again; onOwnCut(tag) for an own utterance cut by a stop;
-- startOwner(id) (optional) who started an utterance ("queue": WowVision's
-- speech queue) and when it was called, see retail/speech.lua;
-- onFailing() once when the readback fails for long; frameMs() the current
-- frame time in ms (default 17); onError(err) for an
-- error in the caller's carry (the sample goes on); line, a slot line of
-- its own (the simulation; the addon's readbacks all share
-- GroupHealth.readbackLine).
function Readback:initialize(env)
    self.env = env
    self.line = env.line or GroupHealth.readbackLine
    self.units = {}
    self.queue = {}
    self.queueSeq = 0
    self.inflight = {}
    self.own = {}
    -- Samples whose carried numbers may still be playing (NUMBER_MS).
    self.numbers = {}
    self.generation = 0
    self.lastReadingMs = env.now()
    self.lastPurgeMs = -math.huge
    self.failedSamples = 0
    self.recent = {}
    self:resetStats()
end

-- Counts for the log and the simulation's report.
function Readback:resetStats()
    self.stats = { samples = 0, readings = 0, discarded = {}, maxInflight = 0, purges = {}, ownCut = 0, otherStarts = 0, unseenStarts = 0, earlyStarts = 0 }
end

-- How long the starts of a slot of `count` utterances may take: the first
-- 34 to 56 ms after the call, each further one about ENGINE_MS later, and
-- the event lands on the next frame. Without the frame, at 30 fps the
-- second start of a sample often fell past the window and the sample was
-- thrown away as ambiguous (simulation, 2026-10-14: a third of all samples
-- with almost no other speech).
function GroupHealth.readbackWindow(count, frameMs)
    local last = R.FIRST_START_MAX_MS + math.max(0, count - 1) * R.ENGINE_MS + (frameMs or R.FRAME_MS)
    return math.max(R.START_WINDOW_MS, last)
end

-- The current frame time, ms.
function Readback:frameMs()
    local frameMs = self.env.frameMs ~= nil and self.env.frameMs() or nil
    if frameMs == nil or frameMs ~= frameMs or frameMs <= 0 then
        return R.FRAME_MS
    end
    return math.min(frameMs, 100)
end

-- Runs fn(slot) (engine calls) in the next free slot of the shared line;
-- `expect` is how many starts the calls make.

function Readback:inSlot(expect, fn)
    local line = self.line
    local now = self.env.now()
    local at = math.max(now, line.nextSlotMs)
    local window = GroupHealth.readbackWindow(expect, self:frameMs())
    line.nextSlotMs = at + math.max(R.SLOT_MS, window + R.SLOT_MS - R.START_WINDOW_MS)
    local function run()
        local slot = { t = self.env.now(), starts = 0, expect = expect, window = window }
        tinsert(line.slots, slot)
        while #line.slots > 32 do
            tremove(line.slots, 1)
        end
        fn(slot)
    end
    if at <= now then
        run()
    else
        self.env.after((at - now) / 1000, run)
    end
end

-- Speech of the caller's own (the monitor's announcements): in a slot, so
-- its start never falls into a sample's window, and is known as ours. The
-- tag comes back through onOwnCut when a stop cuts it.
function Readback:speakOwn(fn, tag)
    self:inSlot(1, function(slot)
        local now = self.env.now()
        for i = #self.own, 1, -1 do
            if now - self.own[i].calledMs > R.OWN_FORGET_MS then
                tremove(self.own, i)
            end
        end
        local own = { tag = tag, calledMs = now, owner = self }
        slot.own = own
        tinsert(self.own, own)
        fn()
    end)
end

-- Samples of one unit out at once. A new health event while one is out
-- starts another at once; with MAX_PER_UNIT out, it asks for one more
-- afterwards. A reading older than one already used is dropped.
local MAX_PER_UNIT = 2
-- Up to R.BATCH_MAX members are read together in one slot: their
-- utterances one run (the engine prepares one after another, so a slot's
-- fixed wait, the first start's 34 to 56 ms and the window's end, is shared
-- by all of them).

-- Read the unit soon; false when two samples are out already (it asks
-- again through rerequest when one is back). The request waits in a queue
-- until the line is free; then up to BATCH_MAX members go out together,
-- the most urgent first (env.priority). opts (optional): plan, the plan to
-- use instead of env.plan's; recheck, a silent sample judged like a carried
-- one (it reads again, at the same health, one that was lost); carry(plan), called in the same
-- frame as the digits and before them, speaks the caller's own utterances
-- (which then read the same health as the sample) and returns how many.
function Readback:request(unit, opts)
    local state = self.units[unit]
    if state == nil then
        state = { out = 0, usedMs = -math.huge }
        self.units[unit] = state
    end
    if state.out >= MAX_PER_UNIT then
        state.again = true
        return false
    end
    state.out = state.out + 1
    self.queueSeq = self.queueSeq + 1
    tinsert(self.queue, { unit = unit, opts = opts, seq = self.queueSeq, generation = self.generation })
    self:schedule()
    return true
end

-- The next batch goes out when the line is free.
function Readback:schedule()
    if self.scheduled or #self.queue == 0 then
        return
    end
    local now = self.env.now()
    local at = self.line.nextSlotMs
    if at <= now then
        self:runBatch()
        return
    end
    self.scheduled = true
    self.env.after((at - now) / 1000, function()
        self.scheduled = false
        self:runBatch()
    end)
end

function Readback:runBatch()
    local now = self.env.now()
    -- Numbers past NUMBER_MS have played out.
    for i = #self.numbers, 1, -1 do
        if now - self.numbers[i].calledMs >= R.NUMBER_MS then
            tremove(self.numbers, i)
        end
    end
    -- Another readback, or own speech, took the line meanwhile.
    if self.line.nextSlotMs > now then
        self:schedule()
        return
    end
    local env = self.env
    local queue = {}
    for _, request in ipairs(self.queue) do
        -- Asked for before a purge: that member is read afresh already.
        if request.generation == self.generation then
            request.priority = env.priority ~= nil and env.priority(request.unit) or 0
            tinsert(queue, request)
        end
    end
    table.sort(queue, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.seq < b.seq
    end)
    local batch, rest, taken = {}, {}, {}
    for _, request in ipairs(queue) do
        if #batch < R.BATCH_MAX and not taken[request.unit] then
            taken[request.unit] = true
            tinsert(batch, request)
        else
            tinsert(rest, request)
        end
    end
    self.queue = rest
    if #batch > 0 then
        self:sampleBatch(batch)
    end
    self:schedule()
end

-- No slot reserved ahead and nobody waiting: a sample asked for now is
-- called at once.
function Readback:lineFree()
    return self.line.nextSlotMs <= self.env.now() and #self.queue == 0
end

-- The readback asks for the unit again: the caller decides how.
function Readback:rerequest(unit)
    if self.env.rerequest ~= nil then
        self.env.rerequest(unit)
    else
        self:request(unit)
    end
end

-- One slot for the batch, all in this frame, so every utterance reads the
-- health of the same moment: first what the callers carry (most urgent
-- member first: a spoken number is heard soonest), then each member's two
-- digits. Their ids are one run counting up by one per call.
function Readback:sampleBatch(batch)
    local env, line = self.env, self.line
    local now = env.now()
    local slot = { t = now, starts = 0, expect = 0, window = R.START_WINDOW_MS, samples = {}, list = {}, finishes = {}, failed = {}, owner = self, carried = 0, seen = {} }
    local ready = {}
    for _, request in ipairs(batch) do
        local opts = request.opts
        local plan = (opts ~= nil and opts.plan) or (env.plan ~= nil and env.plan(request.unit)) or GroupHealth.locatePlan()
        local m = { unit = request.unit, plan = plan, calledMs = now, owner = self, slot = slot, opts = opts }
        self.stats.samples = self.stats.samples + 1
        -- The caller's last word on a request that waited for the line
        -- (a re-check is only good while the health is unchanged).
        if opts ~= nil and opts.valid ~= nil and not opts.valid() then
            m.error = "stale"
            -- Counted back by the caller like the check it was.
            m.carried = opts.recheck or opts.carry ~= nil
            m.recheck = opts.recheck
        end
        local silences = {}
        for digit = 1, plan.digitCount do
            local ok, silence = pcall(env.through, request.unit, plan.digitPoints[digit], digit)
            if not ok or silence == nil then
                silences = nil
                break
            end
            silences[digit] = silence
        end
        if m.error ~= nil then
            self:finish(m)
        elseif silences == nil then
            m.error = "no health"
            self:finish(m)
        else
            m.silences = silences
            -- A re-check: silent, judged like the lost sample it reads
            -- again (opts.plan is that sample's plan; the caller sends one
            -- only while the health is unchanged).
            if opts ~= nil and opts.recheck then
                m.carried = true
                m.recheck = true
            end
            tinsert(ready, m)
        end
    end
    if #ready == 0 then
        return
    end
    tinsert(line.slots, slot)
    while #line.slots > 32 do
        tremove(line.slots, 1)
    end
    for _, m in ipairs(ready) do
        local opts = m.opts
        if opts ~= nil and opts.carry ~= nil then
            m.carried = true
            -- Where its own utterances fall in the slot's run.
            m.carriedAt = slot.carried
            local ok, count = pcall(opts.carry, m.plan)
            if ok and type(count) == "number" then
                m.carriedCount = count
                slot.carried = slot.carried + count
                if count > 0 then
                    tinsert(self.numbers, m)
                end
            elseif not ok and env.onError ~= nil then
                env.onError(count)
            end
        end
    end
    local position = slot.carried
    for _, m in ipairs(ready) do
        -- Where its utterances fall in the slot's run.
        m.digitAt = position
        position = position + m.plan.digitCount
        tinsert(slot.samples, m)
        tinsert(self.inflight, m)
        for digit = 1, m.plan.digitCount do
            local ok, err = pcall(env.speak, 'a<silence msec="' .. m.silences[digit] .. '"/>' .. GroupHealth.readbackPad(env.nextCount()))
            if not ok then
                -- A missing call breaks the run: the slot's samples are lost.
                slot.broken = true
                slot.why = slot.why or "a call failed"
                m.error = "speak: " .. tostring(err)
            end
        end
    end
    self.stats.maxInflight = math.max(self.stats.maxInflight, #self.inflight)
    slot.expect = position
    slot.window = GroupHealth.readbackWindow(slot.expect, self:frameMs())
    line.nextSlotMs = now + math.max(R.SLOT_MS, slot.window + R.SLOT_MS - R.START_WINDOW_MS)
    -- The run is known once the window and the grace after it are over.
    env.after((slot.window + R.GRACE_MS) / 1000 + 0.001, function()
        self:checkSlot(slot)
    end)
    env.after(R.TIMEOUT_SECONDS + slot.window / 1000, function()
        for _, m in ipairs(slot.samples) do
            if not m.done then
                m.error = m.error or "timeout"
                self:finish(m)
            end
        end
    end)
end

-- Whether a start of WowVision's queue (called at `calledMs`) can be told
-- apart from a slot's own starts by the order of the ids alone: called
-- before the slot, so it starts before any of the slot's; or called after,
-- so it starts after all of them (the engine starts in call order). Then it
-- is left out of the slot instead of spoiling it. Anything else (a start
-- out of that order, speech we cannot see) spoils the slot as before.
local function queueStartFits(slot, calledMs)
    if calledMs < slot.t then
        return slot.starts == 0
    end
    return slot.expect > 0 and slot.starts >= slot.expect
end

-- Someone else's start before ours in a slot's window (left out): the
-- engine prepared it first, so ours start one engine step later, and the
-- window stretches by that step. (Else our last start fell past the window
-- and the slot was thrown away: simulation, 2026-10-14.)
function Readback:widen(slot)
    if slot.samples == nil or slot.starts > 0 then
        return
    end
    slot.window = slot.window + R.ENGINE_MS
    -- The next slot keeps its distance to the longer window.
    local line = self.line
    line.nextSlotMs = math.max(line.nextSlotMs, slot.t + slot.window + R.SLOT_MS - R.START_WINDOW_MS)
    local owner = slot.owner or self
    local wait = slot.t + slot.window + R.GRACE_MS - self.env.now()
    owner.env.after(math.max(0, wait) / 1000 + 0.001, function()
        owner:checkSlot(slot)
    end)
end

-- Every readback hears every start; the line records it once.
function Readback:startEntry(id)
    local line = self.line
    local entry = line.byId[id]
    if entry ~= nil then
        return entry
    end
    local now = self.env.now()
    entry = { t = now, id = id }
    local owner, calledMs = nil, nil
    if self.env.startOwner ~= nil then
        owner, calledMs = self.env.startOwner(id)
        entry.owner = owner or "unseen"
        if owner == nil then
            -- Counted for the log: how often the game speaks without us.
            self.stats.unseenStarts = self.stats.unseenStarts + 1
            -- A start no call of ours matches: speech we cannot see, which
            -- may have shifted the matching by one (it took a call's place,
            -- and every start after it got the call before its own). A
            -- slot that left out a start as WowVision's lately may have
            -- left out one of its own: it is not trusted.
            -- Every start the speech module took for a call's since the
            -- unseen start before this one may be shifted: a shift takes a
            -- call too early, and the start whose call it took finds none
            -- and is unseen, which ends the shift. Skips before it were
            -- judged then.
            local since = line.lastUnseenMs or -math.huge
            line.lastUnseenMs = now
            for _, slot in ipairs(line.slots) do
                if slot.queueSkips ~= nil and slot.lastSkipMs > since and now - slot.t < R.SHIFT_MS then
                    slot.ambiguous = true
                    slot.why = slot.why or "a start left out as WowVision's speech, then speech we cannot see"
                    slot.run = nil
                end
            end
        end
    end
    for i = #line.slots, 1, -1 do
        local slot = line.slots[i]
        if now >= slot.t and now <= slot.t + (slot.window or R.START_WINDOW_MS) + R.GRACE_MS then
            -- Kept for the log (GroupHealth.describeSlot).
            if slot.seen ~= nil and #slot.seen < 12 then
                tinsert(slot.seen, entry)
            end
            if owner == "queue" and calledMs ~= nil and slot.samples ~= nil and queueStartFits(slot, calledMs) then
                -- WowVision's own speech, in an order that cannot be ours.
                entry.queue = true
                slot.queueSkips = (slot.queueSkips or 0) + 1
                slot.lastSkipMs = now
                if calledMs < slot.t then
                    self:widen(slot)
                end
                break
            end
            if now - slot.t < R.FIRST_START_MS then
                -- Sooner than the engine ever starts an utterance after its
                -- call (now is debugprofilestop's clock, and a start is
                -- handled at or after it happened): called before our slot,
                -- someone else's. Left out instead of spoiling the slot.
                entry.early = true
                self.stats.earlyStarts = (self.stats.earlyStarts or 0) + 1
                self:widen(slot)
                break
            end
            if now > slot.t + (slot.window or R.START_WINDOW_MS) then
                -- Past the window: not this slot's (the run check looks).
                break
            end
            slot.starts = slot.starts + 1
            entry.slot = slot
            entry.order = slot.starts
            break
        end
    end
    line.byId[id] = entry
    tinsert(line.starts, entry)
    while #line.starts > 64 do
        line.byId[tremove(line.starts, 1).id] = nil
    end
    return entry
end

function Readback:onStarted(id)
    local entry = self:startEntry(id)
    local slot = entry.slot
    if slot == nil then
        -- Someone else's speech outside our windows: counted, so the
        -- simulation's disturbances can be set from a real fight.
        self.stats.otherStarts = self.stats.otherStarts + 1
        return
    end
    local own = slot.own
    if own ~= nil and own.owner == self and entry.order == 1 then
        own.id = id
        return
    end
    if slot.owner ~= self or slot.samples == nil then
        return
    end
    -- Up to the starts the slot expects are ours; one more makes the whole
    -- slot ambiguous.
    if entry.order <= slot.expect then
        tinsert(slot.list, entry)
    else
        slot.ambiguous = true
        slot.why = slot.why or "more starts than calls"
    end
end

-- The slot's run once its window and grace are over: exactly as many
-- starts as it made calls, their ids consecutive, and no start with the id
-- right after them. nil before; nil and true (broken) for
-- anything else (a start missing, or a foreign one: the engine was busy,
-- or speech called just before ours started in our window).
function Readback:slotRun(slot)
    if slot.run ~= nil then
        return slot.run
    end
    if self.env.now() < slot.t + slot.window + R.GRACE_MS then
        return nil
    end
    if slot.broken or slot.ambiguous or #slot.list ~= slot.expect or #slot.list < 1 then
        if not slot.broken and not slot.ambiguous then
            slot.why = slot.why or "a start missing"
        end
        return nil, true
    end
    local sorted = {}
    for _, entry in ipairs(slot.list) do
        tinsert(sorted, entry)
    end
    table.sort(sorted, function(x, y)
        return x.id < y.id
    end)
    if sorted[#sorted].id - sorted[1].id ~= #sorted - 1 then
        slot.why = slot.why or "ids not in a row"
        return nil, true
    end
    -- The id right after the run started by the end of the grace, and not
    -- as the next slot's own (between the windows, or sooner after that
    -- slot's call than the engine can): the run may be shifted by one
    -- (someone else's utterance at its start, our last one late).
    local after = self.line.byId[sorted[#sorted].id + 1]
    -- (A start of WowVision's queue known to come after ours is not.)
    if after ~= nil and not after.queue and after.t <= slot.t + slot.window + R.GRACE_MS then
        local nextSlot = after.slot
        if nextSlot == nil or (nextSlot ~= slot and after.t < nextSlot.t + R.FIRST_START_MS) then
            slot.why = slot.why or "a start right after ours"
            slot.after = after
            return nil, true
        end
    end
    slot.run = sorted
    return sorted
end

-- A sample's utterances (the second nil for a single one): in the run
-- after what was carried, in call order.
function Readback:digits(m)
    local run, broken = self:slotRun(m.slot)
    if run == nil then
        return nil, nil, broken
    end
    local at = m.digitAt
    return run[at + 1], m.plan.digitCount == 2 and run[at + 2] or nil
end

-- Ends the slot's samples whose digits have both finished (or failed), or
-- all of them when the run is broken.
function Readback:checkSlot(slot)
    for _, m in ipairs(slot.samples) do
        if not m.done then
            local first, second, broken = self:digits(m)
            if broken then
                m.error = m.error or "ambiguous"
                self:finish(m)
            elseif first ~= nil then
                if slot.failed[first.id] or (second ~= nil and slot.failed[second.id]) then
                    m.error = "failed"
                    self:finish(m)
                elseif m.error ~= nil or (slot.finishes[first.id] ~= nil and (second == nil or slot.finishes[second.id] ~= nil)) then
                    self:finish(m)
                end
            end
        end
    end
end

function Readback:onFinished(id, failed)
    for i, own in ipairs(self.own) do
        if own.id == id then
            tremove(self.own, i)
            return
        end
    end
    local entry = self.line.byId[id]
    local slot = entry ~= nil and entry.slot or nil
    if slot == nil or slot.owner ~= self or slot.samples == nil then
        return
    end
    if failed then
        slot.failed[id] = true
    elseif slot.finishes[id] == nil then
        slot.finishes[id] = self.env.now()
    end
    self:checkSlot(slot)
end

-- Drop everything and start afresh; the caller reads everyone again.
function Readback:purge(why)
    self.generation = self.generation + 1
    self.queue = {}
    for _, m in ipairs(self.inflight) do
        m.done = true
    end
    self.inflight = {}
    self.units = {}
    self.lastPurgeMs = self.env.now()
    self.stats.purges[why] = (self.stats.purges[why] or 0) + 1
    if self.env.onPurge ~= nil then
        self.env.onPurge(why)
    end
end

-- Whether a stop cut what the sample carried (the caller's number): true
-- unless each of its utterances had played to its end.
function Readback:carriedCut(m)
    if not m.carried or (m.carriedCount or 0) == 0 then
        return false
    end
    local run = self:slotRun(m.slot)
    if run == nil then
        return true
    end
    for i = m.carriedAt + 1, m.carriedAt + m.carriedCount do
        if run[i] == nil or m.slot.finishes[run[i].id] == nil then
            return true
        end
    end
    return false
end

-- Someone stopped all speech: every sample out is cut, and so is our own
-- speech that was playing or about to start (a stopped utterance reports
-- no end). The cut samples are dropped and their members read again at
-- once; samples still waiting for their slot were not called yet, so they
-- keep their turn. Then the cut speech is handed back.
function Readback:onStop()
    local now = self.env.now()
    local cut = {}
    for _, own in ipairs(self.own) do
        if own.id ~= nil or now - own.calledMs < R.OWN_START_MS then
            tinsert(cut, own.tag)
        end
    end
    self.own = {}
    -- Whoever stopped all speech mostly speaks at once (WowVision's
    -- interrupting alerts and keys): the samples read again wait until
    -- that speech has started, else its start falls into their window.
    self.line.nextSlotMs = math.max(self.line.nextSlotMs, now + R.POST_STOP_MS)
    -- Numbers that may still have been playing: a sample can end before
    -- the number it carried (its reading is in, the number still plays).
    local numbers = self.numbers
    self.numbers = {}
    -- One whose reading said it was silent does not matter; one heard, or
    -- lost before (heard or not unknown), does. The samples still out are
    -- handled below, with their discard.
    for _, m in ipairs(numbers) do
        if now - m.calledMs < R.NUMBER_MS and m.done and (m.heard or not m.read) and self:carriedCut(m) and self.env.onNumberCut ~= nil then
            self.env.onNumberCut(m.unit, m)
        end
    end
    local rewake, seen = {}, {}
    local cutSamples = self.inflight
    self.inflight = {}
    for _, m in ipairs(cutSamples) do
        m.done = true
        m.carriedCut = self:carriedCut(m)
        self.stats.discarded.stop = (self.stats.discarded.stop or 0) + 1
        local state = self.units[m.unit]
        if state ~= nil then
            state.out = math.max(0, state.out - 1)
        end
        if self.env.onDiscard ~= nil then
            self.env.onDiscard(m.unit, "stop", m)
        end
        if not seen[m.unit] then
            seen[m.unit] = true
            tinsert(rewake, m.unit)
        end
    end
    self.stats.purges.stop = (self.stats.purges.stop or 0) + 1
    for _, unit in ipairs(rewake) do
        self:rerequest(unit)
    end
    for _, tag in ipairs(cut) do
        self.stats.ownCut = self.stats.ownCut + 1
        if self.env.onOwnCut ~= nil then
            self.env.onOwnCut(tag)
        end
    end
end

-- The last samples' outcomes (true: used); tells the caller once when too
-- few were usable.
function Readback:outcome(used)
    local recent = self.recent
    tinsert(recent, used)
    while #recent > R.FAIL_WINDOW do
        tremove(recent, 1)
    end
    if #recent < R.FAIL_WINDOW then
        return
    end
    local count = 0
    for _, ok in ipairs(recent) do
        if ok then
            count = count + 1
        end
    end
    local ratio = count / #recent
    if ratio >= R.RECOVER_RATIO then
        self.failingSaid = false
    elseif ratio < R.FAIL_RATIO then
        self:failing()
    end
end

function Readback:failing()
    if self.failingSaid then
        return
    end
    self.failingSaid = true
    if self.env.onFailing ~= nil then
        self.env.onFailing()
    end
end

-- A sample lost to a disturbance is taken again; a refused unit ("no
-- health") is not.
local RETRY = { stop = true, ambiguous = true, timeout = true, failed = true, ["between levels"] = true, ["out of range"] = true, ["game in the background"] = true }

-- Whether the readback takes a sample lost this way again.
function GroupHealth.readbackRetries(why)
    return RETRY[why] == true
end

-- Returns true when it purged.
function Readback:discard(m, why)
    local stats = self.stats
    local env = self.env
    stats.discarded[why] = (stats.discarded[why] or 0) + 1
    if env.onDiscard ~= nil then
        env.onDiscard(m.unit, why, m)
    end
    if not RETRY[why] then
        return false
    end
    local now = env.now()
    self.failedSamples = self.failedSamples + 1
    self:outcome(false)
    if now - self.lastReadingMs > R.FAIL_MS and self.failedSamples >= R.FAIL_SAMPLES then
        self:failing()
    end
    local state = self.units[m.unit]
    if state == nil then
        return false
    end
    state.failingSinceMs = state.failingSinceMs or m.calledMs
    if now - state.failingSinceMs > R.STUCK_MS and now - self.lastPurgeMs > R.STUCK_MS then
        self:purge("stuck")
        return true
    end
    -- No retry while a newer sample of the unit is still out (out counts this one).
    if state.out <= 1 then
        state.retries = (state.retries or 0) + 1
        if state.retries <= R.QUICK_RETRIES then
            state.again = true
        else
            state.later = true
        end
    end
    return false
end

-- The utterances by id: the lower id was called first. (Speech that cut
-- ours short was once looked for right after its end; with every caller
-- allowed to overlap, only a stop of all speech cuts, and the hook tells.)
function Readback:decode(m)
    local first, second = self:digits(m)
    if first == nil then
        return nil, "ambiguous"
    end
    local finishes = m.slot.finishes
    local playedHigh = finishes[first.id] - first.t
    local playedLow = second ~= nil and finishes[second.id] - second.t or nil
    local value, why, rawHigh, rawLow = GroupHealth.readbackValue(m.plan, playedHigh, playedLow)
    -- Kept on the sample, so whoever hears of a discard sees what it played.
    m.rawHigh, m.rawLow = rawHigh, rawLow
    if value == nil then
        return nil, why
    end
    return {
        value = value,
        plan = m.plan,
        carried = m.carried,
        recheck = m.recheck,
        calledMs = m.calledMs,
        rawHigh = rawHigh,
        rawLow = rawLow,
        playedHigh = playedHigh,
        playedLow = playedLow,
    }
end

function Readback:finish(m)
    if m.done then
        return
    end
    m.done = true
    for i, other in ipairs(self.inflight) do
        if other == m then
            tremove(self.inflight, i)
            break
        end
    end
    local env = self.env
    local generation = self.generation
    -- Next frame: out of the engine event or the slot call that ended it
    -- (the reading may call the engine again).
    env.after(0, function()
        -- A purge since: the sample's member is read afresh already.
        if generation ~= self.generation then
            return
        end
        local state = self.units[m.unit]
        if m.error ~= nil then
            if self:discard(m, m.error) then
                return
            end
        else
            local reading, why = self:decode(m)
            if reading == nil then
                if self:discard(m, why) then
                    return
                end
            elseif state ~= nil and m.calledMs < state.usedMs then
                self:discard(m, "older than the last reading")
            else
                self.stats.readings = self.stats.readings + 1
                self.lastReadingMs = env.now()
                self.failedSamples = 0
                self:outcome(true)
                if state ~= nil then
                    state.retries = 0
                    state.usedMs = m.calledMs
                    state.failingSinceMs = nil
                end
                -- true when the number it carried was heard (the caller says)
                m.read = true
                m.heard = env.onReading(m.unit, reading) == true
            end
        end
        if state ~= nil then
            state.out = math.max(0, state.out - 1)
            if state.again then
                state.again = false
                state.later = false
                self:rerequest(m.unit)
            elseif state.later then
                state.later = false
                env.after(R.RETRY_LATER_SECONDS, function()
                    if self.units[m.unit] == state then
                        self:rerequest(m.unit)
                    end
                end)
            end
        end
    end)
end
