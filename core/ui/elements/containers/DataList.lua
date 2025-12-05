local DataList, parent = WowVision.ui:CreateElementType("DataList", "Widget")

-- Define InfoClass fields at class level
DataList.info:addFields({
    {
        key = "dataset",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj:unfocusCurrent()
            obj.currentIndex = -1
            obj.currentElement = -1
            obj.dataset = value
        end,
    },
    { key = "getElement", default = nil },
})

function DataList:initialize()
    parent.initialize(self)

    self.sync = true
    self:setProp("displayType", "List")
    self:addProp({
        key = "dataset",
        type = "reference",
        set = function(value)
            self:unfocusCurrent()
            self.currentIndex = -1
            self.currentElement = -1
            self.dataset = value
        end,
    })

    self:addProp({
        key = "getElement",
    })

    self.childPanel = WowVision.ui:CreateElement("GeneratorPanel", WowVision.ui.generator)

    self.currentIndex = -1
    self.currentElement = nil
    self.focused = false
end

function DataList:getNumEntries()
    return #self.dataset.data
end

function DataList:getFocus()
    if self.childPanel:getFocused() then
        return self.childPanel
    end
    return nil
end

function DataList:focusCurrent()
    if self.currentElement then
        self.childPanel:focus()
    end
end

function DataList:unfocusCurrent()
    if self.childPanel:getFocused() then
        self.childPanel:unfocus()
    end
end

function DataList:setCurrentIndex(index)
    if index == self.currentIndex then
        return
    end
    self:unfocusCurrent()
    if index < 1 or index > self:getNumEntries() then
        return
    end
    self.childPanel:unfocus()
    self.currentIndex = index
    self.currentElement = self.dataset.data[index]
    local childRoot = self:getChildRoot(index)
    self:setChild(childRoot)
end

function DataList:getChildRoot(index)
    return self:getElement(self.dataset.data[index])
end

function DataList:setChild(root)
    self.childPanel:setStartingElement(root)
end

function DataList:onFocus()
    if self.currentIndex < 1 or self.currentIndex > self:getNumEntries() then
        self:setCurrentIndex(1)
    end
end

function DataList:onUnfocus()
    self:unfocusCurrent()
    self.currentIndex = -1
    self.currentElement = nil
end

function DataList:isContainer()
    return true
end

function DataList:onUpdate()
    self.childPanel:update()
end

function DataList:getDirectionKeys()
    return "up", "down"
end
