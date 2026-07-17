local graph = WowVision.graph
local GraphHost = graph.GraphHost

-- Typed text entry through one shared edit box: keyboard focus swallows keys
-- while it is up, Enter commits, Escape or focus loss cancels.
-- config: { label = string|function?, text = string?, onCommit = function, onCancel = function? }
function GraphHost:openTextEntry(config)
    local frame = self.editFrame
    if frame == nil then
        frame = CreateFrame("EditBox", "WowVisionGraphTextEntry", UIParent)
        frame:SetSize(300, 20)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
        frame:SetFontObject(ChatFontNormal)
        frame:SetAlpha(0)
        frame:SetAutoFocus(false)
        local function finish(f, committed)
            local entry = self._textEntry
            self._textEntry = nil
            f:ClearFocus()
            f:Hide()
            if entry == nil then
                return
            end
            if committed then
                if entry.onCommit ~= nil then
                    entry.onCommit(f:GetText())
                end
            elseif entry.onCancel ~= nil then
                entry.onCancel()
            end
        end
        frame:SetScript("OnEnterPressed", function(f)
            finish(f, true)
        end)
        frame:SetScript("OnEscapePressed", function(f)
            finish(f, false)
        end)
        frame:SetScript("OnEditFocusLost", function(f)
            finish(f, false)
        end)
        -- Tab commits and moves on, exactly like the real edit boxes'
        -- hooked OnTabPressed -- without this the entry box traps Tab.
        frame:SetScript("OnTabPressed", function(f)
            local previous = IsShiftKeyDown()
            finish(f, true)
            self:onKey(previous and "previous" or "next")
        end)
        -- Speak the content as it changes, like the live watch does for
        -- real edit boxes (this shared box is not a graph node, so nothing
        -- else is watching it). Interrupt first: each keystroke should read
        -- the latest content, not queue behind the previous one.
        frame:SetScript("OnTextChanged", function(f, userInput)
            if userInput then
                WowVision.base.speech:uiStop()
                local text = f:GetText()
                if text ~= nil and text ~= "" then
                    self:_speak(text)
                end
            end
        end)
        self.editFrame = frame
    end
    self._textEntry = config
    frame:SetText(config.text or "")
    frame:Show()
    frame:SetFocus()
    frame:HighlightText()
    local label = config.label
    if type(label) == "function" then
        label = label()
    end
    if label ~= nil then
        self:_speak(label)
    end
    if config.text ~= nil and config.text ~= "" then
        self:_speak(config.text)
    end
end
