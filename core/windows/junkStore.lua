-- The logic of marking items as junk (junk.lua) and selling them at a merchant (merchant.lua): pure Lua without game
-- functions, so the headless suite tests it. The game's side (the bag functions, the selling call, the speech) is
-- handed in by the caller.
--
-- marks: { [key] = item name } -- the junk module's per-character data. The name is only there to be read back
-- (speech, a look at the list); the key is what counts.
local store = {}
WowVision.junkStore = store

local MAX_NAMES = 5

local function usable(value)
    return value ~= nil and not (WowVision.isSecret ~= nil and WowVision.isSecret(value))
end

-- What makes an item the same item next time: its item number, and for items that exist in several random
-- variants ("of the Monkey", "of the Eagle") the variant's suffix as well, so marking one variant never marks
-- the others. Everything else a link carries is left out on purpose: the enchant, the gems, the level and the
-- unique number of one drop all change while the item stays the same (and the unique number is new on every
-- drop, so a mark made with it would never match a later one).
-- The link is the game's item link; nil for anything that is not one.
function store.keyFromLink(link)
    if type(link) ~= "string" then
        return nil
    end
    local body = link:match("item:([%-%d:]*)")
    if body == nil then
        return nil
    end
    local fields = {}
    for field in (body .. ":"):gmatch("([^:]*):") do
        tinsert(fields, field)
    end
    local id = tonumber(fields[1])
    if id == nil or id <= 0 or id ~= math.floor(id) then
        return nil
    end
    local suffix = tonumber(fields[7]) or 0
    if suffix ~= 0 and suffix == math.floor(suffix) then
        return string.format("%d:%d", id, suffix)
    end
    return string.format("%d", id)
end

-- The item's name as its link writes it ("[Linen Cloth]"), for when the game has not given the name itself yet.
function store.nameFromLink(link)
    if type(link) ~= "string" then
        return nil
    end
    return link:match("|h%[(.-)%]|h")
end

function store.isMarked(marks, key)
    return marks ~= nil and key ~= nil and marks[key] ~= nil
end

-- Marks an unmarked item and unmarks a marked one. Returns whether it is marked now.
function store.toggle(marks, key, name)
    if marks[key] ~= nil then
        marks[key] = nil
        return false
    end
    marks[key] = name or true
    return true
end

function store.count(marks)
    local count = 0
    for _ in pairs(marks) do
        count = count + 1
    end
    return count
end

function store.clear(marks)
    for key in pairs(marks) do
        marks[key] = nil
    end
end

-- Why a bag slot is to be sold, or nil when it is not: "marked" (the player marked this item and the marks are
-- on), "poor" (grey quality and selling poor items is on). Never anything else: an item that is neither is left
-- alone, whatever it is worth. An item the vendor would not buy is left alone too (using it would be the result
-- of the sell call once the window closes), and so is one the game has locked (a sale under way).
local function classify(info, opts)
    if info.isLocked == true or info.hasNoValue == true then
        return nil
    end
    if opts.marks ~= nil then
        local key = store.keyFromLink(info.hyperlink)
        if store.isMarked(opts.marks, key) then
            -- Marked items are only sold on proof that the vendor buys them: the flag says so, or a sell price.
            if info.hasNoValue == false or (opts.sellPrice ~= nil and opts.sellPrice(info.itemID) ~= nil) then
                return "marked", key
            end
            return nil
        end
    end
    if opts.sellPoor and info.quality == 0 and not info.hasNoValue then
        return "poor"
    end
    return nil
end

-- One pass over the bags: sells every slot classify() accepts and counts what went. Each slot is looked at once,
-- no pass repeats itself, and only the listed bags are looked at (the bags the player carries: never the bank,
-- and what is worn is not in a bag).
--
-- opts: bags = { bag ids }, numSlots(bag), getInfo(bag, slot) -> the game's container item info or nil,
-- sellPrice(itemID) -> copper or nil, sell(bag, slot) -> sells that slot, marks = the marks table or nil to leave
-- marked items alone, sellPoor = whether grey items go too.
-- Returns { units, value, poorUnits, markedUnits, markedNames, error }: units counts items (a stack of five is
-- five), value is in copper, markedNames lists each marked item sold once, by name. error is the first failure
-- of the sell call; the pass stops there and what was sold before it stays counted.
function store.sell(opts)
    local result = { units = 0, value = 0, poorUnits = 0, markedUnits = 0, markedNames = {} }
    local named = {}
    for _, bag in ipairs(opts.bags) do
        for slot = 1, opts.numSlots(bag) or 0 do
            local info = opts.getInfo(bag, slot)
            local ok, reason, key = false, nil, nil
            if info ~= nil then
                ok, reason, key = pcall(classify, info, opts)
            end
            if ok and reason ~= nil then
                local units = usable(info.stackCount) and type(info.stackCount) == "number" and info.stackCount or 1
                local price = opts.sellPrice ~= nil and opts.sellPrice(info.itemID) or nil
                local sold, err = pcall(opts.sell, bag, slot)
                if not sold then
                    result.error = err
                    return result
                end
                result.units = result.units + units
                if price ~= nil then
                    result.value = result.value + price * units
                end
                if reason == "marked" then
                    result.markedUnits = result.markedUnits + units
                    local name = usable(info.itemName) and info.itemName or nil
                    if type(name) ~= "string" or name == "" then
                        name = store.nameFromLink(info.hyperlink) or opts.marks[key]
                    end
                    if type(name) ~= "string" then
                        name = key
                    end
                    if not named[name] then
                        named[name] = true
                        tinsert(result.markedNames, name)
                    end
                else
                    result.poorUnits = result.poorUnits + units
                end
            end
        end
    end
    return result
end

local function listNames(names, L)
    local shown = {}
    for i = 1, math.min(#names, MAX_NAMES) do
        tinsert(shown, names[i])
    end
    local text = table.concat(shown, ", ")
    if #names > MAX_NAMES then
        text = string.format(L["%s and %d more"], text, #names - MAX_NAMES)
    end
    return text
end

-- What is said after a sale, or nil when nothing was sold. Grey items are counted; the marked ones are named,
-- so a mark made by mistake is heard at once (and no count stands next to "1 items": the names carry it).
-- coinText(copper) writes the amount as the game does.
function store.summary(result, L, coinText)
    if result.units == 0 then
        return nil
    end
    local coin = coinText(result.value)
    if result.markedUnits == 0 then
        return string.format(L["Sold %d poor quality items for %s."], result.units, coin)
    end
    local names = listNames(result.markedNames, L)
    if result.poorUnits == 0 then
        return string.format(L["Sold marked junk for %s: %s."], coin, names)
    end
    return string.format(L["Sold marked junk and %d poor quality items for %s: %s."], result.poorUnits, coin, names)
end
