local ProxyCheckButton, parent = WowVision.ui:CreateElementType("ProxyCheckButton", "ProxyButton")

-- Override inherited defaults
ProxyCheckButton.info:updateFields({
    { key = "displayType", default = "Checkbox" },
})

function ProxyCheckButton:initialize()
    parent.initialize(self)
end

function ProxyCheckButton:getValue()
    if not self.frame then
        return nil
    end
    if self.dropdown then
        local regions = { self.frame:GetRegions() }
        return regions[2]:GetAtlas() == "common-dropdown-icon-checkmark-yellow-classic"
    else
        return self.frame:GetChecked()
    end
end

function ProxyCheckButton:getLabel()
    if self.dropdown and self.frame then
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
