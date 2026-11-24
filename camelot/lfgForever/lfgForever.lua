-- LFG Forever: the group finder addon of that name (by Artefius, opened with /lfg) as a WowVision window.
--
-- This is NOT Blizzard's group finder: camelot/lfg.lua reads that one (LFGParentFrame). LFG Forever is a third-party
-- addon for WoW: Forever that draws a window of its own, LFGForeverFrame, with its own search (category and activity
-- menus), filters (roles, level, classes, play style, languages), results (groups and players looking for a group),
-- whisper log and player ratings. It is optional (OptionalDeps in WowVision_Camelot.toc): without it this file stops
-- here and no module is made.
--
-- LFG Forever keeps all its code in a private table (local _, LFGF = ...), so none of it can be called from here.
-- What is reachable is what it leaves in the game's global space: its window (LFGForeverFrame), the two panels the
-- window is made of (frame.Content.FilterPanel and frame.Content.ListPanel) with the controls and lists they carry by
-- name, and the function its key binding runs (LFGForever_ToggleWindow). screen.lua reads those and clicks the real
-- controls, as WowVision does with the game's own windows, so nothing here changes how LFG Forever works. The names
-- are LFG Forever's (read from version 2.3.0, checked against 2.5.0): when it renames one, the window is read less (a part that fails is
-- left out and reported, the others still work) or says once that it cannot be read. Never an error that stops the
-- rest.
local loaded = WowVision.loadedAddons
if loaded == nil or not (loaded["LFGForever"] or loaded["lfgforever"]) then
    return
end

local module = WowVision.base.windows:createModule("lfgForever")
local L = module.L
module:setLabel(L["LFG Forever"])

local game = {}
module.game = game

-- The name of the window LFG Forever builds (on the first /lfg) and the window WowVision registers over it.
game.FRAME = "LFGForeverFrame"
game.WINDOW = "lfgForever"

-- ----------------------------------------------------------------- saying

-- A message that a state keeps true (a window that cannot be read, drawn again every tick) is said once. module.said
-- holds what was said, for the tests.
local said = {}
module.said = said
function module.sayOnce(key, text)
    if said[key] then
        return
    end
    said[key] = true
    WowVision:notify(text)
end

-- ----------------------------------------------------------------- reading

-- A value the game keeps secret (in a dungeon, a raid, a fight, or while chat messaging is locked down) cannot be
-- compared, joined or used as a key: it is read as nothing.
function game.readable(value)
    if value == nil then
        return nil
    end
    if WowVision.secrets.isSecret(value) then
        return nil
    end
    local canAccess = rawget(_G, "canaccessvalue")
    if canAccess ~= nil and not canAccess(value) then
        return nil
    end
    return value
end

local function call(fn, ...)
    if fn == nil then
        return nil
    end
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

local function lfgList()
    return rawget(_G, "C_LFGList")
end

-- One listing of the search results: leaderName, numMembers, activityIDs, comment, isDelisted, hasSelf,
-- newPlayerFriendly, generalPlaystyle... (any of them can be secret).
function game.resultInfo(resultID)
    local api = lfgList()
    return api ~= nil and call(api.GetSearchResultInfo, resultID) or nil
end

-- A member of a listing: classFilename, level, areaName, lfgRoles ({ tank, healer, dps }).
function game.memberInfo(resultID, index)
    local api = lfgList()
    return api ~= nil and call(api.GetSearchResultPlayerInfo, resultID, index) or nil
end

-- What a group has: { TANK = n, HEALER = n, DAMAGER = n }.
function game.memberCounts(resultID)
    local api = lfgList()
    return api ~= nil and call(api.GetSearchResultMemberCounts, resultID) or nil
end

-- The name the game gives an activity, in the game's language.
function game.activityName(activityID)
    local api = lfgList()
    local info = api ~= nil and call(api.GetActivityInfoTable, activityID) or nil
    if type(info) ~= "table" then
        return nil
    end
    local named = rawget(_G, "LFGUtil_GetActivityInfoName")
    local name = named ~= nil and call(named, info) or nil
    return game.readable(name or info.fullName or info.shortName)
end

function game.playstyleName(playstyle)
    local word = rawget(_G, "GetGeneralPlaystyleString")
    if word == nil or playstyle == nil then
        return nil
    end
    local text = call(word, playstyle)
    if text == nil or text == "" then
        return nil
    end
    return text
end

function game.className(classFilename)
    if type(classFilename) ~= "string" then
        return nil
    end
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    return names ~= nil and names[classFilename] or classFilename
end

-- The game's own words for the three roles (Tank, Healer, Damage).
local ROLE_GLOBALS = { TANK = "TANK", HEALER = "HEALER", DAMAGER = "DAMAGER" }
function game.roleName(role)
    local name = rawget(_G, ROLE_GLOBALS[role] or "")
    if type(name) == "string" and name ~= "" then
        return name
    end
    return nil
end

-- The headers of the two parts of the results, in the game's words.
function game.dividerName(dividerType)
    if dividerType == "solo" then
        return rawget(_G, "LFG_LIST_CATEGORY_SOLO_PLAYERS")
    end
    return rawget(_G, "LFG_LIST_CATEGORY_GROUPS")
end

-- ------------------------------------------------------------- LFG Forever

-- LFG Forever's window, and the two panels it is made of. Any of them is nil until the window has been opened once
-- (LFG Forever builds it on the first /lfg).
function game.frame()
    return rawget(_G, game.FRAME)
end

function game.panels()
    local frame = game.frame()
    local content = frame ~= nil and frame.Content or nil
    if content == nil then
        return frame, nil, nil
    end
    return frame, content.FilterPanel, content.ListPanel
end

function game.shown(frame)
    return frame ~= nil and frame.IsShown ~= nil and frame:IsShown() == true
end

-- ---------------------------------------------------- marks on a drawn row

-- The icon LFG Forever puts before the name of a guild member or a friend (core/relations.lua: the icon is shown
-- and its field relation is "guild" or "friend"; hidden for anyone else).
function game.relation(icon)
    if icon == nil or not game.shown(icon) then
        return nil
    end
    local relation = game.readable(icon.relation)
    if relation == "guild" or relation == "friend" then
        return relation
    end
    return nil
end

-- The strip LFG Forever draws on the left edge of a row whose player you rated (for a group: its lowest rated
-- member). The rating itself is kept in LFG Forever's private table; what the row carries is the strip's colour
-- (core/main.lua, PlayerRatingRGB): the game's red for 1 star, silver for 2, a dim green for 3. So the colour is
-- read back into the number. A hidden strip, or a colour that is none of the three (LFG Forever changed them), is
-- no rating: nothing is said rather than a wrong number.
local SILVER, DIM = 192 / 255, 64 / 255
local COLOUR_SLACK = 0.06

local function near(r, g, b, r2, g2, b2)
    return math.abs(r - r2) < COLOUR_SLACK and math.abs(g - g2) < COLOUR_SLACK and math.abs(b - b2) < COLOUR_SLACK
end

function game.stripRating(strip)
    if strip == nil or strip.GetVertexColor == nil or not game.shown(strip) then
        return nil
    end
    local ok, r, g, b = pcall(strip.GetVertexColor, strip)
    r, g, b = game.readable(r), game.readable(g), game.readable(b)
    if not ok or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return nil
    end
    -- the game's red is made at load from its colour data, so it is asked for here
    local redR, redG, redB = 1, 32 / 255, 32 / 255
    local red = rawget(_G, "RED_FONT_COLOR")
    if type(red) == "table" and red.GetRGB ~= nil then
        local okRed, rr, rg, rb = pcall(red.GetRGB, red)
        if okRed and type(rr) == "number" and type(rg) == "number" and type(rb) == "number" then
            redR, redG, redB = rr, rg, rb
        end
    end
    if near(r, g, b, redR, redG, redB) then
        return 1
    elseif near(r, g, b, SILVER, SILVER, SILVER) then
        return 2
    elseif near(r, g, b, DIM, SILVER, DIM) then
        return 3
    end
    return nil
end

-- Closes the window (Escape on WowVision's screen). A plain Hide is never refused, in combat or not.
function game.hide()
    local frame = game.frame()
    if frame ~= nil then
        frame:Hide()
    end
end

-- Opens LFG Forever's window, or closes it when it is open, the way its own key does: through the function it gives
-- that key (a plain frame, so this works in combat too). WowVision's window follows the frame.
function module.toggle()
    local toggle = rawget(_G, "LFGForever_ToggleWindow")
    if type(toggle) ~= "function" then
        WowVision:notify(L["LFG Forever cannot be opened from here, type /lfg"])
        return false
    end
    WowVision.utils.guardedCall("lfgForever:toggle", toggle)
    return true
end

-- ----------------------------------------------------------- key, command

-- Alt+Ctrl is the family of the windows' own keys (the roll keys, Accept Trade). LFG Forever has two keys of its own
-- in the game's key bindings (Open and Search); they are left as they are.
module:registerBinding({
    type = "Function",
    key = "lfgForever/open",
    inputs = { "ALT-CTRL-G" },
    label = L["Open or Close LFG Forever"],
    conflictingAddons = { "Sku" },
    interruptSpeech = true,
    func = function()
        module.toggle()
    end,
})

module:registerCommand({
    name = "lfg",
    description = "Open or close LFG Forever, the third-party group finder",
    conflictingAddons = { "Sku" },
    func = function()
        module.toggle()
    end,
})
