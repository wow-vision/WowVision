local testRunner = WowVision.testing.testRunner
local items = WowVision.items

-- Item tooltips after the game's own lines (itemCompare.lua): Pawn's upgrade summary and the comparison with what is
-- worn. The game and Pawn are stand-ins. Strings read back as their English keys, like AceLocale's fallback.

local GLOBALS = {
    "C_Item",
    "GetInventoryItemLink",
    "GetInventorySlotInfo",
    "GetLocale",
    "ITEM_LEVEL",
    "RESISTANCE0_NAME",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    "PawnGetItemData",
    "PawnIsItemAnUpgrade",
    "PawnCommon",
    "PawnBigUpgradeThreshold",
    "PawnGetSlotsForItemType",
}

-- Runs fn(world) with a fake client, then puts every global back. world.add(id, name, quality, equipLoc, ilvl, stats)
-- defines an item; world.equipped[slot] = id wears one.
local function inWorld(fn)
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
    end
    -- the quality colour in a name (itemQuality.lua) asks WowVision.isSecret, which WowVision.lua defines in the game
    local savedIsSecret = WowVision.isSecret
    WowVision.isSecret = function(value)
        return WowVision.secrets.isSecret(value)
    end
    local db, equipped = {}, {}
    local world = { equipped = equipped }
    function world.add(id, name, quality, equipLoc, ilvl, stats)
        db[id] = { name = name, quality = quality, equipLoc = equipLoc, ilvl = ilvl, stats = stats or {} }
    end
    function world.link(id)
        return "|cff1eff00|Hitem:" .. id .. ":0:0:0|h[" .. db[id].name .. "]|h|r"
    end
    local function idOf(link)
        return tonumber(tostring(link):match("item:(%d+)"))
    end
    C_Item = {
        GetItemInfo = function(link)
            local item = db[idOf(link)]
            if item == nil then
                return nil
            end
            return item.name, link, item.quality, item.ilvl, 1, "Armor", "Cloth", 1, item.equipLoc
        end,
        GetItemInfoInstant = function(link)
            local item = db[idOf(link)]
            if item == nil then
                return nil
            end
            return idOf(link), "Armor", "Cloth", item.equipLoc or ""
        end,
        GetDetailedItemLevelInfo = function(link)
            local item = db[idOf(link)]
            return item and item.ilvl or nil
        end,
        GetItemStats = function(link)
            local copy = {}
            local item = db[idOf(link)]
            for key, value in pairs(item and item.stats or {}) do
                copy[key] = value
            end
            return copy
        end,
    }
    GetInventoryItemLink = function(_, slot)
        local id = equipped[slot]
        return id ~= nil and world.link(id) or nil
    end
    GetInventorySlotInfo = nil
    GetLocale = function()
        return "enUS"
    end
    ITEM_LEVEL = "Item Level %d"
    RESISTANCE0_NAME = "Armor"
    ITEM_MOD_STAMINA_SHORT = "Stamina"
    ITEM_MOD_INTELLECT_SHORT = "Intellect"
    ITEM_MOD_STRENGTH_SHORT = "Strength"
    ITEM_MOD_AGILITY_SHORT = "Agility"
    ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike"
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "Damage Per Second"
    PawnGetItemData, PawnIsItemAnUpgrade, PawnCommon, PawnBigUpgradeThreshold, PawnGetSlotsForItemType =
        nil, nil, nil, nil, nil

    -- Pawn answers with these upgrades for every item (nil = none).
    function world.pawn(upgrades)
        PawnCommon = { Scales = {} }
        PawnBigUpgradeThreshold = 100
        PawnGetItemData = function(link)
            return { Link = link }
        end
        PawnIsItemAnUpgrade = function()
            return upgrades
        end
    end

    local ok, err = pcall(fn, world)
    WowVision.isSecret = savedIsSecret
    for _, name in ipairs(GLOBALS) do
        _G[name] = saved[name]
    end
    if not ok then
        error(err, 0)
    end
end

-- The lines the comparison adds to a tooltip that already says rows (one line each, by default).
local function added(link, rows)
    local lines = {}
    for i, row in ipairs(rows or { { "An item" } }) do
        lines[i] = { row[1], row[2] }
    end
    local before = #lines
    items.augmentComparisonLines(lines, link)
    local out = {}
    for i = before + 1, #lines do
        out[#out + 1] = lines[i][1]
    end
    return out
end

local function join(list)
    return table.concat(list, " | ")
end

testRunner:addSuite("Item compare", {
    ["a better helm reads the item level and each stat that changes, main stats first"] = function(t)
        inWorld(function(w)
            w.add(100, "Old Helm", 2, "INVTYPE_HEAD", 50, {
                RESISTANCE0_NAME = 120,
                ITEM_MOD_STAMINA_SHORT = 10,
                ITEM_MOD_INTELLECT_SHORT = 4,
            })
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55, {
                RESISTANCE0_NAME = 130,
                ITEM_MOD_STAMINA_SHORT = 12,
                ITEM_MOD_CRIT_RATING_SHORT = 8,
            })
            w.equipped[1] = 100
            t:assertEqual(
                join(added(w.link(101))),
                "Compared to equipped: Old Helm, Green | Item level: 5 more | Armor: 10 more | Stamina: 2 more"
                    .. " | Intellect: 4 less | Critical Strike: 8 more"
            )
        end)
    end,

    ["a worse item reads less, equal item levels read same"] = function(t)
        inWorld(function(w)
            w.add(100, "Helm A", 2, "INVTYPE_HEAD", 50, { RESISTANCE0_NAME = 120 })
            w.add(101, "Helm B", 2, "INVTYPE_HEAD", 50, { RESISTANCE0_NAME = 118 })
            w.add(102, "Helm C", 2, "INVTYPE_HEAD", 50, { RESISTANCE0_NAME = 120 })
            w.equipped[1] = 100
            t:assertEqual(join(added(w.link(101))), "Compared to equipped: Helm A, Green | Item level: same | Armor: 2 less")
            t:assertEqual(
                join(added(w.link(102))),
                "Compared to equipped: Helm A, Green | Item level: same | No difference in stats"
            )
        end)
    end,

    ["decimals take a comma in the languages that write one"] = function(t)
        inWorld(function(w)
            w.add(100, "Axe A", 2, "INVTYPE_2HWEAPON", 50, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 40.0 })
            w.add(101, "Axe B", 2, "INVTYPE_2HWEAPON", 50, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 42.5 })
            w.equipped[16] = 100
            local lines = added(w.link(101))
            t:assertEqual(lines[#lines], "Damage Per Second: 2.5 more")
            GetLocale = function()
                return "frFR"
            end
            lines = added(w.link(101))
            t:assertEqual(lines[#lines], "Damage Per Second: 2,5 more")
        end)
    end,

    ["the item that is already worn is not compared with itself"] = function(t)
        inWorld(function(w)
            w.add(100, "Old Helm", 2, "INVTYPE_HEAD", 50, { RESISTANCE0_NAME = 120 })
            w.equipped[1] = 100
            t:assertEqual(#added(w.link(100)), 0)
        end)
    end,

    ["an empty slot is announced"] = function(t)
        inWorld(function(w)
            w.add(101, "New Helm", 2, "INVTYPE_HEAD", 55, { RESISTANCE0_NAME = 130 })
            t:assertEqual(join(added(w.link(101))), "Nothing equipped in this slot")
        end)
    end,

    ["rings are compared with both worn rings"] = function(t)
        inWorld(function(w)
            w.add(1, "Ring One", 2, "INVTYPE_FINGER", 40, { ITEM_MOD_STAMINA_SHORT = 5 })
            w.add(2, "Ring Two", 2, "INVTYPE_FINGER", 45, { ITEM_MOD_STAMINA_SHORT = 9 })
            w.add(3, "Ring New", 3, "INVTYPE_FINGER", 50, { ITEM_MOD_STAMINA_SHORT = 7 })
            w.equipped[11], w.equipped[12] = 1, 2
            t:assertEqual(
                join(added(w.link(3))),
                "Slot 1 of 2: Compared to equipped: Ring One, Green | Item level: 10 more | Stamina: 2 more"
                    .. " | Slot 2 of 2: Compared to equipped: Ring Two, Green | Item level: 5 more | Stamina: 2 less"
            )
        end)
    end,

    ["reading a worn ring does not announce the empty second ring slot"] = function(t)
        inWorld(function(w)
            w.add(1, "Ring One", 2, "INVTYPE_FINGER", 40, { ITEM_MOD_STAMINA_SHORT = 5 })
            w.equipped[11] = 1
            t:assertEqual(#added(w.link(1)), 0)
        end)
    end,

    ["a one-hand weapon is compared with the off hand only when that holds a weapon"] = function(t)
        inWorld(function(w)
            w.add(10, "Sword A", 2, "INVTYPE_WEAPON", 40, { ITEM_MOD_STRENGTH_SHORT = 5 })
            w.add(11, "Shield", 2, "INVTYPE_SHIELD", 40, { RESISTANCE0_NAME = 300 })
            w.add(12, "Sword B", 2, "INVTYPE_WEAPON", 40, { ITEM_MOD_STRENGTH_SHORT = 4 })
            w.add(13, "Sword New", 3, "INVTYPE_WEAPON", 45, { ITEM_MOD_STRENGTH_SHORT = 6 })
            w.equipped[16], w.equipped[17] = 10, 11
            t:assertEqual(
                join(added(w.link(13))),
                "Compared to equipped: Sword A, Green | Item level: 5 more | Strength: 1 more"
            )
            w.equipped[17] = 12
            local both = added(w.link(13))
            t:assertEqual(#both, 6)
            t:assertEqual(both[1], "Slot 1 of 2: Compared to equipped: Sword A, Green")
            t:assertEqual(both[4], "Slot 2 of 2: Compared to equipped: Sword B, Green")
        end)
    end,

    ["a two-hander says it also takes off the off hand"] = function(t)
        inWorld(function(w)
            w.add(20, "Axe", 2, "INVTYPE_WEAPON", 40)
            w.add(21, "Shield", 2, "INVTYPE_SHIELD", 40)
            w.add(22, "Greatsword", 3, "INVTYPE_2HWEAPON", 50)
            w.equipped[16], w.equipped[17] = 20, 21
            local lines = added(w.link(22))
            t:assertEqual(lines[#lines], "Also takes off the off hand: Shield, Green")
        end)
    end,

    ["ranged weapons go to the ranged slot Pawn names"] = function(t)
        inWorld(function(w)
            w.add(30, "Old Bow", 2, "INVTYPE_RANGED", 30, { ITEM_MOD_AGILITY_SHORT = 5 })
            w.add(31, "New Bow", 3, "INVTYPE_RANGED", 35, { ITEM_MOD_AGILITY_SHORT = 8 })
            PawnGetSlotsForItemType = function(equipLoc)
                if equipLoc == "INVTYPE_RANGED" then
                    return 18
                end
            end
            w.equipped[18] = 30
            t:assertEqual(added(w.link(31))[1], "Compared to equipped: Old Bow, Green")
        end)
    end,

    ["things that are not gear get nothing"] = function(t)
        inWorld(function(w)
            w.add(40, "Healing Potion", 1, nil, nil)
            w.add(41, "Bag", 1, "INVTYPE_BAG", nil)
            t:assertEqual(#added(w.link(40)), 0)
            t:assertEqual(#added(w.link(41)), 0)
        end)
    end,

    ["an unreadable link leaves the tooltip alone"] = function(t)
        inWorld(function(w)
            t:assertEqual(#added(nil), 0)
            local isSecret = WowVision.secrets.isSecret
            WowVision.secrets.isSecret = function()
                return true
            end
            local ok, count = pcall(function()
                return #added("item:1")
            end)
            WowVision.secrets.isSecret = isSecret
            t:assertTrue(ok)
            t:assertEqual(count, 0)
        end)
    end,

    ["a failing game API does not break the tooltip"] = function(t)
        inWorld(function(w)
            w.add(100, "Old Helm", 2, "INVTYPE_HEAD", 50, { RESISTANCE0_NAME = 120 })
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55, { RESISTANCE0_NAME = 130 })
            w.equipped[1] = 100
            C_Item.GetItemStats = function()
                error("boom")
            end
            t:assertEqual(added(w.link(101))[1], "Compared to equipped: Old Helm, Green")
        end)
    end,

    ["Pawn's upgrade becomes a sentence naming what it replaces"] = function(t)
        inWorld(function(w)
            w.add(100, "Old Helm", 2, "INVTYPE_HEAD", 50)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.equipped[1] = 100
            w.pawn({
                {
                    ScaleName = "a",
                    LocalizedScaleName = "Hunter: Marksmanship",
                    PercentUpgrade = 0.123,
                    ExistingItemLink = "item:100:0:0:0",
                },
            })
            t:assertEqual(added(w.link(101))[1], "Pawn: Hunter: Marksmanship, upgrade of 12 percent, over Old Helm, Green")
        end)
    end,

    ["one Pawn sentence per scale, big upgrades without a number, Pawn before the comparison"] = function(t)
        inWorld(function(w)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.pawn({
                { ScaleName = "a", LocalizedScaleName = "Hunter: Marksmanship", PercentUpgrade = 0.04 },
                { ScaleName = "b", LocalizedScaleName = "Hunter: Survival", PercentUpgrade = 100 },
            })
            t:assertEqual(
                join(added(w.link(101))),
                "Pawn: Hunter: Marksmanship, upgrade of 4 percent | Pawn: Hunter: Survival, big upgrade"
                    .. " | Nothing equipped in this slot"
            )
        end)
    end,

    ["no upgrade, no Pawn sentence; no Pawn, no error"] = function(t)
        inWorld(function(w)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.pawn(nil)
            t:assertEqual(join(added(w.link(101))), "Nothing equipped in this slot")
            PawnGetItemData, PawnIsItemAnUpgrade, PawnCommon = nil, nil, nil
            t:assertEqual(join(added(w.link(101))), "Nothing equipped in this slot")
        end)
    end,

    ["Pawn's own upgrade lines are replaced, its other lines and the item level stay"] = function(t)
        inWorld(function(w)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.pawn({ { ScaleName = "a", LocalizedScaleName = "Mage: Fire", PercentUpgrade = 0.2 } })
            local arrow = "|TInterface\\AddOns\\Pawn\\Textures\\UpgradeArrow:0|t"
            local lines = {
                { "New Helm" },
                { "Item Level 55  " .. arrow .. "|cff00ff00+5" },
                { " " },
                { "|cff3fc7ebMage: Fire:  " .. arrow .. "|cff00ff00+20% upgrade|r" },
                { "|cff3fc7ebMage: Frost:  12.0  (your best)" },
                { "Mage: Arcane", "12.0 " .. arrow .. " +20% upgrade" },
            }
            items.augmentComparisonLines(lines, w.link(101))
            local texts = {}
            for _, line in ipairs(lines) do
                texts[#texts + 1] = (line[1] or "") .. "|" .. (line[2] or "")
            end
            t:assertEqual(#texts, 6)
            t:assertTrue(texts[1]:find("New Helm", 1, true) == 1)
            t:assertTrue(texts[2]:find("Item Level 55", 1, true) == 1, "the item level line kept its text")
            t:assertTrue(texts[4]:find("your best", 1, true) ~= nil, "Pawn's non-upgrade line stays")
            t:assertEqual(texts[5], "Pawn: Mage: Fire, upgrade of 20 percent|")
            t:assertEqual(texts[6], "Nothing equipped in this slot|")
        end)
    end,

    ["Pawn's lines read with the tooltip, the comparison is a block of its own"] = function(t)
        inWorld(function(w)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.pawn({ { ScaleName = "a", LocalizedScaleName = "Mage: Fire", PercentUpgrade = 0.2 } })
            local lines = { { "New Helm" } }
            items.augmentComparisonLines(lines, w.link(101))
            t:assertEqual(#lines, 3)
            t:assertNil(lines[2].compare, "Pawn's line is read with the whole tooltip")
            t:assertTrue(lines[3].compare, "the comparison is left out of the whole tooltip")
            t:assertTrue(lines[3].blockStart, "the comparison starts a block")
        end)
    end,

    ["each part can be switched off"] = function(t)
        inWorld(function(w)
            w.add(100, "Old Helm", 2, "INVTYPE_HEAD", 50)
            w.add(101, "New Helm", 3, "INVTYPE_HEAD", 55)
            w.equipped[1] = 100
            w.pawn({ { ScaleName = "a", LocalizedScaleName = "Mage: Fire", PercentUpgrade = 0.2 } })
            local original = items.compareEnabled
            local on = { pawn = true, equipped = true }
            items.compareEnabled = function(part)
                return on[part]
            end
            local ok, err = pcall(function()
                t:assertEqual(#added(w.link(101)), 4, "everything on")
                on.pawn = false
                t:assertEqual(#added(w.link(101)), 3, "Pawn off: the comparison only")
                on.equipped = false
                t:assertEqual(#added(w.link(101)), 0, "both off")
                on.pawn = true
                t:assertEqual(#added(w.link(101)), 1, "Pawn only")
            end)
            items.compareEnabled = original
            if not ok then
                error(err, 0)
            end
        end)
    end,
})
