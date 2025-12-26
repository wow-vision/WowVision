local Navigator = WowVision.Class("Navigator")
WowVision.Navigator = Navigator
WowVision.navigators = WowVision.Registry:new()

function Navigator:initialize(root)
    self.root = root
    self.nodes = {}
    self.containerNodeType = WowVision.NavigatorContainerNode
    self.syncedContainerNodeType = WowVision.NavigatorSyncedContainerNode
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
end

function Navigator:setNodeTypes() end

function Navigator:createNode(parent, element, direction)
    if element:isContainer() then
        if element.sync then
            return self.syncedContainerNodeType:new(parent, self, element, direction)
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
    local node = self.rootNode
    local focusChanged = false
    while node do
        if node.focusChange then
            focusChanged = true
            node.focusChange = false
        end
        -- Announce "always" mode updates regardless of focus change
        for k, v in pairs(node.alwaysUpdates or {}) do
            WowVision:speak(v)
        end
        if node.childNode then
            node = node.childNode
        else
            break
        end
    end
    -- Announce "focus" mode updates only if focus didn't change
    if not focusChanged then
        for k, v in pairs(node.liveUpdates) do
            WowVision:speak(v)
        end
    end
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
    local elementFocus = self.element:getFocus()
    if elementFocus then
        if elementFocus == self.selectedElement then
            return
        end
    end
    self.element:setFocus(self.selectedElement)
    self.focusChange = true
    self:reconcileChildNode(direction)
end

function NavigatorContainerNode:unfocusSelected()
    if self.selectedElement and self.element:getFocus() == self.selectedElement then
        self.element:setFocus(nil)
        self.focusChange = true
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

    local initialFocusedElement = self.element:getFocus()
    if initialFocusedElement ~= nil and initialFocusedElement ~= self.selectedElement then
        self:select(initialFocusedElement, self.initialDirection)
        self.focusChange = true
        return
    end
    local children = self.element:getNavigatorChildren()
    if self.selectedElement then
        local newIndex = children[self.selectedElement]
        if newIndex then
            --Selected element still exists; update new index
            self.selectedIndex = newIndex
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
        local targetIndex = 1
        local prevKey, nextKey = self.element:getDirectionKeys()
        if self.initialDirection == prevKey or self.initialDirection == "END" then
            targetIndex = #children
        end
        self:selectIndex(targetIndex, self.initialDirection)
    end

    local focusedElement = self.element:getFocus()
    if focusedElement ~= initialFocusedElement then
        self.focusChange = true
    end
    self:reconcileChildNode(self.initialDirection)
    self.initialDirection = nil
end

function NavigatorContainerNode:reconcileChildNode(direction)
    local focus = self.element:getFocus()
    if not focus then
        if self.childNode then
            self.childNode = nil
        end
        return
    end

    if not self.childNode then
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    if not self.childNode.shouldRebuild then
        f = self.childNode
        error("Missing method on childNode rebuild")
    end

    if self.childNode:shouldRebuild(focus) then
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    self.childNode:reconcile()
end

local SyncedContainerNode = WowVision.Class("NavigatorSyncedContainerNode", NavigatorContainerNode)
WowVision.NavigatorSyncedContainerNode = SyncedContainerNode

function SyncedContainerNode:selectIndex(index, direction)
    if index < 1 or index > self:getNumEntries() then
        return
    end
    local element = self.element:setCurrentIndex(index)
    if element and element ~= self.selectedElement then
        self:deselect()
        self:select(element, direction)
        return element
    end
end

function SyncedContainerNode:select(element, direction)
    self.selectedElement = element
    self:onSelect(element, direction)
end

function SyncedContainerNode:deselect()
    if self.selectedElement then
        self:onDeselect(self.selectedElement)
    end
    self.selectedElement = nil
    self.selectedIndex = -1
end

function SyncedContainerNode:getNumEntries()
    return self.element:getNumEntries()
end

function SyncedContainerNode:focusSelected(direction)
    if self.selectedElement then
        self.element:focusCurrent()
        self.focusChange = true
    end
    self:reconcileChildNode(direction)
end

function SyncedContainerNode:unfocusSelected()
    local focus = self.element:getFocus()
    if focus then
        self.element:unfocusCurrent()
        self.focusChange = true
    end
    self:reconcileChildNode()
end

-- Synced container reconcile - handles navigation/selection and conditional field reconciliation
-- Only reconciles fields if the element has "always" mode liveFields (optimization)
function SyncedContainerNode:reconcile()
    if self:hasAlwaysFields() then
        self:reconcileFields()
    else
        self.liveUpdates = {}
        self.alwaysUpdates = {}
    end

    local initialFocus = self.element:getFocus()
    local current = self.element.currentElement
    if current ~= self.selectedElement then
        self:deselect()
        if current then
            self:select(current, self.initialDirection)
        end
    end
    if not self.selectedElement then
        local targetIndex = 1
        local prevKey, nextKey = self.element:getDirectionKeys()
        if self.initialDirection == prevKey or self.initialDirection == "END" then
            targetIndex = self:getNumEntries()
        end
        self:selectIndex(targetIndex, self.initialDirection)
    end
    if initialFocus ~= self.element:getFocus() then
        self.focusChange = true
    end
    self:reconcileChildNode(self.initialDirection)
    self.initialDirection = nil
end

function SyncedContainerNode:reconcileChildNode(direction)
    local focus = self.element:getFocus()
    if not focus then
        if self.childNode then
            self.childNode = nil
        end
        return
    end

    if not self.childNode then
        self.childNode = self.navigator:createNode(self, focus, direction)
        return
    end

    self.childNode:reconcile(focus)
end
