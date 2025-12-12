--Generators handle react-style component generation for WowVision.
--Comparison functions should be called each frame, as there is often a delay between user input and UI updates
-- Unlike frameworks such as React, state is not held on virtual components. Use game state or your own tables to influence UI state.

-- VirtualElementType manages a virtual element's function and regeneration conditions
-- Similar to how elementTypes manages real elements with generationConditions
local VirtualElementType = WowVision.Class("VirtualElementType")

function VirtualElementType:initialize(elementType, func, generator)
    self.elementType = elementType
    self.func = func
    self.generator = generator
    self.events = {}
    self.frameFields = {} -- { { frame, "fieldName" }, ... }
    self.framePredicates = {} -- { { frame, "methodName" }, ... }
    self.valuesFunc = nil
    self.alwaysRun = true -- default until conditions added
end

function VirtualElementType:addEvents(events)
    for _, event in ipairs(events) do
        self.events[event] = true
    end
    -- Register events with generator
    if self.generator then
        self.generator:registerElementEvents(self.elementType, events)
    end
    self.alwaysRun = false
    return self
end

function VirtualElementType:addFrameFields(fields)
    for _, fieldConfig in ipairs(fields) do
        tinsert(self.frameFields, fieldConfig)
    end
    self.alwaysRun = false
    return self
end

function VirtualElementType:addFramePredicates(predicates)
    for _, predicateConfig in ipairs(predicates) do
        tinsert(self.framePredicates, predicateConfig)
    end
    self.alwaysRun = false
    return self
end

function VirtualElementType:setValues(func)
    self.valuesFunc = func
    self.alwaysRun = false
    return self
end

function VirtualElementType:setAlwaysRun(value)
    self.alwaysRun = value
    return self
end

WowVision.VirtualElementType = VirtualElementType

--GeneratorNode is equivalent to a Virtual DOM node in React.
local GeneratorNode = WowVision.Class("GeneratorNode")

function GeneratorNode:initialize(parent)
    self.parent = parent
    self.elementType = ""
    self.virtualElement = false
    self.children = {}
    self.props = {}
    self.hooks = {}
end

function GeneratorNode:addChild(child)
    tinsert(self.children, child)
end

local Generator = WowVision.Class("Generator")

function Generator:initialize()
    self.includedGenerators = {}
    self.virtualElements = {}

    -- Event-driven regeneration system
    self.activePanels = {} -- set of active GeneratorPanel instances
    self.registeredEvents = {} -- event name -> { elementType = true, ... }

    -- Create event frame for WoW events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        self:onEvent(event, ...)
    end)
end

-- Panel registration for dirty tracking
function Generator:registerPanel(panel)
    self.activePanels[panel] = true
end

function Generator:unregisterPanel(panel)
    self.activePanels[panel] = nil
end

-- Register events for an element type
function Generator:registerElementEvents(elementType, events)
    for _, event in ipairs(events) do
        if not self.registeredEvents[event] then
            self.registeredEvents[event] = {}
            self.eventFrame:RegisterEvent(event)
        end
        self.registeredEvents[event][elementType] = true
    end
end

-- Handle WoW events - mark elements dirty in all active panels
function Generator:onEvent(event, ...)
    local elementTypes = self.registeredEvents[event]
    if elementTypes then
        for elementType in pairs(elementTypes) do
            for panel in pairs(self.activePanels) do
                panel.dirtyElements[elementType] = true
            end
        end
    end
end

-- Shallow comparison of two tables for dynamicValues caching
-- Returns true if all values are equal
function Generator:valuesEqual(t1, t2)
    if t1 == t2 then
        return true
    end
    if t1 == nil or t2 == nil then
        return false
    end
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end
    -- Check all keys in t1 exist in t2 with same value
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end
    -- Check t2 doesn't have extra keys
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end
    return true
end

function Generator:include(generator)
    for _, v in ipairs(self.includedGenerators) do
        if generator == v then
            return
        end
    end
    tinsert(self.includedGenerators, generator)
end

function Generator:exclude(generator)
    for i, v in ipairs(self.includedGenerators) do
        if generator == v then
            table.remove(self.includedGenerators, i)
            return
        end
    end
end

-- Creates a virtual element type and returns it for chained configuration
function Generator:CreateVirtualElement(elementType, func)
    local virtualElement = VirtualElementType:new(elementType, func, self)
    self.virtualElements[elementType] = virtualElement
    return virtualElement
end

function Generator:Element(elementType, configOrFunc, elementFunc)
    -- Support both old and new signatures:
    -- Old: gen:Element("name", function(props) ... end)
    -- New: gen:Element("name", { dynamicValues = ..., alwaysRun = ..., regenerateOn = ... }, function(props) ... end)
    local config, func
    if type(configOrFunc) == "function" then
        -- Old signature
        func = configOrFunc
        -- Create VirtualElementType with alwaysRun default
        local virtualElement = self:CreateVirtualElement(elementType, func)
        virtualElement:setAlwaysRun(true)
        return virtualElement
    else
        -- New signature
        config = configOrFunc or {}
        func = elementFunc

        local virtualElement = self:CreateVirtualElement(elementType, func)

        -- Handle regenerateOn config
        local regenerateOn = config.regenerateOn
        if regenerateOn then
            if regenerateOn.events then
                virtualElement:addEvents(regenerateOn.events)
            end
            if regenerateOn.frameFields then
                virtualElement:addFrameFields(regenerateOn.frameFields)
            end
            if regenerateOn.framePredicates then
                virtualElement:addFramePredicates(regenerateOn.framePredicates)
            end
            if regenerateOn.values then
                virtualElement:setValues(regenerateOn.values)
            end
        end

        -- Handle legacy dynamicValues
        if config.dynamicValues then
            virtualElement:setValues(config.dynamicValues)
        end

        -- Handle explicit alwaysRun
        if config.alwaysRun ~= nil then
            virtualElement:setAlwaysRun(config.alwaysRun)
        elseif config.dynamicValues == nil and config.regenerateOn == nil then
            -- If no conditions specified, default to alwaysRun for backwards compatibility
            virtualElement:setAlwaysRun(true)
        end

        return virtualElement
    end
end

function Generator:hasElement(element)
    if self.virtualElements[element] then
        return true
    end
    for _, v in ipairs(self.includedGenerators) do
        if v:hasElement(element) then
            return true
        end
    end
    return false
end

-- Returns the VirtualElementType for a virtual element
function Generator:getVirtualElementDef(path)
    local def = self.virtualElements[path]
    if def then
        return def
    end
    for _, v in ipairs(self.includedGenerators) do
        def = v:getVirtualElementDef(path)
        if def then
            return def
        end
    end
    return nil
end

-- Returns just the function for backwards compatibility with existing code
function Generator:getVirtualElement(path)
    local def = self:getVirtualElementDef(path)
    if def then
        return def.func
    end
    return nil
end

function Generator:generateNode(parent, props, previousNode, panel)
    if props == nil or props[1] == nil then
        return nil
    end
    local node = GeneratorNode:new(parent)
    node.elementType = props[1]
    local elementDef = self:getVirtualElementDef(props[1])
    -- Fallback to global generator if not found (submodule elements are registered on separate generators)
    if not elementDef and self ~= WowVision.ui.generator then
        elementDef = WowVision.ui.generator:getVirtualElementDef(props[1])
    end
    local virtualElement = elementDef and elementDef.func
    for k, v in pairs(props) do
        if k == "hooks" then
            node.hooks = v
        elseif k ~= 1 and k ~= "hooks" then
            --Note: the children prop must be passed to child nodes here but will be removed later
            node.props[k] = v
        end
    end
    if virtualElement then
        node.virtualElement = true

        local root
        local shouldRegenerate = false

        -- Check if marked dirty by event (highest priority)
        if panel and panel.dirtyElements[props[1]] then
            panel.dirtyElements[props[1]] = nil
            shouldRegenerate = true
        end

        -- Check frameFields (property access)
        if not shouldRegenerate and #elementDef.frameFields > 0 and previousNode then
            for _, fieldConfig in ipairs(elementDef.frameFields) do
                local frameRef, field = fieldConfig[1], fieldConfig[2]
                -- Support string frame names (looked up at check time) or direct references
                local frame = type(frameRef) == "string" and _G[frameRef] or frameRef
                if frame then
                    local currentValue = frame[field]
                    local cacheKey = (type(frameRef) == "string" and frameRef or tostring(frame)) .. "." .. field
                    local cachedValue = previousNode.frameCache and previousNode.frameCache[cacheKey]
                    if currentValue ~= cachedValue then
                        shouldRegenerate = true
                        break
                    end
                end
            end
        end

        -- Check framePredicates (method calls)
        if not shouldRegenerate and #elementDef.framePredicates > 0 and previousNode then
            for _, predicateConfig in ipairs(elementDef.framePredicates) do
                local frameRef, method = predicateConfig[1], predicateConfig[2]
                -- Support string frame names (looked up at check time) or direct references
                local frame = type(frameRef) == "string" and _G[frameRef] or frameRef
                if frame and frame[method] then
                    local currentValue = frame[method](frame)
                    local cacheKey = (type(frameRef) == "string" and frameRef or tostring(frame)) .. ":" .. method
                    local cachedValue = previousNode.frameCache and previousNode.frameCache[cacheKey]
                    if currentValue ~= cachedValue then
                        shouldRegenerate = true
                        break
                    end
                end
            end
        end

        -- Can skip regeneration if:
        -- 1. Not marked dirty (shouldRegenerate is false)
        -- 2. Not alwaysRun
        -- 3. Has previous cached output for the SAME element type
        local canSkipRegeneration = not shouldRegenerate
            and not elementDef.alwaysRun
            and previousNode
            and previousNode.virtualElement
            and previousNode.elementType == node.elementType
            and previousNode.cachedGeneratorOutput

        -- Track whether this element regenerated (vs using cached output)
        -- Used to invalidate child caches when parent structure changes
        local didRegenerate = false

        if canSkipRegeneration then
            if elementDef.valuesFunc then
                -- Has values function - check if values changed
                local currentValues = elementDef.valuesFunc(node.props)
                if self:valuesEqual(currentValues, previousNode.lastDynamicValues) then
                    -- Values unchanged, reuse cached output
                    node.lastDynamicValues = currentValues
                    root = previousNode.cachedGeneratorOutput
                else
                    -- Values changed, regenerate
                    node.lastDynamicValues = currentValues
                    root = virtualElement(node.props)
                    didRegenerate = true
                end
            else
                -- No values function (event-only) - use cached output
                root = previousNode.cachedGeneratorOutput
            end
        else
            -- Must regenerate (first run, alwaysRun, dirty, or no previous)
            if elementDef.valuesFunc then
                node.lastDynamicValues = elementDef.valuesFunc(node.props)
            end
            root = virtualElement(node.props)
            didRegenerate = true
        end

        -- Cache frame field/predicate values for next comparison
        if #elementDef.frameFields > 0 or #elementDef.framePredicates > 0 then
            node.frameCache = {}
            for _, fieldConfig in ipairs(elementDef.frameFields) do
                local frameRef, field = fieldConfig[1], fieldConfig[2]
                local frame = type(frameRef) == "string" and _G[frameRef] or frameRef
                if frame then
                    local cacheKey = (type(frameRef) == "string" and frameRef or tostring(frame)) .. "." .. field
                    node.frameCache[cacheKey] = frame[field]
                end
            end
            for _, predicateConfig in ipairs(elementDef.framePredicates) do
                local frameRef, method = predicateConfig[1], predicateConfig[2]
                local frame = type(frameRef) == "string" and _G[frameRef] or frameRef
                if frame and frame[method] then
                    local cacheKey = (type(frameRef) == "string" and frameRef or tostring(frame)) .. ":" .. method
                    node.frameCache[cacheKey] = frame[method](frame)
                end
            end
        end

        -- Cache the generator output for potential reuse
        node.cachedGeneratorOutput = root

        -- Process children
        -- If this element regenerated, don't pass previousChild - force children to regenerate fresh
        -- This ensures that when a parent's structure changes, stale child caches are invalidated
        local previousChild = nil
        if not didRegenerate and previousNode then
            previousChild = previousNode.children[1]
        end
        local childNode = self:generateNode(node, root, previousChild, panel)
        if childNode then
            node:addChild(childNode)
        end
        node.props.children = nil
        return node
    end

    node.props.children = nil
    local realData = WowVision.ui.elementTypes:get(props[1])
    if not realData then
        if type(props[1]) == "table" then
            tpairs(props[1])
        end
        error("Unknown element " .. props[1])
    end

    for _, v in pairs(realData.generationConditions) do
        if not v(props) then
            return nil
        end
    end

    if props.children then
        -- Build a map of previous children by key for efficient lookup
        local previousChildrenByKey = {}
        if previousNode then
            for _, prevChild in ipairs(previousNode.children) do
                if prevChild.props.key then
                    previousChildrenByKey[prevChild.props.key] = prevChild
                end
            end
        end

        for i, child in ipairs(props.children) do
            -- Find matching previous child by key or index
            local prevChild = nil
            if child.key and previousChildrenByKey[child.key] then
                prevChild = previousChildrenByKey[child.key]
            elseif previousNode and previousNode.children[i] then
                prevChild = previousNode.children[i]
            end

            local childRoot = self:generateNode(node, child, prevChild, panel)
            if childRoot then
                node:addChild(childRoot)
            end
        end
    end

    return node
end

-- Combined compare + reconcile in a single pass
function Generator:reconcileDirect(realParent, tree1, tree2)
    if tree1 == nil and tree2 == nil then
        return
    end

    -- Case: Node is new (add)
    if not tree1 and tree2 then
        self:build(realParent, tree2)
        return
    end

    -- Case: Node was removed
    if tree1 and not tree2 then
        self:unbuild(realParent, tree1)
        return
    end

    -- Case: Element type changed (replace entire subtree)
    if tree1.elementType ~= tree2.elementType then
        self:unbuild(realParent, tree1)
        self:build(realParent, tree2)
        return
    end

    -- Same element type - compare props and reconcile children
    local real = realParent
    if not tree1.virtualElement then
        real = tree1.realElement
        tree2.realElement = real

        -- Apply prop changes directly
        for k, v in pairs(tree1.props) do
            if k ~= "children" and tree2.props[k] == nil then
                real:setProp(k, nil)
            end
        end

        for k, v in pairs(tree2.props) do
            if k ~= "children" then
                local oldValue = tree1.props[k]
                if oldValue ~= v then
                    -- Check if actually changed using InfoClass field comparison
                    local field = real.class.info:getField(k)
                    if field then
                        if not field:compare(real:getProp(k), v) then
                            real:setProp(k, v)
                        end
                    else
                        real:setProp(k, v)
                    end
                end
            end
        end
    end

    -- Reconcile children
    self:reconcileChildrenDirect(real, tree1, tree2)
end

-- Helper to collect real elements from a node (traversing through virtual wrappers)
function Generator:collectRealElements(node, result)
    result = result or {}
    if not node then
        return result
    end
    if node.realElement then
        -- This is a real element, add it
        tinsert(result, node.realElement)
    else
        -- Virtual element - collect from children
        for _, child in ipairs(node.children) do
            self:collectRealElements(child, result)
        end
    end
    return result
end

-- Reconcile children, choosing keyed or non-keyed strategy
function Generator:reconcileChildrenDirect(realParent, tree1, tree2)
    -- Try keyed comparison if first child has a key
    if tree2.children[1] and tree2.children[1].props.key ~= nil then
        local success = self:reconcileKeyedChildrenDirect(realParent, tree1, tree2)
        if success then
            return
        end
    end
    self:reconcileNonKeyedChildrenDirect(realParent, tree1, tree2)
end

-- Keyed children reconciliation
function Generator:reconcileKeyedChildrenDirect(realParent, tree1, tree2)
    -- Validate all children have keys
    for _, child in ipairs(tree1.children) do
        if child.props.key == nil then
            return false
        end
    end
    for _, child in ipairs(tree2.children) do
        if child.props.key == nil then
            return false
        end
    end

    -- Build key maps
    local oldByKey = {}
    for i, child in ipairs(tree1.children) do
        if oldByKey[child.props.key] then
            error("Duplicate key " .. child.props.key .. ".")
        end
        oldByKey[child.props.key] = child
    end

    local newByKey = {}
    for i, child in ipairs(tree2.children) do
        if newByKey[child.props.key] then
            error("Duplicate key " .. child.props.key .. ".")
        end
        newByKey[child.props.key] = child
    end

    -- Remove nodes that no longer exist
    for key, oldChild in pairs(oldByKey) do
        if not newByKey[key] then
            self:unbuild(realParent, oldChild)
        end
    end

    -- Add or update nodes (following tree2 order)
    for _, newChild in ipairs(tree2.children) do
        local key = newChild.props.key
        local oldChild = oldByKey[key]
        if not oldChild then
            -- New node
            self:build(realParent, newChild)
        else
            -- Existing node - reconcile
            self:reconcileDirect(realParent, oldChild, newChild)
        end
    end

    -- Reorder real children to match tree2's order
    -- Must traverse through virtual wrappers to find the actual real elements
    if realParent.reorderChildren then
        local orderedChildren = {}
        for _, newChild in ipairs(tree2.children) do
            self:collectRealElements(newChild, orderedChildren)
        end
        realParent:reorderChildren(orderedChildren)
    end

    return true
end

-- Non-keyed children reconciliation (index-based)
function Generator:reconcileNonKeyedChildrenDirect(realParent, tree1, tree2)
    local i1, i2 = 1, 1
    while i1 <= #tree1.children or i2 <= #tree2.children do
        local oldChild = tree1.children[i1]
        local newChild = tree2.children[i2]

        if oldChild == nil and newChild then
            -- New child
            self:build(realParent, newChild)
        elseif oldChild and not newChild then
            -- Removed child
            self:unbuild(realParent, oldChild)
        else
            -- Both exist - reconcile
            self:reconcileDirect(realParent, oldChild, newChild)
        end

        if oldChild then
            i1 = i1 + 1
        end
        if newChild then
            i2 = i2 + 1
        end
    end
end

function Generator:unbuild(parent, root)
    --Recursively removes elements from the parent based on the generated virtual tree.
    if not parent or not root then
        return
    end
    if not root.virtualElement then
        --removing the real element here will functionally remove all children of real anyway; so no need for further recursion.
        parent:remove(root.realElement)
        return
    end
    for _, child in ipairs(root.children) do
        self:unbuild(parent, child)
    end
end

function Generator:build(parent, root)
    --Builds a subtree using real elements
    --use newParent to keep track of the real element to add child real elements to, as virtual elements can have multiple levels without a real element.
    local newParent = parent
    if not root.virtualElement then
        newParent = WowVision.ui:CreateElement(root.elementType, root.props)
        root.realElement = newParent
        parent:add(newParent)
    end
    if root.hooks.mount then
        root.hooks.mount(newParent, root.props)
    end
    for _, child in ipairs(root.children) do
        self:build(newParent, child)
    end
end

WowVision.Generator = Generator
