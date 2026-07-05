local module = WowVision.base.ui
local L = module.L
local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The graph bindings screen: one row per named binding -- a button per
-- current input (Enter removes it) and an Add button (Enter captures a key
-- combination). Mirrors the old binding/List screen.

-- Old-system activations and our own override-binding handles both hold the
-- previous keys until told otherwise.
local function refreshAll(set)
    set:reactivateAll()
    WowVision.graphHost:refreshBindings()
end

local function removeInput(set, binding, input)
    if #binding.inputs <= 0 then
        return
    end
    if #binding.inputs == 1 and binding.vital then
        WowVision:speak(L["Cannot remove; Binding must have at least one input."])
        return
    end
    binding:removeInput(input)
    refreshAll(set)
end

local function completeMapping(set, binding, mapping)
    local conflicting = binding:doesInputConflict(mapping)
    if conflicting ~= nil then
        if conflicting == binding then
            WowVision:speak(L["This input already exists for this binding."])
            return
        end
        if conflicting.vital and #conflicting.inputs <= 1 then
            WowVision:speak(L["Cannot replace this binding as it requires at least one input."])
            return
        end
        nodes.pushConfirm({
            prompt = L["This input conflicts with"] .. " " .. conflicting:getLabel() .. ". " .. L["Replace?"],
            onConfirm = function()
                conflicting:removeInput(mapping)
                binding:addInput(mapping)
                refreshAll(set)
            end,
        })
        return
    end
    binding:addInput(mapping)
    refreshAll(set)
end

local function renderBindings(builder)
    local set = WowVision.input.bindings
    builder:pushContext("bindings", L["Bindings"])
    for _, binding in ipairs(set.orderedBindings) do
        local label = binding:getLabel() or binding.key
        builder:pushContext("binding:" .. binding.key, label)
        builder:startRow()
        for _, input in ipairs(binding.inputs) do
            local capturedInput = input
            builder:addItem(
                ControlId.structural("b:" .. binding.key .. ":" .. capturedInput),
                nodes.button({
                    label = function()
                        if GetBindingText ~= nil then
                            return GetBindingText(capturedInput, "KEY_")
                        end
                        return capturedInput
                    end,
                    onActivate = function()
                        removeInput(set, binding, capturedInput)
                    end,
                })
            )
        end
        builder:addItem(
            ControlId.structural("b:" .. binding.key .. ":add"),
            nodes.button({
                label = L["Add"],
                onActivate = function()
                    WowVision.graphHost:openKeyCapture({
                        label = label,
                        onCommit = function(mapping)
                            completeMapping(set, binding, mapping)
                        end,
                    })
                end,
            })
        )
        builder:endRow()
        builder:popContext()
    end
    builder:popContext()
end

module.renderGraphBindings = renderBindings

function module:getGraphMenuItems(builder)
    builder:addItem(
        ControlId.structural("bindings"),
        nodes.button({
            label = L["Bindings"],
            onActivate = function()
                local host = WowVision.graphHost
                local stack = host:focusedStack()
                if stack ~= nil then
                    host:push(stack, { key = "bindings", render = renderBindings })
                end
            end,
        })
    )
end
