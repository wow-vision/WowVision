local graph = WowVision.graph
local GraphHost = graph.GraphHost

-- Capture one key combination through a shared keyboard-capturing frame. All
-- keys are blocked from the game and from our own bindings while it is up --
-- that is what capturing means. Modifiers speak as they build; releasing the
-- main key commits "ALT-CTRL-SHIFT-KEY"; Escape cancels. The combination is
-- the one held when the main key went DOWN: people let go of Alt a moment
-- before the letter, and a combination read at the release lost its Alt.
-- config: { label = string|function?, onCommit = function(mapping), onCancel = function? }
function GraphHost:openKeyCapture(config)
    local frame = self.captureFrame
    if frame == nil then
        frame = CreateFrame("Frame", "WowVisionGraphKeyCapture", UIParent)
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(false)
        frame:SetFrameStrata("DIALOG")

        local function normalize(key)
            if key == "LCTRL" or key == "RCTRL" then
                return "CTRL"
            end
            if key == "LSHIFT" or key == "RSHIFT" then
                return "SHIFT"
            end
            if key == "LALT" or key == "RALT" then
                return "ALT"
            end
            return key
        end

        -- A modifier counts as held when we saw it go down or the game says it
        -- is down (it may have been pressed before the capture opened).
        local function held(name, isDown)
            return frame.modifiers[name] or (isDown ~= nil and isDown() == true)
        end

        local function currentMapping()
            -- Modifier order is the one the WoW binding API requires.
            local parts = {}
            if held("ALT", IsAltKeyDown) then
                tinsert(parts, "ALT")
            end
            if held("CTRL", IsControlKeyDown) then
                tinsert(parts, "CTRL")
            end
            if held("SHIFT", IsShiftKeyDown) then
                tinsert(parts, "SHIFT")
            end
            if frame.mainKey ~= nil then
                tinsert(parts, frame.mainKey)
            end
            return table.concat(parts, "-")
        end

        frame.resetCapture = function()
            frame.modifiers = { CTRL = false, SHIFT = false, ALT = false }
            frame.mainKey = nil
            frame.mapping = nil
        end

        frame:SetScript("OnKeyDown", function(f, key)
            local entry = self._keyCapture
            if entry == nil then
                return
            end
            local k = normalize(key)
            if k == "ESCAPE" then
                self._keyCapture = nil
                f:Hide()
                if entry.onCancel ~= nil then
                    entry.onCancel()
                end
                return
            end
            if k == "CTRL" or k == "SHIFT" or k == "ALT" then
                f.modifiers[k] = true
            elseif f.mainKey == nil then
                f.mainKey = k
                f.mapping = currentMapping()
            end
            local mapping = f.mapping or currentMapping()
            if mapping ~= "" then
                self:_speak(mapping)
            end
        end)

        frame:SetScript("OnKeyUp", function(f, key)
            local entry = self._keyCapture
            if entry == nil then
                return
            end
            local k = normalize(key)
            if k == "CTRL" or k == "SHIFT" or k == "ALT" then
                f.modifiers[k] = false
                return
            end
            if f.mainKey == k then
                local mapping = f.mapping or currentMapping()
                self._keyCapture = nil
                f:Hide()
                if entry.onCommit ~= nil then
                    entry.onCommit(mapping)
                end
            end
        end)

        frame:Hide()
        self.captureFrame = frame
    end

    frame.resetCapture()
    self._keyCapture = config
    frame:Show()
    local label = config.label
    if type(label) == "function" then
        label = label()
    end
    if label ~= nil then
        self:_speak(label)
    end
end
