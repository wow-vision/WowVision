local UIElement = WowVision.Class("UIElement"):include(WowVision.InfoClass)

-- Define InfoClass fields at class level
UIElement.info:addFields({
    { key = "userdata", default = nil, compareMode = "direct" },
    {
        key = "label",
        default = "",
        get = function(obj)
            return obj:getLabel()
        end,
        set = function(obj, key, value)
            obj:setLabel(value)
        end,
        getLabel = function(obj, value)
            return tostring(value)
        end,
    },
    {
        key = "events",
        get = function(obj)
            return obj.eventPropHandlers
        end,
        set = function(obj, key, value)
            obj:setEventProp(value)
        end,
    },
    { key = "layout", default = false },
    { key = "shouldAnnounce", default = true },
    { key = "key", default = nil },
    { key = "displayType", default = nil },
    { key = "sync", default = false },
})

-- Initialize liveFields for base class (child classes will get copies via CreateElementType)
UIElement.liveFields = {
    label = "focus",
}

-- Set typeKey at class level (child classes get this via CreateElementType)
UIElement.typeKey = "Element"

function UIElement:initialize()
    self.L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
    self.typeKey = self.class.typeKey
    self._focused = false
    self._batching = false
    self.parent = nil
    self.props = {}
    self.events = {}
    self.activationSet = WowVision.input:createActivationSet()
    self.activationInfo = { dorment = false }
    self:addProp({
        key = "userdata",
        type = "reference",
        default = nil,
    })
    self:addProp({
        key = "label",
        default = "",
        live = "focus",
        getLabel = function(value)
            return tostring(value)
        end,
        get = function()
            return self:getLabel()
        end,
        set = function(value)
            self:setLabel(value)
        end,
    })

    self:addProp({
        key = "events",
        get = function()
            return self.eventPropHandlers
        end,
        set = function(value)
            self:setEventProp(value)
        end,
    })

    self:addProp({
        key = "layout",
        default = false,
    })

    self:addProp({
        key = "shouldAnnounce",
        default = true,
    })

    self:addProp({
        key = "key",
        default = nil,
    })

    self:addProp({
        key = "displayType",
        default = nil,
    })

    self:addProp({
        key = "sync",
        default = false,
    })

    self:setupUniqueBindings()
end

function UIElement:setupUniqueBindings() end

function UIElement:clearBindings()
    self.activationSet:deactivateAll()
    self.activationSet:clear()
end

function UIElement:addBinding(info)
    return self.activationSet:add(info)
end

function UIElement:setActivationInfo(info)
    info.dorment = false
    self.activationInfo = info
end

function UIElement:addEvent(event)
    self.events[event] = WowVision.Event:new(event)
end

function UIElement:addProp(prop)
    if not prop.key then
        error("Missing key for prop.")
    end
    if not prop.get then
        prop.get = function()
            return self[prop.key]
        end
    end
    if not prop.set then
        prop.set = function(value)
            self[prop.key] = value
        end
    end
    if not prop.type then
        prop.type = "value"
    end
    self.props[prop.key] = prop
    if prop.default then
        if type(prop.default) == "function" then
            prop.set(prop.default())
        else
            prop.set(prop.default)
        end
    end
end

function UIElement:updateProp(prop)
    local oldProp = self.props[prop.key]
    if not oldProp then
        error("No prop to update matching " .. prop.key)
    end

    local newProp = {
        key = prop.key,
        default = prop.default or oldProp.default,
        type = prop.type or oldProp.type,
        live = prop.live or oldProp.live,
        getLabel = prop.getLabel or oldProp.getLabel,
        get = prop.get or oldProp.get,
        set = prop.set or oldProp.set,
    }
    self:addProp(newProp)
end

function UIElement:getProp(key)
    if key == 1 or key == "children" or key == "events" then
        return nil
    end
    local prop = self.props[key]
    if not prop then
        error("Unknown prop " .. key .. ".")
    end
    return prop.get()
end

function UIElement:setEventProp(events)
    self.eventPropHandlers = events
    for event, handlers in pairs(events) do
        local eventTable = self.events[event]
        if not eventTable then
            error("Unknown event " .. event)
        end
        local newHandlers = handlers
        if type(handlers) == "function" then
            newHandlers = { handlers }
        end
        eventTable.handlers = newHandlers
    end
end

function UIElement:setProp(key, value, initial)
    if key == 1 or key == "children" then
        return
    end

    local prop = self.props[key]
    if not prop then
        error("Unknown prop " .. key .. ".")
    end
    if initial and value == nil then
        prop.set(prop.default)
    else
        prop.set(value)
    end
end

function UIElement:emitEvent(event, source, ...)
    self.events[event]:emit(source, ...)
end

function UIElement:batch()
    self._batching = true
    self.batchOp = {
        changed = false,
    }
end

function UIElement:endBatch()
    --This should return itself if something on the element changed during focus that needs to be announced or that needs to notify other UI elements
    self._batching = false
    if not self.batchOp then
        error("Somehow element was not batched: " .. self:getFocusString())
    end
    if self.batchOp.changed then
        return self
    end
    return nil
end

function UIElement:getFocused()
    return self._focused
end

function UIElement:focus(key)
    if self._focused then
        return
    end
    self._focused = true
    self.activationSet:activateAll(self.activationInfo)
    self:onFocus(key)
end

function UIElement:unfocus()
    if not self._focused then
        return
    end
    self._focused = false
    self.activationSet:deactivateAll()
    self:onUnfocus()
end

function UIElement:refocus()
    self:unfocus()
    self:focus()
end

function UIElement:onFocus(key, newlyFocused) end

function UIElement:onUnfocus() end

function UIElement:onInputPressed(binding) end

function UIElement:onBindingPressed(binding)
    return false
end

function UIElement:getLabel()
    return self.label
end

function UIElement:setLabel(label)
    self.label = label
end

function UIElement:getTypeString()
    if self.displayType then
        if self.displayType == "" then
            return nil
        end
        return self.L[self.displayType]
    end
    return self.L[self.typeKey]
end

function UIElement:getExtras()
    return {}
end

function UIElement:getExtrasString()
    local extras = self:getExtras()
    if extras == nil or #extras == 0 then
        return nil
    end
    return table.concat(extras, " ")
end

function UIElement:getFocusString()
    local focus = {}

    local label = self:getLabel()
    if label then
        tinsert(focus, label)
    end

    local typeString = self:getTypeString()
    if typeString then
        tinsert(focus, typeString)
    end

    local extrasString = self:getExtrasString()
    if extrasString then
        tinsert(focus, extrasString)
    end

    return table.concat(focus, " ")
end

function UIElement:setContext(context)
    self.context = context
end

function UIElement:getBatching()
    return self._batching
end

function UIElement:getParent()
    return self.parent
end

function UIElement:setParent(parent)
    self.parent = parent
    if parent then
        self:setContext(parent.context)
    end
end

function UIElement:onUpdate() end

function UIElement:update()
    self:onUpdate()
end

function UIElement:isContainer()
    return false
end

function UIElement:onAdd() end

function UIElement:onRemove() end

function UIElement:announce()
    WowVision:speak(self:getFocusString())
end

WowVision.ui.elementTypes:register("Element", { class = UIElement, generationConditions = {} })
