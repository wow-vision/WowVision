-- The group health monitor's game-independent half: the curve points that
-- turn a member's health into a pitch or a volume gate, raid numbering, the
-- spoken text and the repeat's order. No WoW API in here, so the headless
-- suite covers it (retail/groupHealth/tests.lua).
--
-- Health is a SECRET value on Retail and WoW: Forever: addon code cannot
-- compare it, do arithmetic on it or keep it to compare later. What works
-- (measured on Forever 1.60.1, 2026-10-03, with a probe):
-- - UnitHealthPercent(unit, true, curve) runs the real health (0 to 1)
--   through a curve WE build and hands back the result, itself secret.
-- - A secret survives concatenation, so the result can be the number in a
--   SAPI <pitch absmiddle="..."> or <volume level="..."> tag, and
--   C_VoiceChat.SpeakText honours both tags with a real SAPI voice. The
--   NVDA bridge voice speaks the text but ignores pitch.
-- - A step curve yields the value of the last point at or below the input:
--   points (0, 100), (0.5, 0) give 100 below half health, 0 from half up.
-- - A word at volume 0 is silent but takes as long as if it were spoken.
-- - PlaySoundFile refuses a secret path, so recorded files are no way out.
--
-- So the addon never decides whether someone is hurt. Every announcement
-- carries its possible forms, each behind a volume gate, and the engine
-- plays the one whose health range matches.

local GroupHealth = {}
WowVision.groupHealth = GroupHealth

GroupHealth.ROLES = { "TANK", "HEALER", "DAMAGER", "NONE" }
GroupHealth.MAX_RAID_GROUPS = 8

-- Sku's monitor uses 15 pitch steps of about 7 percent, the highest pitch
-- at the lowest health; Sku's recordings span 12.6 semitones, about one per
-- step. What a SAPI voice allows (2026-10-03; absmiddle takes whole numbers
-- only, "2.5" made a line silent in game; the rest measured offline,
-- rendered through SAPI with exactly this markup):
-- - absmiddle -10 to 10 moves the voice about half a semitone per unit,
--   10 semitones in all; nothing goes past either end.
-- - The voice's own melody comes on top. A number that ends the sentence
--   falls; a number followed by anything, even a silent word, rises: the
--   same absmiddle sounds about 4 semitones higher on Hedda, 6.5 on Zira.
--   Punctuation and "?" as the last word change nothing on Hedda; <emph>
--   replaces the pitch instead of adding to it. A "?" or "!" with any word
--   after it (2026-11-11) makes the number end a sentence: the falling
--   form, 3 to 4 semitones lower, no deeper than the HIGH copy already
--   goes, so it adds no range.
-- So every announcement carries the number twice, each behind a volume
-- gate: the LOW copy first (rising: the urgent part of the scale), the
-- HIGH copy last (falling: the healthy part). The HIGH copy starts about
-- 0.15 seconds after the LOW one would have, 0.2 with the pause after the
-- LOW copy (END_PAUSE). 13 levels, about 1 to 1.5
-- semitones apart: the two lowest and the two highest 7 percent steps
-- share a level.
--
-- Each voice's melody differs, so each voice has its own levels: a voice
-- profile (voices.lua, measured offline through SAPI). A voice without one
-- uses the fallback profile.
GroupHealth.PITCH_STEPS = 15

local VoiceProfiles = WowVision.Class("GroupHealthVoiceProfiles")
GroupHealth.VoiceProfiles = VoiceProfiles

function VoiceProfiles:initialize()
    self.profiles = {}
    self.fallback = nil
end

local function checkLevels(info, copy)
    local levels = info[copy]
    if type(levels) ~= "table" or #levels == 0 then
        error("Voice profile " .. tostring(info.key) .. " needs " .. copy .. " levels")
    end
    for i, pitch in ipairs(levels) do
        if pitch ~= math.floor(pitch) or pitch < -10 or pitch > 10 then
            error("Voice profile " .. info.key .. ": " .. copy .. " level " .. i .. " is not a whole number in -10..10")
        end
        if i > 1 and pitch >= levels[i - 1] then
            error("Voice profile " .. info.key .. ": " .. copy .. " levels must fall")
        end
    end
end

-- info: key; match (lowercase part of the game's voice name); low and high
-- (absmiddle per level of each copy, lowest health first; PITCH_STEPS - 2
-- levels in all, as the two lowest and the two highest steps share one);
-- measured (the voice's peak pitch line per copy, { a, b } = a + b *
-- absmiddle semitones, for the tests); fallback (true for the profile of
-- voices without one); endPause (true: the LOW copy ends in
-- GroupHealth.END_PAUSE; `measured` was then rendered with it). The
-- profile gets its pitch per step (scale), the first step of the HIGH copy
-- (highFrom) and the end of its LOW copy (lowEnd).
function VoiceProfiles:register(info)
    checkLevels(info, "low")
    checkLevels(info, "high")
    if #info.low + #info.high ~= GroupHealth.PITCH_STEPS - 2 then
        error("Voice profile " .. info.key .. " needs " .. (GroupHealth.PITCH_STEPS - 2) .. " levels in all")
    end
    if type(info.match) ~= "string" or info.match ~= string.lower(info.match) then
        error("Voice profile " .. info.key .. " needs a lowercase match")
    end
    local scale = { info.low[1] }
    for _, pitch in ipairs(info.low) do
        tinsert(scale, pitch)
    end
    for _, pitch in ipairs(info.high) do
        tinsert(scale, pitch)
    end
    tinsert(scale, info.high[#info.high])
    info.scale = scale
    info.highFrom = #info.low + 2
    info.lowEnd = info.endPause and GroupHealth.END_PAUSE or ""
    self.profiles[info.key] = info
    if info.fallback then
        self.fallback = info
    end
    return info
end

function VoiceProfiles:get(key)
    return self.profiles[key]
end

-- The profile for a game voice by its name ("Microsoft Zira Desktop -
-- English"): the longest match that is part of the name, so a specific
-- profile ("hedda desktop") wins over a general one ("hedda").
function VoiceProfiles:forVoice(voiceName)
    local name = string.lower(voiceName or "")
    local found
    for _, profile in pairs(self.profiles) do
        if string.find(name, profile.match, 1, true) and (found == nil or #profile.match > #found.match) then
            found = profile
        end
    end
    return found or self.fallback
end

GroupHealth.voices = VoiceProfiles:new()

-- The health from which the HIGH copy speaks.
function GroupHealth.split(profile)
    return (profile.highFrom - 1) / GroupHealth.PITCH_STEPS
end

-- Step k covers health k/steps up to (k+1)/steps; full health falls into
-- the last step.
function GroupHealth.pitchPoints(profile)
    local scale = profile.scale
    local steps = #scale
    local points = {}
    for k = 0, steps - 1 do
        tinsert(points, { k / steps, scale[k + 1] })
    end
    return points
end

-- A lane's health range [low, high) split between the copies: the LOW copy
-- below the profile's split, the HIGH copy from it up. A `high` above 1
-- includes full health.
function GroupHealth.copyRanges(low, high, profile)
    local split = GroupHealth.split(profile)
    local lowCopy = { low, math.min(high, split) }
    local highCopy = { math.max(low, split), high }
    return lowCopy, highCopy
end

local SILENT = { { 0, 0 } }

-- Volume 100 below `high`, 0 at or above it. Thresholds are fractions of
-- full health (0 to 1).
function GroupHealth.belowPoints(high)
    if high == nil or high <= 0 then
        return SILENT
    end
    return { { 0, 100 }, { high, 0 } }
end

-- Volume 100 from `low` up to (not including) `high`.
function GroupHealth.bandPoints(low, high)
    if high == nil or high <= 0 or (low ~= nil and low >= high) then
        return SILENT
    end
    if low == nil or low <= 0 then
        return GroupHealth.belowPoints(high)
    end
    return { { 0, 0 }, { low, 100 }, { high, 0 } }
end

-- Volume 100 at exactly full health.
function GroupHealth.fullPoints()
    return { { 0, 0 }, { 1, 100 } }
end

-- The engine's fastest rate, for what is silent anyway.
GroupHealth.FAST_RATE = 10

-- The rate curve of a part: `rate` (the monitor's setting) on [low, high),
-- where the part can be heard, the fastest rate everywhere else. A silent
-- word takes as long as a spoken one, and a silent part at rate 10 takes
-- about a third of the time: two silent copies 0.23 instead of 0.70 s on
-- Hedda, 0.29 instead of 0.66 on Zira (rendered offline through SAPI,
-- 2026-11-02). The audible copy's pitch stays: measured within 0.15
-- semitones at every level the profiles use, with the silent copy at rate
-- 7 and at rate 10. A `high` above 1 includes full health.
function GroupHealth.ratePoints(low, high, rate)
    local fast = GroupHealth.FAST_RATE
    local empty = high == nil or high <= 0 or (low ~= nil and low >= high)
    if rate == nil or rate >= fast or empty then
        return { { 0, fast } }
    end
    local points = {}
    if low == nil or low <= 0 then
        tinsert(points, { 0, rate })
    else
        tinsert(points, { 0, fast })
        tinsert(points, { low, rate })
    end
    if high <= 1 then
        tinsert(points, { high, fast })
    end
    return points
end

-- The end of the LOW copy. The silent HIGH copy right behind it cuts the
-- audible number off: the volume drops to 0 where the next word starts,
-- while the number is still sounding (Hedda: 60 ms heard instead of 88, at
-- nearly full loudness, no fade). A short pause after the number lets it
-- end as it would alone. Measured offline through SAPI, 2026-11-10, on
-- Hedda, Zira and Katja: 5 ms gives the whole number with its natural fade
-- and the shortest announcement (about 0.05 s longer than without the
-- pause; 1 or 2 ms make SAPI add a longer pause of its own, about 0.1 s);
-- 10 and 20 ms sound the same as 5. A comma, a dash or a quieter instead
-- of a silent HIGH copy did not help. A comma instead of the pause
-- (2026-11-11) keeps the whole number and sits 0.7 semitones higher, but
-- SAPI adds about 0.22 s after it (and 0.08 s before a HIGH number behind
-- a silent comma copy), and by ear it made no difference.
-- The pause lowers both copies, as the silent LOW copy in front of an
-- audible HIGH copy carries it too (measured 2026-11-12 with exactly the
-- game's text, pad included): Hedda's copies stay 5.15 semitones apart
-- (5.3 without the pause), Katja's 2.66 (3.3), but Zira's come to 1.7
-- (5.6), too close for a scale. So the pause is a profile's choice
-- (endPause, the register call sets profile.lowEnd), measured with it.
-- Must stay on one line in this form: tools/voice-profiles/render.ps1
-- reads it from here.
GroupHealth.END_PAUSE = '<silence msec="5"/>'

-- A cache key for a point list, so equal gates share one curve object.
function GroupHealth.pointsKey(points)
    local parts = {}
    for _, point in ipairs(points) do
        tinsert(parts, point[1] .. ":" .. point[2])
    end
    return table.concat(parts, ",")
end

-- Raid numbers as Sku gives them, the key that targets the member in Sku's
-- dial targeting: up to 10 members 1 to 10 in group order; from 11 on
-- (group - 1) * 5 + place in the group. Within a group the place counts in
-- raid index order. `roster` maps a raid index (1 to 40) to its group
-- number; holes are allowed. Returns raid index -> number.
function GroupHealth.raidNumbers(roster, maxIndex)
    local byGroup = {}
    local count = 0
    for index = 1, maxIndex or 40 do
        local group = roster[index]
        if group ~= nil then
            byGroup[group] = byGroup[group] or {}
            tinsert(byGroup[group], index)
            count = count + 1
        end
    end
    local numbers = {}
    local counted = 0
    for group = 1, GroupHealth.MAX_RAID_GROUPS do
        for place, index in ipairs(byGroup[group] or {}) do
            counted = counted + 1
            numbers[index] = count > 10 and (group - 1) * 5 + place or counted
        end
    end
    return numbers
end

-- One spoken part: the words at a volume and a pitch, and at a rate when
-- given (ratePoints), any of which may be a secret curve result. Plain
-- concatenation only, which secrets allow.
function GroupHealth.segment(volume, pitch, words, rate)
    local inner = '<pitch absmiddle="' .. pitch .. '">' .. words .. "</pitch>"
    if rate ~= nil then
        inner = '<rate absspeed="' .. rate .. '">' .. inner .. "</rate>"
    end
    return '<volume level="' .. volume .. '">' .. inner .. "</volume>"
end

-- The engine caches the audio of every text it speaks and replays it when
-- the same text comes again, keyed AFTER stripping the markup: a "3" at one
-- pitch and a "3" at another are one key, and the replay keeps the old
-- pitch and volume. Every utterance therefore gets a padding no other
-- utterance has, from one account-wide counter (module:nextCount): count n
-- written in base 8, each digit a run of 1 to 8 no-break spaces, the runs
-- led by plain spaces. Inaudible (Sku measured U+00A0 on the client), and
-- unlike the shared cache-buster's 512 variants per text it never repeats:
-- a member repeated every few seconds passes 512 within one long fight.
local NBSP = "\194\160"

function GroupHealth.uniquePad(n)
    local parts = {}
    repeat
        local digit = n % 8
        tinsert(parts, " " .. string.rep(NBSP, digit + 1))
        n = math.floor(n / 8)
    until n == 0
    return table.concat(parts)
end

-- Settings store thresholds in percent; curves take fractions.
function GroupHealth.fraction(percent)
    if percent == nil then
        return nil
    end
    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end
    return percent / 100
end

-- The member whose repeat is the most overdue, for the one slot the repeat
-- fills at a time: due when `now` is at least intervalOf(member) seconds
-- past their last repeat (never repeated counts as overdue since forever;
-- an interval of nil or 0 is no repeat); of the due ones, the one furthest
-- past its interval, measured in intervals, so a tank at 2 seconds and a
-- damage dealer at 6 both get their turn; ties go to the lower number.
-- nil when nobody is due.
function GroupHealth.mostOverdue(members, now, intervalOf)
    local best, bestScore
    for _, member in pairs(members) do
        local interval = intervalOf(member)
        if interval ~= nil and interval > 0 then
            local score = math.huge
            if member.lastRepeat ~= nil then
                score = (now - member.lastRepeat) / interval
            end
            local earlier = bestScore == nil or score > bestScore or (score == bestScore and member.number < best.number)
            if score >= 1 and earlier then
                best, bestScore = member, score
            end
        end
    end
    return best
end
