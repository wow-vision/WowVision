local utils = {}

function utils.splitString(str, delim)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delim, from, true)
    while delim_from do
        tinsert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from, true)
    end
    tinsert(result, string.sub(str, from))
    return result
end

-- Lowercase for case-insensitive matching. Lua's lower() only folds ASCII,
-- so on its own a capital umlaut or accented capital never matches its
-- small form ("Öl" against "öl"). This also folds the accented Latin
-- capitals of German and French, which UTF-8 writes as two bytes:
--   U+00C0..U+00DE (lead byte 195, second byte 128..158) -> second byte + 32
--     (not U+00D7, the multiplication sign)
--   U+0152 OE ligature and U+0178 Y with diaeresis
-- Accents are kept: "ö" does not match "o". Strings without those bytes,
-- which is nearly every English name, take the plain lower() path only.
local function foldLatin1(second)
    if second == "\151" then
        return nil
    end
    return "\195" .. string.char(string.byte(second) + 32)
end

function utils.foldCase(text)
    local lowered = string.lower(text)
    if string.find(lowered, "\195", 1, true) ~= nil then
        lowered = string.gsub(lowered, "\195([\128-\158])", foldLatin1)
    end
    if string.find(lowered, "\197", 1, true) ~= nil then
        lowered = string.gsub(lowered, "\197\146", "\197\147")
        lowered = string.gsub(lowered, "\197\184", "\195\191")
    end
    return lowered
end

-- The units of the player's side of a fight: you and your pet, then the
-- group's members and their pets. In a party "player" is you and party1 to
-- party4 are the others; in a raid raid1 to raid40 include you. Pets are
-- partypetN and raidpetN. inRaid, inGroup: IsInRaid() and IsInGroup().
local SOLO_UNITS = { "player", "pet" }
local PARTY_UNITS = { "player", "pet" }
for i = 1, 4 do
    tinsert(PARTY_UNITS, "party" .. i)
    tinsert(PARTY_UNITS, "partypet" .. i)
end
local RAID_UNITS = { "player", "pet" }
for i = 1, 40 do
    tinsert(RAID_UNITS, "raid" .. i)
    tinsert(RAID_UNITS, "raidpet" .. i)
end

function utils.groupUnits(inRaid, inGroup)
    if inRaid then
        return RAID_UNITS
    elseif inGroup then
        return PARTY_UNITS
    end
    return SOLO_UNITS
end

-- Whether you or your group (pets included) are fighting a unit, for the
-- "Target in Combat" sound. Only a unit you can attack counts: yourself, a
-- group member or another friendly unit is never a fight, even when its
-- target is one of you. Then three signs, any one is enough:
--   1. a group unit is on its threat list (UnitThreatSituation not nil; a
--      secret answer is not nil either, so it counts);
--   2. it targets a group unit (its "target" unit is one of them);
--   3. in a group: it is in combat, attackable and not tapped by anyone
--      else (UnitIsTapDenied false), so the fight is your group's.
-- The threat list of a mob you have not hit yet reaches the client only
-- after you target it, so on a target change sign 1 misses a fight only
-- your group is in; signs 2 and 3 are known at once. A secret answer to
-- signs 2 and 3 (Forever and Retail hide identities in combat) counts as
-- no, and so does a secret answer to whether you can attack it. api: the game reads (tests pass fakes), the globals by default.
local function plainTrue(value)
    if issecretvalue ~= nil and issecretvalue(value) then
        return false
    end
    return value == true or value == 1
end

-- Sign 3 on its own, shared with the enemy count: a unit in combat
-- (UnitAffectingCombat) that nobody outside the group has tapped
-- (UnitIsTapDenied false) is the group's fight. A missing or secret answer
-- to either counts as no. isSecret: the secret check to use (the globals'
-- issecretvalue by default; tests pass their own).
function utils.groupTapped(inCombat, tapDenied, isSecret)
    isSecret = isSecret or function(value)
        return issecretvalue ~= nil and issecretvalue(value)
    end
    if isSecret(inCombat) or not (inCombat == true or inCombat == 1) then
        return false
    end
    return tapDenied ~= nil and not isSecret(tapDenied) and not tapDenied
end

function utils.groupFighting(unit, api)
    api = api or _G
    local function read(name, ...)
        local fn = api[name]
        if fn == nil then
            return nil
        end
        local ok, result = pcall(fn, ...)
        if not ok then
            return nil
        end
        return result
    end
    local inRaid = plainTrue(read("IsInRaid"))
    local inGroup = plainTrue(read("IsInGroup"))
    local members = utils.groupUnits(inRaid, inGroup)
    if not plainTrue(read("UnitExists", unit)) or not plainTrue(read("UnitCanAttack", "player", unit)) then
        return false
    end
    local existing = {}
    for _, member in ipairs(members) do
        if plainTrue(read("UnitExists", member)) then
            tinsert(existing, member)
            if read("UnitThreatSituation", member, unit) ~= nil then
                return true
            end
        end
    end
    local victim = unit .. "target"
    if plainTrue(read("UnitExists", victim)) then
        for _, member in ipairs(existing) do
            if plainTrue(read("UnitIsUnit", victim, member)) then
                return true
            end
        end
    end
    if inGroup or inRaid then
        if utils.groupTapped(read("UnitAffectingCombat", unit), read("UnitIsTapDenied", unit)) then
            return true
        end
    end
    return false
end

-- Money in tooltip text. The game writes coins as an amount followed by a
-- coin texture ("12 |T...UI-GoldIcon...|t 5 |T...UI-SilverIcon...|t"), and
-- speech drops the textures, leaving bare numbers. Some lines carry only a
-- bare number after the sell price label; that number is copper, the
-- game's money unit.
local COIN_FACTORS = { gold = 10000, silver = 100, copper = 1 }
local COIN_AMOUNT = "([%d%.,']+)%s*(|[TA].-|[ta])"

local function coinKind(escape)
    local lower = escape:lower()
    for kind in pairs(COIN_FACTORS) do
        if lower:find(kind, 1, true) then
            return kind
        end
    end
    return nil
end

-- Digits only: thousands separators (1.234 or 1,234) are dropped.
local function amountNumber(amount)
    return tonumber((amount:gsub("[^%d]", "")))
end

local function patternEscape(text)
    return (text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- The line rewritten with its money spoken by coinText (copper -> text,
-- C_CurrencyInfo.GetCoinText in the game), or nil when it has none.
-- sellLabel is the game's sell price label (SELL_PRICE); after it a bare
-- number counts as copper.
function utils.moneyLineText(text, sellLabel, coinText)
    if type(text) ~= "string" then
        return nil
    end
    local first, last, total = nil, nil, 0
    local position = 1
    while true do
        local s, e, amount, escape = text:find(COIN_AMOUNT, position)
        if s == nil then
            break
        end
        local kind = coinKind(escape)
        local number = amountNumber(amount)
        if kind ~= nil and number ~= nil then
            first = first or s
            last = e
            total = total + number * COIN_FACTORS[kind]
        end
        position = e + 1
    end
    if first ~= nil then
        local before = text:sub(1, first - 1):gsub("%s+$", "")
        local after = text:sub(last + 1)
        local spoken = coinText(total)
        if before ~= "" then
            spoken = before .. " " .. spoken
        end
        return spoken .. after
    end
    if type(sellLabel) == "string" and sellLabel ~= "" then
        local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local label, amount = plain:match("^%s*(" .. patternEscape(sellLabel) .. ":?)%s*([%d%.,']+)%s*$")
        local number = amount ~= nil and amountNumber(amount) or nil
        if number ~= nil then
            return label .. " " .. coinText(number)
        end
    end
    return nil
end

-- Runs func(...) so that an error in it never stops the caller: one failing
-- part of the frame (a module's update, an object type, the windows) must
-- not leave the rest dead. The error still goes to the game's error handler
-- (BugGrabber, WowVision's error list and its spoken alert), called from
-- inside the failing call so its stack is kept, but once per part and
-- message: a part that fails every frame would otherwise report 60 times a
-- second and bury every other line of speech (Screen:buildRender reports a
-- failing render once the same way). key names the part; any value works.
-- Returns xpcall's results.
local reportedErrors = setmetatable({}, { __mode = "k" })
local errorReporters = setmetatable({}, { __mode = "k" })
local MAX_MESSAGES_PER_PART = 20

local function reporterFor(key)
    local reporter = errorReporters[key]
    if reporter == nil then
        reporter = function(message)
            local seen = reportedErrors[key]
            if seen == nil then
                seen = { count = 0 }
                reportedErrors[key] = seen
            end
            local text = tostring(message)
            if not seen[text] and seen.count < MAX_MESSAGES_PER_PART then
                seen[text] = true
                seen.count = seen.count + 1
                geterrorhandler()(message)
            end
            return message
        end
        errorReporters[key] = reporter
    end
    return reporter
end

function utils.guardedCall(key, func, ...)
    return xpcall(func, reporterFor(key), ...)
end

WowVision.utils = utils
