local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local L = WowVision:getLocale()

-- Renders InfoFrame settings trees as graph screens: fields become value
-- controls wired straight to Field get/set (validation and persistence ride
-- along), child categories and refs become buttons pushing child screens.
-- This replaces InfoFrame:getGenerator for migrated screens; both run during
-- coexistence.
local settings = {}
graph.settings = settings

local function getterOf(infoFrame, field)
    return function()
        return field:get(infoFrame)
    end
end

local function setterOf(infoFrame, field)
    return function(value)
        field:set(infoFrame, value)
    end
end

local function valueTextOf(infoFrame, field)
    return function()
        return field:getValueString(infoFrame, field:get(infoFrame))
    end
end

-- typeKey -> vtable factory. Register more with settings.registerFieldControl.
local fieldControls = {}

function settings.registerFieldControl(typeKey, make)
    fieldControls[typeKey] = make
end

function settings.hasFieldControl(typeKey)
    return fieldControls[typeKey] ~= nil
end

settings.registerFieldControl("Bool", function(field, infoFrame)
    return nodes.toggle({
        label = field:getLabel(),
        get = getterOf(infoFrame, field),
        set = setterOf(infoFrame, field),
    })
end)

settings.registerFieldControl("Number", function(field, infoFrame)
    return nodes.number({
        label = field:getLabel(),
        get = getterOf(infoFrame, field),
        set = setterOf(infoFrame, field),
        valueText = valueTextOf(infoFrame, field),
    })
end)

settings.registerFieldControl("Choice", function(field, infoFrame)
    return nodes.choice({
        label = field:getLabel(),
        get = getterOf(infoFrame, field),
        set = setterOf(infoFrame, field),
        choices = function()
            return field:getChoices(infoFrame)
        end,
        valueText = valueTextOf(infoFrame, field),
    })
end)

settings.registerFieldControl("String", function(field, infoFrame)
    return nodes.textInput({
        label = field:getLabel(),
        get = getterOf(infoFrame, field),
        set = setterOf(infoFrame, field),
        valueText = valueTextOf(infoFrame, field),
    })
end)

-- Field types with no control yet read as label plus value, non-interactive.
local function fallbackControl(field, infoFrame)
    local valueText = valueTextOf(infoFrame, field)
    return nodes.text({
        label = function()
            local label = field:getLabel() or field.key
            local value = valueText()
            if value ~= nil and value ~= "" then
                return label .. ", " .. value
            end
            return label
        end,
    })
end

-- The control vtable for one field against one owner object (an InfoFrame or
-- any InfoClass instance).
function settings.controlFor(field, owner)
    local make = fieldControls[field.typeKey] or fallbackControl
    return make(field, owner)
end

-- Emit an InfoClass instance's own fields (a component's editor body). An
-- object may take over entirely by defining renderGraphSettings(builder).
function settings.renderObjectInto(builder, obj)
    if obj.renderGraphSettings ~= nil then
        obj:renderGraphSettings(builder)
        return
    end
    local fields = nil
    if obj.class ~= nil then
        if obj.class.getFields ~= nil then
            fields = obj.class:getFields()
        end
        if (fields == nil or #fields == 0) and obj.class.info ~= nil then
            fields = obj.class.info.fields -- old InfoClass classes, during conversion
        end
    end
    if fields == nil then
        return
    end
    for _, field in ipairs(fields) do
        if field.showInUI ~= false then
            builder:addItem(ControlId.structural("field:" .. field.key), settings.controlFor(field, obj))
        end
    end
end

local function pushChildScreen(target)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack ~= nil then
        host:push(stack, {
            key = "settings:" .. tostring(target.key or target.label),
            render = function(builder)
                settings.renderInto(builder, target)
            end,
        })
    end
end

-- Emit one InfoFrame's fields and children into the builder.
function settings.renderInto(builder, infoFrame)
    if infoFrame.label ~= nil then
        builder:pushContext(tostring(infoFrame.key or infoFrame.label), infoFrame.label)
    end
    for _, field in ipairs(infoFrame.info.fields) do
        if field.showInUI then
            builder:addItem(ControlId.structural("field:" .. field.key), settings.controlFor(field, infoFrame))
        end
    end
    for _, child in ipairs(infoFrame.children) do
        local target = child.ref and child.target or child
        builder:addItem(
            ControlId.structural("child:" .. tostring(child.key or target.key or target.label)),
            nodes.button({
                label = target.label,
                onActivate = function()
                    pushChildScreen(target)
                end,
            })
        )
    end
    if infoFrame.label ~= nil then
        builder:popContext()
    end
end

-- A graphScreen config for a settings tree (frameless: Escape closes it).
function settings.screen(infoFrame)
    return {
        key = "settings:" .. tostring(infoFrame.key or infoFrame.label),
        captureClose = true,
        render = function(builder)
            settings.renderInto(builder, infoFrame)
        end,
    }
end

-- ---- component arrays (buffer groups, buffers, monitors, rules) ----

local function pushScreen(key, render)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack ~= nil then
        host:push(stack, { key = key, render = render })
    end
end
settings.pushScreen = pushScreen

local function instanceLabel(instance)
    local label = instance.getLabel ~= nil and instance:getLabel() or nil
    if label ~= nil and label ~= "" then
        return label
    end
    return "item"
end

local function pushComponentEditor(field, owner, instance)
    pushScreen("component:" .. tostring(instance), function(builder)
        -- The instance may have been removed under us.
        local present = false
        for _, current in ipairs(field:get(owner)) do
            if current == instance then
                present = true
                break
            end
        end
        if not present then
            return
        end
        builder:pushContext("component", instanceLabel(instance))
        settings.renderObjectInto(builder, instance)
        builder:addItem(
            ControlId.structural("remove"),
            nodes.button({
                label = L["Remove"],
                onActivate = function()
                    for i, current in ipairs(field:get(owner)) do
                        if current == instance then
                            field:removeElement(owner, i)
                            break
                        end
                    end
                    local host = WowVision.graphHost
                    host:pop(host:focusedStack())
                end,
            })
        )
        builder:popContext()
    end)
end

local function pushTypeSelector(field, owner)
    pushScreen("componentType:" .. tostring(field.key), function(builder)
        builder:pushContext("selectType", L["Select Type"])
        for _, typeEntry in ipairs(field:getAvailableTypes()) do
            local typeKey = field:getTypeKeyFromEntry(typeEntry)
            local typeLabel = field:getTypeLabel(typeEntry)
            builder:addItem(
                ControlId.structural("type:" .. tostring(typeKey)),
                nodes.button({
                    label = typeLabel,
                    onActivate = function()
                        local instance = field.factory({
                            type = typeKey,
                            label = L["New"] .. " " .. typeLabel,
                        })
                        field:addElement(owner, instance)
                        local host = WowVision.graphHost
                        host:pop(host:focusedStack())
                        pushComponentEditor(field, owner, instance)
                    end,
                })
            )
        end
        builder:popContext()
    end)
end

local function pushComponentList(field, owner)
    pushScreen("components:" .. tostring(field.key), function(builder)
        builder:pushContext("components:" .. tostring(field.key), field:getLabel() or field.key)
        for _, instance in ipairs(field:get(owner)) do
            local captured = instance
            builder:addItem(
                ControlId.forObject(captured),
                nodes.button({
                    label = function()
                        return instanceLabel(captured)
                    end,
                    onActivate = function()
                        pushComponentEditor(field, owner, captured)
                    end,
                })
            )
        end
        if #field:getAvailableTypes() > 0 then
            builder:addItem(
                ControlId.structural("add"),
                nodes.button({
                    label = L["Add"],
                    onActivate = function()
                        pushTypeSelector(field, owner)
                    end,
                })
            )
        end
        builder:popContext()
    end)
end

settings.registerFieldControl("ComponentArray", function(field, owner)
    return nodes.button({
        label = function()
            return (field:getLabel() or field.key) .. " (" .. field:getLength(owner) .. ")"
        end,
        onActivate = function()
            pushComponentList(field, owner)
        end,
    })
end)

-- ---- the module menu ----

local function moduleSortComp(a, b)
    return (a:getLabel() or "") < (b:getLabel() or "")
end

local function pushModuleScreen(module)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack ~= nil then
        host:push(stack, {
            key = "module:" .. tostring(module.key or module:getLabel()),
            render = function(builder)
                settings.renderModuleInto(builder, module)
            end,
        })
    end
end

-- Emit one module's menu: enabled toggle (non-vital modules), sorted
-- submodule buttons pushing child screens, the module's own graph menu items
-- (getGraphMenuItems), then its settings fields. Mirrors the old ModulePanel.
function settings.renderModuleInto(builder, module)
    builder:pushContext("module:" .. tostring(module.key), module:getLabel() or tostring(module.key))

    if not module:isVital() then
        builder:addItem(
            ControlId.structural("enabled"),
            nodes.toggle({
                label = L["Enabled"],
                get = function()
                    return module:getEnabled()
                end,
                set = function(value)
                    module:setEnabled(value)
                end,
            })
        )
    end

    local submodules = {}
    for _, submodule in ipairs(module.submodules) do
        tinsert(submodules, submodule)
    end
    table.sort(submodules, moduleSortComp)
    for _, submodule in ipairs(submodules) do
        builder:addItem(
            ControlId.structural("module:" .. tostring(submodule.key)),
            nodes.button({
                label = submodule:getLabel() or tostring(submodule.key),
                onActivate = function()
                    pushModuleScreen(submodule)
                end,
            })
        )
    end

    if module.getGraphMenuItems ~= nil then
        module:getGraphMenuItems(builder)
    end

    if module.settingsRoot ~= nil then
        settings.renderInto(builder, module.settingsRoot)
    end

    builder:popContext()
end

-- A graphScreen config for a module's menu (frameless: Escape closes it).
function settings.moduleScreen(module)
    return {
        key = "menu:" .. tostring(module.key or module:getLabel()),
        captureClose = true,
        render = function(builder)
            settings.renderModuleInto(builder, module)
        end,
    }
end

-- The graph version of the WowVision menu. Parallel to the old menu until
-- parity; opened by /wv gmenu.
function settings.openMenu()
    WowVision.UIHost:openTemporaryWindow({ graphScreen = settings.moduleScreen(WowVision.base) })
end

-- Dev entry: open a module's settings as a graph window for side-by-side
-- comparison with the old UI. Path is dot-separated under WowVision.base,
-- for example "speech" or "windows.GameMenu".
function settings.openModuleSettings(path)
    local target = WowVision.base
    for part in tostring(path or ""):gmatch("[^%.%s]+") do
        target = target ~= nil and target[part] or nil
    end
    if target == nil or target.settingsRoot == nil then
        print("No settings found for " .. tostring(path))
        return
    end
    WowVision.UIHost:openTemporaryWindow({ graphScreen = settings.screen(target.settingsRoot) })
end
