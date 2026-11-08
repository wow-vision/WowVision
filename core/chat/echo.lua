-- The addon's own messages, written to the chat as well (the setting "Addon
-- Messages in Chat" of the chat module, off by default). A message is what
-- WowVision reports by itself: a route started, a scan's progress, why
-- something did not work. That is WowVision:notify. Reading things out (menus,
-- targets, tooltips, what a key asks for) and alerts stay WowVision:speak and
-- never reach the chat. Speech is what matters: a line that cannot be written
-- never gets in its way.
--
-- An echoed line passes the chat module's own hook on the frame. `active` is
-- true for exactly that call: the hook stores the line like any other (the
-- chat window and the chat buffers read the stores), but does not speak it a
-- second time.
local echo = { active = false }
WowVision.chatEcho = echo

local PREFIX = "WowVision: "

local function addLine(frame, text)
    frame:AddMessage(PREFIX .. text)
end

-- Writes one line to frame. True when it was written.
function echo.send(frame, text)
    if frame == nil or not WowVision.secrets.hasText(text) then
        return false
    end
    echo.active = true
    local ok, err = pcall(addLine, frame, text)
    echo.active = false
    if not ok then
        geterrorhandler()(err)
    end
    return ok
end

-- The addon reported text: the chat module writes it if it is set to.
function echo.spoken(text)
    local chat = WowVision.base ~= nil and WowVision.base.chat or nil
    if chat ~= nil and chat.echoSpoken ~= nil then
        chat:echoSpoken(text)
    end
end

-- A message of the addon: spoken like everything else, then offered to the chat.
function WowVision:notify(text, voice)
    self:speak(text, voice)
    echo.spoken(text)
end
