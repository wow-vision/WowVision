local ProxyDropdownButton, parent = WowVision.ui:CreateElementType("ProxyDropdownButton", "ProxyWidget")

-- Define InfoClass fields at class level
ProxyDropdownButton.info:addFields({
    { key = "menuDescription", default = nil },
    { key = "textIsValue", default = false },
})

-- Add value to liveFields (equivalent to live = true)
ProxyDropdownButton.liveFields.value = "focus"

function ProxyDropdownButton:initialize()
    parent.initialize(self)
    self:setProp("displayType", "Dropdown")

    self:addProp({
        key = "menuDescription",
        default = nil,
    })

    self:addProp({
        key = "textIsValue",
        default = false,
    })

    self:updateProp({
        key = "value",
        live = true,
    })

    self.menuOpen = false
end

function ProxyDropdownButton:getValue()
    if self.textIsValue then
        return self.frame:GetText()
    end
end

function ProxyDropdownButton:onClick()
    self.frame:OpenMenu()
    parent.onClick(self)
end
