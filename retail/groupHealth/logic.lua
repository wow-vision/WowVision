-- The group health monitor's game-independent half: the curve points that
-- turn a member's health into a pitch or a volume gate, the pitch levels,
-- raid numbering and the spoken text. No WoW API in here, so the headless
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
-- So the addon never decides whether someone is hurt. Every health event
-- prepares the possible announcements, each behind a volume gate, and the
-- engine plays the one whose health range matches.

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
--   Punctuation and "?" change nothing on Hedda; <emph> replaces the pitch
--   instead of adding to it.
-- So every announcement carries the number twice, each behind a volume
-- gate: the LOW copy first (rising: the urgent part of the scale), the
-- HIGH copy last (falling: the healthy part). The HIGH copy starts about
-- 0.15 seconds after the LOW one would have. 13 levels, about 1 to 1.5
-- semitones apart: the two lowest and the two highest 7 percent steps
-- share a level.
--
-- Each voice's melody differs, so each voice has its own levels: a voice
-- profile (voices.lua; made with tools/voice-profiles). A voice without
-- one uses the fallback profile.
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
-- voices without one). The profile gets its pitch per step (scale) and the
-- first step of the HIGH copy (highFrom).
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

-- The pitch levels a listener tells apart, lowest health first, as health
-- ranges { low, high }: one per step of the scale, except where neighbours
-- in the same copy share a pitch (the two lowest, the two highest), and
-- last "full" at exactly full health, a word of its own.
function GroupHealth.pitchLevels(profile)
    local scale = profile.scale
    local steps = #scale
    local levels = {}
    for k = 0, steps - 1 do
        local index = k + 1
        local sameCopy = (index < profile.highFrom) == (index - 1 < profile.highFrom)
        if k > 0 and sameCopy and scale[index] == scale[index - 1] then
            levels[#levels][2] = (k + 1) / steps
        else
            tinsert(levels, { k / steps, (k + 1) / steps })
        end
    end
    tinsert(levels, { 1, 1.01 })
    return levels
end

-- Sku's "minimum pitch steps" as a band: the health that sounds less than
-- `steps` levels away from the reference (whole percent), where a number
-- stays silent. nil for no steps or no reference.
function GroupHealth.pitchQuiet(levels, reference, steps)
    if steps == nil or steps <= 0 or reference == nil then
        return nil
    end
    local health = reference / 100
    local at = #levels
    for i, level in ipairs(levels) do
        if health < level[2] then
            at = i
            break
        end
    end
    local first = math.max(1, at - steps + 1)
    local last = math.min(#levels, at + steps - 1)
    return { levels[first][1], levels[last][2] }
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

-- Volume 100 on [low, high) except inside `quiet` ({ low, high }, either
-- end may lie outside 0 to 1): Sku's rule as a gate, "moved at least the
-- threshold since the last announcement", with the band around that
-- announcement as `quiet`. Without `quiet`, bandPoints. A `high` above 1
-- includes full health.
function GroupHealth.gatePoints(low, high, quiet)
    if quiet == nil then
        return GroupHealth.bandPoints(low, high)
    end
    low = low or 0
    if high == nil or high <= low then
        return SILENT
    end
    local pieces = {}
    local below = math.min(high, quiet[1])
    if below > low then
        tinsert(pieces, { low, below })
    end
    local above = math.max(low, quiet[2])
    if high > above and above <= 1 then
        tinsert(pieces, { above, high })
    end
    if #pieces == 0 then
        return SILENT
    end
    local points = {}
    if pieces[1][1] > 0 then
        tinsert(points, { 0, 0 })
    end
    for _, piece in ipairs(pieces) do
        tinsert(points, { math.max(0, piece[1]), 100 })
        if piece[2] <= 1 then
            tinsert(points, { piece[2], 0 })
        end
    end
    return points
end

-- Whether a gate keeps every health silent: such an utterance need not be
-- sent at all (fewer utterances at once in the engine).
function GroupHealth.isSilent(points)
    for _, point in ipairs(points) do
        if point[2] ~= 0 then
            return false
        end
    end
    return true
end

-- Volume 100 at exactly full health.
function GroupHealth.fullPoints()
    return { { 0, 0 }, { 1, 100 } }
end

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

-- One spoken part: the words at a volume and a pitch, either of which may
-- be a secret curve result. Plain concatenation only, which secrets allow.
function GroupHealth.segment(volume, pitch, words)
    return '<volume level="' .. volume .. '"><pitch absmiddle="' .. pitch .. '">' .. words .. "</pitch></volume>"
end

-- The engine caches the audio of every text it speaks and replays it when
-- the same text comes again, keyed AFTER stripping the markup: a "3" at one
-- pitch and a "3" at another are one key, and the replay keeps the old
-- pitch and volume. Every utterance therefore gets a padding no other
-- utterance has, from one account-wide counter (module:nextCount): count n
-- written in base 8, each digit a run of 1 to 8 no-break spaces, the runs
-- led by plain spaces. Inaudible (Sku measured U+00A0 on the client), and
-- unlike the shared cache-buster's 512 variants per text it never repeats:
-- a tank's number would reach 512 within one long fight.
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

-- The readback's silent samples (readback.lua) need a padding of their
-- own: all of the same length, so the text is identical in all but its
-- code and plays the same time. 24 positions of a no-break space followed
-- by a space or a second no-break space.
function GroupHealth.readbackPad(n)
    local parts = {}
    for _ = 1, 24 do
        tinsert(parts, n % 2 == 1 and (NBSP .. NBSP) or (NBSP .. " "))
        n = math.floor(n / 2)
    end
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
