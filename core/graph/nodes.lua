local graph = WowVision.graph
local ControlId = graph.ControlId
local kinds = graph.kinds
local L = WowVision:getLocale()

-- Node factories: each takes a single config table and returns a vtable for
-- builder:addItem. Screens stay declarative; the factories own the control
-- type, the announcement parts, and the input bindings for each control kind.
local nodes = {}
graph.nodes = nodes

local function chainCalls(first, second)
    if first == nil then
        return second
    end
    if second == nil then
        return first
    end
    return function(...)
        first(...)
        second(...)
    end
end

local function resolveFrame(frameOrFunction)
    if type(frameOrFunction) == "function" then
        return frameOrFunction()
    end
    return frameOrFunction
end

local function runFrameScript(frameOrFunction, script)
    local frame = resolveFrame(frameOrFunction)
    if frame ~= nil and frame.HasScript ~= nil and frame:HasScript(script) then
        ExecuteFrameScript(frame, script)
    end
end

-- Run a frame's hover scripts as focus enters and leaves the node: the game
-- shows its own tooltip and highlight, and the tooltip reader has content.
-- Appends to any existing onFocus/onUnfocus (a scroll adapter's scroll hook
-- runs first, so the frame is materialized before hovering). Also marks the
-- node's tooltipFrame so the host points the tooltip reader at it (SPACE and
-- the shift-arrow line keys).
function nodes.attachHover(vtable, frameOrFunction)
    vtable.onFocus = chainCalls(vtable.onFocus, function()
        runFrameScript(frameOrFunction, "OnEnter")
    end)
    vtable.onUnfocus = chainCalls(vtable.onUnfocus, function()
        runFrameScript(frameOrFunction, "OnLeave")
    end)
    if vtable.tooltipFrame == nil then
        vtable.tooltipFrame = frameOrFunction
    end
    return vtable
end

-- Scroll a plain (non-virtualized) ScrollFrame so a region is visible when
-- its node gains focus. Content is fully instantiated; only the viewport
-- moves, piloted through the real scrollbar when there is one. Runs before
-- any existing onFocus hook.
function nodes.attachScrollFrame(vtable, scrollFrame, regionOrFunction)
    vtable.onFocus = chainCalls(function()
        local frame = resolveFrame(scrollFrame)
        local region = resolveFrame(regionOrFunction)
        if frame == nil or region == nil then
            return
        end
        pcall(function()
            local scrollChild = frame:GetScrollChild()
            local childTop = scrollChild ~= nil and scrollChild:GetTop() or nil
            local regionTop = region:GetTop()
            local regionBottom = region:GetBottom() or regionTop
            if childTop == nil or regionTop == nil then
                return
            end
            local offsetTop = childTop - regionTop
            local offsetBottom = childTop - regionBottom
            local viewHeight = frame:GetHeight()
            local current = frame:GetVerticalScroll()
            local target = current
            if offsetTop < current then
                target = offsetTop
            elseif offsetBottom > current + viewHeight then
                target = offsetBottom - viewHeight
            end
            local range = frame:GetVerticalScrollRange()
            if target < 0 then
                target = 0
            elseif target > range then
                target = range
            end
            if target ~= current then
                local scrollBar = frame.ScrollBar
                    or (frame.GetName ~= nil and frame:GetName() ~= nil and _G[frame:GetName() .. "ScrollBar"])
                    or nil
                if scrollBar ~= nil and scrollBar.SetValue ~= nil then
                    scrollBar:SetValue(target)
                else
                    frame:SetVerticalScroll(target)
                end
            end
        end)
    end, vtable.onFocus)
    return vtable
end

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
    return nodes.attachHover({
        controlType = graph.controlTypes.button,
        announcements = { { text = config.label or nodes.frameText(target), kind = kinds.label } },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target },
        },
    }, target)
end

-- A synthetic button: Enter runs the handler. An optional value part reads
-- after the role word and is watched live while focused (an opener button
-- showing the value it edits).
-- config: { label = string|function, onActivate = function, value = string|function?, onSecondary = function?, stateText = function? }
function nodes.button(config)
    if config.label == nil then
        error("button requires a label")
    end
    if config.onActivate == nil then
        error("button requires an onActivate handler")
    end
    local announcements = { { text = config.label, kind = kinds.label } }
    if config.value ~= nil then
        tinsert(announcements, { text = config.value, kind = kinds.value, live = "focus" })
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = announcements,
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

-- ---- value controls ----
-- All take get/set functions; the settings renderer builds those from
-- InfoClass fields, other screens pass their own closures.

-- A checkbox: Enter flips it. The value part is live, so game-driven flips
-- announce themselves while focused.
-- config: { label = string|function, get = function, set = function, valueText = function? }
function nodes.toggle(config)
    if config.label == nil or config.get == nil or config.set == nil then
        error("toggle requires label, get, and set")
    end
    local get = config.get
    local set = config.set
    local valueText = config.valueText
        or function()
            return get() and L["Checked"] or L["Unchecked"]
        end
    return {
        controlType = graph.controlTypes.toggle,
        announcements = {
            { text = config.label, kind = kinds.label },
            { text = valueText, kind = kinds.value, live = "focus" },
        },
        onActivate = function()
            set(not get())
        end,
        stateText = valueText,
    }
end

-- A numeric value: left/right adjust by step (large jumps with a modifier
-- later), Enter opens typed entry. Clamping belongs to the setter.
-- config: { label, get, set, step = 1?, largeStep = step*10?, valueText = function? }
function nodes.number(config)
    if config.label == nil or config.get == nil or config.set == nil then
        error("number requires label, get, and set")
    end
    local get = config.get
    local set = config.set
    local step = config.step or 1
    local largeStep = config.largeStep or step * 10
    local valueText = config.valueText
        or function()
            local value = get()
            return value ~= nil and tostring(value) or nil
        end
    local function trySet(value)
        local ok = pcall(set, value)
        return ok
    end
    return {
        controlType = graph.controlTypes.number,
        announcements = {
            { text = config.label, kind = kinds.label },
            { text = valueText, kind = kinds.value, live = "focus" },
        },
        onAdjust = function(sign, large)
            local value = get() or 0
            trySet(value + sign * (large and largeStep or step))
        end,
        onActivate = function()
            WowVision.graphHost:openTextEntry({
                label = config.label,
                text = tostring(get() or ""),
                onCommit = function(text)
                    if trySet(tonumber(text) or text) then
                        WowVision:speak(valueText() or "")
                    end
                end,
            })
        end,
        stateText = valueText,
    }
end

-- A single-select value: Enter opens a child screen of the options, landing
-- on the current pick; choosing sets the value and returns.
-- config: { label, get, set, choices = list or function, valueText = function? }
function nodes.choice(config)
    if config.label == nil or config.get == nil or config.set == nil or config.choices == nil then
        error("choice requires label, get, set, and choices")
    end
    local get = config.get
    local set = config.set
    local function choicesOf()
        if type(config.choices) == "function" then
            return config.choices()
        end
        return config.choices
    end
    local valueText = config.valueText
        or function()
            local value = get()
            for _, choice in ipairs(choicesOf()) do
                if choice.value == value then
                    return choice.label
                end
            end
            return value ~= nil and tostring(value) or nil
        end
    local function renderChoices(builder)
        local label = config.label
        if type(label) == "function" then
            label = label()
        end
        builder:pushContext(label or "")
        for _, choice in ipairs(choicesOf()) do
            local value = choice.value
            builder:addItem(ControlId.structural("choice:" .. tostring(value)), {
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = choice.label, kind = kinds.label },
                    {
                        -- Non-empty only on the current pick: drives both the
                        -- spoken state and landing on it when the list opens.
                        text = function()
                            if get() == value then
                                return L["Checked"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                        live = "focus",
                    },
                },
                onActivate = function()
                    set(value)
                    local host = WowVision.graphHost
                    host:pop(host:focusedStack())
                end,
            })
        end
        builder:popContext()
    end
    return {
        controlType = graph.controlTypes.dropdown,
        announcements = {
            { text = config.label, kind = kinds.label },
            { text = valueText, kind = kinds.value, live = "focus" },
        },
        onActivate = function()
            local host = WowVision.graphHost
            local stack = host:focusedStack()
            if stack ~= nil then
                host:push(stack, { key = "choices", render = renderChoices })
            end
        end,
    }
end

-- A text value: Enter opens typed entry.
-- config: { label, get, set, valueText = function? }
function nodes.textInput(config)
    if config.label == nil or config.get == nil or config.set == nil then
        error("textInput requires label, get, and set")
    end
    local get = config.get
    local set = config.set
    local valueText = config.valueText
        or function()
            local value = get()
            return value ~= nil and tostring(value) or nil
        end
    return {
        controlType = graph.controlTypes.editBox,
        announcements = {
            { text = config.label, kind = kinds.label },
            { text = valueText, kind = kinds.value, live = "focus" },
        },
        onActivate = function()
            WowVision.graphHost:openTextEntry({
                label = config.label,
                text = tostring(get() or ""),
                onCommit = function(text)
                    if pcall(set, text) then
                        WowVision:speak(valueText() or "")
                    end
                end,
            })
        end,
        stateText = valueText,
    }
end

-- Push a confirmation child screen: a prompt line and confirm/cancel buttons.
-- Escape pops without confirming, like cancel.
-- config: { prompt = string|function, confirmLabel?, cancelLabel?, onConfirm = function, onCancel = function? }
function nodes.pushConfirm(config)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack == nil then
        return
    end
    host:push(stack, {
        key = "confirm",
        render = function(builder)
            builder:addItem(ControlId.structural("prompt"), nodes.text({ label = config.prompt }))
            builder:addItem(
                ControlId.structural("yes"),
                nodes.button({
                    label = config.confirmLabel or "Yes",
                    onActivate = function()
                        host:pop(host:focusedStack())
                        if config.onConfirm ~= nil then
                            config.onConfirm()
                        end
                    end,
                })
            )
            builder:addItem(
                ControlId.structural("no"),
                nodes.button({
                    label = config.cancelLabel or "No",
                    onActivate = function()
                        host:pop(host:focusedStack())
                        if config.onCancel ~= nil then
                            config.onCancel()
                        end
                    end,
                })
            )
        end,
    })
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
