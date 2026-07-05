-- Action strategies for the input activator: each entry is a pair of functions
-- configuring and clearing one pooled secure frame. What happens on a keypress
-- is decided entirely by the action spec the requester passes -- keymaps (the
-- named, user-rebindable bindings) never own behavior.
--
-- A spec is a plain table: { binding = "leftClick", type = "Click", ... } plus
-- whatever fields its action type needs. emulatedKey may be set per spec; when
-- absent the keymap's default applies (leftClick defaults to LeftButton).
local actions = WowVision.Registry:new()
WowVision.inputActions = actions

-- Secure click-through to a protected Blizzard frame: the emulated mouse
-- button is passed through, so Enter on a proxy node is a true left click.
-- spec: { target = frame }
actions:register("Click", {
    configure = function(frame, spec, emulatedKey)
        frame:SetAttribute("type", "click")
        frame:SetAttribute("clickbutton", spec.target)
        frame:SetAttribute("button", emulatedKey)
    end,
    clear = function(frame, spec)
        frame:SetAttribute("clickbutton", nil)
        frame:SetAttribute("button", nil)
    end,
})

-- Insecure Lua callback, with the speech-interrupt and TTS-delay handling the
-- old Function binding type carried.
-- spec: { func = function, interruptSpeech = bool?, delay = seconds? }
actions:register("Function", {
    configure = function(frame, spec, emulatedKey)
        local func = spec.func
        local delay = spec.delay
        if delay == nil then
            delay = WowVision.consts.UI_DELAY or 0
        end
        if delay > 0 then
            local inner = func
            if spec.interruptSpeech then
                func = function()
                    WowVision.base.speech:stop()
                    C_Timer.After(delay, inner)
                end
            else
                func = function()
                    C_Timer.After(delay, inner)
                end
            end
        elseif spec.interruptSpeech then
            local inner = func
            func = function()
                WowVision.base.speech:stop()
                inner()
            end
        end
        frame.func = func
        frame:SetAttribute("type", "macro")
        frame:SetAttribute("macrotext", "/run " .. frame:GetName() .. ".func()")
    end,
    clear = function(frame, spec)
        frame.func = nil
        frame:SetAttribute("macrotext", nil)
    end,
})

-- Secure unit targeting.
-- spec: { unit = unitId }
actions:register("Target", {
    configure = function(frame, spec, emulatedKey)
        frame:SetAttribute("type", "target")
        frame:SetAttribute("unit", spec.unit)
    end,
    clear = function(frame, spec)
        frame:SetAttribute("unit", nil)
    end,
})

-- Raw macro text.
-- spec: { script = macrotext }
actions:register("Script", {
    configure = function(frame, spec, emulatedKey)
        frame:SetAttribute("type", "macro")
        frame:SetAttribute("macrotext", spec.script)
    end,
    clear = function(frame, spec)
        frame:SetAttribute("macrotext", nil)
    end,
})
