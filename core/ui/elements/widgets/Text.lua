local Text, parent = WowVision.ui:CreateElementType("Text", "Widget")

-- Define InfoClass fields at class level
Text.info:addFields({
    {
        key = "text",
        default = "",
        set = function(obj, key, value)
            if value then
                obj.text = "" .. value
            else
                obj.text = ""
            end
        end,
    },
})

function Text:initialize()
    parent.initialize(self, "Text")

    self:addProp({
        key = "text",
        default = "",
        set = function(value)
            if value then
                self.text = "" .. value
            else
                self.text = ""
            end
        end,
    })
end

function Text:getValue()
    return self.text
end

function Text:getValueString()
    return self.text
end
