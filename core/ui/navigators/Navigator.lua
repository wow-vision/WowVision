local Navigator = WowVision.Class("Navigator")
WowVision.Navigator = Navigator
WowVision.navigators = WowVision.Registry:new()

function Navigator:initialize(root)
    self.root = root
    self.nodes = {}
    self.containerNodeType = WowVision.NavigatorContainerNode
    self.syncedContainerNodeType = WowVision.NavigatorSyncedContainerNode
    self.preservingContainerNodeType = WowVision.NavigatorPreservingContainerNode
    self.elementNodeType = WowVision.NavigatorElementNode
    self:setNodeTypes()
    self.rootNode = self:createNode(nil, root)
    self.activationSet = WowVision.input:createActivationSet()
end

function Navigator:getBottomNode()
    local node = self.rootNode
    while node do
        if node.childNode then
            node = node.childNode
        else
            return node
        end
    end
end

function Navigator:activate()
    self.activationSet:activateAll({ targetFrame = WowVision.UIHost, dorment = false })
end

function Navigator:deactivate()
    self.activationSet:deactivateAll()
end

function Navigator:destroy()
    self:deactivate()
    if self.rootNode then
        self.rootNode:destroy()
        self.rootNode = nil
    end
    self.nodes = {}
    self.root = nil
    self._lastFocusPath = nil
    self._lastFocusKeys = nil
end

function Navigator:setNodeTypes() end

function Navigator:createNode(parent, element, direction)
    if element:isContainer() then
        if element.sync then
            return self.syncedContainerNodeType:new(parent, self, element, direction)
        end
        if element.preserveChildNodes then
            return self.preservingContainerNodeType:new(parent, self, element, direction)
        end
        return self.containerNodeType:new(parent, self, element, direction)
    end
    return self.elementNodeType:new(parent, self, element, direction)
end

function Navigator:reconcile()
    self.rootNode:reconcile()
end

function Navigator:update()
    if not self.rootNode then
        return
    end

    self:reconcile()

    -- Build new focus path and handle alwaysUpdates in one walk
    -- Keys track extra identity (e.g. currentIndex for synced containers)
    -- so that index changes are detected even when element references stay the same
    local newPath = {}
    local newKeys = {}
    local node = self.rootNode
    local leafNode = node
    while node do
        tinsert(newPath, node.element)
        tinsert(newKeys, node.element.currentIndex)
        for k, v in pairs(node.alwaysUpdates or {}) do
            WowVision:speak(v)
        end
        leafNode = node
        node = node.childNode
    end

    -- Find divergence between old and new focus paths
    local oldPath = self._lastFocusPath or {}
    local oldKeys = self._lastFocusKeys or {}
    local divergence = nil
    local contentChanged = false
    for i = 1, math.max(#oldPath, #newPath) do
        if oldPath[i] ~= newPath[i] then
            divergence = i
            break
        elseif oldKeys[i] ~= newKeys[i] then
            contentChanged = true
        end
    end

    if divergence then
        -- Structure changed: announce each shouldAnnounce element from divergence to leaf
        for i = divergence, #newPath do
            if newPath[i].shouldAnnounce then
                newPath[i]:announce()
            end
        end
    elseif contentChanged then
        -- Content changed (e.g. synced container scrolled): announce the leaf
        newPath[#newPath]:announce()
    else
        -- No focus change: speak leaf's live field updates
        for k, v in pairs(leafNode.liveUpdates) do
            WowVision:speak(v)
        end
    end

    self._lastFocusPath = newPath
    self._lastFocusKeys = newKeys
end

WowVision.NavigatorElementNode = WowVision.Class("NavigatorElementNode")
local NavigatorNode = WowVision.NavigatorElementNode

function NavigatorNode:initialize(parent, navigator, element, direction)
    self.parent = parent
    self.navigator = navigator
    self.fieldValues = {} -- Stores current field values for comparison
    self.liveUpdates = {} -- "focus" mode updates (only announce when focused and no focus change)
    self.alwaysUpdates = {} -- "always" mode updates (announce regardless of focus change)
    self.initialDirection = direction
    self:setElement(element)
end

function NavigatorNode:shouldRebuild(element)
    if self.element ~= element then
        return true
    end
    return false
end

function NavigatorNode:announce()
    if self.element then
        self.element:announce()
    end
end

function NavigatorNode:setElement(element)
    if element == nil then
        error("Tried to set navigator nil element")
    end
    self.element = element
    self.fieldValues = {}
    self:reconcile()
end

-- Reconciles field values and populates liveUpdates/alwaysUpdates
function NavigatorNode:reconcileFields()
    self.liveUpdates = {}
    self.alwaysUpdates = {}

    local elementClass = self.element.class
    if elementClass and elementClass.info and elementClass.info.fields then
        local liveFields = elementClass.liveFields or {}
        for k, field in pairs(elementClass.info.fields) do
            local newValue = field:get(self.element)
            if not field:compare(self.fieldValues[k], newValue) then
                self.fieldValues[k] = newValue
                local liveMode = liveFields[k]
                if liveMode then
                    local label = field:getValueString(self.element, newValue)
                    if label then
                        if liveMode == "always" then
                            self.alwaysUpdates[k] = label
                        else -- "focus" mode
                            self.liveUpdates[k] = label
                        end
                    end
                end
            end
        end
    end
end

-- Check if this element has any "always" mode liveFields
function NavigatorNode:hasAlwaysFields()
    local elementClass = self.element.class
    if elementClass and elementClass.liveFields then
        for k, mode in pairs(elementClass.liveFields) do
            if mode == "always" then
                return true
            end
        end
    end
    return false
end

-- Base reconcile for leaf elements - reconciles fields
function NavigatorNode:reconcile()
    self:reconcileFields()
end

-- Cleanup method to release references
function NavigatorNode:destroy()
    self.parent = nil
    self.navigator = nil
    self.element = nil
    self.fieldValues = nil
    self.liveUpdates = nil
    self.alwaysUpdates = nil
end

function NavigatorNode:onBindingPressed(binding)
    if self.element:onBindingPressed(binding) then
        return true
    end
    return false
end

local NavigatorContainerNode = WowVision.Class("NavigatorContainerNode", WowVision.NavigatorElementNode)
WowVision.NavigatorContainerNode = NavigatorContainerNode

function NavigatorContainerNode:initialize(parent, navigator, element, direction)
    WowVision.NavigatorElementNode.initialize(self, parent, navigator, element, direction)
end

function NavigatorContainerNode:select(element, direction)
    if element == self.selectedElement then
        return
    end
    for i, v in ipairs(self.element:getNavigatorChildren()) do
        if v.element == element then
            self:deselect()
            self.selectedIndex = i
            self.selectedElement = v.element
            self:onSelect(v.element, direction)
            return
        end
    end
    local tbl = {}
    for _, v in ipairs(self.element:getNavigatorChildren()) do
        tinsert(tbl, v.element:getLabel())
    end
    error(
        "Attempted to select element that doesn't exist: "
            .. element:getLabel()
            .. ". Children = "
            .. table.concat(tbl, ", ")
    )
end

function NavigatorContainerNode:selectIndex(index, direction)
    local children = self.element:getNavigatorChildren()
    self:select(children[index].element, direction)
end

function NavigatorContainerNode:deselect()
    if self.selectedElement == nil then
        return
    end

    self:onDeselect(self.selectedElement)
    self.selectedElement = nil
    self.selectedIndex = nil
end

function NavigatorContainerNode:onSelect(element, direction) end

function NavigatorContainerNode:onDeselect(element) end

-- Override destroy to also clean up child node
function NavigatorContainerNode:destroy()
    if self.childNode then
        self.childNode:destroy()
        self.childNode = nil
    end
    self.selectedElement = nil
    self.selectedIndex = nil
    WowVision.NavigatorElementNode.destroy(self)
end

function NavigatorContainerNode:focusSelected(direction)
    if not self.selectedElement then
        return
    end
    if self.selectedElement:getFocused() then
        return
    end
    self.selectedElement:focus()
    self:reconcileChildNode(direction)
end

function NavigatorContainerNode:unfocusSelected()
    if self.selectedElement and self.selectedElement:getFocused() then
        self.selectedElement:unfocus()
    end
end

-- Container reconcile - handles navigation/selection and conditional field reconciliation
-- Only reconciles fields if the element has "always" mode liveFields (optimization)
-- "focus" mode fields only matter on the focused leaf element
function NavigatorContainerNode:reconcile()
    if self:hasAlwaysFields() then
        self:reconcileFields()
    else
        self.liveUpdates = {}
        self.alwaysUpdates = {}
    end

    -- Check if getDesiredFocus() changed (e.g., HorizontalContext added a new window)
    local desiredFocus = self.element:getDesiredFocus()
    if desiredFocus ~= nil and desiredFocus ~= self.lastDesiredFocus then
        self.lastDesiredFocus = desiredFocus
        if desiredFocus ~= self.selectedElement then
            self:select(desiredFocus, self.initialDirection)
        end
    end

    local children = self.element:getNavigatorChildren()
    if self.selectedElement then
        -- Find the current index of the selected element
        local newIndex = nil
        for i, v in ipairs(children) do
            if v.element == self.selectedElement then
                newIndex = i
                break
            end
        end
        if newIndex then
            --Selected element still exists; update index
            self.selectedIndex = newIndex
            -- Re-focus if element was unfocused externally (e.g., by Container:onUnfocus cascade)
            if self.element:getFocused() and not self.selectedElement:getFocused() then
                self:onSelect(self.selectedElement, self.initialDirection)
            end
        else
            --Selected element no longer exists. Find the closest element and select it.
            local foundSelection = false
            for i = self.selectedIndex, 1, -1 do
                local newSelection = children[i]
                if newSelection then
                    self:select(newSelection.element, self.initialDirection)
                    foundSelection = true
                    break
                end
            end
            if not foundSelection then
                self:deselect() --Deselect if there are no more elements
            end
        end
    end

    if not self.selectedElement and #children > 0 then
        local desired = self.element:getDesiredFocus()
        if desired then
            self:select(desired, self.initialDirection)
        else
            local targetIndex = 1
            local prevKey, nextKey = self.element:getDirectionKeys()
            if self.initialDirection == prevKey or self.initialDirection == "END" then
                targetIndex = #children
            end
            self:selectIndex(targetIndex, self.initialDirection)
        end
    end

    self:reconcileChildNode(self.initialDirection)
    self.initialDirection = nil
end

function NavigatorContainerNode:reconcileChildNode(direction)
    local focus = self.selectedElement
    if not focus then
        if self.childNode then
            self.childNode:destroy()
            self.childNode = nil
        end
        return
    end

    if not self.childNode then
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    if self.childNode:shouldRebuild(focus) then
        self.childNode:destroy()
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    self.childNode:reconcile()
end

-- PreservingContainerNode: caches child nodes when focus moves away (for StackContext, WindowContext)
local PreservingContainerNode = WowVision.Class("NavigatorPreservingContainerNode", NavigatorContainerNode)
WowVision.NavigatorPreservingContainerNode = PreservingContainerNode

function PreservingContainerNode:initialize(parent, navigator, element, direction)
    self.cachedNodes = {}
    NavigatorContainerNode.initialize(self, parent, navigator, element, direction)
end

function PreservingContainerNode:select(element, direction)
    if element == self.selectedElement then
        return
    end
    -- Cache current child node before switching
    self:cacheCurrentChild()
    -- Deselect without destroying (child is cached)
    if self.selectedElement then
        self:onDeselect(self.selectedElement)
        self.selectedElement = nil
        self.selectedIndex = nil
        self.childNode = nil
    end
    -- Find element in children
    for i, v in ipairs(self.element:getNavigatorChildren()) do
        if v.element == element then
            self.selectedIndex = i
            self.selectedElement = v.element
            break
        end
    end
    if not self.selectedElement then
        return
    end
    -- Restore cached child node if available
    local cached = self.cachedNodes[element]
    if cached then
        self.childNode = cached
        self.cachedNodes[element] = nil
    end
    self:onSelect(element, direction)
end

function PreservingContainerNode:reconcile()
    if self:hasAlwaysFields() then
        self:reconcileFields()
    else
        self.liveUpdates = {}
        self.alwaysUpdates = {}
    end

    local desiredFocus = self.element:getDesiredFocus()

    if desiredFocus == nil then
        if self.selectedElement then
            self:cacheCurrentChild()
            self:deselect()
        end
        self.lastDesiredFocus = nil
        self:pruneCache()
        return
    end

    -- Only react to desiredFocus CHANGES (e.g., new window opened, context pushed/popped).
    -- Don't continuously enforce it — allow user navigation to persist.
    if desiredFocus ~= self.lastDesiredFocus then
        self.lastDesiredFocus = desiredFocus
        if desiredFocus ~= self.selectedElement then
            self:select(desiredFocus, self.initialDirection)
        end
    end

    -- Validate current selection still exists in children
    if self.selectedElement then
        local children = self.element:getNavigatorChildren()
        local newIndex = nil
        for i, v in ipairs(children) do
            if v.element == self.selectedElement then
                newIndex = i
                break
            end
        end
        if newIndex then
            self.selectedIndex = newIndex
            -- Re-focus if element was unfocused externally (e.g., by Container:onUnfocus cascade)
            if self.element:getFocused() and not self.selectedElement:getFocused() then
                self:onSelect(self.selectedElement, self.initialDirection)
            end
        else
            -- Selected element removed, find closest
            local foundSelection = false
            for i = (self.selectedIndex or 1), 1, -1 do
                local newSelection = children[i]
                if newSelection then
                    self:select(newSelection.element, self.initialDirection)
                    foundSelection = true
                    break
                end
            end
            if not foundSelection then
                self:cacheCurrentChild()
                self:deselect()
            end
        end
    end

    -- Initial selection if nothing selected
    if not self.selectedElement then
        local children = self.element:getNavigatorChildren()
        if #children > 0 then
            if desiredFocus then
                self:select(desiredFocus, self.initialDirection)
            else
                local targetIndex = 1
                local prevKey, nextKey = self.element:getDirectionKeys()
                if self.initialDirection == prevKey or self.initialDirection == "END" then
                    targetIndex = #children
                end
                self:selectIndex(targetIndex, self.initialDirection)
            end
        end
    end

    self:pruneCache()
    self:reconcileChildNode(self.initialDirection)
    self.initialDirection = nil
end

function PreservingContainerNode:cacheCurrentChild()
    if self.selectedElement and self.childNode then
        self.cachedNodes[self.selectedElement] = self.childNode
        self.childNode = nil
    end
end

function PreservingContainerNode:pruneCache()
    local children = self.element:getNavigatorChildren()
    local childSet = {}
    for _, v in ipairs(children) do
        childSet[v.element] = true
    end
    for element, node in pairs(self.cachedNodes) do
        if not childSet[element] then
            node:destroy()
            self.cachedNodes[element] = nil
        end
    end
end

function PreservingContainerNode:destroy()
    for _, node in pairs(self.cachedNodes) do
        node:destroy()
    end
    self.cachedNodes = {}
    NavigatorContainerNode.destroy(self)
end

local SyncedContainerNode = WowVision.Class("NavigatorSyncedContainerNode", NavigatorContainerNode)
WowVision.NavigatorSyncedContainerNode = SyncedContainerNode

function SyncedContainerNode:selectIndex(index, direction)
    if index < 1 or index > self:getNumEntries() then
        return
    end
    self.element:setCurrentIndex(index)
    local newIndex = self.element.currentIndex
    if newIndex >= 1 then
        self:deselect()
        self.selectedIndex = newIndex
        self:onSelect(nil, direction)
    end
end

function SyncedContainerNode:deselect()
    if self.selectedIndex and self.selectedIndex >= 1 then
        self:onDeselect(nil)
    end
    self.selectedIndex = nil
end

function SyncedContainerNode:getNumEntries()
    return self.element:getNumEntries()
end

function SyncedContainerNode:focusSelected(direction)
    if self.selectedIndex and self.selectedIndex >= 1 then
        self.element:focusCurrent()
    end
    self:reconcileChildNode(direction)
end

function SyncedContainerNode:unfocusSelected()
    if self.selectedIndex and self.selectedIndex >= 1 and self.element.childPanel:getFocused() then
        self.element:unfocusCurrent()
    end
    self:reconcileChildNode()
end

-- Synced container reconcile - uses currentIndex for state tracking
function SyncedContainerNode:reconcile()
    if self:hasAlwaysFields() then
        self:reconcileFields()
    else
        self.liveUpdates = {}
        self.alwaysUpdates = {}
    end

    local currentIndex = self.element.currentIndex
    if currentIndex ~= self.selectedIndex then
        self:deselect()
        if currentIndex >= 1 then
            self.selectedIndex = currentIndex
            self:onSelect(nil, self.initialDirection)
        end
    end
    -- Re-focus if element was unfocused externally (e.g., by Container:onUnfocus cascade)
    if self.selectedIndex and self.selectedIndex >= 1
        and self.element:getFocused()
        and not self.element.childPanel:getFocused() then
        self:onSelect(nil, self.initialDirection)
    end
    if not self.selectedIndex or self.selectedIndex < 1 then
        local targetIndex = 1
        local prevKey, nextKey = self.element:getDirectionKeys()
        if self.initialDirection == prevKey or self.initialDirection == "END" then
            targetIndex = self:getNumEntries()
        end
        self:selectIndex(targetIndex, self.initialDirection)
    end
    self:reconcileChildNode(self.initialDirection)
    self.initialDirection = nil
end

function SyncedContainerNode:reconcileChildNode(direction)
    local focus = nil
    if self.selectedIndex and self.selectedIndex >= 1 then
        focus = self.element.childPanel
    end
    if not focus then
        if self.childNode then
            self.childNode:destroy()
            self.childNode = nil
        end
        return
    end

    if not self.childNode then
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    if self.childNode:shouldRebuild(focus) then
        self.childNode:destroy()
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    self.childNode:reconcile()
end
