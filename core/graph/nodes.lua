local graph = WowVision.graph
local ControlId = graph.ControlId
local kinds = graph.kinds

-- Node factories: each takes a single config table and returns a vtable for
-- builder:addItem. Screens stay declarative; the factories own the control
-- type, the announcement parts, and the input bindings for each control kind.
local nodes = {}
graph.nodes = nodes

-- A live label function for a Blizzard frame: its own text, else the first
-- text region (dropdown-style buttons keep their text on a region).
function nodes.frameText(frame)
    return function()
        local text = frame.GetText ~= nil and frame:GetText() or nil
        if text ~= nil and text ~= "" then
            return text
        end
        for _, region in ipairs({ frame:GetRegions() }) do
            if region.GetText ~= nil then
                local regionText = region:GetText()
                if regionText ~= nil and regionText ~= "" then
                    return regionText
                end
            end
        end
        return nil
    end
end

-- A real Blizzard button: Enter and Backspace click it securely as true
-- left/right clicks.
-- config: { target = frame, label = string|function? }
function nodes.proxyButton(config)
    local target = config.target
    if target == nil then
        error("proxyButton requires a target frame")
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = config.label or nodes.frameText(target), kind = kinds.label } },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target },
        },
    }
end

-- A synthetic button: Enter runs the handler.
-- config: { label = string|function, onActivate = function, onSecondary = function?, stateText = function? }
function nodes.button(config)
    if config.label == nil then
        error("button requires a label")
    end
    if config.onActivate == nil then
        error("button requires an onActivate handler")
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = config.label, kind = kinds.label } },
        onActivate = config.onActivate,
        onSecondary = config.onSecondary,
        stateText = config.stateText,
    }
end

-- A read-only line.
-- config: { label = string|function, live = "focus"|"always"? }
function nodes.text(config)
    if config.label == nil then
        error("text requires a label")
    end
    return {
        controlType = graph.controlTypes.text,
        announcements = { { text = config.label, kind = kinds.label, live = config.live } },
    }
end

-- A whole tab-cycled menu of proxy buttons under one announcement context:
-- one tab stop per button, positions stamped across the set. Buttons come
-- from config.buttons, else all shown Button children of config.frame sorted
-- top to bottom.
-- config: { label = string?, frame = frame?, buttons = array? }
function nodes.proxyButtonMenu(builder, config)
    local buttons = config.buttons
    if buttons == nil then
        if config.frame == nil then
            error("proxyButtonMenu requires frame or buttons")
        end
        buttons = {}
        for _, child in ipairs({ config.frame:GetChildren() }) do
            if child:GetObjectType() == "Button" and child:IsShown() then
                tinsert(buttons, child)
            end
        end
        table.sort(buttons, function(a, b)
            return a:GetTop() > b:GetTop()
        end)
    end
    if config.label ~= nil then
        builder:pushContext(config.label)
    end
    for _, button in ipairs(buttons) do
        builder:beginStop()
        builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
    end
    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
