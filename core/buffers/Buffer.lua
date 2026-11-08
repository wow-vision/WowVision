local L = WowVision:getLocale()

local Buffer = WowVision.Class("Buffer")
Buffer:include(WowVision.ViewList)
Buffer:addFields({
    -- Plain managed field: getEnabled/setEnabled below are thin wrappers
    -- and MUST NOT be wired as accessors (they touch self.enabled).
    {
        key = "enabled",
        type = "Bool",
        label = L["Enabled"],
        default = true,
        persist = true,
        sortPriority = 1,
    },
    {
        key = "label",
        type = "String",
        label = L["Label"],
        persist = true,
        sortPriority = 1,
    },
})

function Buffer:initialize(obj)
    obj = obj or {}
    self:setupViewList()
    self.allowRefocus = true
    self.events = {
        add = WowVision.Event:new("add"),
        modify = WowVision.Event:new("modify"),
        remove = WowVision.Event:new("remove"),
    }
    self:applyFields(obj)
end

function Buffer:add(index, item)
    local result = WowVision.ViewList.add(self, index, item)
    if result then
        local addedItem = item or index
        self.events.add:emit(self, addedItem)
    end
    return result
end

function Buffer:remove(item)
    local result = WowVision.ViewList.remove(self, item)
    if result then
        self.events.remove:emit(self, item)
    end
    return result
end

function Buffer:getLabel()
    return self.label
end

function Buffer:setLabel(label)
    self.label = label or ""
end

function Buffer:getEnabled()
    return self.enabled
end

function Buffer:setEnabled(enabled)
    self.enabled = enabled
end

-- Always Start at Top: entered, the buffer stands on its first item.
function Buffer:startAtTop()
    self:focusIndex(1)
end

-- An item key. restart: this press starts a new run (Always Start at Top) and
-- a forward press then lands on the first item; a backward one moves on from
-- where the buffer stands.
function Buffer:UIMoveItem(direction, restart)
    if restart and direction > 0 then
        local first = self:focusIndex(1)
        if first ~= nil then
            WowVision:speak(first:getFocusString())
        end
        return
    end
    self:UIFocusDirection(direction)
end

function Buffer:getFocusString()
    local result = self:getLabel()
    local focus = self:getFocus()
    if focus then
        result = result .. " " .. focus:getFocusString()
    end
    return result
end

-- Create component registry for buffer types
local registry = WowVision.components.createRegistry({
    path = "buffers/buffer",
    type = "class",
    baseClass = Buffer,
    classNameSuffix = "Buffer",
})

local buffers = {
    Buffer = Buffer,
    registry = registry,
}

-- Convenience method to create buffer types
function buffers:createType(key)
    local typeClass = registry:createType({ key = key })
    return typeClass, self.Buffer
end

-- Convenience method to create buffer instances
function buffers:create(typeKey, params)
    params = params or {}
    params.type = typeKey
    return registry:createComponent(params)
end

-- The setting Always Start at Top; the buffers module answers it (core/buffers/module.lua).
function buffers.startsAtTop()
    return false
end

-- What a run starting or ending sounds like; the buffers module answers it.
function buffers.runStarted() end

function buffers.runEnded() end

-- A run through the buffers lasts as long as Alt is held: letting go ends it
-- (the module hears that), and the next buffer key takes the new one.
local newRun = true

function buffers.endRun()
    if not newRun then
        newRun = true
        buffers.runEnded()
    end
end

function buffers.takeNewRun()
    local isNew = newRun
    newRun = false
    if isNew then
        buffers.runStarted()
    end
    return isNew
end

WowVision.buffers = buffers
