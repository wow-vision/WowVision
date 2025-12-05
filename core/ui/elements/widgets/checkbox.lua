local Checkbox, parent = WowVision.ui:CreateElementType("Checkbox", "Widget")

function Checkbox:initialize()
    parent.initialize(self)
end

function Checkbox:onClick()
    self:setValue(not self:getValue())
end

function Checkbox:getValueString()
    local value = self:getValue()
    if value == true then
        return self.L["Checked"]
    else
        return self.L["Unchecked"]
    end
end
