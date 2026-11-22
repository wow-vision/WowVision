-- Ping Target (unbound by default): the game's own ping on your target, as BlindSlash's pingtarget does. The game
-- plays the ping's sound from where the target stands, so with headphones you hear whether it is left or right of
-- you; WowVision then says how far it is. Pinging is restricted (C_Ping.SendMacroPing), so it is a secure macro:
-- /ping [@target] sends nothing without a target (the game's /ping handler returns when a conditional finds no
-- unit), and the /run line says "No target" then. The ping goes to the group like any ping: members see it and read
-- it in chat. BlindSlash says the range only when it changed; here every press says it.

local pingTarget = {}
WowVision.pingTarget = pingTarget

-- What is said on a press. api: { exists, isFriend, inCombat, getRange (min, max), isSecret, L }. getRange may throw
-- or answer secrets; then only the ping speaks. A friendly target in combat is not ranged: LibRangeCheck's friendly
-- checks are protected there (as in range.lua).
function pingTarget.announcement(api)
    local L = api.L
    local exists = api.exists("target")
    if api.isSecret(exists) then
        return nil
    end
    if not exists then
        return L["No target"]
    end
    if api.inCombat() then
        local friend = api.isFriend("player", "target")
        if api.isSecret(friend) or friend then
            return nil
        end
    end
    local ok, minRange, maxRange = pcall(api.getRange, "target")
    if not ok or api.isSecret(minRange) or api.isSecret(maxRange) then
        return nil
    end
    if maxRange ~= nil then
        return string.format(L["%d yards"], maxRange)
    end
    if minRange ~= nil then
        return string.format(L["more than %d yards"], minRange)
    end
    return nil
end

local module = WowVision.base ~= nil and WowVision.base.targeting or nil
if module == nil or module.registerBinding == nil then
    return
end
local L = module.L
local rangeCheck = LibStub("LibRangeCheck-3.0", true)

local gameApi = {
    exists = function(unit)
        return UnitExists(unit)
    end,
    isFriend = function(a, b)
        return UnitIsFriend(a, b)
    end,
    inCombat = function()
        return InCombatLockdown()
    end,
    getRange = function(unit)
        if rangeCheck == nil then
            return nil, nil
        end
        return rangeCheck:GetRange(unit)
    end,
    isSecret = WowVision.isSecret,
    L = L,
}

function module:announcePing()
    local text = pingTarget.announcement(gameApi)
    if text ~= nil then
        WowVision:speak(text)
    end
end

-- The ping system is on Retail and WoW: Forever; a client without it (C_Ping) only hears the distance, as a /ping
-- line there would be an unknown command. The command goes by the game's own name for it (its slash commands are
-- registered under these globals, localized ones too).
local script = "/run WowVision.base.targeting:announcePing()"
if C_Ping ~= nil then
    script = script .. "\n" .. (SLASH_PING1 or "/ping") .. " [@target]"
end

module:registerBinding({
    type = "Script",
    key = "pingTarget",
    label = L["Ping Target"],
    inputs = {},
    script = script,
})
