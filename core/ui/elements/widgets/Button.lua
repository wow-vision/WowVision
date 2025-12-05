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
    {
        key = "bind",
        set = function(obj, key, value)
            obj.bind = value
        end,
    },
})

-- Remove value from liveFields (equivalent to live = false)
Button.liveFields.value = nil

function Button:initialize()
    parent.initialize(self)
    self:updateProp({
        key = "value",
        getLabel = function()
            return nil
        end,
        live = false,
    })
    self:updateProp({
        key = "bind",
        set = function(value)
            self.bind = value
        end,
    })
end

function Button:onClick()
    self:setValue()
    parent.onClick(self)
end
