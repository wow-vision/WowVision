local ChoiceDropdownButton, parent = WowVision.ui:CreateElementType("ChoiceDropdownButton", "Widget")

-- Define InfoClass fields at class level
ChoiceDropdownButton.info:addFields({
    { key = "choices", default = {} },
})

-- Override inherited defaults
ChoiceDropdownButton.info:updateFields({
    { key = "displayType", default = "Dropdown" },
})

function ChoiceDropdownButton:initialize()
    parent.initialize(self)
end

function ChoiceDropdownButton:getDropdown()
    local result = { "List", displayType = "", label = self.L["Dropdown"], children = {} }
    for _, v in ipairs(self.choices) do
        tinsert(result.children, { "Button", label = v.label, bind = { self, type = "name", name = "value", value = v.key } })
    end
    return result
end

function ChoiceDropdownButton:onClick()
    self.context:addGenerated(self:getDropdown())
end

function ChoiceDropdownButton:getExtras()
    local props = parent.getExtras(self)
    tinsert(props, self:getValue())
    return props
end
