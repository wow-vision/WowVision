local List, parent = WowVision.ui:CreateElementType("List", "Container")

function List:initialize()
    parent.initialize(self)
end

function List:getDisplayType()
    if self.direction == "vertical" then
        return self.L["List"]
    elseif self.direction == "horizontal" then
        return self.L["Bar"]
    end
    return nil
end