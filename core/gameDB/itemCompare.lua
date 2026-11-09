local L = WowVision:getLocale()

-- What an item tooltip says after the game's own lines (and the quality and item level of itemQuality.lua), in two
-- parts that read as sentences of their own, so the line keys (Shift+Down) walk them one by one. The whole-tooltip
-- key (Space) reads Pawn's lines with the rest and leaves the comparison out:
--
--   * Pawn's upgrade summary, one line per scale the item is an upgrade for: "Pawn: Hunter: Marksmanship, upgrade of
--     12 percent, over Rusty Helm". Pawn is optional; its functions are looked up when a tooltip is read.
--   * a comparison with the item worn in the same slot (both rings, both trinkets, a one-hand weapon against the off
--     hand when that holds a weapon): "Compared to equipped: Rusty Helm", the item level difference, then every stat
--     that differs.
--
-- Amounts are spelled out ("5 more", "3 less") rather than "+5" and "-3": speech engines read a bare minus sign
-- inconsistently. Everything that touches the game or Pawn is wrapped in pcall and degrades to "add nothing".
local items = WowVision.items

-- Which of the two parts are on ("pawn", "equipped"); the Compare module (UI > Tooltip) replaces this with its
-- switches.
function items.compareEnabled(part)
    return true
end

local function isSecret(value)
    return WowVision.secrets ~= nil and WowVision.secrets.isSecret(value) == true
end

local function usable(value)
    return value ~= nil and not isSecret(value)
end

-- "item:1234:0:..." out of a full hyperlink, so two links to the same item compare equal whatever colour code or
-- bracketed name they carry.
local function itemKey(link)
    if type(link) ~= "string" then
        return nil
    end
    return link:match("|H(item:[^|]*)|h") or link:match("^(item:[%-%d:]*)")
end

-- Locales that write 1,5 rather than 1.5: the speech engine reads the comma as a decimal mark and the point as the
-- word "point".
local DECIMAL_COMMA = { frFR = true, deDE = true, esES = true, itIT = true, ptBR = true, ruRU = true }

local function formatNumber(value)
    local rounded = math.floor(value * 10 + 0.5) / 10
    local text
    if rounded == math.floor(rounded) then
        text = string.format("%d", rounded)
    else
        text = string.format("%.1f", rounded)
    end
    if GetLocale ~= nil and DECIMAL_COMMA[GetLocale()] then
        text = (text:gsub("%.", ","))
    end
    return text
end

local function amountText(diff)
    if diff > 0 then
        return string.format(L["%s more"], formatNumber(diff))
    end
    return string.format(L["%s less"], formatNumber(-diff))
end

-- ----------------------------------------------------------------- game API

local function itemInfo(link)
    local get = (C_Item ~= nil and C_Item.GetItemInfo) or GetItemInfo
    if get == nil then
        return nil
    end
    local ok, name, _, quality = pcall(get, link)
    if not ok or not usable(name) then
        return nil
    end
    return name, quality
end

local function instantEquipLoc(link)
    local get = (C_Item ~= nil and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if get == nil then
        return nil
    end
    local ok, _, _, _, equipLoc = pcall(get, link)
    if ok and usable(equipLoc) and equipLoc ~= "" then
        return equipLoc
    end
    return nil
end

local function itemLevel(link)
    local get = (C_Item ~= nil and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
    if get == nil then
        return nil
    end
    local ok, level = pcall(get, link)
    if ok and usable(level) and type(level) == "number" and level > 0 then
        return level
    end
    return nil
end

local function statsOf(link)
    local get = (C_Item ~= nil and C_Item.GetItemStats) or GetItemStats
    if get == nil then
        return {}
    end
    local ok, stats = pcall(get, link)
    if ok and type(stats) == "table" then
        return stats
    end
    return {}
end

local function equippedLink(slot)
    if GetInventoryItemLink == nil then
        return nil
    end
    local ok, link = pcall(GetInventoryItemLink, "player", slot)
    if ok and usable(link) and link ~= "" then
        return link
    end
    return nil
end

-- An item as it is named in the lists: "Name, Colour". The bracketed name in the link covers an item the client has
-- not cached.
local function itemLabel(link)
    local name, quality = itemInfo(link)
    if name == nil and type(link) == "string" then
        name = link:match("%[(.-)%]")
    end
    if name == nil then
        return nil
    end
    local ok, label = pcall(items.formatName, name, quality)
    if ok and label ~= nil then
        return label
    end
    return name
end

-- ------------------------------------------------------------------- slots

local SLOTS = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 },
}

local RANGED = {
    INVTYPE_RANGED = true,
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_THROWN = true,
    INVTYPE_RELIC = true,
}

-- Classic-era clients (WoW: Forever included) have a slot of their own for ranged weapons; retail wields them in the
-- main hand. Pawn knows which.
local function rangedSlot()
    if PawnGetSlotsForItemType ~= nil then
        local ok, slot = pcall(PawnGetSlotsForItemType, "INVTYPE_RANGED")
        if ok and slot ~= nil then
            return slot
        end
    end
    if GetInventorySlotInfo ~= nil then
        local ok, slot = pcall(GetInventorySlotInfo, "RANGEDSLOT")
        if ok and slot ~= nil then
            return slot
        end
    end
    return 16
end

-- The inventory slots an item of this equip location goes into, or nil when it is not gear worth comparing (bags,
-- ammo, shirts, tabards).
function items.compareSlots(equipLoc)
    if equipLoc == nil then
        return nil
    end
    if RANGED[equipLoc] then
        return { rangedSlot() }
    end
    local slots = SLOTS[equipLoc]
    if slots == nil then
        return nil
    end
    local copy = {}
    for i, slot in ipairs(slots) do
        copy[i] = slot
    end
    -- A one-hand weapon is only compared with the off hand when that holds a weapon too; against a shield, or an
    -- empty hand, it says nothing useful.
    if equipLoc == "INVTYPE_WEAPON" then
        local off = equippedLink(17)
        local offLoc = off ~= nil and instantEquipLoc(off) or nil
        if offLoc ~= "INVTYPE_WEAPON" and offLoc ~= "INVTYPE_WEAPONOFFHAND" then
            copy = { 16 }
        end
    end
    return copy
end

-- ------------------------------------------------------- stat differences

-- Armor and damage first, then the main stats; everything else by name.
local PRIORITY = {
    "RESISTANCE0_NAME",
    "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
}
local PRIORITY_INDEX = {}
for index, key in ipairs(PRIORITY) do
    PRIORITY_INDEX[key] = index
end

-- The keys of GetItemStats are the names of global strings in the client's language ("Stamina", "Armor").
local function statLabel(key)
    local label = _G[key]
    if type(label) == "string" and label ~= "" then
        return label
    end
    local text = key:gsub("^ITEM_MOD_", ""):gsub("_SHORT$", ""):gsub("_NAME$", ""):gsub("_", " ")
    return text:lower()
end

-- { { key, label, diff }, ... } for every stat that differs, candidate minus equipped, in reading order. Only numeric
-- values count.
function items.statDifferences(candidate, equipped)
    local keys = {}
    for key in pairs(candidate) do
        keys[key] = true
    end
    for key in pairs(equipped) do
        keys[key] = true
    end
    local diffs = {}
    for key in pairs(keys) do
        local new, old = candidate[key], equipped[key]
        if type(new) ~= "number" then
            new = 0
        end
        if type(old) ~= "number" then
            old = 0
        end
        local diff = new - old
        if math.abs(diff) >= 0.05 then
            tinsert(diffs, { key = key, label = statLabel(key), diff = diff })
        end
    end
    table.sort(diffs, function(a, b)
        local pa, pb = PRIORITY_INDEX[a.key] or 1000, PRIORITY_INDEX[b.key] or 1000
        if pa ~= pb then
            return pa < pb
        end
        return a.label < b.label
    end)
    return diffs
end

-- ----------------------------------------------------- comparison lines

local function compareGroup(candidateStats, candidateLevel, equipped, index, count)
    local out = {}
    local prefix = count > 1 and (string.format(L["Slot %d of %d:"], index, count) .. " ") or ""
    if equipped == nil then
        out[1] = prefix .. L["Nothing equipped in this slot"]
        return out
    end
    out[1] = prefix .. string.format(L["Compared to equipped: %s"], itemLabel(equipped) or L["unknown item"])

    local equippedLevel = itemLevel(equipped)
    if candidateLevel ~= nil and equippedLevel ~= nil then
        local diff = candidateLevel - equippedLevel
        out[#out + 1] = string.format(L["%s: %s"], L["Item level"], diff == 0 and L["same"] or amountText(diff))
    end

    local diffs = items.statDifferences(candidateStats, statsOf(equipped))
    if #diffs == 0 then
        out[#out + 1] = L["No difference in stats"]
    end
    for _, entry in ipairs(diffs) do
        out[#out + 1] = string.format(L["%s: %s"], entry.label, amountText(entry.diff))
    end
    return out
end

-- The sentences comparing an item with what is worn in its slot(s), or nil when it is not gear, or is the worn item.
function items.comparisonLines(link)
    local equipLoc = instantEquipLoc(link)
    local slots = items.compareSlots(equipLoc)
    if slots == nil then
        return nil
    end

    local candidateKey = itemKey(link)
    local candidateStats = statsOf(link)
    local candidateLevel = itemLevel(link)

    -- Slots holding this very item are left out (it is the one worn); a slot holding another item is compared, an
    -- empty one is announced. When the item is the worn one (read from the character window), an empty slot beside
    -- it is not news: the other ring slot, say.
    local worn = {}
    local isWorn = false
    for index, slot in ipairs(slots) do
        worn[index] = equippedLink(slot)
        if worn[index] ~= nil and itemKey(worn[index]) == candidateKey then
            isWorn = true
        end
    end
    local targets = {}
    for index in ipairs(slots) do
        local wornLink = worn[index]
        if wornLink == nil then
            if not isWorn then
                tinsert(targets, false)
            end
        elseif itemKey(wornLink) ~= candidateKey then
            tinsert(targets, wornLink)
        end
    end
    if #targets == 0 then
        return nil
    end

    local lines = {}
    for index, target in ipairs(targets) do
        for _, text in ipairs(compareGroup(candidateStats, candidateLevel, target or nil, index, #targets)) do
            lines[#lines + 1] = text
        end
    end

    -- A two-hander takes the off hand off as well.
    if equipLoc == "INVTYPE_2HWEAPON" then
        local off = equippedLink(17)
        if off ~= nil then
            lines[#lines + 1] = string.format(L["Also takes off the off hand: %s"], itemLabel(off) or L["unknown item"])
        end
    end
    return lines
end

-- ---------------------------------------------------------------- Pawn

-- The texture Pawn puts in front of an upgrade annotation. The text of every upgrade line Pawn writes into a tooltip
-- carries it, and nothing else does.
local PAWN_ARROW = "UpgradeArrow"

local function isItemLevelLine(text)
    if ITEM_LEVEL == nil then
        return false
    end
    local prefix = ITEM_LEVEL:match("^(.-)%%d")
    return prefix ~= nil and prefix ~= "" and text:find(prefix, 1, true) == 1
end

local function isPawnUpgradeLine(line)
    for column = 1, 2 do
        local text = line[column]
        if type(text) == "string" and usable(text) and text:find(PAWN_ARROW, 1, true) then
            -- Pawn also hangs its arrow on the game's own item level line; that line is the item level, not a Pawn
            -- line.
            if not (column == 1 and isItemLevelLine(text)) then
                return true
            end
        end
    end
    return false
end

-- Pawn's own upgrade lines are replaced by ours, which say what they replace and read cleanly; keeping both would
-- announce each upgrade twice. Its other lines (the best item, the values) stay.
function items.removePawnUpgradeLines(lines)
    local removed = 0
    for index = #lines, 1, -1 do
        if isPawnUpgradeLine(lines[index]) then
            table.remove(lines, index)
            removed = removed + 1
        end
    end
    return removed
end

-- One sentence per scale the item upgrades, or nil when Pawn is missing, does not know the item, or finds no upgrade.
function items.pawnUpgradeLines(link)
    if PawnGetItemData == nil or PawnIsItemAnUpgrade == nil or PawnCommon == nil then
        return nil
    end
    local ok, item = pcall(PawnGetItemData, link)
    if not ok or type(item) ~= "table" then
        return nil
    end
    local ok2, upgrades = pcall(PawnIsItemAnUpgrade, item)
    if not ok2 or type(upgrades) ~= "table" or #upgrades == 0 then
        return nil
    end

    local big = PawnBigUpgradeThreshold or 100
    local lines = {}
    for _, upgrade in ipairs(upgrades) do
        local scale = upgrade.LocalizedScaleName or upgrade.ScaleName
        local percent = upgrade.PercentUpgrade
        local amount
        if type(percent) ~= "number" or percent >= big then
            amount = L["big upgrade"]
        else
            amount = string.format(L["upgrade of %d percent"], math.floor(percent * 100 + 0.5))
        end
        local text = string.format(L["Pawn: %s, %s"], tostring(scale), amount)
        if upgrade.ExistingItemLink ~= nil then
            local name = itemLabel(upgrade.ExistingItemLink)
            if name ~= nil then
                text = text .. ", " .. string.format(L["over %s"], name)
            end
        end
        lines[#lines + 1] = text
    end
    return lines
end

-- ------------------------------------------------------------------- entry

-- Adds the lines to an item tooltip's { left, right } list, in place (see Tooltip:collectLines). A link that is not
-- usable text (a secret, a missing item) leaves the tooltip alone.
function items.augmentComparisonLines(lines, link)
    if type(link) ~= "string" or not usable(link) then
        return
    end

    if items.compareEnabled("pawn") then
        local pawn = items.pawnUpgradeLines(link)
        if pawn ~= nil then
            items.removePawnUpgradeLines(lines)
            for _, text in ipairs(pawn) do
                lines[#lines + 1] = { text, nil }
            end
        end
    end

    -- Marked like the game's comparison (Tooltip:addComparison): reading the whole tooltip at once stays with the
    -- item, the line keys walk on into the comparison, and the block keys jump to its start.
    if items.compareEnabled("equipped") then
        local comparison = items.comparisonLines(link)
        if comparison ~= nil then
            for index, text in ipairs(comparison) do
                lines[#lines + 1] = { text, nil, compare = true, blockStart = index == 1 or nil }
            end
        end
    end
end
