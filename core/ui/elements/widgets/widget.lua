local Widget, parent = WowVision.ui:CreateElementType("Widget", "Element")

-- Define InfoClass fields at class level
Widget.info:addFields({
    {
        key = "bind",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj.bind = value -- Keep raw config for reconciliation comparison
            obj._binding = WowVision.dataBinding:create(value)
        end,
    },
    {
        key = "value",
        default = nil,
        get = function(obj)
            return obj:getValue()
        end,
        set = function(obj, key, value)
            -- Don't write nil to bound source - let bind handle the value
            if value == nil and obj.bind then
                return
            end
            obj:setValue(value)
        end,
        getValueString = function(obj, value)
            return obj:getValueString()
        end,
    },
    { key = "tooltip", default = nil },
    {
        key = "enabled",
        default = true,
        getValueString = function(obj, value)
            if value == false then
                return obj.L["Disabled"]
            end
        end,
    },
    {
        key = "selected",
        default = false,
        getValueString = function(obj, value)
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

function Widget:onSetInfo()
    -- Initialize value from binding after all fields are set
    -- (ensures child class fields like EditBox.type are available)
    if self._binding and self._binding.fixedValue == nil then
        self:setValue(self:getBoundValue())
    end
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
    if not self._binding then
        return self.value
    end
    return self._binding:get()
end

function Widget:setBoundValue(value)
    if not self._binding then
        return
    end
    self._binding:set(value)
end

function Widget:onFocus()
    if self.tooltip then
        WowVision.UIHost.tooltip:set(self, self.tooltip)
        WowVision.UIHost.tooltip:onFocus()
    end
end

function Widget:onUnfocus()
    if self.tooltip then
        WowVision.UIHost.tooltip:onUnfocus()
        WowVision.UIHost.tooltip:reset()
    end
end

function Widget:announceTooltip()
    WowVision.UIHost.tooltip:speak()
end

function Widget:getExtras()
    local extras = {}
    if not self.enabled then
        tinsert(extras, self.L["Disabled"])
    end
    local valueField = self.class.info:getField("value")
    if valueField then
        local label = valueField:getValueString(self, self:getValue())
        if label then
            tinsert(extras, label)
        end
    end
    return extras
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
