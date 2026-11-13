-- Helpers for values the game hands addons as SECRETS (Retail from Midnight
-- on, and WoW: Forever, which runs the same engine). Comparing, measuring or
-- string-processing a secret throws; truthiness and concatenation work, and
-- the speech API accepts secret strings. Pure Lua so the headless tests run
-- it; clients without secrets (classic) see every guard collapse to a plain
-- check.
local secrets = {}
WowVision.secrets = secrets

function secrets.isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

-- Whether a value changed between two reads. A secret on either side cannot
-- be compared, and the events that deliver secrets already mean "changed",
-- so it reads as a change. Callers that poll must use another change signal
-- (the event) while the value is secret, or they would fire every tick.
function secrets.changed(old, new)
    if secrets.isSecret(old) or secrets.isSecret(new) then
        return true
    end
    return old ~= new
end

-- Whether a string has anything to say: nil and "" do not; a secret string
-- is taken to (its length cannot be read, and speech accepts it as is).
function secrets.hasText(text)
    if not text then
        return false
    end
    if secrets.isSecret(text) then
        return true
    end
    return text ~= ""
end

-- "" when the number is zero or nil, else prefix .. whole number .. suffix.
-- A secret number goes through the game's string utilities, which take it
-- (C_StringUtil.TruncateWhenZero, WrapString); without them nothing can be
-- said about it.
function secrets.whenNonZero(number, prefix, suffix)
    if number == nil then
        return ""
    end
    if secrets.isSecret(number) then
        if C_StringUtil ~= nil and C_StringUtil.TruncateWhenZero ~= nil and C_StringUtil.WrapString ~= nil then
            return C_StringUtil.WrapString(C_StringUtil.TruncateWhenZero(number), prefix, suffix)
        end
        return ""
    end
    local whole = math.floor(number)
    if whole == 0 then
        return ""
    end
    return prefix .. whole .. suffix
end

-- "" when the text is empty or nil, else prefix .. text .. suffix. A secret
-- string goes through WrapString, which drops it when empty.
function secrets.whenText(text, prefix, suffix)
    if text == nil then
        return ""
    end
    if secrets.isSecret(text) then
        if C_StringUtil ~= nil and C_StringUtil.WrapString ~= nil then
            return C_StringUtil.WrapString(text, prefix, suffix)
        end
        return prefix .. text .. suffix
    end
    if text == "" then
        return ""
    end
    return prefix .. text .. suffix
end

-- table.concat refuses secret strings; concatenation carries them through.
-- Joins a list of strings with a separator the same way.
function secrets.join(list, separator)
    local text = ""
    for index, item in ipairs(list) do
        if index == 1 then
            text = item
        else
            text = text .. separator .. item
        end
    end
    return text
end

-- A yes or no from a game function that may hide its answer (a secret) or
-- refuse the call (the restricted unit APIs throw). true or false when the
-- answer can be read; otherwise nil and why: "missing" (no such function),
-- "refused" or "hidden". Only a plain true counts as yes.
function secrets.readBool(fn, ...)
    if fn == nil then
        return nil, "missing"
    end
    local ok, value = pcall(fn, ...)
    if not ok then
        return nil, "refused"
    end
    if secrets.isSecret(value) then
        return nil, "hidden"
    end
    return value == true
end
