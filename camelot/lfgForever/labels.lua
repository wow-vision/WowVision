local module = WowVision.base.windows.lfgForever
if module == nil then
    return
end

local L = module.L
local game = module.game

-- What each line of LFG Forever's lists says. A line is said as soon as the focus lands on it, before the game has
-- drawn its row, so it is built from the data (the search results the game holds, the whisper the log holds), never
-- from the drawn row. Every value is read through game.readable: in a dungeon, a raid or a fight the game keeps most
-- of a listing secret, and what cannot be read is left out of the line (never guessed).
local labels = {}
module.labels = labels

local readable = game.readable

-- A word of the game's if it has one, else this module's own.
local function word(gameWord, key)
    if type(gameWord) == "string" and gameWord ~= "" then
        return gameWord
    end
    return L[key]
end

local function add(parts, text)
    if type(text) == "string" and text ~= "" then
        parts[#parts + 1] = text
    end
end

local function oneLine(text)
    return (text:gsub("%s+", " "):match("^%s*(.-)%s*$"))
end

local function readableText(value)
    local text = readable(value)
    if type(text) ~= "string" then
        return nil
    end
    text = oneLine(text)
    if text == "" then
        return nil
    end
    return text
end

local ROLES = {
    { key = "TANK", fallback = "Tank", solo = "tank" },
    { key = "HEALER", fallback = "Healer", solo = "healer" },
    { key = "DAMAGER", fallback = "Damage", solo = "dps" },
}

local function roleWord(role)
    return word(game.roleName(role.key), role.fallback)
end

-- What a group has, "1 Tank, 1 Healer, 3 Damage"; nil when the tally cannot be read or is empty.
function labels.groupRoles(counts)
    counts = readable(counts)
    if type(counts) ~= "table" then
        return nil
    end
    local parts = {}
    for _, role in ipairs(ROLES) do
        local count = readable(counts[role.key])
        if type(count) == "number" and count > 0 then
            add(parts, string.format("%d %s", count, roleWord(role)))
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- The roles a player signed up for, "Tank, Healer"; nil when none can be read.
function labels.playerRoles(lfgRoles)
    lfgRoles = readable(lfgRoles)
    if type(lfgRoles) ~= "table" then
        return nil
    end
    local parts = {}
    for _, role in ipairs(ROLES) do
        if readable(lfgRoles[role.solo]) == true then
            add(parts, roleWord(role))
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- "level 60 Mage", "level 60" or nothing.
local function levelAndClass(level, classFilename)
    level = readable(level)
    if type(level) ~= "number" then
        return nil
    end
    local class = game.className(readable(classFilename))
    if class ~= nil then
        return string.format(L["level %d %s"], level, class)
    end
    return string.format(L["level %d"], level)
end

-- The activities a listing is for: one name, up to three names, else how many.
function labels.activities(activityIDs)
    activityIDs = readable(activityIDs)
    if type(activityIDs) ~= "table" or #activityIDs == 0 then
        return nil
    end
    if #activityIDs > 3 then
        return string.format(L["%d activities"], #activityIDs)
    end
    local names = {}
    for _, activityID in ipairs(activityIDs) do
        add(names, game.activityName(activityID))
    end
    if #names == 0 then
        return string.format(L["%d activities"], #activityIDs)
    end
    return table.concat(names, " / ")
end

-- One listing of the search results: a group or a player looking for a group.
--
-- A group: its leader, what it is for, how many members and what they are, its play style, its note. A player: the
-- name, level and class, the roles, what for, the zone, the play style, the note. Then, for either, what the game
-- says of the listing itself: yours, removed, welcoming new players.
function labels.listing(resultID)
    local info = game.resultInfo(resultID)
    if type(info) ~= "table" then
        return L["Group"]
    end
    local numMembers = readable(info.numMembers)
    local isSolo = type(numMembers) == "number" and numMembers <= 1
    local parts = {}
    local readAny = false

    local name = readableText(info.leaderName)
    add(parts, name)
    readAny = readAny or name ~= nil

    if isSolo then
        local member = game.memberInfo(resultID, 1)
        if type(member) == "table" then
            add(parts, levelAndClass(member.level, member.classFilename))
            local roles = labels.playerRoles(member.lfgRoles)
            if roles ~= nil then
                add(parts, string.format(L["roles: %s"], roles))
            end
        end
        local activities = labels.activities(info.activityIDs)
        add(parts, activities)
        readAny = readAny or activities ~= nil
        local zone = type(member) == "table" and readableText(member.areaName) or nil
        if zone ~= nil then
            add(parts, string.format(L["in %s"], zone))
        end
    else
        local activities = labels.activities(info.activityIDs)
        add(parts, activities)
        readAny = readAny or activities ~= nil
        if type(numMembers) == "number" then
            readAny = true
            local roles = labels.groupRoles(game.memberCounts(resultID))
            if roles ~= nil then
                add(parts, string.format(L["%d members (%s)"], numMembers, roles))
            else
                add(parts, string.format(L["%d members"], numMembers))
            end
        end
    end

    local playstyle = readable(info.generalPlaystyle)
    add(parts, playstyle ~= nil and game.playstyleName(playstyle) or nil)
    add(parts, readableText(info.comment))

    if readable(info.hasSelf) == true then
        add(parts, L["your own listing"])
    end
    if readable(info.isDelisted) == true then
        add(parts, L["listing removed"])
    end
    if readable(info.newPlayerFriendly) == true then
        add(parts, L["welcomes new players"])
    end

    -- nothing that says who or what: the game keeps it secret (a dungeon, a raid, a fight)
    if not readAny then
        table.insert(parts, 1, L["Group"])
        add(parts, L["details unavailable"])
    end
    return table.concat(parts, ", ")
end

-- A header of the results ("Groups", "Players"), with how many listings it holds when that is known.
function labels.divider(dividerType, count)
    local label = word(game.dividerName(dividerType), dividerType == "solo" and "Players" or "Groups")
    if type(count) == "number" then
        return string.format("%s, %d", label, count)
    end
    return label
end

-- One whisper of the whisper log: who, their level and class, what they wrote.
function labels.whisper(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local parts = {}
    add(parts, readableText(entry.name))
    add(parts, levelAndClass(entry.level, entry.classFilename))
    local who = table.concat(parts, ", ")
    local text = readableText(entry.text)
    if text == nil then
        text = L["message unavailable"]
    end
    if who == "" then
        return text
    end
    return who .. ": " .. text
end

-- One recent ally of the Player ratings tab: who, their level and class, what you did together.
function labels.ally(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local parts = {}
    add(parts, readableText(entry.name))
    add(parts, levelAndClass(entry.level, entry.classFilename))
    add(parts, readableText(entry.text))
    if #parts == 0 then
        return L["Player"]
    end
    return table.concat(parts, ", ")
end

-- Whether a listing is one player looking for a group (as labels.listing takes it: one member at most).
function labels.isSolo(resultID)
    local info = game.resultInfo(resultID)
    if type(info) ~= "table" then
        return false
    end
    local numMembers = readable(info.numMembers)
    return type(numMembers) == "number" and numMembers <= 1
end

-- What LFG Forever's icon before a name says: a member of your guild, or a friend.
function labels.relation(relation)
    if relation == "guild" then
        return L["guild member"]
    elseif relation == "friend" then
        return L["friend"]
    end
    return nil
end

-- The rating LFG Forever marks a row with: yours of that player, or for a group the lowest among its members.
function labels.mark(rating, isGroup)
    if type(rating) ~= "number" then
        return nil
    end
    if isGroup then
        return string.format(L["lowest rating in the group: %d of 3 stars"], rating)
    end
    return string.format(L["rated %d of 3 stars"], rating)
end

-- What the stars of an ally say: "rated 2 of 3 stars" or "not rated".
function labels.rating(rating)
    if type(rating) == "number" and rating >= 1 then
        return string.format(L["rated %d of 3 stars"], rating)
    end
    return L["not rated"]
end
