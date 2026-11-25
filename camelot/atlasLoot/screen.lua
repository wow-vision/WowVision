-- The WowVision screen: one list that goes down a level on Enter (category, dungeon, boss, loot) and back up on Escape
-- or Backspace, with the filters and a way back as tab stops of their own. The lines of each level are worked out by
-- Screen.model, from AtlasLoot's tables and the game, so the tests run them without WowVision's graph.
local ns = WowVision.atlasLoot
local L = ns.L
local Game = ns.Game
local Loot = ns.Loot

local Screen = {}
ns.Screen = Screen

-- Where the player is in AtlasLoot's tables. It stays between two openings of the screen.
local state = {
    level = "modules", -- modules | instances | bosses | items | search
    module = nil, -- the AtlasLoot module's addon name
    moduleName = nil,
    version = nil, -- the game version (Classic, Burning Crusade...), nil for the one AtlasLoot's window is on
    instance = nil, -- the instance's key in the module
    instanceName = nil,
    boss = nil, -- the boss' index (or the index of one of the instance's other lists)
    bossName = nil,
    whole = false, -- the loot level shows every boss of the instance together, not one boss
    diff = nil, -- the difficulty asked for; the boss shows the nearest one it has
    slot = nil, -- the slot group the loot is limited to (Loot.slotGroup), nil for all of them
    kind = nil, -- the kind of item the loot is limited to ("c4" a type, "c4s2" a sub type: the game's numbers), nil for all
    query = "", -- what the search level looks for
    index = nil, -- the index of the module's items the search reads (Loot.index), kept while the module and version stay
    cache = {}, -- the lines of the loot tables already worked out
}
Screen.state = state

-- How much the search level does at each rebuild of the screen (which is every tick): bosses read into the index,
-- item names asked of the game, and results shown.
Screen.INDEX_BOSSES = 25
Screen.REQUESTS = 30
Screen.RESULTS = 100

local function graph()
    return WowVision.graph
end

local function id(key)
    return graph().ControlId.structural(key)
end

local function filters()
    return {
        classFilter = Game.getSetting("classFilter") == true,
        levelFilter = Game.getSetting("levelFilter") == true,
        upgradesOnly = Game.getSetting("upgradesOnly") == true,
        slot = state.slot,
        kind = state.kind,
    }
end

local MESSAGES = {
    combat = "That module loads after combat.",
    disabled = "That AtlasLoot module is disabled.",
    missing = "That AtlasLoot module is not installed.",
}

local function say(key)
    Game.speak(L[MESSAGES[key] or key])
end

-- ------------------------------------------------------------------ levels

-- The lines of the list at the player's level: { key, label (text or function), activate, group = { key, label }?,
-- kind = "text"?, tooltip = link? }, plus the title of the list and, on the loot level, the facts the filters stop reads.
local function modulesModel(atlas)
    local rows = {}
    for _, module in ipairs(Loot.modules(atlas)) do
        rows[#rows + 1] = {
            key = "module:" .. module.id,
            label = module.name,
            opensLevel = true,
            activate = function()
                Screen.chooseModule(module)
            end,
        }
    end
    if #rows == 0 then
        rows[1] = { key = "none", kind = "text", label = L["No AtlasLoot module is enabled."] }
    end
    return { title = L["Loot categories"], rows = rows }
end

local function instancesModel(atlas)
    local rows = {}
    local status, data = Loot.open(atlas, state.module)
    if status ~= "ready" then
        return { title = state.moduleName, rows = { { key = "none", kind = "text", label = L[MESSAGES[status]] } } }
    end
    local version = Loot.version(atlas, data, state.version)
    local versions = Loot.versions(data)
    if #versions > 1 then
        rows[#rows + 1] = {
            key = "version",
            label = function()
                return string.format(L["Game version: %s"], Loot.versionName(atlas, version))
            end,
            activate = function()
                Screen.cycleVersion(atlas, versions, version)
            end,
            state = function()
                return Loot.versionName(atlas, Loot.version(atlas, data, state.version))
            end,
        }
    end
    -- "special" lines come first in the list, but the player lands on the first line that is not one
    rows[#rows + 1] = {
        key = "search",
        label = L["Search by name"],
        special = true,
        opensLevel = true,
        activate = function()
            Screen.openSearch()
        end,
    }
    for _, group in ipairs(Loot.instances(atlas, state.module, data, version)) do
        for _, instance in ipairs(group.list) do
            local label = instance.name
            if instance.levels ~= nil then
                label = label .. ", " .. instance.levels
            end
            rows[#rows + 1] = {
                key = "instance:" .. tostring(instance.key),
                label = label,
                opensLevel = true,
                group = { key = "group:" .. group.name, label = group.name },
                activate = function()
                    Screen.chooseInstance(instance)
                end,
            }
        end
    end
    if #rows == 1 and rows[1].special then
        rows[#rows + 1] = { key = "none", kind = "text", label = L["Nothing to show."] }
    end
    return { title = state.moduleName, rows = rows }
end

local function bossesModel(atlas)
    local status, data = Loot.open(atlas, state.module)
    local rows = {}
    if status ~= "ready" then
        return { title = state.instanceName, rows = { { key = "none", kind = "text", label = L[MESSAGES[status]] } } }
    end
    if #Loot.instanceBosses(data, state.instance) >= 2 then
        rows[#rows + 1] = {
            key = "whole",
            label = L["All bosses together"],
            special = true,
            opensLevel = true,
            activate = function()
                Screen.chooseWhole()
            end,
        }
    end
    for _, boss in ipairs(Loot.bosses(data, state.instance)) do
        rows[#rows + 1] = {
            key = "boss:" .. boss.index,
            label = boss.name,
            opensLevel = true,
            group = boss.extra and { key = "group:extra", label = L["Other lists"] } or { key = "group:bosses", label = L["Bosses"] },
            activate = function()
                Screen.chooseBoss(boss)
            end,
        }
    end
    if #rows == 0 then
        rows[1] = { key = "none", kind = "text", label = L["Nothing to show."] }
    end
    return { title = state.instanceName, rows = rows }
end

local function difficultyName(diffs, diff)
    for _, entry in ipairs(diffs) do
        if entry.id == diff then
            return entry.name
        end
    end
    return nil
end

-- One boss's loot lines for the difficulty asked for (the nearest one it has): entries | nil, problem, the boss's
-- difficulties, the one shown and its name. Worked out once per boss and difficulty; the items are asked of the game.
local function bossLines(atlas, data, boss, npcID, wanted)
    local diffs = Loot.difficulties(data, state.instance, boss)
    local diff = Loot.pickDifficulty(diffs, wanted)
    local name = difficultyName(diffs, diff)
    local key = table.concat({ state.module, tostring(state.instance), boss, tostring(diff) }, "/")
    local cached = state.cache[key]
    if cached == nil then
        local entries, problem, message = Loot.table(atlas, state.module, state.instance, boss, diff, Game, npcID)
        if problem == "loading" then
            return nil, "loading", diffs, diff, name
        elseif problem == "error" then
            Game.report(message)
            entries = {}
        end
        cached = { entries = entries }
        state.cache[key] = cached
    end
    for _, entry in ipairs(cached.entries) do
        if entry.kind == "item" then
            Game.requestItem(entry.id)
        end
    end
    return cached.entries, nil, diffs, diff, name
end

function Screen.npcID(data)
    local content = data[state.instance]
    local boss = type(content) == "table" and type(content.items) == "table" and content.items[state.boss] or nil
    return type(boss) == "table" and boss.npcID or nil
end

-- The lines of the loot level for the boss the player is at, with the facts about them.
local function lootLines(atlas)
    local status, data = Loot.open(atlas, state.module)
    if status ~= "ready" then
        return nil, status
    end
    return bossLines(atlas, data, state.boss, Screen.npcID(data), state.diff)
end

-- The loot of every boss of the instance together. In AtlasLoot's order the lines are grouped under each boss's name (a
-- header of its own table becomes "Boss, header"); when the loot is sorted it is one list and each item says which boss
-- it is from. Returns entries | nil, problem, the difficulties of any boss, the one shown, its name and { where = { [entry]
-- = boss name } (sorted lists only), loading = how many bosses' lists are not loaded yet }.
local function wholeLines(atlas)
    local status, data = Loot.open(atlas, state.module)
    if status ~= "ready" then
        return nil, status
    end
    local bosses = Loot.instanceBosses(data, state.instance)
    local diffs = Loot.mergeDifficulties(data, state.instance, bosses)
    local diff = Loot.pickDifficulty(diffs, state.diff)
    local sorted = Loot.isSorted(Game.getSetting("sort"))
    local entries, extra = {}, { where = sorted and {} or nil, loading = 0 }
    for _, boss in ipairs(bosses) do
        local lines, problem = bossLines(atlas, data, boss.index, boss.npcID, diff)
        if lines == nil then
            if problem == "loading" then
                extra.loading = extra.loading + 1
            end
        else
            if not sorted then
                entries[#entries + 1] = { kind = "header", name = boss.name }
            end
            for _, entry in ipairs(lines) do
                if entry.kind == "item" then
                    entries[#entries + 1] = entry
                    if sorted then
                        extra.where[entry] = boss.name
                    end
                elseif not sorted then
                    entries[#entries + 1] = { kind = "header", name = boss.name .. ", " .. entry.name }
                end
            end
        end
    end
    return entries, nil, diffs, diff, difficultyName(diffs, diff), extra
end

local function itemsModel(atlas)
    local rows = {}
    local active = filters()
    local entries, problem, diffs, diff, diffName, extra
    if state.whole then
        entries, problem, diffs, diff, diffName, extra = wholeLines(atlas)
    else
        entries, problem, diffs, diff, diffName = lootLines(atlas)
    end
    extra = extra or {}
    local title = state.whole and L["All bosses together"] or state.bossName
    if diffName ~= nil and diffName ~= "" then
        title = title .. ", " .. diffName
    end
    local model = { title = title, rows = rows, filters = true, diffs = diffs or {}, diff = diff, loading = extra.loading }
    if entries == nil then
        rows[1] = { key = "none", kind = "text", label = problem == "loading" and L["Loading."] or L[MESSAGES[problem] or "Nothing to show."] }
        model.shown, model.hidden, model.total = 0, 0, 0
        model.slotChoices = Loot.slotChoices({}, state.slot, Game)
        model.kindChoices = Loot.kindChoices({}, state.kind, Game)
        return model
    end
    -- the slots offered are the ones the other filters leave something in (the kind among them), and the kinds the ones the
    -- other filters leave something in (the slot among them)
    local others = { classFilter = active.classFilter, levelFilter = active.levelFilter, upgradesOnly = active.upgradesOnly }
    model.slotChoices = Loot.slotChoices(Loot.visible(entries, { classFilter = others.classFilter, levelFilter = others.levelFilter, upgradesOnly = others.upgradesOnly, kind = active.kind }, Game), state.slot, Game)
    model.kindChoices = Loot.kindChoices(Loot.visible(entries, { classFilter = others.classFilter, levelFilter = others.levelFilter, upgradesOnly = others.upgradesOnly, slot = active.slot }, Game), state.kind, Game)
    local visible, hidden = Loot.visible(entries, active, Game)
    visible = Loot.sort(visible, Game.getSetting("sort"), Game)
    model.shown, model.hidden, model.total = Loot.count(visible), hidden, Loot.count(entries)
    local seen, group, section = {}, nil, 0
    for _, entry in ipairs(visible) do
        if entry.kind == "header" then
            section = section + 1
            group = { key = "section:" .. section, label = entry.name }
        else
            local key = "item:" .. entry.pos .. ":" .. entry.id
            seen[key] = (seen[key] or 0) + 1
            if seen[key] > 1 then
                key = key .. "#" .. seen[key]
            end
            local where = extra.where ~= nil and extra.where[entry] or nil
            rows[#rows + 1] = {
                key = key,
                label = function()
                    return Loot.describe(entry, filters(), Game, where)
                end,
                group = group,
                tooltip = "item:" .. entry.id,
                activate = function()
                    if not Game.speakTooltip() then
                        Game.speak(Loot.describe(entry, filters(), Game, where))
                    end
                end,
            }
        end
    end
    if #rows == 0 then
        rows[1] = { key = "none", kind = "text", label = (model.loading or 0) > 0 and L["Loading."] or L["No item to show."] }
    end
    return model
end

-- The search level: a box to type in, then the items of the module (for the game version shown) whose name holds what
-- was typed, each with where it drops. The index of the module's items is read a few bosses at each rebuild of the
-- screen, and the names are asked of the game a few at a time, so the results fill in while the player listens.
local function searchModel(atlas)
    local rows = {
        {
            key = "search:input",
            kind = "input",
            label = L["Search by name"],
            get = function()
                return state.query
            end,
            set = function(text)
                state.query = tostring(text or "")
            end,
            valueText = function()
                return state.query ~= "" and state.query or L["nothing typed yet"]
            end,
        },
    }
    local model = { title = L["Search by name"], rows = rows, filters = true, search = true, diffs = {}, shown = 0, hidden = 0, total = 0 }
    model.slotChoices = Loot.slotChoices({}, state.slot, Game)
    model.kindChoices = Loot.kindChoices({}, state.kind, Game)
    local status, data = Loot.open(atlas, state.module)
    if status ~= "ready" then
        rows[2] = { key = "none", kind = "text", label = L[MESSAGES[status]] }
        return model
    end
    local version = Loot.version(atlas, data, state.version)
    local key = state.module .. "/" .. tostring(version)
    if state.index == nil or state.index.key ~= key then
        state.index = Loot.index(atlas, state.module, data, version)
        state.index.key = key
    end
    local index = state.index
    index:step(Game, Screen.INDEX_BOSSES)
    index:request(Game, Screen.REQUESTS)
    model.reading = not index.done
    local words = Loot.words(state.query)
    if not Loot.searchable(words) then
        rows[2] = { key = "none", kind = "text", label = L["Type at least two letters to search."] }
        return model
    end
    local active = filters()
    local result = Loot.find(index, words, active, Game)
    model.slotChoices = Loot.slotChoices(result.passing, state.slot, Game)
    model.kindChoices = Loot.kindChoices(result.passing, state.kind, Game)
    local found = Loot.sort(result.found, Game.getSetting("sort"), Game)
    model.hidden, model.unknown, model.total = result.hidden, result.unknown, #result.found
    model.more = result.more or #found > Screen.RESULTS
    for position = 1, math.min(#found, Screen.RESULTS) do
        local entry = found[position]
        local record = result.recordOf[entry]
        local where = Loot.where(record)
        rows[#rows + 1] = {
            key = "result:" .. tostring(record.instanceKey) .. ":" .. tostring(record.bossIndex) .. ":" .. entry.id,
            label = function()
                return Loot.describe(entry, filters(), Game, where)
            end,
            tooltip = "item:" .. entry.id,
            activate = function()
                if not Game.speakTooltip() then
                    Game.speak(Loot.describe(entry, filters(), Game, where))
                end
            end,
        }
    end
    model.shown = #rows - 1
    if #rows == 1 then
        rows[2] = {
            key = "none",
            kind = "text",
            label = (model.reading or (model.unknown or 0) > 0) and L["Loading."] or L["No match."],
        }
    end
    return model
end

local BUILDERS = {
    modules = modulesModel,
    instances = instancesModel,
    bosses = bossesModel,
    items = itemsModel,
    search = searchModel,
}

function Screen.model(atlas)
    return BUILDERS[state.level](atlas)
end

-- The key of the first line of the present level that is not a "special" one (the way into the search, the whole
-- instance): a line that only says there is nothing is a fine place to stand, it is what the player must hear.
local function firstKey(atlas)
    local rows = Screen.model(atlas).rows
    for _, row in ipairs(rows) do
        if not row.special then
            return row.key
        end
    end
    return rows[1] ~= nil and rows[1].key or nil
end

-- ---------------------------------------------------------------- movement

-- Puts the player on a line of the new level (the screen was built from the level it just left).
local function land(key)
    local screen = Screen.screen
    if screen ~= nil and screen.keyGraph ~= nil and key ~= nil then
        pcall(screen.keyGraph.focus, screen.keyGraph, id(key))
    end
end

function Screen.chooseModule(module)
    local atlas = Game.atlas()
    if atlas == nil then
        return
    end
    local status = Loot.open(atlas, module.id)
    if status ~= "ready" then
        say(status)
        return
    end
    state.module, state.moduleName = module.id, module.name
    state.version, state.instance, state.boss = nil, nil, nil
    state.level = "instances"
    land(firstKey(atlas))
end

function Screen.chooseInstance(instance)
    local atlas = Game.atlas()
    if atlas == nil then
        return
    end
    state.instance, state.instanceName = instance.key, instance.name
    state.boss = nil
    state.level = "bosses"
    land(firstKey(atlas))
end

function Screen.chooseBoss(boss)
    local atlas = Game.atlas()
    if atlas == nil then
        return
    end
    state.boss, state.bossName = boss.index, boss.name
    state.whole = false
    state.level = "items"
    Loot.resolve(atlas, state.module, state.instance, boss.index)
    land(firstKey(atlas))
end

-- Every boss of the instance in one list.
function Screen.chooseWhole()
    local atlas = Game.atlas()
    if atlas == nil then
        return
    end
    state.whole, state.boss, state.bossName = true, nil, nil
    state.level = "items"
    local status, data = Loot.open(atlas, state.module)
    if status == "ready" then
        for _, boss in ipairs(Loot.instanceBosses(data, state.instance)) do
            Loot.resolve(atlas, state.module, state.instance, boss.index)
        end
    end
    land(firstKey(atlas))
end

-- The search over the module the player is in.
function Screen.openSearch()
    local atlas = Game.atlas()
    if atlas == nil then
        return
    end
    state.level = "search"
    land("search:input")
end

function Screen.cycleVersion(atlas, versions, current)
    local nextVersion = versions[1]
    for position, version in ipairs(versions) do
        if version == current then
            nextVersion = versions[position + 1] or versions[1]
        end
    end
    state.version = nextVersion
    state.instance = nil
    land("version")
end

function Screen.cycleDifficulty(diffs, current)
    local nextDiff = diffs[1] and diffs[1].id
    for position, diff in ipairs(diffs) do
        if diff.id == current then
            nextDiff = (diffs[position + 1] or diffs[1]).id
        end
    end
    state.diff = nextDiff
end

-- One level up; at the top, the screen closes.
function Screen.back()
    local atlas = Game.atlas()
    if state.level == "items" then
        state.level = "bosses"
        land(state.whole and "whole" or ("boss:" .. tostring(state.boss)))
    elseif state.level == "search" then
        state.level = "instances"
        land("search")
    elseif state.level == "bosses" then
        state.level = "instances"
        land("instance:" .. tostring(state.instance))
    elseif state.level == "instances" then
        state.level = "modules"
        land("module:" .. tostring(state.module))
    else
        Screen.close()
    end
    return atlas
end

function Screen.close()
    Game.close()
    if ns.afterClose ~= nil then
        ns.afterClose()
    end
end

-- ------------------------------------------------------------------ render

local LEVEL_LABELS = {
    modules = "Loot categories",
    instances = "Dungeons and raids",
    bosses = "Bosses",
    items = "Loot",
    search = "Search by name",
}

-- Where the player is, from the top: "Dungeons and Raids, Ragefire Chasm, Taragaman the Hungerer".
function Screen.where()
    local parts = {}
    if state.level ~= "modules" and state.moduleName ~= nil then
        parts[#parts + 1] = state.moduleName
    end
    if (state.level == "bosses" or state.level == "items") and state.instanceName ~= nil then
        parts[#parts + 1] = state.instanceName
    end
    if state.level == "items" and state.whole then
        parts[#parts + 1] = L["All bosses together"]
    elseif state.level == "items" and state.bossName ~= nil then
        parts[#parts + 1] = state.bossName
    end
    if state.level == "search" then
        parts[#parts + 1] = L["Search by name"]
    end
    if #parts == 0 then
        return L["Loot categories"]
    end
    return table.concat(parts, ", ")
end

local function nodeFor(nodes, row)
    if row.kind == "text" then
        return nodes.text({ label = row.label })
    elseif row.kind == "input" then
        return nodes.textInput({ label = row.label, get = row.get, set = row.set, valueText = row.valueText })
    end
    local vtable = nodes.button({
        label = row.label,
        onActivate = row.activate,
        opensLevel = row.opensLevel,
        stateText = row.state,
    })
    if row.tooltip ~= nil then
        vtable.tooltip = { type = "Hyperlink", link = row.tooltip }
    end
    return vtable
end

local function renderList(builder, nodes, model)
    builder:beginStop("list")
    builder:pushContext("level:" .. state.level, model.title or L[LEVEL_LABELS[state.level]])
    local group
    for _, row in ipairs(model.rows) do
        local wanted = row.group
        if wanted == nil and group ~= nil then
            builder:popContext()
            group = nil
        elseif wanted ~= nil and (group == nil or group.key ~= wanted.key) then
            if group ~= nil then
                builder:popContext()
            end
            builder:pushContext(wanted.key, wanted.label)
            group = wanted
        end
        builder:addItem(id(row.key), nodeFor(nodes, row))
    end
    if group ~= nil then
        builder:popContext()
    end
    builder:popContext()
end

-- What the filters stop says first: how many lines are shown, how many the filters hid, the slot, and what is still
-- coming (the search's lists and item names, the lists of the whole instance that are not loaded yet).
function Screen.summary(model)
    local text
    if model.search then
        text = string.format(L["Matches shown: %d"], model.shown or 0)
    else
        text = string.format(L["Items shown: %d"], model.shown or 0)
    end
    if model.more then
        text = text .. ", " .. L["more matches exist, refine the search"]
    end
    if (model.hidden or 0) > 0 then
        text = text .. ", " .. string.format(L["Hidden by the filters: %d"], model.hidden)
    end
    if state.slot ~= nil then
        text = text .. ", " .. string.format(L["Slot: %s"], Loot.slotLabel(state.slot, Game))
    end
    if state.kind ~= nil then
        text = text .. ", " .. string.format(L["Item type: %s"], Loot.kindLabel(state.kind))
    end
    if (model.loading or 0) > 0 then
        text = text .. ", " .. string.format(L["Still loading: %d"], model.loading)
    end
    if model.reading then
        text = text .. ", " .. L["Still reading the lists"]
    end
    if (model.unknown or 0) > 0 then
        text = text .. ", " .. string.format(L["Item names still arriving: %d"], model.unknown)
    end
    return text
end

local function renderFilters(builder, nodes, model)
    builder:beginStop("filters")
    builder:pushContext("filters", L["Filters"])
    builder:addItem(
        id("filter:summary"),
        nodes.text({
            label = function()
                return Screen.summary(model)
            end,
            live = "focus",
        })
    )
    builder:addItem(
        id("filter:class"),
        nodes.toggle({
            label = L["Only what my class can use"],
            get = function()
                return Game.getSetting("classFilter") == true
            end,
            set = function(value)
                Game.setSetting("classFilter", value)
            end,
        })
    )
    builder:addItem(
        id("filter:level"),
        nodes.toggle({
            label = L["Only what my level allows"],
            get = function()
                return Game.getSetting("levelFilter") == true
            end,
            set = function(value)
                Game.setSetting("levelFilter", value)
            end,
        })
    )
    builder:addItem(
        id("filter:upgrades"),
        nodes.toggle({
            label = function()
                local measure = Game.upgradeMeasure()
                if measure == "judge" then
                    return L["Only upgrades, judged by Gear Judge"]
                elseif measure == "pawn" then
                    return L["Only upgrades, judged by Pawn"]
                end
                return L["Only upgrades, judged by item level"]
            end,
            get = function()
                return Game.getSetting("upgradesOnly") == true
            end,
            set = function(value)
                Game.setSetting("upgradesOnly", value)
            end,
        })
    )
    builder:addItem(
        id("filter:measure"),
        nodes.choice({
            label = L["Judge of upgrades"],
            get = function()
                return Game.getSetting("measure")
            end,
            set = function(value)
                Game.setSetting("measure", value)
            end,
            choices = Loot.measureChoices,
        })
    )
    builder:addItem(
        id("filter:slot"),
        nodes.choice({
            label = L["Slot"],
            get = function()
                return state.slot or "all"
            end,
            set = function(value)
                state.slot = value ~= "all" and value or nil
            end,
            choices = function()
                return model.slotChoices
            end,
        })
    )
    builder:addItem(
        id("filter:kind"),
        nodes.choice({
            label = L["Item type"],
            get = function()
                return state.kind or "all"
            end,
            set = function(value)
                state.kind = value ~= "all" and value or nil
            end,
            choices = function()
                return model.kindChoices
            end,
        })
    )
    builder:addItem(
        id("filter:sort"),
        nodes.choice({
            label = L["Sort"],
            get = function()
                return Game.getSetting("sort")
            end,
            set = function(value)
                Game.setSetting("sort", value)
            end,
            choices = Loot.sortChoices,
        })
    )
    if #model.diffs > 1 then
        builder:addItem(
            id("filter:difficulty"),
            nodes.button({
                label = function()
                    local name
                    for _, diff in ipairs(model.diffs) do
                        if diff.id == model.diff then
                            name = diff.name
                        end
                    end
                    return string.format(L["Difficulty: %s"], name or "")
                end,
                stateText = function()
                    for _, diff in ipairs(model.diffs) do
                        if diff.id == state.diff then
                            return diff.name
                        end
                    end
                    return nil
                end,
                onActivate = function()
                    Screen.cycleDifficulty(model.diffs, model.diff)
                end,
            })
        )
    end
    builder:popContext()
end

local function renderNavigation(builder, nodes)
    builder:beginStop("navigation")
    builder:pushContext("navigation", L["Navigation"])
    builder:addItem(
        id("nav:where"),
        nodes.text({
            label = function()
                return string.format(L["You are in: %s"], Screen.where())
            end,
            live = "focus",
        })
    )
    if state.level ~= "modules" then
        builder:addItem(
            id("nav:back"),
            nodes.button({
                -- (WowVision's "Back" is the back slot)
                label = L["Go Back"],
                onActivate = function()
                    Screen.back()
                end,
            })
        )
    end
    builder:addItem(
        id("nav:withAtlasLoot"),
        nodes.toggle({
            label = L["Open with AtlasLoot's window (/al)"],
            get = function()
                return Game.getSetting("openWithAl") == true
            end,
            set = function(value)
                Game.setSetting("openWithAl", value)
            end,
        })
    )
    builder:addItem(
        id("nav:close"),
        nodes.button({
            label = L["Close"],
            onActivate = function()
                Screen.close()
            end,
        })
    )
    builder:popContext()
end

function Screen.render(builder, screen)
    Screen.screen = screen
    local nodes = graph().nodes
    local atlas = Game.atlas()
    if atlas == nil then
        builder:beginStop("list")
        builder:addItem(id("noatlas"), nodes.text({ label = L["AtlasLoot is not installed or not enabled."] }))
        return
    end
    local model = Screen.model(atlas)
    renderList(builder, nodes, model)
    if model.filters then
        renderFilters(builder, nodes, model)
    end
    renderNavigation(builder, nodes)
end

function Screen.config()
    return {
        key = Game.WINDOW,
        captureClose = true,
        letterNavigation = true,
        render = function(builder, screen)
            return Screen.render(builder, screen)
        end,
        onRequestClose = Game.guarded(function()
            Screen.back()
        end),
    }
end

-- Opens the screen (and says where the player is when it was left in the middle of the tables).
function Screen.open()
    if Game.isOpen() then
        return true
    end
    -- what the player wears may have changed in a way no event told (Pawn's scales, say): judge the upgrades again
    Game.gearChanged()
    if not Game.open(Screen.config()) then
        Game.speak(L["WowVision's windows are not available."])
        return false
    end
    return true
end
