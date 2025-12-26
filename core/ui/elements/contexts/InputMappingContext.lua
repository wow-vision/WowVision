local Context, parent = WowVision.ui:CreateElementType("InputMappingContext", "Context")

-- Define InfoClass fields at class level
Context.info:addFields({
    {
        key = "currentMapping",
        default = "",
        getValueString = function(obj, value)
            return value
        end,
    },
})

-- Add currentMapping to liveFields with "always" mode (announce as it builds)
Context.liveFields.currentMapping = "always"

function Context:initialize()
    parent.initialize(self)

    -- Add events
    self:addEvent("mappingComplete")
    self:addEvent("mappingCancelled")

    -- State tracking
    self.modifiers = { CTRL = false, SHIFT = false, ALT = false }
    self.mainKey = nil
    self.isCapturing = false

    -- Create keyboard input frame
    self:createInputFrame()
end

function Context:createInputFrame()
    self.inputFrame = CreateFrame("Frame")
    self.inputFrame:EnableKeyboard(true)
    -- DO NOT propagate - we want exclusive capture for mapping
    self.inputFrame:SetPropagateKeyboardInput(false)

    self.inputFrame:SetScript("OnKeyDown", function(frame, key)
        self:handleKeyDown(key)
    end)

    self.inputFrame:SetScript("OnKeyUp", function(frame, key)
        self:handleKeyUp(key)
    end)

    self.inputFrame:Hide() -- Hidden until focused
end

function Context:normalizeKey(key)
    -- Convert LCTRL/RCTRL to CTRL, etc.
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

function Context:handleKeyDown(key)
    local normalizedKey = self:normalizeKey(key)

    -- Check for Escape - cancel mapping
    if normalizedKey == "ESCAPE" then
        self:emitEvent("mappingCancelled", self)
        self:resetState()
        return
    end

    -- Check if it's a modifier
    if normalizedKey == "CTRL" or normalizedKey == "SHIFT" or normalizedKey == "ALT" then
        self.modifiers[normalizedKey] = true
    else
        -- Non-modifier key - this is the main key
        -- Defense: double-check it's truly not a modifier (in case WoW sends weird key codes)
        if not self.mainKey and normalizedKey ~= "CTRL" and normalizedKey ~= "SHIFT" and normalizedKey ~= "ALT" then
            self.mainKey = normalizedKey
        end
    end
end

function Context:handleKeyUp(key)
    local normalizedKey = self:normalizeKey(key)

    -- Check if it's a modifier
    if normalizedKey == "CTRL" or normalizedKey == "SHIFT" or normalizedKey == "ALT" then
        self.modifiers[normalizedKey] = false
    else
        -- Non-modifier key released - finalize if it's our main key
        if self.mainKey == normalizedKey then
            self:finalizeMapping()
        end
    end
end

function Context:buildAndUpdateMapping()
    local parts = {}

    -- Add modifiers in WoW API required order: ALT, CTRL, SHIFT
    if self.modifiers.ALT then
        tinsert(parts, "ALT")
    end
    if self.modifiers.CTRL then
        tinsert(parts, "CTRL")
    end
    if self.modifiers.SHIFT then
        tinsert(parts, "SHIFT")
    end

    -- Add main key if present
    if self.mainKey then
        tinsert(parts, self.mainKey)
    end

    -- Update the prop (will trigger live announcement)
    self:setProp("currentMapping", table.concat(parts, "-"))
end

function Context:finalizeMapping()
    if not self.mainKey then
        -- No main key, invalid mapping
        self:resetState()
        return
    end

    -- Prevent modifiers from being valid mappings on their own
    -- Normalize to catch LCTRL/RCTRL variants
    local normalizedMainKey = self:normalizeKey(self.mainKey)
    if normalizedMainKey == "CTRL" or normalizedMainKey == "SHIFT" or normalizedMainKey == "ALT" then
        -- Modifier-only mapping not allowed
        self:resetState()
        return
    end

    -- Build the final mapping string
    self:buildAndUpdateMapping()
    local finalMapping = self:getProp("currentMapping")

    -- Fire the mappingComplete event
    self:emitEvent("mappingComplete", self, finalMapping)

    -- Reset for next capture
    self:resetState()
end

function Context:resetState()
    self.modifiers = { CTRL = false, SHIFT = false, ALT = false }
    self.mainKey = nil
    self:setProp("currentMapping", "")
end

function Context:onFocus(key)
    parent.onFocus(self, key)
    self.inputFrame:Show()
    self.isCapturing = true
    self:resetState()
end

function Context:onUnfocus()
    parent.onUnfocus(self)
    self.inputFrame:Hide()
    self.isCapturing = false
    self:resetState()
end

function Context:getLabel()
    return nil
end
