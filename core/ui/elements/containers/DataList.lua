local DataList, parent = WowVision.ui:CreateElementType("DataList", "Widget")
DataList:include(WowVision.SyncedContainer)

-- Define InfoClass fields at class level
DataList.info:addFields({
    {
        key = "dataset",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj:unfocusCurrent()
            obj.currentIndex = -1
            obj.dataset = value
        end,
    },
    { key = "getElement", default = nil },
})

function DataList:initialize()
    parent.initialize(self)
    self:initSyncedContainer()
end

function DataList:getNumEntries()
    return #self.dataset.data
end

function DataList:setCurrentIndex(index)
    if index == self.currentIndex then
        return
    end
    self:unfocusCurrent()
    if index < 1 or index > self:getNumEntries() then
        return
    end
    self.currentIndex = index
    local childRoot = self:getChildRoot(index)
    self:setChild(childRoot)
end

function DataList:getChildRoot(index)
    return self:getElement(self.dataset.data[index])
end

function DataList:onFocus()
    self:onSyncedFocus()
end

function DataList:onUnfocus()
    self:onSyncedUnfocus()
end

function DataList:onUpdate()
    self.childPanel:update()
end
