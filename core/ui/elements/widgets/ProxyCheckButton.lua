local ProxyCheckButton, parent = WowVision.ui:CreateElementType("ProxyCheckButton", "ProxyButton")

function ProxyCheckButton:initialize()
    parent.initialize(self, "ProxyCheckButton")
    self:setProp("displayType", "Checkbox")
end

function ProxyCheckButton:getValue()
    if self.dropdown then
        local regions = { self.frame:GetRegions() }
        return regions[2]:GetAtlas() == "common-dropdown-icon-checkmark-yellow-classic"
    else
        return self.frame:GetChecked()
    end
end

function ProxyCheckButton:getLabel()
    if self.dropdown then
        local regions = { self.frame:GetRegions() }
        return regions[3]:GetText()
    end
    return parent.getLabel(self)
end

function ProxyCheckButton:getValueString()
    local value = self:getValue()
    if value then
        return self.L["Checked"]
    end
    return self.L["Unchecked"]
end
