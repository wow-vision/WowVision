local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

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
        builder:pushContext(infoFrame.label)
    end
    for _, field in ipairs(infoFrame.info.fields) do
        if field.showInUI then
            local make = fieldControls[field.typeKey] or fallbackControl
            builder:addItem(ControlId.structural("field:" .. field.key), make(field, infoFrame))
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
