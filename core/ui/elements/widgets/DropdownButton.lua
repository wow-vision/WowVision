local DropdownButton, parent = WowVision.ui:CreateElementType("DropdownButton", "Widget")

-- Define InfoClass fields at class level
DropdownButton.info:addFields({
    { key = "dropdownRoot", default = nil },
})

function DropdownButton:initialize()
    parent.initialize(self)
end

function DropdownButton:onClick()
    self.context:addGenerated(self.dropdownRoot)
end
