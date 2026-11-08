local module = WowVision.base.windows:createModule("favorites")
local L = module.L
module:setLabel(L["Favorites"])

local store = WowVision.junkStore

-- Favorites: the same as junk (junk.lua) for the items the player wants to find again easily, and nothing is sold
-- because of a mark here. The player marks the item they stand on in the bags (Select Favorite, Shift+Backspace by
-- default, or the item's context menu), the bag says "[Favorite]" ahead of its name, and the item is listed under
-- Favorites in the bags' Item Lists. A favorite is never sold by the merchant sale, even if it is also marked as
-- junk, and even while this module is switched off (switching it off hides the marks; it does not make the items
-- sellable). The marking itself (marks.lua) is shared with junk.
--
-- The marks are remembered per character, by item (junkStore.lua says what makes an item the same item).

module:registerBinding({
    type = "Flexible",
    key = "favorite/toggle",
    dorment = true,
    label = L["Select Favorite"],
    -- the key above Enter that erases a letter, with Shift held
    inputs = { "SHIFT-BACKSPACE" },
})

function module:getDefaultData()
    return { marks = {} }
end

WowVision.marks.attach(module, {
    bindingKey = "favorite/toggle",
    tag = function()
        return L["Favorite"]
    end,
    markLabel = function()
        return L["Mark as Favorite"]
    end,
    unmarkLabel = function()
        return L["Unmark as Favorite"]
    end,
    markedText = function(name)
        return string.format(L["%s: marked as favorite"], name)
    end,
    unmarkedText = function(name)
        return string.format(L["%s: no longer a favorite"], name)
    end,
    cannotText = function()
        return L["This item cannot be marked as a favorite."]
    end,
})

-- Whether the item with this link is a favorite, for the merchant sale. Read whether or not the module is on.
function module:keeps(link)
    local marks = self.data ~= nil and self.data.marks or nil
    if marks == nil then
        return false
    end
    local ok, key = pcall(store.keyFromLink, link)
    return ok and store.isMarked(marks, key)
end

-- The favorites as a category of the bags' Item Lists stop (core/windows/bagLists.lua).
WowVision.bagLists.register({
    key = "favorites",
    label = L["Favorites"],
    order = 30,
    select = function(buttons)
        return module:markedSlots(buttons, WowVision.base.windows.containers.slotLocation)
    end,
})

function module:getGraphMenuItems(builder)
    local nodes = WowVision.graph.nodes
    builder:addItem(
        WowVision.graph.ControlId.structural("forgetFavorites"),
        nodes.button({
            label = L["Forget All Favorites"],
            onActivate = function()
                nodes.pushConfirm({
                    prompt = L["Take the favorite mark off every item?"],
                    onConfirm = function()
                        local marks = module:getMarks()
                        if marks ~= nil then
                            store.clear(marks)
                        end
                        WowVision:speak(L["Favorites forgotten"])
                    end,
                })
            end,
        })
    )
end
