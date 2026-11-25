local ns = WowVision.nameSources
local L = ns.L
local Names = ns.Names
local Sources = ns.Sources

local module = WowVision.base.navigation.wownav:createModule("nameSources")
module:setLabel(L["Name Sources"])
ns.module = module
local settings = module:hasSettings()
-- Off: it walks Questie's database for a while at login.
local complete = settings:add({ type = "Bool", key = "complete", label = L["Complete Missing Names"], default = false })

-- An error here must never break an event or a command, and must not repeat on every call either.
local reported = {}
local function report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("Name sources: " .. err)
end
ns.report = report

local function guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            report(err)
        end
    end
end

-- ---------------------------------------------------------------- the game

-- Everything this addon asks of the game and of the other addons, in one table, so the tests can replace it.
local Game = {}
ns.Game = Game

function Game.locale()
    return GetLocale ~= nil and GetLocale() or "enUS"
end

function Game.isEnglish(locale)
    return locale == "enUS" or locale == "enGB"
end

function Game.library()
    local library = rawget(_G, "LibQuestieDB")
    if type(library) == "table" then
        return library
    end
    return nil
end

local function entity(typeName)
    local db = rawget(_G, typeName .. "DB")
    if type(db) == "table" then
        return db
    end
    return nil
end

function Game.ids(typeName)
    local db = entity(typeName)
    if db == nil or type(db.GetAllIds) ~= "function" then
        return nil
    end
    local ok, ids = pcall(db.GetAllIds)
    if ok and type(ids) == "table" then
        return ids
    end
    return nil
end

function Game.raw(typeName, id, field)
    local db = entity(typeName)
    if db == nil or type(db.GetRaw) ~= "function" then
        return nil
    end
    local ok, value = pcall(db.GetRaw, id, field)
    if ok then
        return value
    end
    return nil
end

function Game.get(typeName, id, field)
    local db = entity(typeName)
    if db == nil or type(db.Get) ~= "function" then
        return nil
    end
    local ok, value = pcall(db.Get, id, field)
    if ok then
        return value
    end
    return nil
end

-- The walk reads a lot of entries; what the database remembered of them is of no use afterwards.
function Game.release(typeName)
    local db = entity(typeName)
    if db ~= nil and type(db.InvalidateCache) == "function" then
        pcall(db.InvalidateCache)
    end
end

function Game.now()
    if debugprofilestop ~= nil then
        return debugprofilestop()
    end
    if os ~= nil and os.clock ~= nil then
        return os.clock() * 1000
    end
    return 0
end

function Game.metadata(addon, field)
    local read = (C_AddOns ~= nil and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if read == nil then
        return nil
    end
    local ok, value = pcall(read, addon, field)
    if ok then
        return value
    end
    return nil
end

function Game.inCombat()
    return InCombatLockdown ~= nil and InCombatLockdown() == true
end

-- What the outside sources are given (see Sources.build).
function Game.sourceEnv(registered)
    local scan = WowVision ~= nil and WowVision.minimapScan or nil
    local l10n = nil
    local loader = rawget(_G, "QuestieLoader")
    if type(loader) == "table" and type(loader.ImportModule) == "function" then
        local ok, module = pcall(loader.ImportModule, loader, "l10n")
        if ok and type(module) == "table" then
            l10n = module
        end
    end
    return {
        locale = Game.locale(),
        registered = registered,
        gathering = scan ~= nil and scan.gatheringNames or nil,
        questieTranslations = l10n ~= nil and l10n.translations or nil,
        zoneLookup = l10n ~= nil and l10n.zoneLookup or nil,
        getAreaInfo = C_Map ~= nil and C_Map.GetAreaInfo or nil,
    }
end

-- What says the cache is still the right one: the database's version and size, and what the sources offered.
function Game.stamp(signature)
    local counts = {}
    for _, typeName in ipairs({ "Npc", "Object", "Item" }) do
        local ids = Game.ids(typeName)
        counts[#counts + 1] = ids ~= nil and #ids or 0
    end
    return table.concat({
        "v" .. Names.VERSION,
        tostring(Game.metadata("QuestieDB", "Version") or "?"),
        tostring(Game.metadata("QuestieDB", "X-BUILD-COMMIT") or "?"),
        table.concat(counts, "/"),
        signature,
    }, "|")
end

function Game.speak(text)
    if WowVision ~= nil and WowVision.speak ~= nil then
        WowVision:speak(text)
    else
        pcall(print, text)
    end
end

function Game.time()
    return time ~= nil and time() or 0
end

-- The text caches of WowVision's navigation lists (the names Questie answered), forgotten so they are asked again.
function Game.forgetWowVisionNames()
    local text = WowVision ~= nil and WowVision.wownavText or nil
    if text ~= nil and type(text.clearLocalNames) == "function" then
        pcall(text.clearLocalNames)
    end
end

-- ---------------------------------------------------------------- saved data

-- The result of the last walk, in the account store; kept in memory only while the store is not bound.
local memory = {}
local function store()
    local data = module.globalDB ~= nil and module.globalDB.data or nil
    return data or memory
end
ns.store = store

function ns.isEnabled()
    return module:getEnabled() and module.settings.complete == true
end

-- ---------------------------------------------------------------- state

-- phase: idle, english, noLibrary, noCorrection, off, scanning, ready, failed
local state = { phase = "idle" }
ns.state = state

ns.registered = {}
ns.BUDGET = 4 -- milliseconds a frame the walk may take
ns.BUDGET_IN_COMBAT = 1

-- Whether there is anything to do in this game, and if not why.
function ns.available()
    if Game.isEnglish(Game.locale()) then
        return false, "english"
    end
    local library = Game.library()
    if library == nil or entity("Npc") == nil or entity("Object") == nil then
        return false, "noLibrary"
    end
    if type(library.l10n) ~= "table" or type(library.l10n.SetCorrection) ~= "function" or type(library.Meta) ~= "table" then
        return false, "noCorrection"
    end
    return true
end

local function metaKeys(library, typeName)
    local meta = library.Meta[typeName]
    return type(meta) == "table" and meta.keys or nil
end

-- Gives the rows to the database (nil withdraws ours). True when every type took them.
function ns.apply(rows)
    local library = Game.library()
    if library == nil or type(library.l10n) ~= "table" or type(library.l10n.SetCorrection) ~= "function" then
        return false
    end
    local locale = Game.locale()
    local converted = Names.corrections(rows or { Npc = {}, Object = {} }, {
        Npc = metaKeys(library, "Npc"),
        Object = metaKeys(library, "Object"),
    })
    local allOk = true
    for _, typeName in ipairs({ "Npc", "Object" }) do
        local forType = converted[typeName]
        if rows == nil or next(forType) == nil then
            forType = nil
        end
        local ok, err = pcall(library.l10n.SetCorrection, Names.OWNER, locale, typeName, Names.SLOT, forType)
        if not ok then
            allOk = false
            report(err)
        end
    end
    Game.forgetWowVisionNames()
    return allOk
end

function ns.withdraw()
    return ns.apply(nil)
end

-- ---------------------------------------------------------------- the walk

local function finish()
    local scan, pending = ns.scan, ns.pending
    ns.scan, ns.pending = nil, nil
    if scan == nil or pending == nil then
        return
    end
    if scan.failed ~= nil then
        state.phase = "failed"
        state.message = scan.failed
        return
    end
    local rows, stats = Names.compute(scan, pending.sources)
    scan = nil
    store().cache = {
        version = Names.VERSION,
        locale = Game.locale(),
        stamp = pending.stamp,
        rows = rows,
        stats = stats,
        builtAt = Game.time(),
    }
    state.phase = "ready"
    state.message = nil
    ns.apply(rows)
    if ns.manual then
        ns.manual = false
        Game.speak(ns.statusText(true))
    end
end

-- One step of the walk; the tests call it themselves, the game calls it every frame.
function ns.pump()
    local scan = ns.scan
    if scan == nil then
        return true
    end
    local ok, done = pcall(scan.step, scan, Game.inCombat() and ns.BUDGET_IN_COMBAT or ns.BUDGET)
    if not ok then
        report(done)
        state.phase = "failed"
        state.message = tostring(done)
        ns.scan, ns.pending = nil, nil
        return true
    end
    if done then
        finish()
        return true
    end
    return false
end

local function beginScan(sources, stamp)
    ns.scan = Names.newScan(Game)
    ns.pending = { sources = sources, stamp = stamp }
    state.phase = "scanning"
    state.message = nil
end

-- Applies the saved result when it is still the right one, else walks the database. force: always walk.
function ns.start(force)
    local ok, why = ns.available()
    if not ok then
        state.phase = why
        return
    end
    if not ns.isEnabled() then
        state.phase = "off"
        return
    end
    if ns.scan ~= nil then
        return
    end
    local sources = Sources.build(Game.sourceEnv(ns.registered))
    local stamp = Game.stamp(Sources.signature(sources))
    local saved = store()
    if not force and Names.cacheMatches(saved.cache, Game.locale(), stamp) then
        ns.apply(saved.cache.rows)
        state.phase = "ready"
        return
    end
    -- the walk must see the database as it is, without our own names
    ns.withdraw()
    saved.cache = nil
    beginScan(sources, stamp)
end

-- The names are added or taken back as the setting says.
function ns.refresh()
    if ns.isEnabled() then
        ns.start(false)
    else
        ns.scan, ns.pending = nil, nil
        ns.withdraw()
        state.phase = "off"
    end
end

function ns.setEnabled(on)
    module.settings.complete = on == true
    ns.refresh()
end

function ns.recalculate()
    if not ns.isEnabled() then
        return false
    end
    ns.manual = true
    ns.start(true)
    if state.phase ~= "scanning" then
        -- nothing was started (not available here), so nothing will be reported when it ends
        ns.manual = false
    end
    return state.phase == "scanning"
end

-- Recalculates and says what happened: that it started, or why it could not.
function ns.recalculateAndSay()
    if ns.recalculate() then
        Game.speak(L["Recalculating the name sources."])
    else
        Game.speak(ns.statusText(false))
    end
end

-- ---------------------------------------------------------------- what is said

local function sourceList(stats)
    local entries = {}
    for key, count in pairs(stats and stats.bySource or {}) do
        entries[#entries + 1] = { key = key, count = count }
    end
    table.sort(entries, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.key < b.key
    end)
    local out = {}
    for _, entry in ipairs(entries) do
        out[#out + 1] = Sources.label(entry.key, L)
    end
    return table.concat(out, ", ")
end

function ns.statusText(justDone)
    if Game.isEnglish(Game.locale()) then
        return L["Not needed: the game is in English."]
    end
    if not ns.isEnabled() then
        return L["Name sources are off."]
    end
    local available, why = ns.available()
    if not available then
        if why == "noCorrection" then
            return L["This version of Questie's database does not accept added names."]
        end
        return L["Questie's database is not there, so there is nothing to complete."]
    end
    local phase = state.phase
    if phase == "failed" then
        return string.format(L["The calculation failed: %s"], tostring(state.message))
    elseif phase == "scanning" then
        local share = ns.scan ~= nil and ns.scan:progress() or 0
        return string.format(L["The calculation is running, %d percent."], math.floor(share * 100))
    end
    local cache = store().cache
    if phase ~= "ready" or type(cache) ~= "table" then
        return L["The calculation has not run yet."]
    end
    local npcNames, npcTitles, objects = Names.countRows(cache.rows)
    local text = string.format(
        justDone and L["The calculation is done. Names added to Questie's database: %d creature names, %d titles and %d world objects."]
            or L["Names added to Questie's database: %d creature names, %d titles and %d world objects."],
        npcNames,
        npcTitles,
        objects
    )
    local sources = sourceList(cache.stats)
    if sources ~= "" then
        text = text .. " " .. string.format(L["Sources used: %s."], sources)
    end
    return text
end

function ns.sayState()
    Game.speak(ns.statusText(false))
end

-- What an English name would become, and from which source (the outside sources only: the database's own votes are
-- gone once the walk is over).
function ns.explain(english)
    local sources = Sources.build(Game.sourceEnv(ns.registered))
    for _, kind in ipairs({ "Object", "Title", "Npc" }) do
        local text, key = sources.lookup(kind, english)
        if text ~= nil then
            return string.format(L["%s becomes %s, from %s."], english, text, Sources.label(key, L))
        end
    end
    return string.format(L["No source knows %s."], english)
end

-- ---------------------------------------------------------------- the public interface for other addons

-- WowVision.nameSources.addSource(key, fn): fn(kind, english, locale) returns the name in the game's language or nil;
-- kind is "Npc" (a creature), "Title" (the line under its name) or "Object" (a world object). Declared before the walk, a
-- source is used by it; declared later, it waits for /wv names recalculate.
function ns.addSource(key, fn)
    if type(fn) ~= "function" then
        return false
    end
    for _, source in ipairs(ns.registered) do
        if source.key == key then
            source.fn = fn
            return true
        end
    end
    ns.registered[#ns.registered + 1] = { key = key, fn = fn }
    return true
end

-- ---------------------------------------------------------------- the command

local function words(list)
    local set = {}
    for _, word in ipairs(list) do
        set[word] = true
    end
    return set
end

local ON = words({ "on", "oui", "yes", "an", "ja", "1", "true", "marche", "actif" })
local OFF = words({ "off", "non", "no", "aus", "nein", "0", "false", "arret", "arrêt", "stop" })
local STATE = words({ "etat", "état", "status", "state", "zustand" })
local REDO = words({ "refaire", "recalcul", "recalculer", "recalculate", "rebuild", "neu", "neuberechnen" })
local TEST = words({ "test", "teste" })
local HELP = words({ "aide", "help", "hilfe", "?" })

function ns.handleCommand(message)
    local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    if command == "" or STATE[command] then
        ns.sayState()
    elseif ON[command] then
        ns.setEnabled(true)
        Game.speak(L["Name sources are on."])
    elseif OFF[command] then
        ns.setEnabled(false)
        Game.speak(L["Name sources are off."])
    elseif REDO[command] then
        ns.recalculateAndSay()
    elseif TEST[command] then
        if rest == "" then
            Game.speak(L["Give an English name after test."])
        else
            Game.speak(ns.explain(rest))
        end
    else
        Game.speak(L["Name sources: /wv names says the state, /wv names on or off, /wv names recalculate redoes the calculation, /wv names test followed by an English name says what it would become."])
    end
end

module:registerCommand({
    name = "names",
    description = L["Names added to Questie's database: state, on, off, recalculate, test."],
    func = function(args)
        ns.handleCommand(args)
    end,
})

-- ---------------------------------------------------------------- module

-- In the module's screen, below its switch: what it did, and doing it again.
function module:getGraphMenuItems(builder)
    local graph = WowVision.graph
    builder:addItem(
        graph.ControlId.structural("nameSources:state"),
        graph.nodes.button({
            label = L["Say the State"],
            onActivate = function()
                ns.sayState()
            end,
        })
    )
    builder:addItem(
        graph.ControlId.structural("nameSources:recalculate"),
        graph.nodes.button({
            label = L["Recalculate"],
            onActivate = function()
                ns.recalculateAndSay()
            end,
        })
    )
end

-- Only once in the world: the saved value arrives before Questie is ready.
complete.events.valueChange:subscribe(module, function()
    if ns.started then
        guarded(ns.refresh)()
    end
end)

-- A few seconds after entering the world, so Questie has settled.
module.START_AFTER = 5

module:registerEvent("event", "PLAYER_ENTERING_WORLD")

function module:onEvent()
    if ns.started then
        return
    end
    ns.started = true
    C_Timer.After(self.START_AFTER, guarded(function()
        ns.start(false)
    end))
end

function module:onEnable()
    self:hasUpdate(function()
        if ns.scan ~= nil then
            guarded(ns.pump)()
        end
    end)
    if ns.started then
        guarded(ns.refresh)()
    end
end

function module:onDisable()
    ns.scan, ns.pending = nil, nil
    ns.withdraw()
    state.phase = "off"
end
