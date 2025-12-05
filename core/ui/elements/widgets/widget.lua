local Widget, parent = WowVision.ui:CreateElementType("Widget", "Element")

-- Define InfoClass fields at class level
Widget.info:addFields({
    {
        key = "bind",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj.bind = value
            obj:setValue(obj:getBoundValue())
        end,
    },
    {
        key = "value",
        default = nil,
        get = function(obj)
            return obj:getValue()
        end,
        set = function(obj, key, value)
            obj:setValue(value)
        end,
        getLabel = function(obj, value)
            return obj:getValueString()
        end,
    },
    { key = "tooltip", default = nil },
    {
        key = "enabled",
        default = true,
        getLabel = function(obj, value)
            if value == false then
                return obj.L["Disabled"]
            end
        end,
    },
    {
        key = "selected",
        default = false,
        getLabel = function(obj, value)
            if value then
                return obj.L["selected"]
            end
        end,
    },
})

-- Add to liveFields (inherits label from UIElement)
Widget.liveFields.value = "focus"
Widget.liveFields.enabled = "focus"
Widget.liveFields.selected = "focus"

function Widget:initialize()
    parent.initialize(self)
    self:addProp({
        key = "bind",
        type = "reference",
        default = nil,
        set = function(value)
            self.bind = value
            self:setValue(self:getBoundValue())
        end,
    })

    self:addProp({
        key = "value",
        default = nil,
        live = "focus",
        getLabel = function()
            return self:getValueString()
        end,
        get = function()
            return self:getValue()
        end,
        set = function(value)
            self:setValue(value)
        end,
    })

    self:addProp({
        key = "tooltip",
    })

    self:addProp({
        key = "enabled",
        default = true,
        live = "focus",
        getLabel = function(value)
            if value == false then
                return self.L["Disabled"]
            end
        end,
    })

    self:addProp({
        key = "selected",
        default = false,
        live = "focus",
        getLabel = function(value)
            if value then
                return self.L["selected"]
            end
        end,
    })

    self:addEvent("click")
    self:addEvent("drag")
    self:addEvent("valueChange")

    self:addBinding({
        binding = "tooltip",
        type = "Function",
        interruptSpeech = true,
        delay = 0.01,
        func = function()
            self:announceTooltip()
        end,
    })
    self:addBinding({
        binding = "drag",
        type = "Function",
        func = function()
            self:drag()
        end,
    })
end

function Widget:setupUniqueBindings()
    self:addBinding({
        binding = "leftClick",
        type = "Function",
        interruptSpeech = true,
        delay = 0.01,
        func = function()
            self:click()
        end,
    })
end

function Widget:getValue()
    if self.bind then
        return self:getBoundValue()
    end
    return self.value
end

function Widget:getValueString()
    local value = self:getValue()
    if value then
        return tostring(self:getValue())
    end
    return nil
end

function Widget:setValue(value)
    if self.bind then
        self:setBoundValue(value)
    else
        self.value = value
    end
    self:emitEvent("valueChange", self, value)
end

function Widget:getBoundValue()
    if not self.bind then
        return self.value
    end
    local tbl = self.bind[1]
    if not tbl then
        error("Missing table for bind prop")
    end
    if self.bind.type then
        if self.bind.type == "name" then
            return tbl[self.bind.name]
        elseif type == "function" then
            return tbl[self.bind.name](tbl)
        else
            error("Unknown bind type")
        end
    end
    if self.bind.getType then
        if self.bind.getType == "name" then
            return tbl[self.bind.getName]
        elseif self.bind.getType == "function" then
            return tbl[self.bind.getName](tbl)
        else
            error("Unknown bind getType")
        end
    end
    return self.value
end

function Widget:setBoundValue(value)
    if not self.bind then
        return nil
    end
    local value = value
    if self.bind.value then
        value = self.bind.value
    end
    local tbl = self.bind[1]
    if not tbl then
        error("Missing table for bind prop")
    end
    if self.bind.type then
        if self.bind.type == "name" then
            tbl[self.bind.name] = value
            return
        elseif type == "function" then
            tbl[self.bind.name](tbl, value)
            return
        else
            error("Unknown bind type")
        end
    end
    if self.bind.setType then
        if self.bind.setType == "name" then
            tbl[self.bind.setName] = value
            return
        elseif self.bind.setType == "function" then
            tbl[self.bind.setName](tbl, value)
            return
        else
            error("Unknown bind setType")
        end
    end
    error("Bind missing either type or setType value.")
end

function Widget:onFocus()
    if self.tooltip then
        WowVision.UIHost.tooltip:set(self, self.tooltip)
    end
end

function Widget:onUnfocus()
    if self.tooltip then
        WowVision.UIHost.tooltip:reset()
    end
end

function Widget:announceTooltip()
    WowVision.UIHost.tooltip:speak()
end

function Widget:getExtras()
    local props = {}
    if not self.enabled then
        tinsert(props, self.L["Disabled"])
    end
    tinsert(props, self.props.value.getLabel())
    return props
end

function Widget:unfocus()
    parent.unfocus(self)
end

function Widget:click()
    if self.enabled then
        self:emitEvent("click", self)
        self:onClick()
    end
end

function Widget:onClick() end

function Widget:drag()
    if self.enabled then
        self:emitEvent("drag", self)
        self:onDrag()
    end
end

function Widget:onDrag() end
