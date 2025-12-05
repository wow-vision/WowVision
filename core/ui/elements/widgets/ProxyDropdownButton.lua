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
    self.displayType = "Dropdown"
    self.menuOpen = false
end

function ProxyDropdownButton:getValue()
    if self.textIsValue and self.frame then
        return self.frame:GetText()
    end
end

function ProxyDropdownButton:onClick()
    if self.frame then
        self.frame:OpenMenu()
    end
    parent.onClick(self)
end
