-- Sharpie's Gear Judge (by SuperSharpie), the third-party addon that judges whether an item would improve your
-- character, for the item up for a group loot roll: one key says "Gold Band, upgrade of 4.2 percent, instead of
-- Old Ring", instead of the whole tooltip. Optional (OptionalDeps in the TOCs): without it this file stops here, so
-- there is no key. The Judge only draws its verdict on the game's own tooltips, which the keyboard does not reach
-- during a roll; only its public interface is used here (SharpiesGearJudgeAPI, from its version 3.2.7).
local loaded = WowVision.loadedAddons
if loaded == nil or not (loaded["SharpiesGearJudge"] or loaded["sharpiesgearjudge"]) then
    return
end

local module = WowVision.base.windows.loot:createModule("gearJudge")
local L = module.L
module:setLabel(L["Gear Judge"])

-- Languages that write 1,5 rather than 1.5: the speech engine reads the comma as a decimal mark and the point as the
-- word "point".
local DECIMAL_COMMA = { frFR = true, deDE = true, esES = true, esMX = true, itIT = true, ptBR = true, ruRU = true }

-- The game and the Judge ----------------------------------------------------------

local game = {}
module.game = game

local function usable(value)
    return value ~= nil and not WowVision.secrets.isSecret(value)
end

function game.api()
    local api = SharpiesGearJudgeAPI
    if type(api) == "table" then
        return api
    end
    return nil
end

-- The items up for a roll, in the order WowVision's own roll keys take their windows (the first visible one first):
-- { { link = the item's link or nil, name = the window's own text or nil } }.
function game.rolls()
    local rolls = {}
    for i = 1, 6 do
        local frame = _G["GroupLootFrame" .. i]
        if frame ~= nil and frame:IsVisible() then
            local roll = {}
            if frame.rollID ~= nil and GetLootRollItemLink ~= nil then
                local ok, link = pcall(GetLootRollItemLink, frame.rollID)
                if ok and usable(link) and type(link) == "string" then
                    roll.link = link
                end
            end
            if frame.Name ~= nil then
                local ok, name = pcall(frame.Name.GetText, frame.Name)
                if ok and usable(name) then
                    roll.name = name
                end
            end
            tinsert(rolls, roll)
        end
    end
    return rolls
end

-- The game's name for an item, nil while the game has not loaded it.
function game.itemName(link)
    local get = (C_Item ~= nil and C_Item.GetItemInfo) or GetItemInfo
    if get == nil then
        return nil
    end
    local ok, name = pcall(get, link)
    if ok and usable(name) and name ~= "" then
        return name
    end
    return nil
end

function game.requestItem(link)
    local id = tonumber(link:match("item:(%d+)"))
    if id ~= nil and C_Item ~= nil and C_Item.RequestLoadItemDataByID ~= nil then
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
end

function game.after(seconds, func)
    C_Timer.After(seconds, func)
end

function game.locale()
    return GetLocale()
end

-- The words ------------------------------------------------------------------------

-- A percentage as it is spoken: one decimal at most, no ".0", never a minus sign (the sentence says which way).
local function spokenNumber(value, locale)
    local text = string.format("%.1f", math.abs(value)):gsub("%.0$", "")
    if DECIMAL_COMMA[locale] then
        text = text:gsub("%.", ",")
    end
    return text
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function nameOf(link)
    local name = game.itemName(link)
    if name == nil then
        name = link:match("%[(.-)%]")
    end
    return name
end

-- The Judge's reasons for giving no score, and "OLD" when it has no public interface.
local REASONS = {
    NOT_USABLE = L["your class cannot use it"],
    NOT_EQUIPPABLE = L["it is not equipment"],
    NOT_READY = L["Gear Judge is not ready yet"],
    NOT_CACHED = L["the item is not loaded yet"],
    BAD_LINK = L["Gear Judge cannot read that item"],
    OLD = L["Gear Judge is too old: version 3.2.7 or later is needed."],
}

-- Asks the Judge about an item link: its result, or nil and a reason.
function module:score(link)
    local api = game.api()
    if api == nil or type(api.ScoreItem) ~= "function" then
        return nil, "OLD"
    end
    if type(api.IsReady) == "function" then
        local ok, ready = pcall(api.IsReady)
        if ok and ready == false then
            return nil, "NOT_READY"
        end
    end
    local ok, result, reason = pcall(api.ScoreItem, link)
    if not ok then
        geterrorhandler()(result)
        return nil, "ERROR"
    end
    if type(result) ~= "table" then
        return nil, reason or "ERROR"
    end
    return result
end

-- What the Judge's answer means for the player, without the item's name.
function module:verdict(result, reason)
    if result == nil then
        return REASONS[reason] or L["Gear Judge reported an error"]
    end
    if result.equipped == true then
        return L["you already wear it"]
    end
    local percent = result.upgradePct
    local text
    if finite(percent) then
        if tonumber(string.format("%.1f", percent)) == 0 then
            text = L["no change"]
        elseif percent > 0 then
            text = string.format(L["upgrade of %s percent"], spokenNumber(percent, game.locale()))
        else
            text = string.format(L["downgrade of %s percent"], spokenNumber(percent, game.locale()))
        end
    elseif finite(result.upgrade) then
        -- No percentage when the character's own score is 0 (nothing worn yet): the points still say which way.
        if result.upgrade > 0 then
            text = L["an upgrade"]
        elseif result.upgrade < 0 then
            text = L["a downgrade"]
        else
            text = L["no change"]
        end
    else
        return L["Gear Judge gave no figure"]
    end
    local replaced = result.equippedLink
    if replaced == nil or replaced == "" then
        return text .. ", " .. L["empty slot"]
    end
    local name = nameOf(replaced)
    if name ~= nil and name ~= "" then
        text = text .. ", " .. string.format(L["instead of %s"], name)
    end
    return text
end

-- The sentence for one roll: the item's name, then the verdict. The second value is true when the game has not loaded
-- the item yet, so it is worth asking again in a moment.
function module:line(roll)
    local name = roll.name
    local verdict, retry
    if roll.link == nil then
        verdict = REASONS.BAD_LINK
    else
        name = nameOf(roll.link) or name
        local result, reason = self:score(roll.link)
        verdict = self:verdict(result, reason)
        retry = result == nil and reason == "NOT_CACHED"
    end
    if name ~= nil and name ~= "" then
        return name .. ", " .. verdict, retry
    end
    return verdict, retry
end

-- The keys -------------------------------------------------------------------------

-- How many times, and how often, the key asks again for an item the game has not loaded yet.
module.RETRIES = 4
module.RETRY_DELAY = 0.5

-- Each press is a new request, which ends the retries of the one before.
local latest = 0

local function ask(roll, attempt, request)
    local text, retry = module:line(roll)
    if retry and attempt < module.RETRIES then
        if attempt == 0 then
            WowVision:speak(L["The item is loading."])
            game.requestItem(roll.link)
        end
        game.after(module.RETRY_DELAY, function()
            if request == latest then
                ask(roll, attempt + 1, request)
            end
        end)
        return
    end
    WowVision:speak(text)
end

local function openRolls()
    latest = latest + 1
    local rolls = game.rolls()
    if #rolls == 0 then
        WowVision:notify(L["No loot."])
        return nil
    end
    return rolls
end

-- The item of the first roll window.
function module:sayFirst()
    local rolls = openRolls()
    if rolls ~= nil then
        ask(rolls[1], 0, latest)
    end
end

-- The item of every roll window, one after the other.
function module:sayAll()
    local rolls = openRolls()
    if rolls == nil then
        return
    end
    local lines = {}
    for position, roll in ipairs(rolls) do
        local text, retry = self:line(roll)
        if retry then
            game.requestItem(roll.link)
        end
        tinsert(lines, string.format(L["Item %d of %d"], position, #rolls) .. ", " .. text)
    end
    WowVision:speak(table.concat(lines, ". "))
end

-- Alt+Ctrl+J, next to WowVision's roll keys (Alt+Ctrl+Y reads the tooltip, U, I and O answer).
module:registerBinding({
    type = "Function",
    key = "loot/gearJudge",
    inputs = { "ALT-CTRL-J" },
    label = L["Roll Gear Judge Verdict"],
    interruptSpeech = true,
    func = function()
        module:sayFirst()
    end,
})

module:registerBinding({
    type = "Function",
    key = "loot/gearJudgeAll",
    inputs = {},
    label = L["All Rolls Gear Judge Verdicts"],
    interruptSpeech = true,
    func = function()
        module:sayAll()
    end,
})
