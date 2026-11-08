local module = WowVision.base.windows:createModule("junk")
local L = module.L
module:setLabel(L["Junk"])

local store = WowVision.junkStore

-- Junk: the player marks the item they stand on in the bags (Select Junk, Shift+Enter by default, or the item's
-- context menu), the bag says "[Junk]" ahead of its name, and the merchant window sells every marked item by
-- itself when it opens (merchant.lua). Marking again takes the mark off. The marking itself (marks.lua) is shared
-- with the favorites (favorites.lua); what is junk's own is the sale, and that an item no vendor buys is not marked.
--
-- The marks are remembered per character, by item (junkStore.lua says what makes an item the same item). A mark
-- on one character never sells anything on another. The module's Enabled toggle switches all of it off.

module:registerBinding({
    type = "Flexible",
    key = "junk/toggle",
    dorment = true,
    label = L["Select Junk"],
    inputs = { "SHIFT-ENTER" },
})

function module:getDefaultData()
    return { marks = {} }
end

WowVision.marks.attach(module, {
    bindingKey = "junk/toggle",
    tag = function()
        return L["Junk"]
    end,
    markLabel = function()
        return L["Mark as Junk"]
    end,
    unmarkLabel = function()
        return L["Unmark as Junk"]
    end,
    markedText = function(name)
        return string.format(L["%s: marked as junk"], name)
    end,
    unmarkedText = function(name)
        return string.format(L["%s: no longer junk"], name)
    end,
    cannotText = function()
        return L["This item cannot be marked as junk."]
    end,
    -- An item no vendor buys is not marked (the mark would promise a sale that never comes), but a mark already
    -- there can always be taken off.
    refuse = function(info, name)
        if info.hasNoValue == true then
            return string.format(L["%s cannot be sold to a vendor."], name)
        end
        return nil
    end,
})

-- The marked items as a category of the bags' Item Lists stop (core/windows/bagLists.lua): the slots among those
-- given whose item carries a mark, in the order given (bag by bag).
WowVision.bagLists.register({
    key = "junk",
    label = L["Junk"],
    order = 20,
    select = function(buttons)
        return module:markedSlots(buttons, WowVision.base.windows.containers.slotLocation)
    end,
})

function module:getGraphMenuItems(builder)
    local nodes = WowVision.graph.nodes
    builder:addItem(
        WowVision.graph.ControlId.structural("forgetJunk"),
        nodes.button({
            label = L["Forget All Junk Marks"],
            onActivate = function()
                nodes.pushConfirm({
                    prompt = L["Take the junk mark off every item?"],
                    onConfirm = function()
                        local marks = module:getMarks()
                        if marks ~= nil then
                            store.clear(marks)
                        end
                        WowVision:speak(L["Junk marks forgotten"])
                    end,
                })
            end,
        })
    )
end
