local Button, parent = WowVision.ui:CreateElementType("Button", "Widget")
local L = WowVision:getLocale()

-- Update InfoClass fields for Button
Button.info:updateFields({
    {
        key = "value",
        getLabel = function(obj, value)
            return nil
        end,
    },
})

-- Remove value from liveFields (equivalent to live = false)
Button.liveFields.value = nil

function Button:initialize()
    parent.initialize(self)
end

function Button:onClick()
    self:setValue()
    parent.onClick(self)
end
