local input = WowVision.input

local Click = input:createBindingType("Click")
Click.info:addFields({
    { key = "targetFrame" },
})

function Click:onActivate(frame, info)
    frame.targetFrame = info.targetFrame
    frame:SetAttribute("type", "click")
    frame:SetAttribute("clickbutton", frame.targetFrame)
    frame:SetAttribute("button", info.emulatedKey)
end

function Click:onDeactivate(frame, info)
    frame.targetFrame = nil
    frame:SetAttribute("clickbutton", nil)
    frame:SetAttribute("button", nil)
end

local Flexible = input:createBindingType("Flexible")

function Flexible:activate(info)
    if not info then
        if self.dorment then
            return nil
        end
        error("Info is required to activate a Flexible binding.")
    end
    if info.type == nil then
        error("Info must have a type to activate a Flexible binding. Key is " .. (info.key or "nil"))
    end
    local newInfo = {}
    self.info:set(newInfo, self)
    for k, v in pairs(info) do
        newInfo[k] = v
    end
    local binding = input:createBinding(newInfo, true)
    local activated = binding:activate()
    if not activated then
        return nil
    end
    tinsert(self.activated, activated)
    return activated
end

local Function = input:createBindingType("Function")
Function.info:addFields({
    { key = "func", required = true },
    { key = "interruptSpeech", required = true, default = false },
    { key = "delay", required = true, default = 0.0 },
})

function Function:onActivate(frame, info)
    local func = info.func
    if info.delay > 0 then
        if info.interruptSpeech then
            func = function()
                WowVision.base.speech:stop()
                C_Timer.After(info.delay, function()
                    info.func()
                end)
            end
        else
            func = function()
                C_Timer.After(info.delay, function()
                    info.func()
                end)
            end
        end
    end
    frame.func = func
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", "/run " .. frame:GetName() .. ".func()")
end

function Function:onDeactivate(frame, info)
    frame.func = nil
    frame:SetAttribute("macrotext", nil)
end

local Script = input:createBindingType("Script")
Script.info:addFields({
    { key = "script", required = true },
})

function Script:onActivate(frame, info)
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", info.script)
end

function Script:onDeactivate(frame, info)
    frame:SetAttribute("macrotext", nil)
end

local Target = input:createBindingType("Target")
Target.info:addFields({
    { key = "unit" },
})

function Target:onActivate(frame, info)
    frame:SetAttribute("type", "target")
    frame:SetAttribute("unit", info.unit)
end

function Target:onDeactivate(frame, info)
    frame:SetAttribute("unit", nil)
end

local VirtualKey = input:createBindingType("VirtualKey")
VirtualKey.info:addFields({
    { key = "targetFrame" },
})

function VirtualKey:onActivate(frame, info)
    frame.targetFrame = info.targetFrame
    frame:SetAttribute("type", "macro")
    frame:SetAttribute(
        "macrotext",
        "/run " .. frame:GetName() .. '.targetFrame:onKeyDown("' .. info.emulatedKey .. '")'
    )
end

function VirtualKey:onDeactivate(frame, info)
    frame.targetFrame = nil
    frame:SetAttribute("macrotext", nil)
end

local Virtual = input:createBindingType("Virtual")
Virtual.info:addFields({
    { key = "targetFrame" },
})

function Virtual:onActivate(frame, info)
    frame.targetFrame = info.targetFrame
    frame:SetAttribute("type", "macro")
    frame:SetAttribute(
        "macrotext",
        "/run " .. frame:GetName() .. ".targetFrame:onBindingPressed(" .. frame:GetName() .. ".binding)"
    )
end

function Virtual:onDeactivate(frame, info)
    frame.targetFrame = nil
    frame:SetAttribute("macrotext", nil)
end
