-- Pure helpers for the errors module: no WoW API, so the headless runner
-- covers them.
local utils = {}
WowVision.errors = { utils = utils }

local PLACEHOLDER = "%%[%-%+%d%.%$]*[sdfioxXcug]"

-- The template's fixed text: placeholders and whitespace stripped. Empty
-- means the template carries no wording of its own ("%s"), so it cannot name
-- the error.
function utils.templateLiteral(template)
    if template == nil then
        return ""
    end
    local stripped = template:gsub(PLACEHOLDER, "")
    stripped = stripped:gsub("%s+", "")
    return stripped
end

-- A template as a readable label: every placeholder becomes an ellipsis.
function utils.prettifyTemplate(template)
    if template == nil then
        return nil
    end
    return (template:gsub(PLACEHOLDER, "…"))
end

-- The filter identity and list label for one message.
-- errorName is the global string name from GetGameMessageInfo
-- (ERR_OUT_OF_RANGE): stable across patches and clients, unlike the numeric
-- message type, which Blizzard renumbers. Errors whose template has wording
-- collapse to one entry however the placeholders fill ("... has died.");
-- wordless templates and untyped messages (SYSMSG, external) key by text.
function utils.identify(errorName, template, message)
    if errorName ~= nil and utils.templateLiteral(template) ~= "" then
        return errorName, utils.prettifyTemplate(template)
    end
    if errorName ~= nil then
        return errorName .. ":" .. message, message
    end
    return "text:" .. message, message
end

-- Repeat suppression: one key speaks at most once per delay seconds.
-- Suppressed repeats do not extend the window, so holding a key down still
-- speaks the error again once the delay has passed.
local Throttle = {}
Throttle.__index = Throttle

function utils.newThrottle()
    return setmetatable({ last = {} }, Throttle)
end

function Throttle:allow(key, now, delay)
    if delay == nil or delay <= 0 then
        return true
    end
    local last = self.last[key]
    if last ~= nil and now - last < delay then
        return false
    end
    self.last[key] = now
    return true
end

-- One message can reach us twice in the same frame: from the event we
-- listen to and from the UIErrorsFrame display hook. The first one wins.
local FrameDedupe = {}
FrameDedupe.__index = FrameDedupe

function utils.newFrameDedupe()
    return setmetatable({ time = nil, seen = {} }, FrameDedupe)
end

function FrameDedupe:first(message, now)
    if self.time ~= now then
        self.time = now
        self.seen = {}
    end
    if self.seen[message] then
        return false
    end
    self.seen[message] = true
    return true
end
