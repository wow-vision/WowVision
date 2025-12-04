local gen = WowVision.ui.generator
local L = WowVision:getLocale()

gen:Element("binding/List", function(props)
    local bindings = props.bindings
    local result = { "List", label = L["Bindings"], children = {} }
    for _, binding in ipairs(bindings.orderedBindings) do
        tinsert(result.children, { "binding/Binding", set = bindings, binding = binding })
    end
    return result
end)

local function InputButton_Click(event, button)
    local binding = button.userdata.binding
    local input = button.userdata.input
    if #binding.inputs <= 0 then
        return
    end
    if #binding.inputs == 1 and binding.vital then
        WowVision.base.speech:speak(L["Cannot remove; Binding must have at least one input."])
        return
    end
    binding:removeInput(input)
    button.userdata.set:reactivateAll()
end

local function InputBinding_ReplaceConfirm(event, source)
    source.context:pop()
    local originalBinding = source.userdata.originalBinding
    local newBinding = source.userdata.newBinding
    local mapping = source.userdata.mapping
    local set = source.userdata.set

    --Ensure that vital bindings don't have their single input removed if they only have one
    if originalBinding.vital and #originalBinding.inputs <= 1 then
        WowVision.base.speech:speak(L["Cannot replace this binding as it requires at least one input."])
        return
    end

    originalBinding:removeInput(mapping)
    newBinding:addInput(mapping)
    set:reactivateAll()
end

local function InputBinding_ReplaceCancel(event, source)
    source.context:pop()
end

local function InputBinding_MappingComplete(event, source, mapping)
    local context = source.context
    context:pop()
    local binding = source.userdata.binding
    local set = source.userdata.set
    local conflictingBinding = binding:doesInputConflict(mapping)
    if conflictingBinding ~= nil then
        if conflictingBinding == binding then
            WowVision.base.speech:speak(L["This input already exists for this binding."])
        else
            local prompt = L["This input conflicts with"]
                .. " "
                .. conflictingBinding:getLabel()
                .. ". "
                .. L["Replace?"]
            local ctx = WowVision.ui:CreateElement("ConfirmationContext")
            ctx:setProp("prompt", prompt)
            ctx:setProp("userdata", {
                set = set,
                originalBinding = conflictingBinding,
                newBinding = binding,
                mapping = mapping,
            })
            ctx.events.confirm:subscribe(nil, InputBinding_ReplaceConfirm)
            ctx.events.cancel:subscribe(nil, InputBinding_ReplaceCancel)
            context:add(ctx)
        end
        return
    end
    binding:addInput(mapping)
    set:reactivateAll()
end

local function InputBinding_MappingCancelled(event, source)
    source.context:pop()
end

local function AddButton_Click(event, button)
    local binding = button.userdata.binding
    local set = button.userdata.set
    local ctx = WowVision.ui:CreateElement("InputMappingContext")
    ctx:setProp("userdata", { set = set, binding = binding })
    ctx.events.mappingComplete:subscribe(nil, InputBinding_MappingComplete)
    ctx.events.mappingCancelled:subscribe(nil, InputBinding_MappingCancelled)
    button.context:add(ctx)
end

gen:Element("binding/Binding", function(props)
    local binding = props.binding
    local result = { "List", label = binding:getLabel(), direction = "horizontal", children = {} }
    for _, input in ipairs(binding.inputs) do
        tinsert(result.children, {
            "Button",
            label = GetBindingText(input, "KEY_"),
            userdata = {
                set = props.set,
                binding = binding,
                input = input,
            },
            events = {
                click = InputButton_Click,
            },
        })
    end
    tinsert(result.children, {
        "Button",
        label = L["Add"],
        userdata = {
            set = props.set,
            binding = binding,
        },
        events = {
            click = AddButton_Click,
        },
    })
    return result
end)
