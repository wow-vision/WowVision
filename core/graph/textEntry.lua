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
