local WindowedContainerFrame = WowVision.Class("WindowedContainerFrame", WowVision.NavigatorContainerFrame)

function WindowedContainerFrame:onSelect(element, direction)
    if element.shouldAnnounce then
        element:announce()
    end
    self:focusSelected(direction)
end

function WindowedContainerFrame:onDeselect(element)
    self:unfocusSelected()
end

function WindowedContainerFrame:onBindingPressed(binding)
    if self.childFrame and self.childFrame:onBindingPressed(binding) then
        return true
    end
    local children = self.element:getNavigatorChildren()
    if not self.element.layout then
        if binding.key == "home" then
            self:selectIndex(1, binding.key)
            return true
        end
        if binding.key == "end" then
            self:selectIndex(#self.element:getNavigatorChildren(), binding.key)
            return true
        end
    end
    if self.element.direction and self.element.direction ~= "grid" and self.selectedIndex then
        local prevKey, nextKey = self.element:getDirectionKeys()
        if binding.key == prevKey then
            local targetIndex = self.selectedIndex - 1
            if targetIndex >= 1 then
                self:selectIndex(targetIndex, binding.key)
                return true
            elseif self.element.wrap then
                self:selectIndex(#children, binding.key)
                return true
            end
            return false
        elseif binding.key == nextKey then
            local targetIndex = self.selectedIndex + 1
            if targetIndex <= #children then
                self:selectIndex(targetIndex, binding.key)
                return true
            elseif self.element.wrap then
                self:selectIndex(1, binding.key)
                return true
            end
            return false
        end
    end
    return false
end

local WindowedSyncedContainerFrame =
    WowVision.Class("WindowedSyncedContainerFrame", WowVision.NavigatorSyncedContainerFrame)

function WindowedSyncedContainerFrame:onSelect(element, direction)
    self:focusSelected(direction)
end

function WindowedSyncedContainerFrame:onDeselect(element)
    self:unfocusSelected()
end

function WindowedSyncedContainerFrame:onBindingPressed(binding)
    if self.childFrame and self.childFrame:onBindingPressed(binding) then
        return true
    end
    if not self.element.layout then
        if binding.key == "home" then
            self:selectIndex(1, binding.key)
            return true
        end
        if binding.key == "end" then
            self:selectIndex(self:getNumEntries(), binding.key)
            return true
        end
    end
    if self.element.direction ~= "grid" then
        local prevKey, nextKey = self.element:getDirectionKeys()
        if binding.key == prevKey and self.element.currentIndex > 1 then
            self:selectIndex(self.element.currentIndex - 1, binding.key)
            return true
        end
        if binding.key == nextKey and self.element.currentIndex < self:getNumEntries() then
            self:selectIndex(self.element.currentIndex + 1, binding.key)
            return true
        end
    end
    return false
end

local WindowedNavigator = WowVision.Class("WindowedNavigator", WowVision.Navigator)

function WindowedNavigator:initialize(root)
    WowVision.Navigator.initialize(self, root)
    local keys = { "up", "down", "left", "right", "next", "previous", "nextWindow", "previousWindow", "home", "end" }
    for _, key in ipairs(keys) do
        self.activationSet:add({
            binding = key,
        })
    end
end

function WindowedNavigator:setFrameTypes()
    self.containerFrameType = WindowedContainerFrame
    self.syncedContainerFrameType = WindowedSyncedContainerFrame
end

function WindowedNavigator:onBindingPressed(binding)
    if self.rootFrame:onBindingPressed(binding) then
        return true
    end
    return false
end

WowVision.navigators:register("Windowed", WindowedNavigator)
