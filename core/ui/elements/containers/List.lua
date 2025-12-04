local List, parent = WowVision.ui:CreateElementType("List", "Container")

function List:initialize()
    parent.initialize(self, "List")
end
