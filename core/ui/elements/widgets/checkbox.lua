local Checkbox, parent = WowVision.ui:CreateElementType("Checkbox", "Widget")

function Checkbox:initialize(checked)
    parent.initialize(self, "Checkbox")
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
