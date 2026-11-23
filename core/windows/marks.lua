-- Marks the player puts on the items of their bags, shared by the modules that have them (junk.lua, favorites.lua).
-- A mark belongs to the item, not to the slot: a second stack of the same item is marked too (junkStore.lua says
-- what makes an item the same item). The marks are kept per character in the module's data:
-- module.data.marks = { [key] = item name }.
--
-- marks.attach(module, opts) gives a module:
--   getMarks()                      the marks table; nil while the module is off or its data is not loaded
--   isMarkedAt(bagID, slotID)       whether the item in that slot carries the mark
--   markedSlots(buttons, locate)    the item buttons among these that do, in the order given
--   tagLabel(label, bagID, slotID)  the label with "[Tag] " ahead of it when marked
--   toggleAt(bagID, slotID)         puts the mark on or takes it off, and says what happened
--   decorateSlot(vtable, locate, owner)  an item slot node with the module's key and context menu entry
--
-- opts: bindingKey (the binding that marks the slot you stand on), and functions that return the module's words in
-- the player's language: tag(), markLabel(), unmarkLabel(), markedText(name), unmarkedText(name), cannotText();
-- and optionally refuse(info, name), a sentence when this item must not get the mark (nil to allow it).
local marks = {}
WowVision.marks = marks

local store = WowVision.junkStore

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

-- One function for every slot (markedSlots runs on every rebuild of the bags: no closure per slot).
local function markedAt(module, locate, itemButton)
    return module:isMarkedAt(locate(itemButton))
end

function marks.attach(module, opts)
    local L = module.L
    -- owner (an item button) -> the function that toggles its slot's mark, made once per button
    local toggles = {}

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

    -- The key of the item in a bag slot, from its link alone. This is asked for every slot on every rebuild of
    -- the bags, so it must cost next to nothing: the link is a string (GetContainerItemInfo would make a table
    -- per call) and its key is remembered (junkStore.keyOf). A client without the link function reads the
    -- item's info as before.
    function module:keyAt(bagID, slotID)
        local getLink = C_Container.GetContainerItemLink
        if getLink == nil then
            local _, key = self:itemAt(bagID, slotID)
            return key
        end
        local ok, link = pcall(getLink, bagID, slotID)
        if not ok then
            return nil
        end
        return store.keyOf(link)
    end

    -- With nothing marked no slot is asked about at all.
    function module:isMarkedAt(bagID, slotID)
        local marked = self:getMarks()
        if marked == nil or next(marked) == nil then
            return false
        end
        return store.isMarked(marked, self:keyAt(bagID, slotID))
    end

    -- The item buttons among these whose slot holds a marked item, in the order given. locate(button) returns the
    -- slot's bag and slot id. A button that cannot be read is left out.
    function module:markedSlots(buttons, locate)
        local slots = {}
        local marked = self:getMarks()
        if marked == nil or next(marked) == nil then
            return slots
        end
        for _, itemButton in ipairs(buttons) do
            local ok, isMarked = pcall(markedAt, self, locate, itemButton)
            if ok and isMarked then
                tinsert(slots, itemButton)
            end
        end
        return slots
    end

    -- A bag slot's label, "[Tag] " ahead of it when its item is marked. Never fails: a slot that cannot be read
    -- has the label it had.
    function module:tagLabel(label, bagID, slotID)
        if label == nil then
            return nil
        end
        local ok, marked = pcall(self.isMarkedAt, self, bagID, slotID)
        if ok and marked then
            return "[" .. opts.tag() .. "] " .. label
        end
        return label
    end

    -- The mark of the item in a bag slot, taken off when it is there and put on when it is not; says what
    -- happened. A mark already there can always be taken off, whatever refuse says.
    function module:toggleAt(bagID, slotID)
        local marked = self:getMarks()
        if marked == nil then
            return
        end
        local info, key = self:itemAt(bagID, slotID)
        -- What happened to a mark is a message of the addon (WowVision:notify): spoken, and written to the chat
        -- when that is switched on.
        if info == nil then
            WowVision:notify(L["Empty"])
            return
        end
        if key == nil then
            WowVision:notify(opts.cannotText())
            return
        end
        local name = nameOf(info, key)
        if not store.isMarked(marked, key) and opts.refuse ~= nil then
            local reason = opts.refuse(info, name)
            if reason ~= nil then
                WowVision:notify(reason)
                return
            end
        end
        if store.toggle(marked, key, name ~= key and name or nil) then
            WowVision:notify(opts.markedText(name))
        else
            WowVision:notify(opts.unmarkedText(name))
        end
        -- The label changed with the mark and was just said; the live watch must not say it a second time.
        local host = WowVision.graphHost
        local screen = host ~= nil and host:focusedScreen() or nil
        if screen ~= nil then
            screen._liveKey = nil
        end
    end

    -- What a bag item slot node gains: the module's key and a context menu entry for the same. locate() returns
    -- the slot's bag and slot id as they are now (the button is reused for other slots). The node is handed back;
    -- nil and a module that is off pass through untouched.
    -- owner (optional): the item button the node stands for, when locate is that button's own function for
    -- good. The toggle function is then made once per button and not on every rebuild of the bags. Buttons are
    -- the game's own frames and stay for the session, so the table does not grow past their number.
    function module:decorateSlot(vtable, locate, owner)
        if vtable == nil or not self:getEnabled() then
            return vtable
        end
        local toggle = owner ~= nil and toggles[owner] or nil
        if toggle == nil then
            toggle = function()
                local bagID, slotID = locate()
                self:toggleAt(bagID, slotID)
            end
            if owner ~= nil then
                toggles[owner] = toggle
            end
        end
        tinsert(vtable.bindings, {
            binding = opts.bindingKey,
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
                label = self:isMarkedAt(locate()) and opts.unmarkLabel() or opts.markLabel(),
                onActivate = toggle,
            })
        end
        return vtable
    end
end
