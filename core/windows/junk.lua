local module = WowVision.base.windows:createModule("junk")
local L = module.L
module:setLabel(L["Junk"])

local store = WowVision.junkStore

-- Junk: the player marks the item they stand on in the bags (Select Junk, Shift+Enter by default, or the item's
-- context menu), the bag says "[Junk]" ahead of its name, and the merchant window sells every marked item by
-- itself when it opens (merchant.lua). Marking again takes the mark off.
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

-- The marks table; nil while the module is off or its data is not loaded, which reads as "nothing is marked".
function module:getMarks()
    if not self:getEnabled() or self.data == nil then
        return nil
    end
    if self.data.marks == nil then
        self.data.marks = {}
    end
    return self.data.marks
end

-- The game's item info for a bag slot and the item's key; nil when the slot is empty or cannot be read.
function module:itemAt(bagID, slotID)
    local ok, info = pcall(C_Container.GetContainerItemInfo, bagID, slotID)
    if not ok or info == nil then
        return nil
    end
    local keyOk, key = pcall(store.keyFromLink, info.hyperlink)
    return info, keyOk and key or nil
end

function module:isMarkedAt(bagID, slotID)
    local marks = self:getMarks()
    if marks == nil then
        return false
    end
    local _, key = self:itemAt(bagID, slotID)
    return store.isMarked(marks, key)
end

-- The item buttons among these whose slot holds a marked item, in the order given. locate(button) returns the
-- slot's bag and slot id. A button that cannot be read is left out.
function module:markedSlots(buttons, locate)
    local marked = {}
    if self:getMarks() == nil then
        return marked
    end
    for _, itemButton in ipairs(buttons) do
        local ok, isMarked = pcall(function()
            return self:isMarkedAt(locate(itemButton))
        end)
        if ok and isMarked then
            tinsert(marked, itemButton)
        end
    end
    return marked
end

-- A bag slot's label, "[Junk] " ahead of it when its item is marked ("[Camelote] " in French: the module's own
-- name in brackets). Never fails: a slot that cannot be read has the label it had.
function module:tagLabel(label, bagID, slotID)
    if label == nil then
        return nil
    end
    local ok, marked = pcall(self.isMarkedAt, self, bagID, slotID)
    if ok and marked then
        return "[" .. L["Junk"] .. "] " .. label
    end
    return label
end

-- What the item is called when it is said: the game's name, else the one in its link, else its key.
local function nameOf(info, key)
    if type(info.itemName) == "string" and info.itemName ~= "" then
        return info.itemName
    end
    local ok, name = pcall(store.nameFromLink, info.hyperlink)
    if ok and name ~= nil then
        return name
    end
    return key
end

-- The mark of the item in a bag slot, taken off when it is there and put on when it is not; says what happened.
-- An item no vendor buys is not marked (the mark would promise a sale that never comes), but a mark already
-- there can always be taken off.
function module:toggleAt(bagID, slotID)
    local marks = self:getMarks()
    if marks == nil then
        return
    end
    local info, key = self:itemAt(bagID, slotID)
    if info == nil then
        WowVision:speak(L["Empty"])
        return
    end
    if key == nil then
        WowVision:speak(L["This item cannot be marked as junk."])
        return
    end
    local name = nameOf(info, key)
    if not store.isMarked(marks, key) and info.hasNoValue == true then
        WowVision:speak(string.format(L["%s cannot be sold to a vendor."], name))
        return
    end
    local marked = store.toggle(marks, key, name ~= key and name or nil)
    if marked then
        WowVision:speak(string.format(L["%s: marked as junk"], name))
    else
        WowVision:speak(string.format(L["%s: no longer junk"], name))
    end
    -- The label changed with the mark and was just said; the live watch must not say it a second time.
    local host = WowVision.graphHost
    local screen = host ~= nil and host:focusedScreen() or nil
    if screen ~= nil then
        screen._liveKey = nil
    end
end

-- What a bag item slot node gains: the Select Junk key and a context menu entry for the same. locate() returns
-- the slot's bag and slot id as they are now (the button is reused for other slots). The node is handed back;
-- nil and a module that is off pass through untouched.
function module:decorateSlot(vtable, locate)
    if vtable == nil or not self:getEnabled() then
        return vtable
    end
    local function toggle()
        local bagID, slotID = locate()
        self:toggleAt(bagID, slotID)
    end
    tinsert(vtable.bindings, {
        binding = "junk/toggle",
        type = "Function",
        interruptSpeech = true,
        func = toggle,
    })
    local actions = vtable.contextActions
    vtable.contextActions = function(add, node)
        if type(actions) == "function" then
            actions(add, node)
        end
        add({
            label = self:isMarkedAt(locate()) and L["Unmark as Junk"] or L["Mark as Junk"],
            onActivate = toggle,
        })
    end
    return vtable
end

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
