-- The step rules of the Resource monitor (ResourceMonitor.lua), pure Lua so
-- the headless tests run them. Two kinds of resources:
-- - Counted (combo points, holy power, chi, ...): a step is a count; the
--   step whose value is the new count fires.
-- - Bars (mana, energy, rage, ...): a step is a percent threshold. Blizzard's
--   Combat Audio Alerts set the convention: thresholds go down from 100 in
--   the chosen size (40 gives 100, 60, 20); falling to or below a threshold
--   fires it and rising above one fires it. 100 fires on reaching full
--   (Blizzard says it only when a jump lands there), never on leaving it.
--   When one change crosses several thresholds, falling fires the lowest
--   crossed and rising the highest crossed (75 to 45 says 50, 43 to 57 says
--   50), as Blizzard does.
local steps = {}
WowVision.resourceSteps = steps

-- The resources whose value is a count of points, not a bar.
steps.COUNTED = {
    arcanecharges = true,
    burningembers = true,
    chi = true,
    combopoints = true,
    essence = true,
    holypower = true,
    runeblood = true,
    runechromatic = true,
    runefrost = true,
    runes = true,
    runeunholy = true,
    shadoworbs = true,
    soulshards = true,
}

-- Blizzard's step sizes for a bar (the "Say ... " dropdown: every 10 to 50
-- percent).
steps.SIZES = { 10, 20, 30, 40, 50 }

function steps.isCounted(powerKey)
    return steps.COUNTED[powerKey] == true
end

-- The step values for a new monitor, lowest first. Counted: every count from
-- 0 to the maximum (0 is the spend). Bars: the thresholds down from 100 in
-- the size, above 0.
function steps.build(counted, maximum, size)
    local result = {}
    if counted then
        for value = 0, maximum do
            tinsert(result, value)
        end
        return result
    end
    local value = 100
    while value > 0 do
        tinsert(result, 1, value)
        value = value - size
    end
    return result
end

-- The value a bar is compared by: the percent, rounded up like Blizzard's
-- (one point of 1000 mana reads as 1, not 0).
function steps.percent(current, maximum)
    if maximum <= 0 then
        return 0
    end
    return math.ceil(current / maximum * 100)
end

-- Whether a bar value counts as above a threshold. 100 is reached by
-- being full; nothing is above it.
local function above(value, threshold)
    if threshold >= 100 then
        return value >= 100
    end
    return value > threshold
end

-- The step value to fire for a change from old to new, or nil. values: the
-- step values (any order).
function steps.crossed(counted, old, new, values)
    if old == nil or new == nil or old == new then
        return nil
    end
    if counted then
        for _, value in ipairs(values) do
            if value == new then
                return value
            end
        end
        return nil
    end
    local result = nil
    for _, threshold in ipairs(values) do
        local before, after = above(old, threshold), above(new, threshold)
        -- 100 is said on reaching full, never on leaving it.
        if before and not after and threshold < 100 then
            -- falling: the lowest threshold crossed
            if result == nil or threshold < result then
                result = threshold
            end
        elseif after and not before then
            -- rising: the highest threshold crossed
            if result == nil or threshold > result then
                result = threshold
            end
        end
    end
    return result
end

-- Sound series a new monitor's steps take their sounds from: the WowVision
-- sound pack's alerts that come in five rising files, and the pitched synth
-- notes for more steps than that.
steps.SERIES = {
    glass = { files = 5 },
    brass = { files = 5 },
    waterdrop = { files = 5 },
    stuck = { files = 5 },
    notes = { files = 0 },
}
steps.SERIES_ORDER = { "glass", "brass", "waterdrop", "stuck", "notes" }

local SOUND_DIR = "Sound/WowVision/alerts/"
-- The spend (a count falling to 0) gets a sound of its own.
steps.SPEND_SOUND = SOUND_DIR .. "click.mp3"

-- The synth notes (audio/sound.lua): 61 files, about a whole tone apart per
-- two files. Steps climb three files from synth 19 (f3); 11 steps end at 49.
local NOTE_NAMES = {
    "c2", "c2", "d2", "d2", "e2", "e2", "f2", "f2", "g2", "a2", "a2", "b2", "c3", "c3", "d3", "d3",
    "e3", "e3", "f3", "f3", "g3", "a3", "a3", "b3", "c4", "c4", "d4", "d4", "e4", "e4", "f4", "f4",
    "g4", "a4", "a4", "b4", "c5", "c5", "d5", "d5", "e5", "e5", "f5", "f5", "g5", "a5", "a5", "b5",
    "c6", "c6", "d6", "d6", "e6", "e6", "f6", "f6", "g6", "a6", "a6", "b6", "c7",
}

function steps.notePath(index)
    local file = 19 + (index - 1) * 3
    if file > #NOTE_NAMES then
        file = #NOTE_NAMES
    end
    return "Sound/WowVision/notes/synth_" .. file .. "_" .. NOTE_NAMES[file] .. ".mp3"
end

-- The default sound of every step, keyed by step value. A count of 0 gets
-- the spend sound; the other steps take the series' files lowest first, or
-- the notes when the series has fewer files than steps.
function steps.sounds(counted, values, seriesKey)
    local sorted = {}
    for _, value in ipairs(values) do
        if not (counted and value == 0) then
            tinsert(sorted, value)
        end
    end
    table.sort(sorted)
    local series = steps.SERIES[seriesKey] or steps.SERIES.glass
    local useSeries = series.files > 0 and #sorted <= series.files
    local result = {}
    for index, value in ipairs(sorted) do
        if useSeries then
            result[value] = SOUND_DIR .. seriesKey .. index .. ".mp3"
        else
            result[value] = steps.notePath(index)
        end
    end
    if counted then
        result[0] = steps.SPEND_SOUND
    end
    return result
end

-- What the speech says, in Blizzard's six formats (Combat Audio Alerts,
-- "Say ... Format"). A count has no percent and is never divided.
steps.FORMATS = { "full", "noPercent", "tenths", "noName", "number", "numberTenths" }

function steps.text(format, counted, name, value)
    local number = value
    if not counted and (format == "tenths" or format == "numberTenths") then
        number = math.floor(value / 10)
    end
    local percent = not counted and (format == "full" or format == "noName")
    local numberText = tostring(number) .. (percent and "%" or "")
    if format == "noName" or format == "number" or format == "numberTenths" or name == nil then
        return numberText
    end
    return name .. " " .. numberText
end
