local Navigator = WowVision.Class("Navigator")
WowVision.Navigator = Navigator
WowVision.navigators = WowVision.Registry:new()

function Navigator:initialize(root)
    self.root = root
    self.frames = {}
    self.containerFrameType = WowVision.NavigatorContainerFrame
    self.syncedContainerFrameType = WowVision.NavigatorSyncedContainerFrame
    self.elementFrameType = WowVision.NavigatorElementFrame
    self:setFrameTypes()
    self.rootFrame = self:createFrame(nil, root)
    self.activationSet = WowVision.input:createActivationSet()
end

function Navigator:getBottomFrame()
    local frame = self.rootFrame
    while frame do
        if self.childFrame then
            frame = self.childFrame
        else
            return frame
        end
    end
end

function Navigator:activate()
    self.activationSet:activateAll({ targetFrame = WowVision.UIHost, dorment = false })
end

function Navigator:deactivate()
    self.activationSet:deactivateAll()
end

function Navigator:setFrameTypes() end

function Navigator:createFrame(parent, element, direction)
    if element:isContainer() then
        if element.sync then
            return self.syncedContainerFrameType:new(parent, self, element, direction)
        end
        return self.containerFrameType:new(parent, self, element, direction)
    end
    return self.elementFrameType:new(parent, self, element, direction)
end

function Navigator:reconcile()
    self.rootFrame:reconcile()
end

function Navigator:update()
    if not self.rootFrame then
        return
    end
    self:reconcile()
    local frame = self.rootFrame
    local focusChanged = false
    while frame do
        if frame.focusChange then
            focusChanged = true
            frame.focusChange = false
        end
        -- Announce "always" mode updates regardless of focus change
        for k, v in pairs(frame.alwaysUpdates or {}) do
            WowVision:speak(v)
        end
        if frame.childFrame then
            frame = frame.childFrame
        else
            break
        end
    end
    -- Announce "focus" mode updates only if focus didn't change
    if not focusChanged then
        for k, v in pairs(frame.liveUpdates) do
            WowVision:speak(v)
        end
    end
end

WowVision.NavigatorElementFrame = WowVision.Class("NavigatorFrame")
local NavigatorFrame = WowVision.NavigatorElementFrame

function NavigatorFrame:initialize(parent, navigator, element, direction)
    self.parent = parent
    self.navigator = navigator
    self.fieldValues = {} -- Stores current field values for comparison
    self.liveUpdates = {} -- "focus" mode updates (only announce when focused and no focus change)
    self.alwaysUpdates = {} -- "always" mode updates (announce regardless of focus change)
    self.initialDirection = direction
    self:setElement(element)
end

function NavigatorFrame:shouldRebuild(element)
    if self.element ~= element then
        return true
    end
    return false
end

function NavigatorFrame:announce()
    if self.element then
        self.element:announce()
    end
end

function NavigatorFrame:setElement(element)
    if element == nil then
        error("Tried to set navigator nil element")
    end
    self.element = element
    self.fieldValues = {}
    self:reconcile()
end

-- Reconciles field values and populates liveUpdates/alwaysUpdates
-- This is the expensive operation that polls all props/fields
function NavigatorFrame:reconcileFields()
    self.liveUpdates = {}
    self.alwaysUpdates = {}

    -- Use InfoClass fields and liveFields system
    local elementClass = self.element.class
    if elementClass and elementClass.info and elementClass.info.fields then
        local liveFields = elementClass.liveFields or {}
        for k, field in pairs(elementClass.info.fields) do
            local newValue = field:get(self.element)
            if not field:compare(self.fieldValues[k], newValue) then
                self.fieldValues[k] = newValue
                local liveMode = liveFields[k]
                if liveMode then
                    local label = field:getLabel(self.element, newValue)
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

    -- Also support old props system during transition
    for k, v in pairs(self.element.props) do
        local newValue = v.get()
        if not WowVision:compareProps(v, self.fieldValues[k], newValue) then
            self.fieldValues[k] = newValue
            if v.live then
                local label = v.getLabel(newValue)
                if label then
                    if v.live == "always" then
                        self.alwaysUpdates[k] = label
                    else
                        self.liveUpdates[k] = label
                    end
                end
            end
        end
    end
end

-- Base reconcile for leaf elements - reconciles fields
function NavigatorFrame:reconcile()
    self:reconcileFields()
end

function NavigatorFrame:onBindingPressed(binding)
    if self.element:onBindingPressed(binding) then
        return true
    end
    return false
end

local NavigatorContainerFrame = WowVision.Class("NavigatorContainerFrame", WowVision.NavigatorElementFrame)
WowVision.NavigatorContainerFrame = NavigatorContainerFrame

function NavigatorContainerFrame:initialize(parent, navigator, element, direction)
    WowVision.NavigatorElementFrame.initialize(self, parent, navigator, element, direction)
end

function NavigatorContainerFrame:select(element, direction)
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

function NavigatorContainerFrame:selectIndex(index, direction)
    local children = self.element:getNavigatorChildren()
    self:select(children[index].element, direction)
end

function NavigatorContainerFrame:deselect()
    if self.selectedElement == nil then
        return
    end

    self:onDeselect(self.selectedElement)
    self.selectedElement = nil
    self.selectedIndex = nil
end

function NavigatorContainerFrame:onSelect(element, direction) end

function NavigatorContainerFrame:onDeselect(element) end

function NavigatorContainerFrame:focusSelected(direction)
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
    self:reconcileChildFrame(direction)
end

function NavigatorContainerFrame:unfocusSelected()
    if self.selectedElement and self.element:getFocus() == self.selectedElement then
        self.element:setFocus(nil)
        self.focusChange = true
    end
end

-- Container reconcile - handles navigation/selection and conditional field reconciliation
-- Only reconciles fields if the element has "always" mode liveFields (optimization)
-- "focus" mode fields only matter on the focused leaf element
function NavigatorContainerFrame:reconcile()
    -- Check if this element has any "always" mode liveFields
    local hasAlwaysFields = false
    local elementClass = self.element.class
    if elementClass and elementClass.liveFields then
        for k, mode in pairs(elementClass.liveFields) do
            if mode == "always" then
                hasAlwaysFields = true
                break
            end
        end
    end

    if hasAlwaysFields then
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
    self:reconcileChildFrame(self.initialDirection)
    self.initialDirection = nil
end

function NavigatorContainerFrame:reconcileChildFrame(direction)
    local focus = self.element:getFocus()
    if not focus then
        if self.childFrame then
            self.childFrame = nil
        end
        return
    end

    if not self.childFrame then
        self.childFrame = self.navigator:createFrame(self, focus, direction)
        return
    end

    if not self.childFrame.shouldRebuild then
        f = self.childFrame
        error("Missing method on childFrame rebuild")
    end

    if self.childFrame:shouldRebuild(focus) then
        self.childFrame = self.navigator:createFrame(self, focus, direction)
        return
    end

    self.childFrame:reconcile()
end

local SyncedContainerFrame = WowVision.Class("NavigatorSyncedContainerFrame", NavigatorContainerFrame)
WowVision.NavigatorSyncedContainerFrame = SyncedContainerFrame

function SyncedContainerFrame:selectIndex(index, direction)
    if index < 1 or index > self:getNumEntries() then
        return
    end
    local element = self.element:setCurrentIndex(index)
    if element and element ~= self.selectedElement then
        self:deselect()
        self:select(element, direction)
        self.index = index
        return element
    end
end

function SyncedContainerFrame:select(element, direction)
    self.selectedElement = element
    self:onSelect(element, direction)
end

function SyncedContainerFrame:deselect()
    if self.selectedElement then
        self:onDeselect(self.selectedElement)
    end
    self.selectedElement = nil
    self.selectedIndex = -1
end

function SyncedContainerFrame:getNumEntries()
    return self.element:getNumEntries()
end

function SyncedContainerFrame:focusSelected(direction)
    if self.selectedElement then
        self.element:focusCurrent()
        self.focusChange = true
    end
    self:reconcileChildFrame(direction)
end

function SyncedContainerFrame:unfocusSelected()
    local focus = self.element:getFocus()
    if focus then
        self.element:unfocusCurrent()
        self.focusChange = true
    end
    self:reconcileChildFrame()
end

-- Synced container reconcile - handles navigation/selection and conditional field reconciliation
-- Only reconciles fields if the element has "always" mode liveFields (optimization)
function SyncedContainerFrame:reconcile()
    -- Check if this element has any "always" mode liveFields
    local hasAlwaysFields = false
    local elementClass = self.element.class
    if elementClass and elementClass.liveFields then
        for k, mode in pairs(elementClass.liveFields) do
            if mode == "always" then
                hasAlwaysFields = true
                break
            end
        end
    end

    if hasAlwaysFields then
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
    self:reconcileChildFrame(self.initialDirection)
    self.initialDirection = nil
end

function SyncedContainerFrame:reconcileChildFrame(direction)
    local focus = self.element:getFocus()
    if not focus then
        if self.childFrame then
            self.childFrame = nil
        end
        return
    end

    if not self.childFrame then
        self.childFrame = self.navigator:createFrame(self, focus, direction)
        return
    end

    self.childFrame:reconcile(focus)
end
