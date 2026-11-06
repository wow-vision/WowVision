local testRunner = WowVision.testing.testRunner
local comparison = WowVision.tooltips.comparison

-- A tooltip whose lines are given instead of read from a frame.
local function fakeTooltip(lines)
    local createFrame = CreateFrame
    CreateFrame = function()
        return {
            SetOwner = function() end,
        }
    end
    local tooltip = WowVision.Tooltip:new("ComparisonTest")
    CreateFrame = createFrame
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
        local spoken = {}
        local speak = WowVision.speak
        WowVision.speak = function(_, text)
            tinsert(spoken, text)
        end
        tooltip:nextLine()
        tooltip:nextLine()
        tooltip:nextLine()
        WowVision.speak = speak
        t:assertEqual(table.concat(spoken, "|"), "Fur Boots|Equipped|Old Boots")
    end,
})
