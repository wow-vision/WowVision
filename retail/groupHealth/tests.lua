local testRunner = WowVision.testing.testRunner
local GroupHealth = WowVision.groupHealth

-- The group health monitor's pure half. A step curve is evaluated here the
-- way the game does it (measured on WoW: Forever, 2026-10-03): the value of
-- the last point at or below the input.
local function evaluate(points, x)
    local y = points[1][2]
    for _, point in ipairs(points) do
        if x >= point[1] then
            y = point[2]
        end
    end
    return y
end

testRunner:addSuite("GroupHealth", {
    ["voices: every profile has fifteen steps and a HIGH copy split"] = function(t)
        for key, profile in pairs(GroupHealth.voices.profiles) do
            t:assertEqual(#profile.scale, GroupHealth.PITCH_STEPS, key)
            t:assertEqual(profile.scale[1], profile.scale[2], key)
            t:assertEqual(profile.scale[14], profile.scale[15], key)
            t:assertEqual(profile.scale[profile.highFrom], profile.high[1], key)
        end
        t:assertNotNil(GroupHealth.voices.fallback)
    end,

    ["voices: every level heard about a semitone or more below the one before"] = function(t)
        for key, profile in pairs(GroupHealth.voices.profiles) do
            local heard = {}
            for _, copy in ipairs({ "low", "high" }) do
                local line = profile.measured[copy]
                for _, pitch in ipairs(profile[copy]) do
                    tinsert(heard, line[1] + line[2] * pitch)
                end
            end
            for i = 2, #heard do
                local fall = heard[i - 1] - heard[i]
                t:assertTrue(fall >= 0.95, key .. ": level " .. i .. " falls only " .. fall)
            end
        end
    end,

    ["voices: registration refuses a profile that cannot work"] = function(t)
        local voices = GroupHealth.VoiceProfiles:new()
        local good = { 10, 8, 5, 3, 0, -2, -5, -7, -10 }
        t:assertError(function()
            voices:register({ key = "short", match = "short", low = good, high = { -3, -6, -10 } })
        end)
        t:assertError(function()
            voices:register({ key = "rising", match = "rising", low = good, high = { -3, -6, -10, -8 } })
        end)
        t:assertError(function()
            voices:register({ key = "half", match = "half", low = good, high = { -3, -6.5, -8, -10 } })
        end)
        t:assertError(function()
            voices:register({ key = "case", match = "Case", low = good, high = { -3, -6, -8, -10 } })
        end)
    end,

    ["voices: chosen by voice name, the longest match, else the fallback"] = function(t)
        local voices = GroupHealth.VoiceProfiles:new()
        local function add(key, match, fallback)
            voices:register({
                key = key,
                match = match,
                fallback = fallback,
                low = { 10, 8, 5, 3, 0, -2, -5, -7, -10 },
                high = { -3, -6, -8, -10 },
            })
        end
        add("hedda", "hedda", true)
        add("hedda_desktop", "hedda desktop")
        add("zira", "zira")
        t:assertEqual(voices:forVoice("Microsoft Zira Desktop - English (United States)").key, "zira")
        t:assertEqual(voices:forVoice("Microsoft Hedda Desktop - German").key, "hedda_desktop")
        t:assertEqual(voices:forVoice("Microsoft Hedda - German (Germany)").key, "hedda")
        t:assertEqual(voices:forVoice("Some Other Voice").key, "hedda")
        t:assertEqual(voices:forVoice(nil).key, "hedda")
    end,

    ["voices: the game's voices get their profiles"] = function(t)
        local voices = GroupHealth.voices
        t:assertEqual(voices:forVoice("Microsoft Hedda Desktop - German").key, "hedda")
        t:assertEqual(voices:forVoice("Microsoft Zira Desktop - English (United States)").key, "zira")
        -- The OneCore voices, as named once copied into the SAPI list.
        t:assertEqual(voices:forVoice("Microsoft Hedda - German (Germany)").key, "hedda")
        t:assertEqual(voices:forVoice("Microsoft Katja - German (Germany)").key, "katja")
        t:assertEqual(voices:forVoice("Microsoft Stefan - German (Germany)").key, "hedda")
    end,

    ["copy ranges: below the split the LOW copy, from it the HIGH copy"] = function(t)
        local profile = GroupHealth.voices:get("hedda")
        local split = GroupHealth.split(profile)
        local lowCopy, highCopy = GroupHealth.copyRanges(0, 0.35, profile)
        t:assertEqual(lowCopy[2], 0.35)
        t:assertTrue(highCopy[1] >= highCopy[2]) -- nothing for the HIGH copy
        lowCopy, highCopy = GroupHealth.copyRanges(0.35, 0.9, profile)
        t:assertEqual(lowCopy[1], 0.35)
        t:assertEqual(lowCopy[2], split)
        t:assertEqual(highCopy[1], split)
        t:assertEqual(highCopy[2], 0.9)
        -- Every health in a lane plays exactly one copy.
        for i = 0, 100 do
            local x = i / 100
            local a = evaluate(GroupHealth.bandPoints(lowCopy[1], lowCopy[2]), x)
            local b = evaluate(GroupHealth.bandPoints(highCopy[1], highCopy[2]), x)
            if x >= 0.35 and x < 0.9 then
                t:assertEqual(a + b, 100, "health " .. x)
            else
                t:assertEqual(a + b, 0, "health " .. x)
            end
        end
    end,

    ["copy ranges: above 1 the HIGH copy includes full health"] = function(t)
        local _, highCopy = GroupHealth.copyRanges(0, 2, GroupHealth.voices:get("zira"))
        t:assertEqual(evaluate(GroupHealth.bandPoints(highCopy[1], highCopy[2]), 1), 100)
    end,

    ["below gate: audible under the threshold only"] = function(t)
        local points = GroupHealth.belowPoints(0.4)
        t:assertEqual(evaluate(points, 0.1), 100)
        t:assertEqual(evaluate(points, 0.39), 100)
        t:assertEqual(evaluate(points, 0.4), 0)
        t:assertEqual(evaluate(points, 1), 0)
    end,

    ["below gate at 100 percent: everything but full health"] = function(t)
        local points = GroupHealth.belowPoints(1)
        t:assertEqual(evaluate(points, 0.99), 100)
        t:assertEqual(evaluate(points, 1), 0)
    end,

    ["below gate at 0: always silent"] = function(t)
        local points = GroupHealth.belowPoints(0)
        t:assertEqual(evaluate(points, 0), 0)
        t:assertEqual(evaluate(points, 0.5), 0)
    end,

    ["band gate: audible from low up to high"] = function(t)
        local points = GroupHealth.bandPoints(0.35, 0.8)
        t:assertEqual(evaluate(points, 0.2), 0)
        t:assertEqual(evaluate(points, 0.35), 100)
        t:assertEqual(evaluate(points, 0.79), 100)
        t:assertEqual(evaluate(points, 0.8), 0)
        t:assertEqual(evaluate(points, 1), 0)
    end,

    ["band gate: an empty band leaves nothing"] = function(t)
        local points = GroupHealth.bandPoints(0.8, 0.8)
        t:assertEqual(evaluate(points, 0.5), 0)
        t:assertEqual(evaluate(points, 0.9), 0)
    end,

    ["neighbouring gates never sound together"] = function(t)
        local below = GroupHealth.belowPoints(0.35)
        local above = GroupHealth.bandPoints(0.35, 0.9)
        for i = 0, 100 do
            local x = i / 100
            t:assertTrue(evaluate(below, x) + evaluate(above, x) <= 100)
        end
    end,

    ["full gate: exactly full health"] = function(t)
        local points = GroupHealth.fullPoints()
        t:assertEqual(evaluate(points, 0.999), 0)
        t:assertEqual(evaluate(points, 1), 100)
    end,

    ["raid numbers: up to 10 members 1 to 10 in group order, holes skipped"] = function(t)
        -- A 10-man with someone in group 3: 1 to 10, never 11.
        local roster = { [1] = 1, [2] = 2, [3] = 1, [5] = 2, [6] = 3 }
        for index = 7, 11 do
            roster[index] = index <= 9 and 1 or 2
        end
        local numbers = GroupHealth.raidNumbers(roster, 40)
        t:assertEqual(numbers[1], 1)
        t:assertEqual(numbers[3], 2)
        t:assertEqual(numbers[7], 3)
        t:assertEqual(numbers[9], 5)
        t:assertEqual(numbers[2], 6)
        t:assertEqual(numbers[5], 7)
        t:assertEqual(numbers[11], 9)
        t:assertEqual(numbers[6], 10)
        t:assertNil(numbers[4])
    end,

    ["raid numbers: from 11 members group times five plus place"] = function(t)
        local roster = {}
        for index = 1, 10 do
            roster[index] = math.floor((index - 1) / 5) + 1
        end
        roster[11] = 8
        local numbers = GroupHealth.raidNumbers(roster, 40)
        t:assertEqual(numbers[1], 1)
        t:assertEqual(numbers[6], 6)
        t:assertEqual(numbers[10], 10)
        t:assertEqual(numbers[11], 36)
    end,

    ["pitch levels: the shared ends are one level each, full is its own"] = function(t)
        local levels = GroupHealth.pitchLevels(GroupHealth.voices:get("hedda"))
        -- 15 steps, two pairs sharing a pitch, plus full.
        t:assertEqual(#levels, 14)
        t:assertEqual(levels[1][1], 0)
        t:assertTrue(math.abs(levels[1][2] - 2 / 15) < 1e-9)
        t:assertTrue(math.abs(levels[13][1] - 13 / 15) < 1e-9)
        t:assertEqual(levels[13][2], 1)
        t:assertEqual(levels[14][1], 1)
    end,

    ["pitch steps: the band of health within the steps of the reference"] = function(t)
        local levels = GroupHealth.pitchLevels(GroupHealth.voices:get("hedda"))
        t:assertNil(GroupHealth.pitchQuiet(levels, 61, 0))
        t:assertNil(GroupHealth.pitchQuiet(levels, nil, 1))
        -- 61 percent is step 9 (60 to 66.7): one step keeps only that level.
        local one = GroupHealth.pitchQuiet(levels, 61, 1)
        t:assertTrue(math.abs(one[1] - 9 / 15) < 1e-9)
        t:assertTrue(math.abs(one[2] - 10 / 15) < 1e-9)
        -- Two steps: one level each way.
        local two = GroupHealth.pitchQuiet(levels, 61, 2)
        t:assertTrue(math.abs(two[1] - 8 / 15) < 1e-9)
        t:assertTrue(math.abs(two[2] - 11 / 15) < 1e-9)
        -- 95 percent: the shared top level, never full health.
        local top = GroupHealth.pitchQuiet(levels, 95, 1)
        t:assertTrue(math.abs(top[1] - 13 / 15) < 1e-9)
        t:assertEqual(top[2], 1)
        -- At full health one step keeps only full.
        t:assertEqual(GroupHealth.pitchQuiet(levels, 100, 1)[1], 1)
    end,

    ["segment text carries volume, pitch and words"] = function(t)
        t:assertEqual(
            GroupHealth.segment(100, -4, "3"),
            '<volume level="100"><pitch absmiddle="-4">3</pitch></volume>'
        )
    end,

    ["points key tells gates apart"] = function(t)
        t:assertTrue(
            GroupHealth.pointsKey(GroupHealth.belowPoints(0.4)) ~= GroupHealth.pointsKey(GroupHealth.belowPoints(0.5))
        )
    end,

    ["unique padding: never repeats, only spaces"] = function(t)
        local seen = {}
        for n = 0, 20000 do
            local pad = GroupHealth.uniquePad(n)
            t:assertNil(seen[pad], "padding repeats at " .. n)
            seen[pad] = true
            t:assertNil(pad:gsub("\194\160", ""):find("[^ ]"), "only spaces")
        end
        -- About fifty invisible characters even at a million utterances.
        t:assertTrue(#GroupHealth.uniquePad(1000000) < 120)
    end,

    ["fraction clamps percent"] = function(t)
        t:assertEqual(GroupHealth.fraction(150), 1)
        t:assertEqual(GroupHealth.fraction(-5), 0)
        t:assertEqual(GroupHealth.fraction(35), 0.35)
    end,
})
