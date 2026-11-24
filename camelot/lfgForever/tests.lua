-- LFG Forever's window (camelot/lfgForever). tools/headless-tests.lua loads the module's files against a stand-in
-- window module (harness.load) and then this file; it is not in modules.xml, as the game cannot run it without that
-- harness.
--
-- LFG Forever's window and the game are stand-ins shaped after LFG Forever's own source (version 2.3.0; the
-- row marks and the delist button after 2.5.0: core/window.lua, core/relations.lua, core/main.lua,
-- core/filterpanel*.lua, core/listpanel.lua, core/whisperlog.lua, core/playerratings.lua): the same fields on the same
-- panels, so the screen is built and walked by the real graph code (Builder, node factories, the scroll box adapter)
-- over what LFG Forever's real frames carry. The values the game keeps secret are stand-ins that raise on any use.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._lfgForeverTestHarness
local graph = WowVision.graph
local Builder = graph.Builder
local module = harness.module

-- ------------------------------------------------------------------ world

local GLOBALS = {
    "LFGForeverFrame",
    "LFGForever_ToggleWindow",
    "C_LFGList",
    "GetGeneralPlaystyleString",
    "TANK",
    "HEALER",
    "DAMAGER",
    "LOCALIZED_CLASS_NAMES_MALE",
    "LFG_LIST_CATEGORY_GROUPS",
    "LFG_LIST_CATEGORY_SOLO_PLAYERS",
    "RED_FONT_COLOR",
    "issecretvalue",
    "canaccessvalue",
    "geterrorhandler",
}

local Frame = {}
Frame.__index = Frame

local function newFrame(fields)
    local frame = setmetatable({ shown = true, enabled = true, scripts = {}, clicks = {} }, Frame)
    for key, value in pairs(fields or {}) do
        frame[key] = value
    end
    return frame
end

function Frame:IsShown()
    return self.shown
end
function Frame:IsVisible()
    return self.shown
end
function Frame:Hide()
    self.shown = false
    self.hides = (self.hides or 0) + 1
end
function Frame:GetText()
    return self.text
end
function Frame:IsEnabled()
    return self.enabled
end
function Frame:GetChecked()
    return self.checked
end
function Frame:GetObjectType()
    return self.objectType or "Button"
end
function Frame:GetRegions() end
function Frame:GetChildren() end
function Frame:GetScript(kind)
    return self.scripts[kind]
end
function Frame:HasScript()
    return true
end
function Frame:IsProtected()
    return false
end
function Frame:OpenMenu()
    self.menuOpened = true
end
function Frame:SetFocus()
    self.focused = true
end
function Frame:ClearFocus() end
function Frame:SetAutoFocus() end
function Frame:GetName()
    return nil
end

local function text(value)
    return newFrame({ text = value })
end

-- A tree node, as the game's tree data provider hands them out.
local function treeNode(payload, collapsed)
    local node = { payload = payload, collapsed = collapsed == true, children = {} }
    function node:GetData()
        return self.payload
    end
    function node:IsCollapsed()
        return self.collapsed
    end
    function node:GetNodes()
        return self.children
    end
    return node
end

-- A scroll box over a flat list of nodes (what the tree shows: collapsed headers hide their children).
local function scrollBox(isTree)
    local box = newFrame({ flat = {}, frames = {}, scrolled = {} })
    box.provider = {
        GetRootNode = isTree and function()
            return {}
        end or nil,
    }
    function box.provider:Find(index)
        return box.flat[index]
    end
    function box:GetDataProvider()
        return self.provider
    end
    function box:GetDataProviderSize()
        return #self.flat
    end
    function box:FindElementData(index)
        return self.flat[index]
    end
    function box:ScrollToElementDataIndex(index)
        self.scrolled[#self.scrolled + 1] = index
    end
    function box:FindFrame(node)
        return self.frames[node]
    end
    return box
end

-- A drawn row of the results: the row's own two action buttons, as LFG Forever adds them.
local function resultRow(kind, asked)
    local row = newFrame({})
    row.LFGFAskToJoin = newFrame({ shown = kind == "group" })
    row.LFGFAskToJoin.Check = newFrame({ shown = asked == true })
    row.LFGFInvite = newFrame({ shown = kind == "solo" })
    row.LFGFDelist = newFrame({ shown = kind == "own" })
    return row
end

-- The strip LFG Forever draws on a rated player's row: a texture in the rating's colour.
local function strip(r, g, b, shown)
    local texture = newFrame({ shown = shown ~= false })
    function texture:GetVertexColor()
        return r, g, b, 1
    end
    return texture
end

-- The icon LFG Forever puts before the name of a guild member or a friend.
local function relationIcon(relation)
    return newFrame({ shown = relation ~= nil, relation = relation })
end

local function section(title, collapsed)
    local s = newFrame({})
    s.Title = text(title)
    s.Header = newFrame({ text = title })
    s.Header.Warning = newFrame({ shown = false })
    s.Content = newFrame({ shown = collapsed ~= true })
    s.collapsed = collapsed == true
    return s
end

local function check(label, checked)
    local c = newFrame({ checked = checked == true, objectType = "CheckButton" })
    c.Text = text(label)
    return c
end

-- One start of the game: LFG Forever's window (options.installed = false: not built yet, as before the first /lfg),
-- the game's words (options.gameWords = false: it has none for the headers), and what the speech was asked to say.
-- Everything it sets is put back by withWorld.
local function newWorld(options)
    options = options or {}
    local world = { errors = {}, spoken = {}, results = {}, activities = {}, members = {}, counts = {} }

    local function refuse(what)
        return function()
            error("a secret value cannot be " .. what)
        end
    end
    local secretMeta = {
        __index = refuse("indexed"),
        __len = refuse("measured"),
        __concat = refuse("joined"),
        __lt = refuse("compared"),
        __le = refuse("compared"),
        __call = refuse("called"),
        __tostring = refuse("turned into text"),
    }
    -- A secret number cannot be told from a plain one in Lua: this one is the value the game's checks refuse.
    world.SECRET_NUMBER = 98765
    issecretvalue = function(value)
        return value == world.SECRET_NUMBER or (type(value) == "table" and getmetatable(value) == secretMeta)
    end
    canaccessvalue = function(value)
        return not issecretvalue(value)
    end
    function world.secret()
        return setmetatable({}, secretMeta)
    end
    geterrorhandler = function()
        return function(err)
            world.errors[#world.errors + 1] = tostring(err)
        end
    end

    C_LFGList = {
        GetSearchResultInfo = function(id)
            return world.results[id]
        end,
        GetSearchResultPlayerInfo = function(id, index)
            return world.members[id] ~= nil and world.members[id][index] or nil
        end,
        GetSearchResultMemberCounts = function(id)
            return world.counts[id]
        end,
        GetActivityInfoTable = function(id)
            return world.activities[id]
        end,
    }
    GetGeneralPlaystyleString = function(playstyle)
        return ({ "Learning", "Relaxed", "Competitive", "Carry" })[playstyle]
    end
    TANK, HEALER, DAMAGER = "Tank", "Healer", "Damage"
    LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", WARRIOR = "Warrior", PRIEST = "Priest" }
    if options.gameWords ~= false then
        LFG_LIST_CATEGORY_GROUPS = "Groups"
        LFG_LIST_CATEGORY_SOLO_PLAYERS = "Players"
    else
        LFG_LIST_CATEGORY_GROUPS = nil
        LFG_LIST_CATEGORY_SOLO_PLAYERS = nil
    end
    WowVision.notify = function(_, message)
        world.spoken[#world.spoken + 1] = message
    end

    -- a group listing and a player listing, as the search returns them
    function world.group(id, fields)
        local info = { leaderName = "Leader" .. id, numMembers = 3, activityIDs = { 100 }, comment = "", age = id }
        for key, value in pairs(fields or {}) do
            info[key] = value
        end
        world.results[id] = info
        world.activities[100] = world.activities[100] or { fullName = "Deadmines" }
        return info
    end
    function world.player(id, fields, member)
        local info = { leaderName = "Player" .. id, numMembers = 1, activityIDs = { 100 }, comment = "", age = id }
        for key, value in pairs(fields or {}) do
            info[key] = value
        end
        world.results[id] = info
        world.activities[100] = world.activities[100] or { fullName = "Deadmines" }
        world.members[id] = {
            member or {
                classFilename = "MAGE",
                level = 17,
                areaName = "Westfall",
                lfgRoles = { tank = false, healer = false, dps = true },
            },
        }
        return info
    end

    -- the window, with its two panels and the controls they carry
    local frame = newFrame({})
    local content = newFrame({})
    local filter = newFrame({})
    local list = newFrame({})
    frame.Content = content
    content.FilterPanel = filter
    content.ListPanel = list
    world.frame, world.filter, world.list = frame, filter, list

    filter.CategoryDropdown = newFrame({ text = "Dungeons" })
    filter.ActivityDropdown = newFrame({ text = "All activities" })
    filter.SearchButton = newFrame({ text = "Search" })
    filter.RoleCheckButton = newFrame({ text = "Role check" })
    filter.SettingsGear = newFrame({})

    filter.GroupSection = section("Groups")
    filter.GroupFilterChecks = { check("Tank role available"), check("Healer role available", true), check("Has tank") }
    filter.GroupClassDropdown = newFrame({ text = "No groups with..." })
    filter.ResetFiltersLink = newFrame({ text = "Reset filters" })
    filter.SaveNewFilterLink = newFrame({ text = "Save new filter" })
    filter.MyFiltersDropdown = newFrame({ text = "My filters", shown = false })

    filter.RoleSection = section("Player roles")
    filter.PlayerRoleChecks = { check("Tank", true), check("Healer", true), check("Damage", true) }
    filter.LevelLabel = text("Player level range")
    filter.LevelRange = newFrame({})
    filter.LevelRange.MinLevel = newFrame({ text = "", objectType = "EditBox" })
    filter.LevelRange.MaxLevel = newFrame({ text = "20", objectType = "EditBox" })

    filter.ClassSection = section("Player classes")
    filter.PlayerClassChecks = { check("Mage", true), check("Warrior", true) }
    filter.UnselectAllClasses = newFrame({ text = "Unselect all" })
    filter.SelectAllClasses = newFrame({ text = "Select all" })

    filter.MiscellaneousSection = section("Miscellaneous")
    filter.PlaystyleLabel = text("Play style")
    filter.PlaystyleDropdown = newFrame({ text = "All" })
    filter.LanguagesLabel = text("Languages")
    filter.LanguagesDropdown = newFrame({ text = "English" })

    filter.WhispersSection = section("Whispers")
    filter.WhispersSection.shown = false
    filter.WhisperLog = newFrame({ ScrollBox = scrollBox(false) })
    filter.ClearChatLink = newFrame({ text = "Clear chat" })
    filter.RatingsSection = section("Player ratings")
    filter.RatingsSection.shown = false
    filter.PlayerRatings = newFrame({ ScrollBox = scrollBox(false) })
    filter.ClearPlayerRatingLink = newFrame({ text = "Clear a rating" })

    filter.filtersTabID, filter.whispersTabID, filter.ratingsTabID = 1, 2, 3
    filter.tabButtons = {
        [1] = newFrame({ tabText = "Filters" }),
        [2] = newFrame({ tabText = "Whispers" }),
        [3] = newFrame({ tabText = "Player ratings" }),
    }
    function filter:GetTabButton(id)
        return self.tabButtons[id]
    end

    list.ScrollBox = scrollBox(true)
    list.SearchingSpinner = newFrame({ shown = false })

    -- which tab is open: LFG Forever hides the content of the others
    function world.openTab(name)
        filter.GroupSection.shown = name == "filters"
        filter.RoleSection.shown = name == "filters"
        filter.ClassSection.shown = name == "filters"
        filter.MiscellaneousSection.shown = name == "filters"
        filter.WhispersSection.shown = name == "whispers"
        filter.RatingsSection.shown = name == "ratings"
    end
    world.openTab("filters")

    -- LFG Forever's window exists once /lfg has been typed, and its toggle is a global
    function world.install()
        LFGForeverFrame = frame
        LFGForever_ToggleWindow = function()
            world.toggled = (world.toggled or 0) + 1
            frame.shown = not frame.shown
        end
    end
    function world.uninstall()
        LFGForeverFrame = nil
        LFGForever_ToggleWindow = nil
    end
    world.uninstall()
    if options.installed ~= false then
        world.install()
    end
    -- what LFG Forever said once is not said again in a later test
    for key in pairs(module.said) do
        module.said[key] = nil
    end
    return world
end

local function withWorld(options, fn)
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
    end
    local savedNotify = WowVision.notify
    local announcer = graph.announcer
    local savedPosition = announcer.positionText
    announcer.positionText = function(index, count)
        return index .. " of " .. count
    end
    local ok, err = pcall(function()
        fn(newWorld(options))
    end)
    for _, name in ipairs(GLOBALS) do
        _G[name] = saved[name]
    end
    WowVision.notify = savedNotify
    announcer.positionText = savedPosition
    if not ok then
        error(err, 0)
    end
end

-- ----------------------------------------------------------------- helpers

-- Every node of the screen, in order, with the stop it belongs to and what it says.
local function walk()
    local builder = Builder:new()
    module.render(builder)
    local render = builder:build()
    local out = {}
    if render == nil then
        return out, nil
    end
    for _, node in ipairs(render.order) do
        out[#out + 1] = {
            stop = node.stopKey,
            text = graph.announcer.leafText(node),
            node = node,
            vtable = node.vtable,
        }
    end
    return out, render
end

local function texts(rows, stop)
    local out = {}
    for _, row in ipairs(rows) do
        if stop == nil or row.stop == stop then
            out[#out + 1] = row.text
        end
    end
    return out
end

local function joined(rows, stop)
    return table.concat(texts(rows, stop), "|")
end

local function find(rows, start, stop)
    for _, row in ipairs(rows) do
        if (stop == nil or row.stop == stop) and row.text ~= nil and row.text:sub(1, #start) == start then
            return row
        end
    end
    return nil
end

local function stops(rows)
    local out, seen = {}, {}
    for _, row in ipairs(rows) do
        if row.stop ~= nil and not seen[row.stop] then
            seen[row.stop] = true
            out[#out + 1] = row.stop
        end
    end
    return table.concat(out, " ")
end

-- The actions a node's context menu offers.
local function contextActions(vtable)
    local out = {}
    if vtable.contextActions ~= nil then
        vtable.contextActions(function(entry)
            out[#out + 1] = entry
        end)
    end
    return out
end

local function actionLabels(vtable)
    local out = {}
    for _, entry in ipairs(contextActions(vtable)) do
        out[#out + 1] = entry.label
    end
    return table.concat(out, "|")
end

local function binding(vtable, name)
    for _, spec in ipairs(vtable.bindings or {}) do
        if spec.binding == name then
            return spec
        end
    end
    return nil
end

local function resolve(target)
    if type(target) == "function" then
        return target()
    end
    return target
end

-- A results tree: dividers with the listings under them (the listings of a folded divider are not in the flat list).
local function fillResults(world, items)
    local box = world.list.ScrollBox
    box.flat, box.frames, box.scrolled = {}, {}, {}
    world.nodes = {}
    for _, item in ipairs(items) do
        local divider = treeNode({ dividerType = item.divider }, item.collapsed)
        box.frames[divider] = newFrame({})
        box.flat[#box.flat + 1] = divider
        world.nodes[item.divider] = divider
        for _, row in ipairs(item.rows) do
            local child = treeNode({ resultID = row.id })
            divider.children[#divider.children + 1] = child
            world.nodes[row.id] = child
            if not item.collapsed then
                box.flat[#box.flat + 1] = child
                box.frames[child] = resultRow(row.kind, row.asked)
            end
        end
    end
end

-- The usual search: two groups and two players.
local function usualSearch(world)
    world.group(1, { leaderName = "Thrall", numMembers = 3, comment = "LF healer,  fast\n please" })
    world.counts[1] = { TANK = 1, HEALER = 0, DAMAGER = 2 }
    world.group(2, { leaderName = "Garrosh", numMembers = 5 })
    world.player(3, { leaderName = "Jaina", comment = "Need a dungeon" })
    world.player(4, { leaderName = "Anduin", newPlayerFriendly = true }, {
        classFilename = "PRIEST",
        level = 21,
        areaName = "Duskwood",
        lfgRoles = { tank = false, healer = true, dps = false },
    })
    fillResults(world, {
        { divider = "group", rows = { { id = 1, kind = "group" }, { id = 2, kind = "group", asked = true } } },
        { divider = "solo", rows = { { id = 3, kind = "solo" }, { id = 4, kind = "solo" } } },
    })
end

local function fillWhispers(world)
    local box = world.filter.WhisperLog.ScrollBox
    local entries = {
        { name = "Aragorn", level = 30, classFilename = "WARRIOR", text = "Hello there" },
        { name = "Boromir", text = "Need a hand?" },
    }
    box.flat, box.frames = entries, {}
    for _, entry in ipairs(entries) do
        local row = newFrame({})
        row.InviteLink = newFrame({ text = "Invite" })
        row.LocationLink = newFrame({ text = "Location", shown = false })
        row.RemoveLink = newFrame({ text = "Remove" })
        box.frames[entry] = row
    end
    return entries
end

local function fillAllies(world)
    local box = world.filter.PlayerRatings.ScrollBox
    local entries = {
        { name = "Legolas", level = 40, classFilename = "MAGE", text = "Deadmines" },
        { name = "Gimli" },
    }
    box.flat, box.frames = entries, {}
    for index, entry in ipairs(entries) do
        local row = newFrame({})
        row.Stars = newFrame({
            rating = index == 1 and 2 or nil,
            Buttons = { newFrame({}), newFrame({}), newFrame({}) },
        })
        box.frames[entry] = row
    end
    return entries
end

-- ------------------------------------------------------------------ labels

testRunner:addSuite("LFGForeverLabels", {
    ["a group says who leads it, what for, how many and what they are, and the note on one line"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            t:assertEqual(
                module.labels.listing(1),
                "Thrall, Deadmines, 3 members (1 Tank, 2 Damage), LF healer, fast please"
            )
            t:assertEqual(module.labels.listing(2), "Garrosh, Deadmines, 5 members")
        end)
    end,

    ["a player says level, class, roles, what for, where and the note"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            t:assertEqual(
                module.labels.listing(3),
                "Jaina, level 17 Mage, roles: Damage, Deadmines, in Westfall, Need a dungeon"
            )
            t:assertEqual(
                module.labels.listing(4),
                "Anduin, level 21 Priest, roles: Healer, Deadmines, in Duskwood, welcomes new players"
            )
        end)
    end,

    ["several activities are named up to three, then counted"] = function(t)
        withWorld(nil, function(world)
            world.activities[101] = { fullName = "Wailing Caverns" }
            world.activities[102] = { fullName = "Shadowfang Keep" }
            world.activities[103] = { fullName = "Stockade" }
            world.group(5, { activityIDs = { 100, 101 } })
            t:assertTrue(module.labels.listing(5):find("Deadmines / Wailing Caverns", 1, true) ~= nil)
            world.group(6, { activityIDs = { 100, 101, 102, 103 } })
            t:assertTrue(module.labels.listing(6):find("4 activities", 1, true) ~= nil)
            t:assertNil(module.labels.listing(6):find("Deadmines", 1, true))
        end)
    end,

    ["a listing says if it is yours, removed, and its play style"] = function(t)
        withWorld(nil, function(world)
            world.group(7, { hasSelf = true, isDelisted = true, generalPlaystyle = 3 })
            local line = module.labels.listing(7)
            t:assertTrue(line:find("Competitive", 1, true) ~= nil)
            t:assertTrue(line:find("your own listing", 1, true) ~= nil)
            t:assertTrue(line:find("listing removed", 1, true) ~= nil)
        end)
    end,

    ["the game's own words for the headers and the roles are used when it has them"] = function(t)
        withWorld(nil, function()
            LFG_LIST_CATEGORY_GROUPS, LFG_LIST_CATEGORY_SOLO_PLAYERS = "Groupes (jeu)", "Joueurs (jeu)"
            TANK = "Tank (jeu)"
            t:assertEqual(module.labels.divider("group", 4), "Groupes (jeu), 4")
            t:assertEqual(module.labels.divider("solo"), "Joueurs (jeu)")
            t:assertEqual(module.labels.groupRoles({ TANK = 2 }), "2 Tank (jeu)")
        end)
    end,

    ["without the game's words the module's own are said"] = function(t)
        withWorld({ gameWords = false }, function()
            TANK, HEALER, DAMAGER = nil, nil, nil
            t:assertEqual(module.labels.divider("group", 2), "Groups, 2")
            t:assertEqual(module.labels.divider("solo"), "Players")
            t:assertEqual(module.labels.groupRoles({ TANK = 1, HEALER = 1, DAMAGER = 3 }), "1 Tank, 1 Healer, 3 Damage")
        end)
    end,

    ["what the game keeps secret is left out, never guessed"] = function(t)
        withWorld(nil, function(world)
            world.group(8, {
                leaderName = world.secret(),
                numMembers = world.secret(),
                activityIDs = world.secret(),
                comment = world.secret(),
                isDelisted = world.secret(),
                hasSelf = world.secret(),
            })
            t:assertEqual(module.labels.listing(8), "Group, details unavailable")
            world.group(9, {
                leaderName = "Rexxar",
                numMembers = world.secret(),
                activityIDs = world.secret(),
                comment = world.secret(),
            })
            t:assertEqual(module.labels.listing(9), "Rexxar")
            -- a player whose level and roles are secret
            world.player(10, { leaderName = "Vol'jin" }, {
                classFilename = world.secret(),
                level = world.secret(),
                areaName = world.secret(),
                lfgRoles = world.secret(),
            })
            t:assertEqual(module.labels.listing(10), "Vol'jin, Deadmines")
            -- no listing at all
            t:assertEqual(module.labels.listing(404), "Group")
        end)
    end,

    ["a secret value is left out whichever of the game's two checks tells it"] = function(t)
        withWorld(nil, function(world)
            local entry = { name = "Arthas", level = world.SECRET_NUMBER, classFilename = "MAGE", text = "Hi" }
            -- only issecretvalue exists
            canaccessvalue = nil
            t:assertEqual(module.labels.whisper(entry), "Arthas: Hi")
            -- only canaccessvalue knows
            issecretvalue = function()
                return false
            end
            canaccessvalue = function(value)
                return value ~= world.SECRET_NUMBER
            end
            t:assertEqual(module.labels.whisper(entry), "Arthas: Hi")
            -- and neither check exists on a client without secrets
            issecretvalue, canaccessvalue = nil, nil
            entry.level = 12
            t:assertEqual(module.labels.whisper(entry), "Arthas, level 12 Mage: Hi")
        end)
    end,

    ["a class the game has no name for is said by its file name"] = function(t)
        withWorld(nil, function()
            t:assertEqual(
                module.labels.whisper({ name = "Arthas", level = 55, classFilename = "DEATHKNIGHT", text = "Hi" }),
                "Arthas, level 55 DEATHKNIGHT: Hi"
            )
            -- a level the game keeps hidden leaves the class out too
            t:assertEqual(module.labels.whisper({ name = "Arthas", classFilename = "MAGE", text = "Hi" }), "Arthas: Hi")
        end)
    end,

    ["a whisper says who wrote it, level and class, and what"] = function(t)
        withWorld(nil, function(world)
            local labels = module.labels
            t:assertEqual(
                labels.whisper({ name = "Aragorn", level = 30, classFilename = "WARRIOR", text = "Hello there" }),
                "Aragorn, level 30 Warrior: Hello there"
            )
            t:assertEqual(labels.whisper({ name = "Aragorn", text = "Hi" }), "Aragorn: Hi")
            t:assertEqual(
                labels.whisper({ name = "Aragorn", text = world.secret() }),
                "Aragorn: message unavailable"
            )
            t:assertEqual(labels.whisper({ name = world.secret(), text = "Hi" }), "Hi")
            t:assertNil(labels.whisper(nil))
        end)
    end,

    ["an ally says who, level and class, what you did together; the stars say their number"] = function(t)
        withWorld(nil, function()
            local labels = module.labels
            t:assertEqual(
                labels.ally({ name = "Legolas", level = 40, classFilename = "MAGE", text = "Deadmines, 2 hours ago" }),
                "Legolas, level 40 Mage, Deadmines, 2 hours ago"
            )
            t:assertEqual(labels.ally({}), "Player")
            t:assertEqual(labels.rating(2), "rated 2 of 3 stars")
            t:assertEqual(labels.rating(nil), "not rated")
            t:assertEqual(labels.rating(0), "not rated")
        end)
    end,
})

-- ------------------------------------------------------------------ screen

testRunner:addSuite("LFGForeverScreen", {
    ["nothing of LFG Forever yet, nothing is drawn and nothing is said"] = function(t)
        withWorld({ installed = false }, function(world)
            t:assertEqual(#walk(), 0)
            t:assertEqual(#world.spoken, 0)
        end)
    end,

    ["a closed window draws nothing"] = function(t)
        withWorld(nil, function(world)
            world.frame:Hide()
            t:assertEqual(#walk(), 0)
        end)
    end,

    ["a window without its panels says once that it cannot be read"] = function(t)
        withWorld(nil, function(world)
            world.frame.Content = nil
            t:assertEqual(#walk(), 0)
            t:assertEqual(#walk(), 0)
            t:assertEqual(#world.spoken, 1, "said once, not on every tick")
            t:assertEqual(world.spoken[1], "LFG Forever's window has changed and cannot be read")
            t:assertEqual(#world.errors, 0, "a message, not an error")
        end)
    end,

    ["the stops, in order, with the filters tab open"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            t:assertEqual(
                stops(walk()),
                "tabs search results filters:groups filters:roles filters:classes filters:misc options"
            )
        end)
    end,

    ["the tabs say which one is open and follow the tab the window shows"] = function(t)
        withWorld(nil, function(world)
            t:assertEqual(
                joined(walk(), "tabs"),
                "Filters, Button, selected, 1 of 3|Whispers, Button, 2 of 3|Player ratings, Button, 3 of 3"
            )
            world.openTab("whispers")
            local rows = walk()
            t:assertTrue(find(rows, "Whispers", "tabs").text:find("selected", 1, true) ~= nil)
            t:assertNil(find(rows, "Filters", "tabs").text:find("selected", 1, true))
            world.openTab("ratings")
            t:assertTrue(find(walk(), "Player ratings", "tabs").text:find("selected", 1, true) ~= nil)
            t:assertEqual(module.currentTab(world.filter), "ratings")
        end)
    end,

    ["the ratings tab is not offered when LFG Forever hides it"] = function(t)
        withWorld(nil, function(world)
            world.filter.tabButtons[3].shown = false
            local rows = walk()
            t:assertEqual(#texts(rows, "tabs"), 2)
            t:assertNil(find(rows, "Player ratings", "tabs"))
        end)
    end,

    ["a tab is a real click on LFG Forever's tab button"] = function(t)
        withWorld(nil, function(world)
            local tab = find(walk(), "Whispers", "tabs")
            local spec = binding(tab.vtable, "leftClick")
            t:assertEqual(spec.type, "Click")
            t:assertTrue(resolve(spec.target) == world.filter.tabButtons[2], "the click goes to the Whispers tab's button")
            t:assertNil(binding(tab.vtable, "rightClick"), "no right click on a tab")
        end)
    end,

    ["the search stop names the menus and clicks the real buttons"] = function(t)
        withWorld(nil, function(world)
            local rows = walk()
            t:assertEqual(
                joined(rows, "search"),
                "Category, Dungeons, Dropdown, 1 of 4|Activity, All activities, Dropdown, 2 of 4|Search, Button, 3 of 4|Role check, Button, 4 of 4"
            )
            t:assertTrue(
                resolve(binding(find(rows, "Search", "search").vtable, "leftClick").target) == world.filter.SearchButton
            )
            -- Enter on a menu opens it
            find(rows, "Category", "search").vtable.onActivate()
            t:assertTrue(world.filter.CategoryDropdown.menuOpened, "the category menu opened")
        end)
    end,

    ["a menu that shows its own name is not said twice"] = function(t)
        withWorld(nil, function(world)
            world.filter.CategoryDropdown.text = "category"
            t:assertEqual(find(walk(), "Category", "search").text, "Category, Dropdown, 1 of 4")
        end)
    end,

    ["Search says it is disabled while a search runs, and Role check hides when it does"] = function(t)
        withWorld(nil, function(world)
            world.filter.SearchButton.enabled = false
            world.filter.RoleCheckButton.shown = false
            local rows = walk()
            t:assertTrue(find(rows, "Search", "search").text:find("Disabled", 1, true) ~= nil)
            t:assertNil(find(rows, "Role check", "search"))
        end)
    end,

    ["the first stop is the search, where a first press of Tab lands"] = function(t)
        withWorld(nil, function()
            local _, render = walk()
            t:assertNotNil(render.startKey)
            t:assertEqual(render.nodes[render.startKey.key].stopKey, "search")
        end)
    end,

    ["results: empty before a search, with a word while one runs"] = function(t)
        withWorld(nil, function(world)
            t:assertEqual(joined(walk(), "results"), "Empty")
            world.list.SearchingSpinner.shown = true
            t:assertEqual(texts(walk(), "results")[1], "Searching, 1 of 2")
        end)
    end,

    ["results: the headers and the listings, one line each, with what Enter does"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local lines = texts(walk(), "results")
            t:assertEqual(#lines, 6)
            t:assertEqual(lines[1], "Groups, 2, Button, Expanded, 1 of 6")
            t:assertEqual(
                lines[2],
                "Thrall, Deadmines, 3 members (1 Tank, 2 Damage), LF healer, fast please, Button, Ask to join, 2 of 6"
            )
            t:assertEqual(lines[3], "Garrosh, Deadmines, 5 members, Button, Ask to join, already asked, 3 of 6")
            t:assertEqual(lines[4], "Players, 2, Button, Expanded, 4 of 6")
            t:assertEqual(
                lines[5],
                "Jaina, level 17 Mage, roles: Damage, Deadmines, in Westfall, Need a dungeon, Button, Invite, 5 of 6"
            )
            t:assertEqual(
                lines[6],
                "Anduin, level 21 Priest, roles: Healer, Deadmines, in Duskwood, welcomes new players, Button, Invite, 6 of 6"
            )
        end)
    end,

    ["results: what Enter does is said once the row is drawn"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local rows = walk()
            t:assertEqual(find(rows, "Thrall", "results").vtable.announcements[2].text(), "Ask to join")
            t:assertEqual(find(rows, "Jaina", "results").vtable.announcements[2].text(), "Invite")
            -- a row not drawn yet says nothing more
            world.list.ScrollBox.frames[world.nodes[1]] = nil
            t:assertNil(find(walk(), "Thrall", "results").vtable.announcements[2].text())
        end)
    end,

    ["results: Enter asks a group to take you, invites a player, and the right click is the game's menu"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local rows = walk()
            local box = world.list.ScrollBox
            local thrall = find(rows, "Thrall", "results")
            local row1 = box.frames[world.nodes[1]]
            t:assertTrue(resolve(binding(thrall.vtable, "leftClick").target) == row1.LFGFAskToJoin, "a group: Ask to Join")
            t:assertEqual(binding(thrall.vtable, "leftClick").emulatedKey, "LeftButton")
            t:assertTrue(resolve(binding(thrall.vtable, "rightClick").target) == row1, "right click: the row")
            t:assertEqual(binding(thrall.vtable, "rightClick").emulatedKey, "RightButton")
            local jaina = find(rows, "Jaina", "results")
            local row3 = box.frames[world.nodes[3]]
            t:assertTrue(resolve(binding(jaina.vtable, "leftClick").target) == row3.LFGFInvite, "a player: Invite")
        end)
    end,

    ["results: a listing with no action button (yours, removed) falls back to the row"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local row = world.list.ScrollBox.frames[world.nodes[1]]
            row.LFGFAskToJoin.shown = false
            local thrall = find(walk(), "Thrall", "results")
            t:assertTrue(resolve(binding(thrall.vtable, "leftClick").target) == row, "the row itself")
        end)
    end,

    ["results: the context menu lists the actions that apply, then the right click menu"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local rows = walk()
            t:assertEqual(actionLabels(find(rows, "Thrall", "results").vtable), "Ask to join|Right click menu")
            t:assertEqual(actionLabels(find(rows, "Jaina", "results").vtable), "Invite|Right click menu")
            local actions = contextActions(find(rows, "Thrall", "results").vtable)
            t:assertTrue(actions[1].click.target == world.list.ScrollBox.frames[world.nodes[1]].LFGFAskToJoin)
            t:assertEqual(actions[1].click.emulatedKey, "LeftButton")
            t:assertEqual(actions[2].click.emulatedKey, "RightButton")
        end)
    end,

    ["results: your own listing is removed with Enter, LFG Forever's own delist button"] = function(t)
        withWorld(nil, function(world)
            world.group(1, { leaderName = "Me", numMembers = 2, hasSelf = true })
            fillResults(world, { { divider = "group", rows = { { id = 1, kind = "own" } } } })
            local rows = walk()
            local mine = find(rows, "Me", "results")
            local row = world.list.ScrollBox.frames[world.nodes[1]]
            t:assertEqual(mine.vtable.announcements[2].text(), "Remove my listing")
            t:assertTrue(resolve(binding(mine.vtable, "leftClick").target) == row.LFGFDelist, "Enter: the delist button")
            t:assertEqual(binding(mine.vtable, "leftClick").emulatedKey, "LeftButton")
            t:assertEqual(actionLabels(mine.vtable), "Remove my listing|Right click menu")
            t:assertTrue(contextActions(mine.vtable)[1].click.target == row.LFGFDelist)
            t:assertTrue(mine.text:find("your own listing", 1, true) ~= nil)
            -- in a group you do not lead LFG Forever hides the button: nothing is offered
            row.LFGFDelist.shown = false
            mine = find(walk(), "Me", "results")
            t:assertNil(mine.vtable.announcements[2].text())
            t:assertEqual(actionLabels(mine.vtable), "Right click menu")
            t:assertTrue(resolve(binding(mine.vtable, "leftClick").target) == row, "the row itself")
        end)
    end,

    ["results: a guild member, a friend and your rating are said from the drawn row"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local box = world.list.ScrollBox
            local thrall, garrosh = box.frames[world.nodes[1]], box.frames[world.nodes[2]]
            local jaina, anduin = box.frames[world.nodes[3]], box.frames[world.nodes[4]]
            thrall.LFGFRelation = relationIcon("guild")
            thrall.LFGFRatingStrip = strip(1, 32 / 255, 32 / 255)
            garrosh.LFGFRelation = relationIcon(nil)
            garrosh.LFGFRatingStrip = strip(192 / 255, 192 / 255, 192 / 255, false)
            jaina.LFGFRelation = relationIcon("friend")
            anduin.LFGFRatingStrip = strip(64 / 255, 192 / 255, 64 / 255)
            local rows = walk()
            local function said(name)
                return find(rows, name, "results").vtable.announcements[3].text()
            end
            t:assertEqual(said("Thrall"), "guild member, lowest rating in the group: 1 of 3 stars")
            t:assertNil(said("Garrosh"), "a hidden icon and a hidden strip say nothing")
            t:assertEqual(said("Jaina"), "friend")
            t:assertEqual(said("Anduin"), "rated 3 of 3 stars", "a player: your rating of them")
            t:assertEqual(
                find(rows, "Thrall", "results").text,
                "Thrall, Deadmines, 3 members (1 Tank, 2 Damage), LF healer, fast please, Button, Ask to join, "
                    .. "guild member, lowest rating in the group: 1 of 3 stars, 2 of 6"
            )
            -- silver is 2 stars
            garrosh.LFGFRatingStrip.shown = true
            t:assertEqual(said("Garrosh"), "lowest rating in the group: 2 of 3 stars")
            -- a row not drawn yet says nothing more
            box.frames[world.nodes[1]] = nil
            t:assertNil(find(walk(), "Thrall", "results").vtable.announcements[3].text())
        end)
    end,

    ["results: a strip colour that is none of LFG Forever's three, or a secret one, is no rating"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local game = module.game
            t:assertNil(game.stripRating(strip(0.2, 0.2, 1)), "blue is none of the three")
            t:assertNil(game.stripRating(strip(world.secret(), 0.5, 0.5)), "a secret colour")
            t:assertNil(game.stripRating(nil))
            t:assertNil(game.stripRating(newFrame({})), "not a texture")
            t:assertEqual(game.stripRating(strip(1, 0.13, 0.12)), 1, "close to the red counts")
            -- the game's red is asked of the game when it has one
            RED_FONT_COLOR = {
                GetRGB = function()
                    return 0.9, 0.3, 0.3
                end,
            }
            t:assertEqual(game.stripRating(strip(0.9, 0.3, 0.3)), 1)
            t:assertNil(game.stripRating(strip(1, 32 / 255, 32 / 255)), "no longer the game's red")
            t:assertNil(module.game.relation(relationIcon("enemy")), "a relation LFG Forever does not have")
            t:assertNil(module.game.relation(newFrame({ relation = world.secret() })))
        end)
    end,

    ["results: a header folds and unfolds by a real click, and says which"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local header = find(walk(), "Groups", "results")
            local spec = binding(header.vtable, "leftClick")
            t:assertTrue(resolve(spec.target) == world.list.ScrollBox.frames[world.nodes.group])
            t:assertEqual(spec.emulatedKey, "LeftButton")
            -- folded: its listings are gone from the list and the header says so, with how many it holds
            fillResults(world, {
                { divider = "group", collapsed = true, rows = { { id = 1, kind = "group" }, { id = 2, kind = "group" } } },
                { divider = "solo", rows = { { id = 3, kind = "solo" } } },
            })
            local lines = texts(walk(), "results")
            t:assertEqual(lines[1], "Groups, 2, Button, Collapsed, 1 of 3")
            t:assertEqual(#lines, 3)
        end)
    end,

    ["results: a header is folded or not by its own state, whichever way the tree says it"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            -- a node that only has the field (no IsCollapsed method), as WowVision's own list reads it
            local node = world.nodes.group
            node.IsCollapsed = nil
            node.collapsed = true
            t:assertEqual(texts(walk(), "results")[1], "Groups, 2, Button, Collapsed, 1 of 6")
            node.collapsed = false
            t:assertEqual(texts(walk(), "results")[1], "Groups, 2, Button, Expanded, 1 of 6")
        end)
    end,

    ["results: moving to a row scrolls it into view and hovers it"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local box = world.list.ScrollBox
            -- the runner's ExecuteFrameScript records the scripts a frame was asked to run in frame._scripts
            for _, frame in pairs(box.frames) do
                frame._scripts = {}
            end
            local thrall = find(walk(), "Thrall", "results")
            thrall.vtable.onFocus()
            t:assertTrue(#box.scrolled == 1 and box.scrolled[1] == 2, "scrolled to the second line of the list")
            local row = box.frames[world.nodes[1]]
            t:assertEqual(row._scripts[1], "OnEnter", "the row's own OnEnter ran (it shows the group's tooltip)")
            t:assertTrue(resolve(thrall.vtable.tooltipFrame) == row)
        end)
    end,

    ["results: unreadable listings are still lines, and never an error"] = function(t)
        withWorld(nil, function(world)
            world.group(1, {
                leaderName = world.secret(),
                numMembers = world.secret(),
                activityIDs = world.secret(),
                comment = world.secret(),
            })
            fillResults(world, { { divider = "group", rows = { { id = 1, kind = "group" } } } })
            t:assertEqual(texts(walk(), "results")[2], "Group, details unavailable, Button, Ask to join, 2 of 2")
            t:assertEqual(#world.errors, 0)
        end)
    end,

    ["filters: every section is a stop with its header and its controls, read from LFG Forever's own words"] = function(t)
        withWorld(nil, function()
            local rows = walk()
            t:assertEqual(
                joined(rows, "filters:groups"),
                "Groups, Button, Expanded, 1 of 7|Tank role available, Checkbox, Unchecked, 2 of 7|Healer role available, Checkbox, Checked, 3 of 7|Has tank, Checkbox, Unchecked, 4 of 7|No groups with..., Dropdown, 5 of 7|Reset filters, Button, 6 of 7|Save new filter, Button, 7 of 7"
            )
            t:assertEqual(
                joined(rows, "filters:roles"),
                "Player roles, Button, Expanded, 1 of 6|Tank, Checkbox, Checked, 2 of 6|Healer, Checkbox, Checked, 3 of 6|Damage, Checkbox, Checked, 4 of 6|Player level range, minimum, EditBox, 5 of 6|Player level range, maximum, EditBox, 20, 6 of 6"
            )
            t:assertEqual(
                joined(rows, "filters:classes"),
                "Player classes, Button, Expanded, 1 of 5|Mage, Checkbox, Checked, 2 of 5|Warrior, Checkbox, Checked, 3 of 5|Unselect all, Button, 4 of 5|Select all, Button, 5 of 5"
            )
            t:assertEqual(
                joined(rows, "filters:misc"),
                "Miscellaneous, Button, Expanded, 1 of 3|Play style, All, Dropdown, 2 of 3|Languages, English, Dropdown, 3 of 3"
            )
        end)
    end,

    ["filters: a check box is the real one, and the level boxes take typing"] = function(t)
        withWorld(nil, function(world)
            local rows = walk()
            local tank = find(rows, "Tank role available", "filters:groups")
            t:assertTrue(resolve(binding(tank.vtable, "leftClick").target) == world.filter.GroupFilterChecks[1])
            find(rows, "Player level range, maximum", "filters:roles").vtable.onActivate()
            t:assertTrue(world.filter.LevelRange.MaxLevel.focused, "Enter puts the cursor in the box")
        end)
    end,

    ["filters: a folded section shows its header and the controls on its title row only, and its warning"] = function(t)
        withWorld(nil, function(world)
            local section = world.filter.GroupSection
            section.collapsed = true
            section.Content.shown = false
            section.Header.Warning.shown = true
            world.filter.MyFiltersDropdown.shown = true
            local rows = walk()
            t:assertEqual(
                joined(rows, "filters:groups"),
                "Groups, Button, Collapsed, has changed filters, 1 of 4|Reset filters, Button, 2 of 4|Save new filter, Button, 3 of 4|My filters, Dropdown, 4 of 4"
            )
            t:assertNil(find(rows, "Tank role available"))
            -- the header is the real one: a click folds or unfolds it
            local header = find(rows, "Groups", "filters:groups")
            t:assertTrue(resolve(binding(header.vtable, "leftClick").target) == section.Header)
            -- the other sections are unaffected
            t:assertEqual(#texts(rows, "filters:roles"), 6)
        end)
    end,

    ["filters: a section LFG Forever has folded lists nothing of it, even while its content still reads as shown"] = function(t)
        withWorld(nil, function(world)
            world.filter.RoleSection.collapsed = true
            t:assertTrue(world.filter.RoleSection.Content:IsShown())
            t:assertEqual(joined(walk(), "filters:roles"), "Player roles, Button, Collapsed")
        end)
    end,

    ["filters: a section is named by LFG Forever's own title"] = function(t)
        withWorld(nil, function()
            local header = find(walk(), "Player roles", "filters:roles")
            t:assertEqual(header.node.parent.vtable.announcements[1].text, "Player roles")
        end)
    end,

    ["filters: a section whose content is hidden lists nothing of it, whatever its flag says"] = function(t)
        withWorld(nil, function(world)
            world.filter.RoleSection.Content.shown = false
            t:assertEqual(joined(walk(), "filters:roles"), "Player roles, Button, Expanded")
        end)
    end,

    ["filters: the controls only show when LFG Forever shows them"] = function(t)
        withWorld(nil, function(world)
            world.filter.GroupClassDropdown.shown = false
            world.filter.LevelRange.shown = false
            world.filter.PlaystyleDropdown.shown = false
            local rows = walk()
            t:assertNil(find(rows, "No groups with"))
            t:assertNil(find(rows, "Player level range"))
            t:assertNil(find(rows, "Play style"))
            t:assertNotNil(find(rows, "Languages"))
        end)
    end,

    ["filters: Options holds LFG Forever's settings"] = function(t)
        withWorld(nil, function(world)
            local settings = find(walk(), "Settings", "options")
            t:assertTrue(resolve(binding(settings.vtable, "leftClick").target) == world.filter.SettingsGear)
        end)
    end,

    ["whispers: the tab lists the whispers, Enter opens the line's menu, the actions are in its context menu"] = function(t)
        withWorld(nil, function(world)
            local entries = fillWhispers(world)
            world.openTab("whispers")
            local rows = walk()
            t:assertEqual(stops(rows), "tabs search results whispers options")
            t:assertEqual(
                joined(rows, "whispers"),
                "Aragorn, level 30 Warrior: Hello there, Button, 1 of 3|Boromir: Need a hand?, Button, 2 of 3|Clear chat, Button, 3 of 3"
            )
            local box = world.filter.WhisperLog.ScrollBox
            local aragorn = find(rows, "Aragorn", "whispers")
            local spec = binding(aragorn.vtable, "leftClick")
            t:assertEqual(spec.emulatedKey, "RightButton", "Enter is a right click: the menu")
            t:assertTrue(resolve(spec.target) == box.frames[entries[1]])
            local actions = contextActions(aragorn.vtable)
            t:assertEqual(#actions, 2, "the Location link is hidden, so it is not offered")
            t:assertEqual(actions[1].label, "Invite")
            t:assertEqual(actions[2].label, "Remove")
            t:assertTrue(actions[1].click.target == box.frames[entries[1]].InviteLink)
            box.frames[entries[1]].LocationLink.shown = true
            actions = contextActions(find(walk(), "Aragorn", "whispers").vtable)
            t:assertEqual(actions[2].label, "Where is this player")
            t:assertTrue(find(rows, "Clear chat", "whispers").text:find("Button", 1, true) ~= nil)
        end)
    end,

    ["whispers and ratings: a guild member, a friend and your rating of the sender are said from the drawn row"] = function(t)
        withWorld(nil, function(world)
            local entries = fillWhispers(world)
            local box = world.filter.WhisperLog.ScrollBox
            box.frames[entries[1]].Relation = relationIcon("friend")
            box.frames[entries[1]].RatingStrip = strip(192 / 255, 192 / 255, 192 / 255)
            world.openTab("whispers")
            local rows = walk()
            t:assertEqual(
                find(rows, "Aragorn", "whispers").text,
                "Aragorn, level 30 Warrior: Hello there, Button, friend, rated 2 of 3 stars, 1 of 3"
            )
            t:assertEqual(find(rows, "Boromir", "whispers").text, "Boromir: Need a hand?, Button, 2 of 3")
            local allies = fillAllies(world)
            world.filter.PlayerRatings.ScrollBox.frames[allies[2]].Relation = relationIcon("guild")
            world.openTab("ratings")
            t:assertEqual(find(walk(), "Gimli", "ratings").text, "Gimli, Button, not rated, guild member, 2 of 3")
        end)
    end,

    ["whispers: an empty log says it is empty"] = function(t)
        withWorld(nil, function(world)
            world.openTab("whispers")
            t:assertEqual(joined(walk(), "whispers"), "Empty, 1 of 2|Clear chat, Button, 2 of 2")
        end)
    end,

    ["ratings: the tab lists the recent allies with their stars, the stars are in the context menu"] = function(t)
        withWorld(nil, function(world)
            local entries = fillAllies(world)
            world.openTab("ratings")
            local rows = walk()
            t:assertEqual(stops(rows), "tabs search results ratings options")
            t:assertEqual(
                joined(rows, "ratings"),
                "Legolas, level 40 Mage, Deadmines, Button, rated 2 of 3 stars, 1 of 3|Gimli, Button, not rated, 2 of 3|Clear a rating, Button, 3 of 3"
            )
            local box = world.filter.PlayerRatings.ScrollBox
            local legolas = find(rows, "Legolas", "ratings")
            local labels, clicks = {}, {}
            for _, entry in ipairs(contextActions(legolas.vtable)) do
                labels[#labels + 1] = entry.label
                clicks[#clicks + 1] = resolve(entry.click.target)
            end
            t:assertEqual(table.concat(labels, "|"), "Rate 1 star|Rate 2 stars|Rate 3 stars|Right click menu")
            local stars = box.frames[entries[1]].Stars
            t:assertTrue(
                clicks[1] == stars.Buttons[1] and clicks[2] == stars.Buttons[2] and clicks[3] == stars.Buttons[3],
                "each star's own button"
            )
            t:assertTrue(clicks[4] == box.frames[entries[1]], "the right click menu: the row")
            t:assertEqual(binding(legolas.vtable, "leftClick").emulatedKey, "RightButton")
            t:assertTrue(find(rows, "Clear a rating", "ratings").text:find("Button", 1, true) ~= nil)
        end)
    end,

    ["ratings: a rating the game keeps secret is said as not rated"] = function(t)
        withWorld(nil, function(world)
            local entries = fillAllies(world)
            world.filter.PlayerRatings.ScrollBox.frames[entries[1]].Stars.rating = world.SECRET_NUMBER
            world.openTab("ratings")
            t:assertEqual(
                find(walk(), "Legolas", "ratings").text,
                "Legolas, level 40 Mage, Deadmines, Button, not rated, 1 of 3"
            )
            t:assertEqual(#world.errors, 0)
        end)
    end,

    ["ratings: the stars of a row that is not drawn yet are not guessed"] = function(t)
        withWorld(nil, function(world)
            local entries = fillAllies(world)
            local box = world.filter.PlayerRatings.ScrollBox
            box.frames[entries[1]] = nil
            world.openTab("ratings")
            local rows = walk()
            t:assertEqual(find(rows, "Legolas", "ratings").text, "Legolas, level 40 Mage, Deadmines, Button, 1 of 3")
            -- and a click on a star that is not there is nothing
            t:assertNil(resolve(contextActions(find(rows, "Legolas", "ratings").vtable)[1].click.target))
            -- a row that is there but not filled yet has no stars: nothing is said of them
            box.frames[entries[1]] = newFrame({})
            rows = walk()
            t:assertEqual(find(rows, "Legolas", "ratings").text, "Legolas, level 40 Mage, Deadmines, Button, 1 of 3")
            t:assertNil(resolve(contextActions(find(rows, "Legolas", "ratings").vtable)[1].click.target))
        end)
    end,

    ["the filters tab is the one read when no section says otherwise"] = function(t)
        withWorld(nil, function(world)
            world.openTab("none")
            t:assertEqual(module.currentTab(world.filter), "filters")
            t:assertEqual(stops(walk()), "tabs search results options")
        end)
    end,

    ["a listing keeps its place by its own number, whatever line it is on"] = function(t)
        withWorld(nil, function(world)
            usualSearch(world)
            local rows = walk()
            t:assertEqual(find(rows, "Thrall", "results").node.id.key, "result:1")
            t:assertEqual(find(rows, "Jaina", "results").node.id.key, "result:3")
            t:assertEqual(find(rows, "Groups", "results").node.id.key, "resultsHeader:group")
        end)
    end,

    ["an error in the middle of the tabs row is reported once and the rest is read"] = function(t)
        withWorld(nil, function(world)
            world.filter.tabButtons[2] = setmetatable({}, {
                __index = function()
                    error("lfgForeverRowBoom")
                end,
            })
            local rows = walk()
            walk()
            t:assertEqual(#world.errors, 1, "reported once, and the row was closed so the next part could start")
            t:assertTrue(world.errors[1]:find("lfgForeverRowBoom", 1, true) ~= nil)
            t:assertEqual(
                stops(rows),
                "tabs search results filters:groups filters:roles filters:classes filters:misc options"
            )
            t:assertEqual(#texts(rows, "tabs"), 1, "the tab before the failure stays")
        end)
    end,

    ["a control that is not what it was expected to be is reported once and the rest is read"] = function(t)
        withWorld(nil, function(world)
            world.filter.PlayerRoleChecks = {
                setmetatable({}, {
                    __index = function()
                        error("lfgForeverTestBoom")
                    end,
                }),
            }
            local rows = walk()
            local again = walk()
            t:assertEqual(#world.errors, 1, "reported once, not on every tick")
            t:assertTrue(world.errors[1]:find("lfgForeverTestBoom", 1, true) ~= nil)
            -- what was built before the error stays (the section's header), what it could not build does not
            t:assertEqual(
                stops(rows),
                "tabs search results filters:groups filters:roles filters:classes filters:misc options"
            )
            t:assertEqual(#texts(rows, "filters:roles"), 1)
            t:assertEqual(#again, #rows)
            -- the contexts were closed again: what follows is still inside the window, a sibling of the sections before
            local mage = find(rows, "Mage", "filters:classes").node
            local settings = find(rows, "Settings", "options").node
            t:assertTrue(mage.parent ~= nil and mage.parent.parent ~= nil, "inside the window")
            t:assertTrue(mage.parent.parent == settings.parent.parent, "the window's context, not the failed section's")
            local category = find(rows, "Category", "search").node
            t:assertTrue(category.parent.parent == mage.parent.parent, "the same context as the parts before the failure")
        end)
    end,
})

-- ------------------------------------------------- window, key and command

testRunner:addSuite("LFGForeverWindow", {
    ["the window follows LFG Forever's frame, over WowVision's FrameWindow"] = function(t)
        local window = harness.registered.windows.lfgForever
        t:assertNotNil(window)
        t:assertEqual(window.type, "FrameWindow")
        t:assertEqual(window.frameName, "LFGForeverFrame")
        t:assertEqual(window.conflictingAddons[1], "Sku")
        t:assertEqual(type(window.graphScreen.render), "function")
    end,

    ["Escape closes LFG Forever's window with a plain Hide"] = function(t)
        withWorld(nil, function(world)
            local close = harness.registered.windows.lfgForever.graphScreen.onRequestClose
            close()
            t:assertEqual(world.frame.hides, 1)
            t:assertFalse(world.frame:IsShown())
            t:assertEqual(#world.errors, 0)
            -- the window exists once LFG Forever has built it: before that, Escape does nothing and is no error
            world.uninstall()
            close()
            t:assertEqual(#world.errors, 0)
        end)
    end,

    ["Alt+Ctrl+G opens and closes LFG Forever, as a binding of the Bindings screen"] = function(t)
        withWorld(nil, function(world)
            local info = harness.registered.bindings["lfgForever/open"]
            t:assertNotNil(info)
            t:assertEqual(info.inputs[1], "ALT-CTRL-G")
            t:assertEqual(#info.inputs, 1)
            t:assertEqual(info.type, "Function")
            t:assertTrue(info.interruptSpeech)
            t:assertEqual(info.label, "Open or Close LFG Forever")
            t:assertEqual(info.conflictingAddons[1], "Sku")
            info.func()
            t:assertEqual(world.toggled, 1)
            t:assertFalse(world.frame:IsShown())
            info.func()
            t:assertEqual(world.toggled, 2)
            t:assertTrue(world.frame:IsShown())
        end)
    end,

    ["/wv lfg does the same as the key"] = function(t)
        withWorld(nil, function(world)
            local command = harness.registered.commands.lfg
            t:assertNotNil(command)
            t:assertEqual(command.conflictingAddons[1], "Sku")
            command.func()
            command.func()
            t:assertEqual(world.toggled, 2)
        end)
    end,

    ["a toggle LFG Forever no longer has is said, not an error"] = function(t)
        withWorld({ installed = false }, function(world)
            harness.registered.bindings["lfgForever/open"].func()
            t:assertEqual(world.spoken[#world.spoken], "LFG Forever cannot be opened from here, type /lfg")
            t:assertEqual(#world.errors, 0)
        end)
    end,

    ["a toggle that fails is reported once and raises nothing"] = function(t)
        withWorld(nil, function(world)
            LFGForever_ToggleWindow = function()
                error("lfgForeverToggleBoom")
            end
            local func = harness.registered.bindings["lfgForever/open"].func
            func()
            func()
            t:assertEqual(#world.errors, 1)
            t:assertTrue(world.errors[1]:find("lfgForeverToggleBoom", 1, true) ~= nil)
        end)
    end,

    ["without LFG Forever there is no module, no window, no key and no command"] = function(t)
        local absent, registered = harness.load({ Sku = true })
        t:assertNil(absent)
        t:assertNil(next(registered.windows))
        t:assertNil(next(registered.bindings))
        t:assertNil(next(registered.commands))
        absent, registered = harness.load(nil)
        t:assertNil(absent)
        t:assertNil(next(registered.windows))
    end,
})
