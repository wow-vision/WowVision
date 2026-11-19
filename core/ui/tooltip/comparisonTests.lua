local testRunner = WowVision.testing.testRunner
local comparison = WowVision.tooltips.comparison

-- Runs fn with the given fields of target replaced, and puts them back
-- even when fn fails, so a broken test cannot leak into later suites.
local function withReplaced(target, replacements, fn)
    local saved = {}
    for key, value in pairs(replacements) do
        saved[key] = target[key]
        target[key] = value
    end
    local ok, err = pcall(fn)
    for key in pairs(replacements) do
        target[key] = saved[key]
    end
    if not ok then
        error(err, 0)
    end
end

-- What fn speaks, joined with "|".
local function spokenBy(fn)
    local spoken = {}
    withReplaced(WowVision, {
        speak = function(_, text)
            tinsert(spoken, text)
        end,
    }, fn)
    return table.concat(spoken, "|")
end

-- A tooltip whose lines are given instead of read from a frame.
local function fakeTooltip(lines)
    local tooltip
    withReplaced(_G, {
        CreateFrame = function()
            return {
                SetOwner = function() end,
            }
        end,
    }, function()
        tooltip = WowVision.Tooltip:new("ComparisonTest")
    end)
    tooltip.activeFrame = {}
    tooltip.tooltipData = {}
    tooltip.readLines = function()
        return lines
    end
    return tooltip
end

testRunner:addSuite("TooltipComparison", {
    ["a block gets its header and every line is marked"] = function(t)
        local lines = { { "Fur Boots" } }
        comparison.append(lines, "Equipped", { { "Old Boots" }, { "Feet", "Leather" } })
        t:assertEqual(#lines, 4)
        t:assertNil(lines[1].compare)
        t:assertEqual(lines[2][1], "Equipped")
        t:assertTrue(lines[2].compare)
        t:assertEqual(lines[3][1], "Old Boots")
        t:assertTrue(lines[4].compare)
    end,

    ["the game's own header line is not doubled"] = function(t)
        local lines = { { "Gold Ring" } }
        comparison.append(lines, "Currently Equipped", { { "Currently Equipped" }, { "Silver Ring" } })
        comparison.append(lines, "Currently Equipped", { { "Currently Equipped" }, { "Copper Ring" } })
        t:assertEqual(#lines, 5)
        t:assertEqual(lines[4][1], "Currently Equipped")
        t:assertEqual(lines[5][1], "Copper Ring")
    end,

    ["a secret first line still gets the header"] = function(t)
        local secret = {}
        local lines = { { "Gold Ring" } }
        withReplaced(WowVision.secrets, {
            isSecret = function(value)
                return value == secret
            end,
        }, function()
            comparison.append(lines, "Currently Equipped", { { secret }, { "Silver Ring" } })
        end)
        t:assertEqual(#lines, 4)
        t:assertEqual(lines[2][1], "Currently Equipped")
        t:assertEqual(lines[3][1], secret)
    end,

    ["no header when the game gives none"] = function(t)
        local lines = { { "Gold Ring" } }
        comparison.append(lines, nil, { { "Silver Ring" } })
        t:assertEqual(#lines, 2)
        t:assertEqual(lines[2][1], "Silver Ring")
    end,

    ["reading the whole tooltip stays with the item"] = function(t)
        local lines = { { "Fur Boots" }, { "Feet", "Leather" } }
        comparison.append(lines, "Equipped", { { "Old Boots" } })
        local tooltip = fakeTooltip(lines)
        t:assertEqual(tooltip:getText(), "Fur Boots\nFeet Leather")
    end,

    ["line by line walks on into the blocks"] = function(t)
        local lines = { { "Fur Boots" } }
        comparison.append(lines, "Equipped", { { "Old Boots" } })
        local tooltip = fakeTooltip(lines)
        local spoken = spokenBy(function()
            tooltip:nextLine()
            tooltip:nextLine()
            tooltip:nextLine()
        end)
        t:assertEqual(spoken, "Fur Boots|Equipped|Old Boots")
    end,

    ["block keys jump between the item and each equipped item"] = function(t)
        local lines = { { "" }, { "Leather Belt" }, { "Waist", "Leather" } }
        comparison.append(lines, "Equipped", { { "Old Belt" }, { "Waist", "Leather" } })
        comparison.append(lines, "Equipped", { { "Older Belt" } })
        local tooltip = fakeTooltip(lines)
        local spoken = spokenBy(function()
            tooltip:nextBlock() -- the item, past its blank first line
            tooltip:nextBlock()
            tooltip:nextLine() -- into the first equipped item
            tooltip:nextBlock()
            tooltip:nextBlock() -- the end: read again
            tooltip:previousBlock()
            tooltip:previousBlock()
            tooltip:previousBlock() -- the start: read again
        end)
        t:assertEqual(spoken, "Leather Belt|Equipped|Old Belt|Equipped|Equipped|Equipped|Leather Belt|Leather Belt")
    end,

    ["the stat changes are a block of their own"] = function(t)
        local heading = "If you replace this item, the following stat changes will occur:"
        local lines = { { "Leather Belt" } }
        withReplaced(_G, { ITEM_DELTA_DESCRIPTION = heading }, function()
            comparison.append(lines, "Equipped", { { "Old Belt" }, { " " }, { heading }, { "+2 Stamina" } })
        end)
        local tooltip = fakeTooltip(lines)
        local spoken = spokenBy(function()
            tooltip:nextBlock()
            tooltip:nextBlock()
            tooltip:nextBlock()
            tooltip:nextLine()
            tooltip:previousBlock()
        end)
        t:assertEqual(spoken, "Leather Belt|Equipped|" .. heading .. "|+2 Stamina|Equipped")
    end,
})
