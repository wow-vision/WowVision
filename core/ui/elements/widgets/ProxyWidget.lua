local ProxyWidget, parent, manager = WowVision.ui:CreateElementType("ProxyWidget", "Widget")

-- Define InfoClass fields at class level
ProxyWidget.info:addFields({
    { key = "ignoreRequiresFrameShown", default = false },
    {
        key = "frame",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj:setFrame(value)
        end,
    },
    { key = "macroCall", default = nil },
    { key = "dropdown", default = false },
    { key = "useGameTooltip", default = true },
    { key = "secure", default = false },
})

-- Override selected getter from Widget
ProxyWidget.info:updateFields({
    {
        key = "selected",
        get = function(obj)
            return obj:getSelected()
        end,
    },
})

-- Override tooltip default from Widget
ProxyWidget.info:updateFields({
    {
        key = "tooltip",
        compareMode = "direct",
        default = function()
            return {
                type = "game",
                mode = "static",
            }
        end,
    },
})

function ProxyWidget:initialize()
    parent.initialize(self)
    self:addProp({
        key = "ignoreRequiresFrameShown",
        default = false,
    })
    self:addProp({
        key = "frame",
        type = "reference",
        default = nil,
        set = function(value)
            self:setFrame(value)
        end,
    })

    self:updateProp({
        key = "selected",
        get = function()
            return self:getSelected()
        end,
    })

    self:addProp({
        key = "macroCall",
        default = nil,
    })

    self:addProp({
        key = "dropdown",
        default = false,
    })

    self:addProp({
        key = "useGameTooltip",
        default = true,
    })

    self:addProp({
        key = "secure",
        default = false,
    })

    self:updateProp({
        key = "tooltip",
        type = "reference",
        default = function()
            return {
                type = "game",
                mode = "static",
            }
        end,
    })
end

function ProxyWidget:setFrame(frame)
    if frame == nil then
        self.frameName = nil
        self.frame = nil
        return
    end
    self.frame = frame
    self.frameName = frame:GetName()
    self:setActivationInfo({ targetFrame = frame })
end

function secureClick(frame, ...)
    frame:Click(...)
end

function ProxyWidget:getSelected()
    if self.selected then
        return true
    end
    if not self.frame then
        return false
    end
    if self.frame.IsSelected and self.frame:IsSelected() then
        return true
    end
    return false
end

function ProxyWidget:onFocus()
    parent.onFocus(self)
    if self.tooltip then
        if self.tooltip.mode == "static" then
            if self.frame:HasScript("OnEnter") then
                ExecuteFrameScript(self.frame, "OnEnter")
            end
        end
    end
end

function ProxyWidget:onUnfocus()
    WowVision.UIHost.tooltip:reset()
    if self.tooltip and self.tooltip.mode == "static" and self.frame:HasScript("OnLeave") then
        ExecuteFrameScript(self.frame, "OnLeave")
    end
    parent.onUnfocus(self)
end

function ProxyWidget:getValue()
    return nil
end

function ProxyWidget:getValueString()
    local value = self:getValue()
    if value then
        return tostring(value)
    end
end

function ProxyWidget:getExtras()
    if not self.frame then
        return nil
    end
    local props = {}
    if self.enabled == false or (self.frame.IsEnabled and not self.frame:IsEnabled()) then
        tinsert(props, self.L["Disabled"])
    end
    if self.selected or (self.frame.IsSelected and self.frame:IsSelected()) then
        tinsert(props, self.L["selected"])
    end
    local value = self:getValueString()
    if value then
        tinsert(props, value)
    end
    return props
end

function ProxyWidget:onDrag()
    local script = self.frame:GetScript("OnDragStart")
    if script then
        script(self.frame)
    end
end

function ProxyWidget:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    if self.frame.Text then
        local text = self.frame.Text:GetText()
        if text and text ~= "" then
            return text
        end
    end
    if self.frame.GetText then
        local text = self.frame:GetText()
        if text and text ~= "" then
            return text
        end
    end
    if self.hasTooltip then
        self.frame:GetScript("OnEnter")(self.frame)
        local label = GameTooltip:GetItem()
        self.frame:GetScript("OnLeave")(self.frame)
        return label
    end
end

--We only want proxy widgets to be added to containers when their corresponding frame is actually visible
-- This saves us having to perform constant if someFrame:IsShown() then add to list end checks in our generator code
-- Descendent elements can remove this condition by setting requiresFrameShown to nil in the manager table
manager.generationConditions.requiresFrameShown = function(props)
    if props.ignoreRequiresFrameShown then
        return true
    end
    local frame = props.frame
    if frame and frame:IsShown() then
        return true
    end
    return false
end
