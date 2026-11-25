-- The logic, with no call into the game or into Forever Fishing: what the popup says and what the player can do with
-- it, worked out from a "game" table handed in (so the tests give it a stand-in). Main.lua, Screen.lua and Menu.lua
-- call these.
--
-- game: available() -> Forever Fishing is there and its window exists; isOpen() -> the window is shown;
-- inCombat(); texts() -> { hint =, label =, gold =, seconds =, others = {...} } (what is written on it);
-- inputKey() -> the fishing key or nil; rod() -> "equipped" | "bags" | "none" | nil (not known yet);
-- gearOn() -> true | false | nil; autoEquip(), autoRestore() -> true | false | nil;
-- toggleUI() opens or closes the window (Forever Fishing's own /fish); toggleGear() equips or restores (its Gear button);
-- setQuiet(boolean) holds back the "window closed" announcement while we close it ourselves.
local ns = WowVision.foreverFishing
local L = ns.L

local Fishing = {}
ns.Fishing = Fishing

-- "SHIFT-F7" -> "Maj+F7" (the words of the game's language)
function Fishing.keyName(input)
    if type(input) ~= "string" or input == "" then
        return ""
    end
    local parts = {}
    for part in input:gmatch("[^%-]+") do
        local upper = part:upper()
        if upper == "SHIFT" then
            parts[#parts + 1] = L["Shift"]
        elseif upper == "CTRL" then
            parts[#parts + 1] = L["Ctrl"]
        elseif upper == "ALT" then
            parts[#parts + 1] = L["Alt"]
        else
            parts[#parts + 1] = part
        end
    end
    return table.concat(parts, "+")
end

-- Everything the game says about the window, read once.
function Fishing.read(game)
    local info = { available = game.available() == true }
    if not info.available then
        return info
    end
    info.open = game.isOpen() == true
    info.combat = game.inCombat() == true
    info.rod = game.rod()
    info.gearOn = game.gearOn()
    info.autoEquip = game.autoEquip()
    info.autoRestore = game.autoRestore()
    if info.open then
        local texts = game.texts() or {}
        info.hint, info.skill, info.gold, info.seconds = texts.hint, texts.label, texts.gold, texts.seconds
        info.others = {}
        local known = {}
        for _, value in ipairs({ texts.hint, texts.label, texts.gold, texts.seconds }) do
            if value ~= nil then
                known[value] = true
            end
        end
        for _, value in ipairs(texts.others or {}) do
            if not known[value] then
                known[value] = true
                info.others[#info.others + 1] = value
            end
        end
        info.key = game.inputKey()
    end
    -- the session's worth from Life on Azeroth Market and the vendor's prices (Value.lua), when it can be told: open
    -- or not, a session that caught something is worth saying
    info.valueLines = {}
    if ns.Value ~= nil then
        local ok, estimate = pcall(ns.Value.estimate, game)
        if ok and estimate ~= nil then
            info.estimate = estimate
            local built, lines = pcall(ns.Value.lines, game, estimate)
            if built then
                info.valueLines = lines
            end
        end
    end
    return info
end

local function rodLine(info)
    if info.rod == "equipped" then
        return L["Fishing rod equipped."]
    elseif info.rod == "bags" then
        return L["Fishing rod in your bags, not equipped."]
    elseif info.rod == "none" then
        return L["No fishing rod found."]
    end
    return nil
end

-- The lines the screen shows and the key says, in reading order: what is written on the window first, then the state
-- of the gear. Each line is { key =, text = }.
function Fishing.lines(info)
    local lines = {}
    local function add(key, text)
        if text ~= nil and text ~= "" then
            lines[#lines + 1] = { key = key, text = text }
        end
    end
    if not info.available then
        add("unavailable", L["Forever Fishing is not installed or not ready."])
        return lines
    end
    if not info.open then
        add("closed", L["The fishing window is closed. Start fishing opens it and equips the fishing gear."])
        add("rod", rodLine(info))
        if info.gearOn == true then
            add("gear", L["Fishing gear is on."])
        end
        -- what the session caught so far is worth saying after the window closed
        if info.estimate ~= nil and info.estimate.catches > 0 then
            for _, line in ipairs(info.valueLines or {}) do
                add(line.key, line.text)
            end
        end
        return lines
    end
    if info.hint ~= nil then
        add("status", string.format(L["Status: %s"], info.hint))
    end
    add("rod", rodLine(info))
    if info.gearOn == true then
        add("gear", L["Fishing gear is on."])
    elseif info.gearOn == false then
        add("gear", L["Your normal gear is on."])
    end
    if info.autoEquip == true and info.autoRestore ~= false then
        add("auto", L["Automatic gear: on, your gear is put back when the window closes."])
    elseif info.autoEquip == true then
        add("auto", L["Automatic gear: on, but your gear is not put back when the window closes."])
    elseif info.autoEquip == false then
        add("auto", L["Automatic gear: off, equip your fishing gear yourself."])
    end
    if info.key ~= nil and info.key ~= "" then
        add("key", string.format(L["Fishing key: %s"], Fishing.keyName(info.key)))
    elseif info.key == nil then
        add("key", L["No fishing key is set."])
    end
    if info.skill ~= nil then
        add("skill", string.format(L["Skill: %s"], info.skill))
    end
    if info.valueLines ~= nil and #info.valueLines > 0 then
        -- our own figures: Life on Azeroth Market and the vendor, not Forever Fishing's (Auctionator or TSM only)
        for _, line in ipairs(info.valueLines) do
            add(line.key, line.text)
        end
    elseif info.gold ~= nil then
        add("gold", string.format(L["Gold per hour: %s"], info.gold))
    end
    if info.seconds ~= nil then
        add("seconds", string.format(L["Cast: %s"], info.seconds))
    end
    for index, text in ipairs(info.others or {}) do
        add("other:" .. index, string.format(L["Other information: %s"], text))
    end
    return lines
end

-- All the lines as one text, for the command and the key.
function Fishing.sentence(info)
    local texts = {}
    for _, line in ipairs(Fishing.lines(info)) do
        texts[#texts + 1] = line.text
    end
    return table.concat(texts, " ")
end

-- ----------------------------------------------------------------- actions

-- Opens the fishing window the way /fish does (Forever Fishing then equips the fishing gear). speak: how to say it.
function Fishing.start(game, speak, keyName)
    local info = Fishing.read(game)
    if not info.available then
        speak(L["Forever Fishing is not installed or not ready."])
        return false
    end
    if info.combat then
        speak(L["Not possible during combat."])
        return false
    end
    if info.open then
        speak(string.format(L["You are already fishing: the fishing window is open. Press %s to read it."], keyName))
        return false
    end
    speak(L["Start fishing"])
    game.toggleUI()
    if not game.isOpen() then
        speak(L["The fishing window did not open."])
        return false
    end
    return true
end

-- Closes the window (Forever Fishing puts the normal gear back by itself when its automatic gear is on).
function Fishing.close(game, speak)
    local info = Fishing.read(game)
    if not info.available then
        speak(L["Forever Fishing is not installed or not ready."])
        return false
    end
    if not info.open then
        speak(L["The fishing window is not open."])
        return false
    end
    if info.combat then
        speak(L["Not possible during combat."])
        return false
    end
    game.setQuiet(true)
    local ok, err = pcall(game.toggleUI)
    game.setQuiet(false)
    if not ok then
        error(err, 0)
    end
    if info.autoRestore ~= false and info.autoEquip ~= false then
        speak(L["Fishing window closed. Your normal gear is being put back."])
    else
        speak(L["Fishing window closed."])
    end
    return true
end

-- The Gear button of the window: equip the fishing gear, or put the normal gear back.
function Fishing.gear(game, speak)
    local info = Fishing.read(game)
    if not info.available then
        speak(L["Forever Fishing is not installed or not ready."])
        return false
    end
    if not info.open then
        speak(L["The fishing window is not open."])
        return false
    end
    if info.combat then
        speak(L["Not possible during combat."])
        return false
    end
    game.toggleGear()
    speak(L["Changing your gear."])
    return true
end

-- What is said when the window opens: that it did, what it says, and the key.
function Fishing.openedText(info, keyName)
    local parts = { L["Fishing window opened."] }
    if info.hint ~= nil then
        parts[#parts + 1] = info.hint .. "."
    end
    if keyName ~= nil and keyName ~= "" then
        parts[#parts + 1] = string.format(L["Press %s to read it, equip the fishing gear, put your gear back or close it."], keyName)
    end
    return table.concat(parts, " ")
end

-- The messages of the window that are said by themselves: the results of the gear change and the warnings.
local NOTICE_KINDS = { gear = true, gearFailure = true, gearRestore = true }
function Fishing.noticeWanted(kind)
    return NOTICE_KINDS[kind] == true
end
