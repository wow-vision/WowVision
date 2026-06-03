local ProxyCheckButton, parent = WowVision.ui:CreateElementType("ProxyCheckButton", "ProxyButton")

-- Override inherited defaults
ProxyCheckButton.info:updateFields({
    { key = "displayType", default = "Checkbox" },
})

-- Add field for checked state value
ProxyCheckButton.info:addFields({
    {
        key = "value",
        get = function(self)
            return self:getValueString()
        end,
    },
})

-- Register value as a live field (announces changes when focused)
ProxyCheckButton.liveFields.value = "focus"

function ProxyCheckButton:initialize()
    parent.initialize(self)
end

function ProxyCheckButton:getValue()
    if not self.frame then
        return nil
    end
    if self.dropdown then
        local regions = { self.frame:GetRegions() }
        for _, region in ipairs(regions) do
            local atlas = region:GetObjectType() == "Texture" and region:GetAtlas()
            if atlas and atlas:find("common-dropdown-icon-checkmark", 1, true) then
                return true
            end
        end
        return false
    else
        if self.frame.GetChecked then
        return self.frame:GetChecked()
        else
            error("Checkbox " .. (self.frame:GetName() or "unnamed") .. " has no GetChecked.")
        end
    end
end

function ProxyCheckButton:getLabel()
    if self.dropdown and self.frame then
        if self.label and self.label ~= "" then
            return self.label
        end
        local regions = { self.frame:GetRegions() }
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" then
                return region:GetText()
            end
        end
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
