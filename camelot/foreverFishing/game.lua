-- Everything this addon asks of the game, of Forever Fishing and of WowVision, in one table, so the tests can replace it.
--
-- Forever Fishing is never changed and nothing of it is copied: this addon only asks its public global
-- (ForeverFishing), reads what its window writes, calls the methods its own /fish command and Gear button call
-- (ToggleUI, ToggleCustomGear), and listens (hooks run after its own code) when its window shows, hides or puts up a
-- message.
local ns = WowVision.foreverFishing
local L = ns.L

local Game = {}
ns.Game = Game

-- The name of the WowVision window this addon opens.
Game.WINDOW = "foreverFishing"

-- An error here must never break a key or an event, and must not repeat on every press either: each distinct message once.
local reported = {}
function Game.report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("Forever Fishing with WowVision: " .. err)
end

function Game.guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            Game.report(err)
        end
    end
end

function Game.speak(text)
    if text == nil or text == "" then
        return
    end
    local wowVision = rawget(_G, "WowVision")
    if wowVision ~= nil and wowVision.speak ~= nil then
        wowVision:speak(text)
    else
        print(text)
    end
end

-- ------------------------------------------------------- Forever Fishing

local function ff()
    local addon = rawget(_G, "ForeverFishing")
    if type(addon) == "table" then
        return addon
    end
    return nil
end

local function isSecret(value)
    local check = rawget(_G, "issecretvalue")
    return check ~= nil and check(value) == true
end

local function plain(value)
    return type(value) == "string" and value ~= "" and not isSecret(value)
end

-- The text of a font string (or of a frame's .text), or nil when it is empty, hidden or secret.
local function textOf(region)
    if type(region) ~= "table" or type(region.GetText) ~= "function" then
        return nil
    end
    local ok, text = pcall(region.GetText, region)
    if ok and plain(text) then
        return text
    end
    return nil
end

local function shown(region)
    if type(region) ~= "table" or type(region.IsShown) ~= "function" then
        return false
    end
    local ok, value = pcall(region.IsShown, region)
    return ok and value == true
end

function Game.available()
    local addon = ff()
    return addon ~= nil and type(addon.ToggleUI) == "function" and type(addon.bar) == "table"
end

function Game.isOpen()
    local addon = ff()
    return addon ~= nil and addon.bar ~= nil and shown(addon.bar)
end

function Game.inCombat()
    return InCombatLockdown ~= nil and InCombatLockdown() == true
end

-- Every shown text under a frame, in the order the game lists them (the regions, then the children), skipping what is
-- only digits and signs (a count without its meaning).
local function scrape(frame, out, seen, depth)
    if type(frame) ~= "table" or depth > 4 or not shown(frame) then
        return
    end
    if type(frame.GetRegions) == "function" then
        local ok, regions = pcall(function()
            return { frame:GetRegions() }
        end)
        if ok then
            for _, region in ipairs(regions) do
                if shown(region) and type(region.GetObjectType) == "function" and region:GetObjectType() == "FontString" then
                    local text = textOf(region)
                    if text ~= nil and not text:match("^[%d%s%p]*$") and not seen[text] then
                        seen[text] = true
                        out[#out + 1] = text
                    end
                end
            end
        end
    end
    if type(frame.GetChildren) == "function" then
        local ok, children = pcall(function()
            return { frame:GetChildren() }
        end)
        if ok then
            for _, child in ipairs(children) do
                scrape(child, out, seen, depth + 1)
            end
        end
    end
end

-- What the window writes: the status line (hint), the skill (label), gold per hour, the cast countdown, and
-- whatever else is on it or on its notices.
function Game.texts()
    local addon = ff()
    if addon == nil then
        return {}
    end
    local out = { others = {} }
    local button = addon.castButton
    if type(button) == "table" then
        if shown(button.hint) then
            out.hint = textOf(button.hint)
        end
        if shown(button.label) then
            out.label = textOf(button.label)
        end
        local gold = button.fishingGold
        if type(gold) == "table" and shown(gold) then
            out.gold = textOf(gold.text)
        end
        if shown(button.fishingSeconds) then
            out.seconds = textOf(button.fishingSeconds)
        end
    end
    local seen = {}
    for _, value in ipairs({ out.hint, out.label, out.gold, out.seconds }) do
        if value ~= nil then
            seen[value] = true
        end
    end
    local found = {}
    for _, frame in ipairs({ addon.bar, addon.toolBar, addon.masterChefPreparationNotice, addon.fishingRodNotice, addon.rangeNotice }) do
        scrape(frame, found, seen, 0)
    end
    for index = 1, math.min(#found, 8) do
        out.others[index] = found[index]
    end
    return out
end

function Game.inputKey()
    local addon = ff()
    if addon == nil or type(addon.GetFishingInputKey) ~= "function" then
        return nil
    end
    local ok, key = pcall(addon.GetFishingInputKey, addon)
    if ok and plain(key) then
        return key
    end
    return nil
end

function Game.rod()
    local addon = ff()
    if addon == nil then
        return nil
    end
    if addon.fishingRodEquipped then
        return "equipped"
    elseif addon.fishingRodInBags then
        return "bags"
    elseif addon.fishingRodEquipped == nil and addon.fishingRodInBags == nil then
        return nil
    end
    return "none"
end

local function setting(name)
    local addon = ff()
    if addon == nil or type(addon.db) ~= "table" then
        return nil
    end
    local value = addon.db[name]
    if value == nil then
        return nil
    end
    return value == true
end

function Game.gearOn()
    return setting("gearSwapActive")
end

function Game.autoEquip()
    return setting("autoEquipGear")
end

function Game.autoRestore()
    return setting("autoRestoreGear")
end

-- ------------------------------------------------- the worth of the session

-- What the session caught: { { id =, count = }, ... } in item order, or nil without a session. Forever Fishing keeps
-- them in its session's records, by item id (the same list its own gold per hour adds up).
function Game.sessionRecords()
    local addon = ff()
    local session = addon ~= nil and addon.session or nil
    if type(session) ~= "table" or type(session.records) ~= "table" then
        return nil
    end
    local list = {}
    for key, record in pairs(session.records) do
        local id = tonumber(key)
        local count = type(record) == "table" and tonumber(record.count) or nil
        if id ~= nil and count ~= nil and count > 0 and count < math.huge then
            list[#list + 1] = { id = id, count = count }
        end
    end
    table.sort(list, function(a, b)
        return a.id < b.id
    end)
    return list
end

-- Seconds of active fishing in the session (Forever Fishing's own clock, which stops while you do something else).
function Game.sessionSeconds()
    local addon = ff()
    if addon == nil or type(addon.CurrentSessionSeconds) ~= "function" then
        return 0
    end
    local ok, seconds = pcall(addon.CurrentSessionSeconds, addon)
    if ok and type(seconds) == "number" then
        return seconds
    end
    return 0
end

-- WowVision's auction hints (camelot/auctionHints), when that module is there: it values items with Life on Azeroth
-- Market's prices and the vendor's.
local function auctionHints()
    local hints = WowVision.auctionHints
    if hints ~= nil and hints.valueOfItem ~= nil and hints.game ~= nil and hints.game.itemInfo ~= nil then
        return hints
    end
    return nil
end

-- The worth of each item id, from the auction hints, or from the vendor's price alone without them. results[id] =
-- { unit, how } or false while the game has not loaded the item.
function Game.values(ids)
    local hints = auctionHints()
    if hints ~= nil then
        local ok, results, meta = pcall(function()
            local snapshot, problem = hints.market.snapshot()
            local found = {}
            for _, id in ipairs(ids) do
                found[id] = hints.valueOfItem(id, snapshot) or false
            end
            local about = { problem = problem, sentences = {} }
            if snapshot ~= nil then
                about.sentences = hints.priceSentences(snapshot, time())
            end
            return found, about
        end)
        if ok then
            return results, meta
        end
        Game.report(results)
    end
    local results = {}
    local get = C_Item ~= nil and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    for _, id in ipairs(ids) do
        local price = nil
        if get ~= nil then
            local ok, name, _, _, _, _, _, _, _, _, _, sell = pcall(get, id)
            if ok and plain(name) and type(sell) == "number" and not isSecret(sell) then
                price = sell
            end
        end
        if price ~= nil then
            results[id] = { unit = price, how = price > 0 and "vendor" or "none" }
        else
            results[id] = false
        end
    end
    return results, { problem = "noaddon", sentences = {} }
end

-- An amount of copper as the game says it.
function Game.coinText(copper)
    local currency = rawget(_G, "C_CurrencyInfo")
    if type(currency) == "table" and type(currency.GetCoinText) == "function" then
        local ok, text = pcall(currency.GetCoinText, copper, " ")
        if ok and plain(text) then
            return text
        end
    end
    return tostring(copper)
end

-- /fish: opens the window and equips the fishing gear, or closes it and puts the normal gear back.
function Game.toggleUI()
    local addon = ff()
    if addon ~= nil and type(addon.ToggleUI) == "function" then
        addon:ToggleUI()
    end
end

-- The Gear button's left click: equip the fishing gear, or put the normal gear back.
function Game.toggleGear()
    local addon = ff()
    if addon ~= nil and type(addon.ToggleCustomGear) == "function" then
        addon:ToggleCustomGear()
    end
end

-- Forever Fishing's own words about its window, for the screen (nil when it has none).
function Game.localized(key)
    local addon = ff()
    if addon ~= nil and type(addon.LocalizedText) == "function" then
        local ok, text = pcall(addon.LocalizedText, addon, key)
        if ok and plain(text) and text ~= key then
            return text
        end
    end
    return nil
end

Game.quiet = false
function Game.setQuiet(value)
    Game.quiet = value == true
end

-- ------------------------------------------------------------- the hooks

-- handlers: shown(), hidden(), notice(message, kind), warning(message). Installed once, when Forever Fishing's window
-- exists (it is made a moment after the player logs in). True when installed.
function Game.installHooks(handlers)
    local addon = ff()
    if addon == nil or type(addon.bar) ~= "table" then
        return false
    end
    if Game.hookedBar == addon.bar then
        return true
    end
    local bar = addon.bar
    if type(bar.HookScript) ~= "function" then
        return false
    end
    bar:HookScript("OnShow", Game.guarded(function()
        handlers.shown()
    end))
    bar:HookScript("OnHide", Game.guarded(function()
        handlers.hidden()
    end))
    if hooksecurefunc ~= nil then
        if type(addon.ShowPreparationStatusNotice) == "function" then
            hooksecurefunc(addon, "ShowPreparationStatusNotice", Game.guarded(function(_, message, kind)
                handlers.notice(message, kind)
            end))
        end
        if type(addon.ShowFishingWarning) == "function" then
            hooksecurefunc(addon, "ShowFishingWarning", Game.guarded(function(_, message)
                handlers.warning(message)
            end))
        end
    end
    Game.hookedBar = bar
    return true
end

-- ------------------------------------------------------------- the window

local function host()
    local wowVision = rawget(_G, "WowVision")
    return wowVision ~= nil and wowVision.UIHost or nil
end

function Game.isScreenOpen()
    local current = host()
    local manager = current ~= nil and current.windowManager or nil
    if manager == nil then
        return false
    end
    for _, instance in ipairs(manager.openWindows) do
        if instance.name == Game.WINDOW then
            return true
        end
    end
    return false
end

-- Opens the frameless graph window. screen is the graphScreen config (render, onRequestClose...).
function Game.openScreen(screen)
    local current = host()
    if current == nil then
        return false
    end
    current:openTemporaryWindow({ name = Game.WINDOW, graphScreen = screen })
    return true
end

function Game.closeScreen()
    local current = host()
    if current ~= nil then
        current:closeWindow(Game.WINDOW)
    end
end
