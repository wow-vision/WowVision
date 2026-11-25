-- Life on Azeroth Market's prices, read from the data the addon reads itself: the global LOA_DATA that its data addon
-- (LifeOnAzeroth_Data) fills. Market keeps its own code private, so this is the only door. No game call here but
-- through hints.game (module.lua), so the headless suite covers it (tests.lua).
--
-- What the data looks like (LifeOnAzeroth_Data/Data.lua, read 2026-11-20, v = 5):
--   LOA_DATA.built    when the companion app wrote the file (Unix time); Market shows "Prices 3 hours ago" from it
--   LOA_DATA.latest   the hour of the last snapshot inside it
--   LOA_DATA.region   "eu", "us"...
--   LOA_DATA.houses   one table per auction house, keyed "<ruleset digit><faction letter>": 0 PvP, 1 Normal,
--                     2 Roleplay, 3 Roleplay PvP; A Alliance, H Horde, B Blackwater (the neutral one)
--   houses[key].latS  one line per item, "itemID,typical,cheapest,listed,auctions,change24h": the prices are in
--                     copper PER ITEM; typical is the middle price of everything listed now, the "Typical price" of
--                     Market's item tooltip
--   houses[key].lat   the same, parsed (itemID -> {typical, ...}); Market parses it a few seconds after login and then
--                     drops latS, so either may be there
--   LOA_DATA.latS / .lat   the same for the whole region, by region, when there are no houses
-- The house is chosen the way Market's tooltip chooses it: the player's own (realm kind and faction), else the one
-- picked in Market's settings, else the first house the data has.
local hints = {}
WowVision.auctionHints = hints

-- The game's calls, filled in by module.lua (the headless tests fill in their own).
hints.game = {}

local market = {}
hints.market = market

local RULESETS = { "PvP", "Normal", "Roleplay", "Roleplay PvP" }
local FACTIONS = { A = "Alliance", H = "Horde", B = "Blackwater" }
local ORDER = { "0A", "0H", "1A", "1H", "2A", "2H", "3A", "3H" }

-- The kind of realm, from its name (Market's own rule).
function market.ruleset(realm)
    local name = type(realm) == "string" and realm:lower() or ""
    if name == "" then
        return nil
    end
    if name:find("rppvp", 1, true) or name:find("rp-pvp", 1, true) or name:find("rp pvp", 1, true) then
        return "Roleplay PvP"
    end
    if name:find("pvp", 1, true) then
        return "PvP"
    end
    if name:find("rp", 1, true) or name:find("roleplay", 1, true) then
        return "Roleplay"
    end
    return "Normal"
end

-- The key of the player's own auction house ("1H" for a Horde on a normal realm), nil when it cannot be told.
function market.ownHouse()
    local ruleset = market.ruleset(hints.game.realmName())
    local faction = hints.game.faction()
    local letter = faction == "Alliance" and "A" or faction == "Horde" and "H" or nil
    if ruleset == nil or letter == nil then
        return nil
    end
    for index, name in ipairs(RULESETS) do
        if name == ruleset then
            return (index - 1) .. letter
        end
    end
    return nil
end

-- "Normal Horde": the house the way Market names it.
function market.houseName(key)
    if type(key) ~= "string" or #key < 2 then
        return nil
    end
    return (RULESETS[(tonumber(key:sub(1, 1)) or -1) + 1] or "?") .. " " .. (FACTIONS[key:sub(2, 2)] or "?")
end

-- The auction house's cut on a sale, in percent: 5, and 15 at the neutral Blackwater house (Market's own figures).
-- The deposit is not counted: it comes back when the auction sells.
function market.cutOf(key)
    if type(key) == "string" and key:sub(2, 2) == "B" then
        return 15
    end
    return 5
end

-- Which house's prices to read, and whether it is the player's own.
function market.chooseHouse(data)
    local houses = data.houses
    if type(houses) ~= "table" then
        return nil, false
    end
    local own = market.ownHouse()
    if own ~= nil and houses[own] ~= nil then
        return own, true
    end
    local settings = hints.game.marketSettings()
    local picked = settings ~= nil and settings.house or nil
    if picked ~= nil and picked ~= "auto" and houses[picked] ~= nil then
        return picked, false
    end
    for _, key in ipairs(ORDER) do
        if houses[key] ~= nil then
            return key, false
        end
    end
    return nil, false
end

-- The typical price of an item in a text of lines "itemID,typical,...": the line must start with the id and a comma.
local function fromText(text, itemID)
    local key = tostring(itemID) .. ","
    local start
    if text:sub(1, #key) == key then
        start = 1
    else
        local found = text:find("\n" .. key, 1, true)
        if found == nil then
            return nil
        end
        start = found + 1
    end
    return tonumber(text:match("^(%d+%.?%d*)", start + #key))
end

local function fromTable(prices, itemID)
    local line = prices[itemID]
    if type(line) == "table" then
        return tonumber(line[1])
    end
    return nil
end

-- What is known about the prices now, or nil and why ("nomarket": no data at all; "noprices": data without prices):
-- { built, house, houseName, own, cut, price = function(itemID) -> copper per item or nil }.
function market.snapshot()
    local data = hints.game.market()
    if data == nil then
        return nil, "nomarket"
    end
    local key, own = market.chooseHouse(data)
    local parsed, text
    if key ~= nil then
        local house = data.houses[key]
        parsed, text = house.lat, house.latS
    else
        local region = data.region
        parsed = type(data.lat) == "table" and data.lat[region] or nil
        text = type(data.latS) == "table" and data.latS[region] or nil
        own = false
    end
    if type(parsed) ~= "table" and type(text) ~= "string" then
        return nil, "noprices"
    end
    local function price(itemID)
        local typical
        if type(parsed) == "table" then
            typical = fromTable(parsed, itemID)
        else
            typical = fromText(text, itemID)
        end
        if typical ~= nil and typical > 0 then
            return typical
        end
        return nil
    end
    return {
        built = tonumber(data.built) or tonumber(data.latest),
        cut = market.cutOf(key),
        house = key,
        houseName = market.houseName(key),
        own = own,
        price = price,
    }
end
