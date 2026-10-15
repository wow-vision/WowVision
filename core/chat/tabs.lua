-- Chat tabs: the game's own chat windows decide which messages each tab
-- receives (the chat settings, per tab); WowVision only decides how a tab
-- is spoken. The rules here are pure so the headless tests run them; the
-- name readers at the end ask the game.
local L = WowVision:getLocale()
local chatTabs = {}
WowVision.chatTabs = chatTabs

-- Permanent chat windows (ChatFrame1..N). Temporary windows -- a whisper
-- popped out into its own tab, the pet battle log -- are numbered above.
chatTabs.MAX_WINDOWS = (
    Constants ~= nil
    and Constants.ChatFrameConstants ~= nil
    and Constants.ChatFrameConstants.MaxChatWindows
) or NUM_CHAT_WINDOWS or 10

-- The message store holding every line of the whisper tabs, across partners.
chatTabs.WHISPERS_KEY = "chat.whispers"

function chatTabs.storeKey(index)
    return "chat." .. index
end

-- A temporary tab the game opened for one conversation (whisperMode
-- "popout" or "popout_and_inline", or "Whisper in new tab" from a menu).
function chatTabs.isWhisperWindow(frame)
    return frame.isTemporary == true and (frame.chatType == "WHISPER" or frame.chatType == "BN_WHISPER")
end

-- "shown": speak while the tab is on screen (the selected docked tab, or an
-- undocked window); "always": speak whatever the tab receives.
function chatTabs.shouldSpeak(mode, shown)
    return mode == "always" or shown == true
end

-- One message reaches every tab that receives it, all in the same frame.
-- Its identity across tabs: the event's line ID (never secret), else the
-- text of a line the game added without an event (connection notices).
-- A secret text without a line ID has no identity: it is not deduplicated.
function chatTabs.lineKey(eventArgs, text)
    local lineID = type(eventArgs) == "table" and eventArgs[11] or nil
    if type(lineID) == "number" then
        return "line:" .. lineID
    end
    if type(text) == "string" and not WowVision.secrets.isSecret(text) then
        return "text:" .. text
    end
    return nil
end

-- The first tab to speak a message claims it; the other tabs stay quiet.
-- Claims only live for one moment (every tab handles the event in the same
-- frame), and never silence the claiming tab itself: two equal lines in one
-- tab (the same combat log hit twice) are two messages.
function chatTabs.newClaims()
    local claims = { time = nil, owners = {} }
    function claims:claim(key, now, tab)
        if now ~= self.time then
            self.time = now
            self.owners = {}
        end
        local owner = self.owners[key]
        if owner ~= nil and owner ~= tab then
            return false
        end
        self.owners[key] = tab
        return true
    end
    return claims
end

-- A tab's name as the game shows it. A whisper tab is named after the
-- partner, which can be a secret: it is passed on, never inspected.
function chatTabs.tabName(frame)
    local name = frame.name
    if not WowVision.secrets.hasText(name) then
        local tab = _G[frame:GetName() .. "Tab"]
        name = tab ~= nil and tab:GetText() or nil
    end
    if not WowVision.secrets.hasText(name) then
        return L["Chat Tab %d"]:format(frame:GetID())
    end
    return name
end

-- A permanent window's saved name, for settings and buffer choices.
function chatTabs.tabLabel(index)
    local name = GetChatWindowInfo(index)
    if name == nil or name == "" then
        return L["Chat Tab %d"]:format(index)
    end
    return name
end
