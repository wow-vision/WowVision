-- Shared navigation handler for both container and synced container nodes
local function handleNavigationBinding(node, binding, getCount, getCurrentIndex)
    if node.childNode and node.childNode:onBindingPressed(binding) then
        return true
    end
    if not node.element.layout then
        if binding.key == "home" then
            node:selectIndex(1, binding.key)
            return true
        end
        if binding.key == "end" then
            node:selectIndex(getCount(), binding.key)
            return true
        end
    end
    if node.element.direction and node.element.direction ~= "grid" then
        local prevKey, nextKey = node.element:getDirectionKeys()
        local currentIndex = getCurrentIndex()
        local count = getCount()
        if currentIndex then
            if binding.key == prevKey then
                if currentIndex > 1 then
                    node:selectIndex(currentIndex - 1, binding.key)
                    return true
                elseif node.element.wrap then
                    node:selectIndex(count, binding.key)
                    return true
                end
                return false
            elseif binding.key == nextKey then
                if currentIndex < count then
                    node:selectIndex(currentIndex + 1, binding.key)
                    return true
                elseif node.element.wrap then
                    node:selectIndex(1, binding.key)
                    return true
                end
                return false
            end
        end
    end
    return false
end

local WindowedContainerNode = WowVision.Class("WindowedContainerNode", WowVision.NavigatorContainerNode)

function WindowedContainerNode:onSelect(element, direction)
    if element.shouldAnnounce then
        element:announce()
    end
    self:focusSelected(direction)
end

function WindowedContainerNode:onDeselect(element)
    self:unfocusSelected()
end

function WindowedContainerNode:onBindingPressed(binding)
    return handleNavigationBinding(self, binding,
        function() return #self.element:getNavigatorChildren() end,
        function() return self.selectedIndex end
    )
end

local WindowedSyncedContainerNode =
    WowVision.Class("WindowedSyncedContainerNode", WowVision.NavigatorSyncedContainerNode)

function WindowedSyncedContainerNode:onSelect(element, direction)
    self:focusSelected(direction)
end

function WindowedSyncedContainerNode:onDeselect(element)
    self:unfocusSelected()
end

function WindowedSyncedContainerNode:onBindingPressed(binding)
    return handleNavigationBinding(self, binding,
        function() return self:getNumEntries() end,
        function() return self.element.currentIndex end
    )
end

local WindowedPreservingContainerNode =
    WowVision.Class("WindowedPreservingContainerNode", WowVision.NavigatorPreservingContainerNode)

function WindowedPreservingContainerNode:onSelect(element, direction)
    if element and element.shouldAnnounce then
        element:announce()
    end
    self:focusSelected(direction)
end

function WindowedPreservingContainerNode:onDeselect(element)
    self:unfocusSelected()
end

function WindowedPreservingContainerNode:onBindingPressed(binding)
    if self.childNode and self.childNode:onBindingPressed(binding) then
        return true
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

function WindowedNavigator:setNodeTypes()
    self.containerNodeType = WindowedContainerNode
    self.syncedContainerNodeType = WindowedSyncedContainerNode
    self.preservingContainerNodeType = WindowedPreservingContainerNode
end

function WindowedNavigator:onBindingPressed(binding)
    if self.rootNode:onBindingPressed(binding) then
        return true
    end
    return false
end

WowVision.navigators:register("Windowed", WindowedNavigator)
