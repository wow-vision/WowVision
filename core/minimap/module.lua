local Scan = WowVision.minimapScan
local Engine = Scan.engine

local module = WowVision.base:createModule("minimap")
local L = module.L
module:setLabel(L["Minimap Scanner"])
local settings = module:hasSettings()

-- The minimap scanner: every named dot on the minimap within its range
-- (233 yards outdoors, 150 indoors), sorted by kind and placed to a few
-- yards, listed in the scanner (F9) tagged "seen". Two parts:
--
-- - The scan (Ctrl+Shift+F, standing still): sorting passes on the
--   shrunk minimap first: every tracking type at once, then one at a
--   time when that showed anything (well under two seconds); when that
--   finds nothing new it stops there. Otherwise the sweep asks every
--   point of the full-size minimap (Minimap:UpdateMouseoverAtPoint, a
--   few frames) and finds each new dot's edges by halving.
--   Moving, turning, the mouse moving, mouselook and combat abort it;
--   everything half-measured is dropped.
-- - The walking check (a setting): twice a second while moving, one read
--   of the shrunk minimap with the player's own tracking; a name that
--   comes into range is announced once, with its kind when a scan
--   already sorted it. A new dot is placed by a sweep while walking on;
--   its name is said again only after the player walked out of its range
--   (Scan.Walk). Dots without a place fall back to 30 seconds out of
--   view while walking outdoors.
--
-- Entries live for the session. Quest givers go to the quest system's
-- seen givers (Quests > Nearby, NPCs > Quest Givers), other NPCs to the
-- NPC categories, gathering nodes (known by name while their tracking
-- spell is on; the scan never switches spells) to Gathering; a database entry of the
-- same name wins over a seen one.

settings:add({
    key = "announceWalking",
    type = "Bool",
    label = L["Announce Tracked Dots While Walking"],
    -- On while it is being tried out: addon settings still reset often.
    default = true,
})
settings:add({
    key = "centreCursor",
    type = "Bool",
    label = L["Centre Mouse Cursor Before Scanning"],
    default = true,
})

-- The walking check's log (/wv mscan log): what each read showed when it
-- changed, every decision of the walking memory, and why a check did not
-- run, repeats of the same line folded into one. Kept in the
-- WowVisionDump saved variable (key minimapWalk), so after /reload or
-- logout it can be read from the SavedVariables file. A diagnostic while
-- the announcement is being tried out.
local WALK_LOG_SIZE = 2000
local WALK_LOG_SHOWN = 300
local lastWalkNote = nil
local sessionMarked = false

local function walkLogLines()
    WowVisionDump = WowVisionDump or {}
    if type(WowVisionDump.minimapWalk) ~= "table" then
        WowVisionDump.minimapWalk = {}
    end
    return WowVisionDump.minimapWalk
end

local function walkNote(text)
    if text == lastWalkNote then
        return
    end
    lastWalkNote = text
    local lines = walkLogLines()
    if not sessionMarked then
        sessionMarked = true
        tinsert(lines, "---- session " .. date("%Y-%m-%d %H:%M:%S") .. " ----")
    end
    tinsert(lines, date("%H:%M:%S") .. " " .. text)
    while #lines > WALK_LOG_SIZE do
        tremove(lines, 1)
    end
end

local dotAlert = module:addAlert({
    key = "newDot",
    label = L["New Minimap Dot Alert"],
})
-- The walking announcements speak with a game voice (voice 0 unless the
-- alert's Voice setting picks another), not the player's speech voice:
-- with an NVDA SAPI voice there they were cut off by the screen reader's
-- own speech.
dotAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    voice = 0,
    buildMessage = function(self, message)
        if message.text then
            walkNote("spoken: " .. message.text)
        end
        return message.text
    end,
})
dotAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})
settings:addRef("newDotAlert", dotAlert.parameters)

module.store = Scan.Store.new()
-- Points of interest (tracking type POI) the last outdoor scan saw, names
-- only. The minimap draws them as an arrow at a fixed distance in the
-- place's direction and drops the arrow once you are there (Warcraft
-- Wiki, Minimap), so a scan knows that a place is near, not where. Names
-- could later lead somewhere through a zone-based route.
module.places = {}

-- Tracking filter (Enum.MinimapTrackingFilter name) -> category. The keys
-- are the quest system's NPC role keys where one exists.
local FILTER_CATEGORY = {
    Auctioneer = "auctioneer",
    Banker = "banker",
    AccountBanker = "banker",
    Battlemaster = "battlemaster",
    TaxiNode = "flightMaster",
    VenderFood = "vendor",
    VendorAmmo = "vendor",
    VendorReagent = "vendor",
    VendorPoison = "vendor",
    Innkeeper = "innkeeper",
    Mailbox = "mailboxes",
    TrainerClass = "classTrainers",
    TrainerProfession = "trainer",
    Repair = "repair",
    Stablemaster = "stableMaster",
    Barber = "other",
    Transmogrifier = "other",
    ItemUpgrade = "other",
    -- Town and landmark markers ("Knotenpunkte" on the German client):
    -- Goldshire, Stormwind. Kept as names only, see module.places.
    POI = "poi",
}
-- Filters that add quest givers: flagged, but still quest givers.
local QUEST_FILTER_FLAG = {
    TrivialQuests = "trivial",
    AccountCompletedQuests = "accountCompleted",
}

local WALK_INTERVAL = 0.5
-- Yards: a scan's find replaces the entry of its name this close; a
-- quest giver this close to a finished quest's point hands it in.
local MATCH_RADIUS = 15
local TURN_IN_RADIUS = 15

-- What each name was sorted as this session, for the walking check's
-- announcement ("Olivia Burnside, Banker").
module.kinds = {}
-- Category -> label, for the spell categories (the tracking spell's name).
module.spellLabels = {}

local CATEGORY_LABELS = {
    questGiver = L["Quest Givers"],
    vendor = L["Vendors"],
    repair = L["Repair"],
    trainer = L["Trainers"],
    classTrainers = L["Class Trainers"],
    flightMaster = L["Flight Masters"],
    innkeeper = L["Innkeepers"],
    banker = L["Bankers"],
    auctioneer = L["Auctioneers"],
    stableMaster = L["Stable Masters"],
    battlemaster = L["Battlemasters"],
    mailboxes = L["Mailboxes"],
    other = L["Other NPCs"],
    poi = L["Points of Interest"],
    unsorted = L["Unsorted"],
}

function module:categoryLabel(category)
    return CATEGORY_LABELS[category] or self.spellLabels[category] or category
end

local function speak(text)
    WowVision:speak(text)
end

-- "Scan canceled, moved": the reason in one word.
local function canceled(reason)
    return L["Scan canceled"] .. ", " .. reason
end

-- Speed is a secret value in combat on the modern engine; comparing it
-- throws, so an unreadable speed counts as standing (the walking check
-- skips combat right after).
local function moving()
    local speed = GetUnitSpeed("player")
    if speed == nil or WowVision.isSecret(speed) then
        return false
    end
    return speed > 0
end

-- ---- the scan ----

local function mapPosition(mapId, continent, wx, wy)
    if mapId == nil or C_Map.GetMapPosFromWorldPos == nil then
        return nil
    end
    local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, continent, CreateVector2D(wx, wy), mapId)
    if ok and pos ~= nil then
        return pos.x * 100, pos.y * 100
    end
    return nil
end

-- The filters the sorting passes switch: the ones with a category.
local function sortableFilters(filters)
    local sortable, on = {}, {}
    for _, t in ipairs(filters) do
        if FILTER_CATEGORY[t.filter] ~= nil or QUEST_FILTER_FLAG[t.filter] ~= nil then
            tinsert(sortable, t)
            on[t.index] = true
        end
    end
    return sortable, on
end

-- Sets every filter in `filters` on when it is `on`, the rest off.
local function setFilters(filters, on)
    for _, t in ipairs(filters) do
        local want = on ~= nil and on[t.index] == true
        local info = C_Minimap.GetTrackingInfo(t.index)
        if info ~= nil and (info.active and true or false) ~= want then
            C_Minimap.SetTracking(t.index, want)
        end
    end
end

-- The sorting passes, on the shrunk minimap. Returns the classified
-- names. Tracking spells are never switched (see Scan.gatheringKinds):
-- with every filter off the baseline holds quest givers and, while a
-- gathering spell is on, its nodes, sorted by name.
local function sortingPasses(task, filters, spells)
    local passes = { filters = {} }
    setFilters(filters, nil)
    passes.baseline = Engine.readSettled()
    -- One pass with every sorted filter on first: when it shows nothing
    -- beyond the baseline, no single pass would (measured 2026-09-24: a
    -- group of filters shows exactly its single passes' names).
    local sortable, everyOn = sortableFilters(filters)
    setFilters(filters, everyOn)
    task.stats.anyFiltered = Scan.hasExtras(passes.baseline, Engine.readSettled())
    if task.stats.anyFiltered then
        for _, t in ipairs(sortable) do
            setFilters(filters, { [t.index] = true })
            tinsert(passes.filters, {
                category = FILTER_CATEGORY[t.filter] or "questGiver",
                flag = QUEST_FILTER_FLAG[t.filter],
                label = t.name,
                dots = Engine.readSettled(),
            })
        end
    end
    setFilters(filters, nil)
    local otherSpell
    passes.gathering, otherSpell = Scan.gatheringKinds(spells, Scan.gatheringNames, GetLocale())
    if otherSpell then
        -- Hunter tracking and the like: their dots stay mixed in with the
        -- quest givers.
        passes.baselineCategory = "unsorted"
    end
    for _, kind in ipairs(passes.gathering) do
        module.spellLabels[kind.category] = kind.label
    end
    local classified = Scan.classify(passes)
    -- The walking check's names for each kind.
    local labels = {}
    for _, pass in ipairs(passes.filters) do
        labels[pass.category] = labels[pass.category] or pass.label
    end
    for _, kind in ipairs(passes.gathering) do
        labels[kind.category] = kind.label
    end
    for _, item in ipairs(classified) do
        module.kinds[item.name] = item.category == "questGiver" and L["quest giver"] or labels[item.category]
    end
    return classified
end

-- The sweep (Engine.pointReader): every cell of the minimap asked in one
-- pass, then each dot's edges found by halving. Returns name -> list of
-- { x, y, otherLevel } offsets (minimap units), one per dot found;
-- otherLevel when its name read grey. Nil when it named none of the
-- work's names.
--
-- Classic clients have no Minimap:UpdateMouseoverAtPoint. A port there
-- would need the old way (gridPositions in this feature's first
-- version): the minimap moved so each grid point in turn lies under the
-- cursor, one point per frame, coarse over the whole minimap, then fine
-- around each find.
local SWEEP_STEP = 2
local EDGE_HALVINGS = 10

local function sweepPositions(task, work, radius)
    local stats = task.stats
    local expected = {}
    for _, item in ipairs(work) do
        expected[item.name] = true
    end
    local read = Engine.pointReader()
    local budget, limits = Engine.frameBudget()
    stats.budget, stats.limits = budget, limits
    local chunkStart = debugprofilestop()
    -- Every question goes through here; past the frame's budget, one
    -- frame goes to the game.
    local function ask(ox, oy)
        stats.questions = stats.questions + 1
        local dots = read(ox, oy)
        local now = debugprofilestop()
        if now - chunkStart > budget then
            stats.ms = stats.ms + (now - chunkStart)
            stats.frames = stats.frames + 1
            Engine.wait()
            chunkStart = debugprofilestop()
        end
        return dots
    end
    local function has(dots, name)
        for _, dot in ipairs(dots) do
            if dot.name == name then
                return true
            end
        end
        return false
    end

    -- The pass: a margin of a dot's reach past the rim, for dots there.
    local hits, any = {}, false
    for _, cell in ipairs(Scan.sweepCells(radius + 10, SWEEP_STEP)) do
        local dots = ask(cell[1] * SWEEP_STEP, cell[2] * SWEEP_STEP)
        for _, dot in ipairs(dots) do
            if expected[dot.name] then
                any = true
                local byName = hits[dot.name]
                if byName == nil then
                    byName = {}
                    hits[dot.name] = byName
                end
                local key = Scan.cellKey(cell[1], cell[2])
                local c = byName[key]
                if c == nil then
                    c = { ix = cell[1], iy = cell[2], n = 0 }
                    byName[key] = c
                end
                c.n = c.n + 1
                c.grey = c.grey or dot.otherLevel
            end
        end
    end
    if not any then
        stats.ms = stats.ms + (debugprofilestop() - chunkStart)
        return nil
    end

    local components, all = {}, {}
    for name, byName in pairs(hits) do
        components[name] = Scan.components(byName)
        for _, comp in ipairs(components[name]) do
            tinsert(all, comp)
        end
    end
    local singleSize = Scan.singleSize(all)

    -- Halving between a point that answers and one that does not.
    local function edge(name, inX, inY, outX, outY)
        for _ = 1, EDGE_HALVINGS do
            local mx, my = (inX + outX) / 2, (inY + outY) / 2
            if has(ask(mx, my), name) then
                inX, inY = mx, my
            else
                outX, outY = mx, my
            end
        end
        return (inX + outX) / 2, (inY + outY) / 2
    end
    -- One dot alone in its group: its four edges. Across on the middle
    -- row between its last cell and the empty one beside it, then up and
    -- down through that middle (a round patch is widest there).
    local function edges(name, comp)
        local S = SWEEP_STEP
        local iy, minX, maxX = Scan.middleRow(comp)
        local y = iy * S
        local left = edge(name, minX * S, y, (minX - 1) * S, y)
        local right = edge(name, maxX * S, y, (maxX + 1) * S, y)
        local x = (left + right) / 2
        if not has(ask(x, y), name) then
            return nil
        end
        local minY, maxY = Scan.column(comp, math.floor(x / S + 0.5))
        minY, maxY = minY or comp.minY, maxY or comp.maxY
        local function outside(from, dir)
            for extra = 1, 3 do
                local oy = (from + dir * extra) * S
                if not has(ask(x, oy), name) then
                    return oy
                end
            end
            return nil
        end
        local downOut, upOut = outside(minY, -1), outside(maxY, 1)
        if downOut == nil or upOut == nil then
            return nil
        end
        local _, bottom = edge(name, x, y, x, downOut)
        local _, top = edge(name, x, y, x, upOut)
        return { left = left, right = right, bottom = bottom, top = top }
    end

    local found, measured, halves = {}, {}, {}
    for name, list in pairs(components) do
        found[name] = {}
        for _, comp in ipairs(list) do
            local grey = false
            for _, c in ipairs(comp.cells) do
                grey = grey or c.grey == true
            end
            local k = Scan.dotsInComponent(comp, singleSize)
            local e = k == 1 and edges(name, comp) or nil
            if e ~= nil then
                tinsert(halves, (e.right - e.left) / 2)
                tinsert(halves, (e.top - e.bottom) / 2)
                local spot = { otherLevel = grey }
                tinsert(found[name], spot)
                tinsert(measured, { spot = spot, e = e })
            elseif k == 1 then
                -- The edges did not behave: the middle of the patch.
                tinsert(found[name], {
                    (comp.minX + comp.maxX) / 2 * SWEEP_STEP,
                    (comp.minY + comp.maxY) / 2 * SWEEP_STEP,
                    otherLevel = grey,
                })
            else
                stats.merged = stats.merged + k
                for _, centre in ipairs(Scan.splitComponent(comp, k, SWEEP_STEP)) do
                    tinsert(found[name], { centre[1], centre[2], otherLevel = grey })
                end
            end
            stats.dots = stats.dots + k
        end
    end
    -- One dot's half size, from all measured: rim dots' short patches
    -- are rare enough not to move the median.
    local half = #halves >= 4 and Scan.median(halves) or nil
    stats.half = half
    for _, m in ipairs(measured) do
        m.spot[1] = Scan.edgeCentre(m.e.left, m.e.right, half)
        m.spot[2] = Scan.edgeCentre(m.e.bottom, m.e.top, half)
    end
    stats.ms = stats.ms + (debugprofilestop() - chunkStart)
    return found
end

local function summary(counts, order, dropped, indoors)
    local parts = {}
    local total = 0
    for _, category in ipairs(order) do
        total = total + counts[category]
        tinsert(parts, counts[category] .. " " .. module:categoryLabel(category))
    end
    local text
    if total == 0 then
        text = L["Nothing new nearby"]
    else
        text = string.format("%s, %d %s: %s", L["Scan done"], total, L["new"], table.concat(parts, ", "))
    end
    if dropped > 0 then
        text = text .. ", " .. dropped .. " " .. L["gone"]
    end
    if indoors then
        text = text .. ", " .. L["indoors, this building only"]
    end
    return text
end

function module:scanBody(task)
    if module.settings.centreCursor then
        Engine.centreCursor()
    end
    Engine.wait()
    if not Engine.cursorOverWorld() then
        Engine.abort(canceled(L["window"]))
    end
    task.cursorX, task.cursorY = GetCursorPosition()
    task.rotating = GetCVar("rotateMinimap") == "1"
    task.facing = GetPlayerFacing() or 0
    local state = Engine.capture()
    task.state = state
    -- Switching quest objective tracking reads as leaving and entering
    -- quest areas; silent until tracking is back (cleanups run newest
    -- first, so this one runs last).
    local quests = WowVision.base.quests
    quests:muteAreaAlerts(true)
    Engine.onCleanup(function()
        quests:muteAreaAlerts(false)
    end)
    Engine.onCleanup(function()
        Engine.restoreFrame(state)
    end)
    Engine.onCleanup(function()
        Engine.restoreTracking(state, false)
    end)

    local px, py, _, continent = UnitPosition("player")
    local mapId = C_Map.GetBestMapForUnit("player")
    Minimap:SetZoom(0)
    Engine.shrink(task.cursorX, task.cursorY)
    Engine.wait()
    local viewRadius = C_Minimap.GetViewRadius()

    local filters, spells = {}, {}
    for _, t in ipairs(state.tracking) do
        tinsert(t.isSpell and spells or filters, t)
    end
    local classified, places = Scan.splitCategory(sortingPasses(task, filters, spells), "poi")

    -- Indoors the minimap shows only this building: what it cannot see
    -- outside is not gone, and everything it does see is indoors.
    local indoors = IsIndoors ~= nil and IsIndoors() or false
    local store = self.store
    local dropped = store:dropMissing(Scan.presentByCategory(classified), px, py, continent, viewRadius * 0.9, indoors)
    local work = Scan.missingWork(classified, store, px, py, continent, viewRadius)
    local counts, order = {}, {}
    -- Indoors the minimap shows only this building; keep the last list.
    if not indoors then
        local known = {}
        for _, name in ipairs(self.places) do
            known[name] = true
        end
        for _, name in ipairs(places) do
            if not known[name] then
                if counts.poi == nil then
                    counts.poi = 0
                    tinsert(order, "poi")
                end
                counts.poi = counts.poi + 1
            end
        end
        self.places = places
    end
    if #work > 0 then
        -- Every kind on, so every name answers in the sweep.
        local _, on = sortableFilters(filters)
        setFilters(filters, on)
        Engine.fullSize(state, task.cursorX, task.cursorY)
        Engine.wait(2)
        local radius = state.width / 2
        local yardsPerUnit = viewRadius / radius
        local facing = task.rotating and task.facing or 0
        task.stats.method = "sweep"
        local found = sweepPositions(task, work, radius)
        if found == nil then
            task.stats.method = "sweep, named none of the new names"
            found = {}
        end
        for _, item in ipairs(work) do
            for _, offset in ipairs(found[item.name] or {}) do
                local north, west = Scan.offsetToWorld(offset[1], offset[2], yardsPerUnit, facing)
                local wx, wy = px + north, py + west
                local x, y = mapPosition(mapId, continent, wx, wy)
                local _, isNew = store:upsert({
                    name = item.name,
                    category = item.category,
                    subtitle = item.subtitle,
                    flag = item.flag,
                    indoors = indoors or offset.otherLevel == true,
                    wx = wx,
                    wy = wy,
                    continent = continent,
                    mapId = mapId,
                    x = x,
                    y = y,
                }, MATCH_RADIUS)
                if isNew then
                    if counts[item.category] == nil then
                        counts[item.category] = 0
                        tinsert(order, item.category)
                    end
                    counts[item.category] = counts[item.category] + 1
                end
            end
        end
    end
    task.result = summary(counts, order, dropped, indoors)
end

function module:scan()
    if self.task ~= nil then
        speak(L["Scan already running"])
        return
    end
    if self.walkTask ~= nil then
        -- The walking check takes two frames; go right after it.
        C_Timer.After(0.1, function()
            self:scan()
        end)
        return
    end
    if not Engine.available() then
        speak(L["Minimap scanner not available on this client"])
        return
    end
    if InCombatLockdown() then
        speak(L["Not in combat"])
        return
    end
    if moving() then
        speak(L["Stand still to scan"])
        return
    end
    if IsMouselooking ~= nil and IsMouselooking() then
        speak(L["Stop mouselook to scan"])
        return
    end
    if UnitPosition("player") == nil or C_Map.GetBestMapForUnit("player") == nil then
        speak(L["No position here"])
        return
    end
    local task = {
        -- What the scan did, for /wv mscan stats.
        stats = {
            started = GetTime(),
            method = "none (nothing new to place)",
            questions = 0,
            frames = 0,
            ms = 0,
            dots = 0,
            merged = 0,
        },
    }
    self.task = task
    speak(L["Scanning minimap"])
    task.body = function()
        module:scanBody(task)
    end
    task.check = function()
        if InCombatLockdown() then
            return canceled(L["combat"])
        end
        if moving() then
            return canceled(L["moved"])
        end
        if task.cursorX ~= nil then
            if IsMouselooking ~= nil and IsMouselooking() then
                return canceled(L["mouselook"])
            end
            local x, y = GetCursorPosition()
            if math.abs(x - task.cursorX) > 2 or math.abs(y - task.cursorY) > 2 then
                return canceled(L["mouse"])
            end
            if task.rotating and math.abs((GetPlayerFacing() or 0) - task.facing) > 0.02 then
                return canceled(L["turned"])
            end
        end
        return nil
    end
    task.finish = function(ok, reason, err)
        self.task = nil
        task.stats.seconds = GetTime() - task.stats.started
        task.stats.outcome = ok and "done" or tostring(reason or "error")
        self.lastStats = task.stats
        -- Give the filters a second, then say so if one did not come
        -- back.
        if task.state ~= nil then
            C_Timer.After(1, function()
                local restored, name = Engine.trackingRestored(task.state)
                if not restored then
                    speak(L["Tracking not restored"] .. ": " .. tostring(name))
                end
            end)
        end
        if ok then
            speak(task.result)
        elseif reason ~= nil then
            speak(reason)
        else
            speak(L["Minimap scan failed"])
            geterrorhandler()(err)
        end
    end
    Engine.run(task)
end

-- ---- the walking check ----

-- What the walking check announced (Scan.Walk): a name is spoken again
-- only after its dots were out of view for 30 seconds of walking
-- outdoors.
module.walk = Scan.Walk.new()
module.centredOnce = false
local lastReadText = nil
-- The arrow atlases go into the log once a session, with the first arrow.
local atlasNoted = false

-- "Mailbox x2, Peacebloom below, Copper Vein grey": a read's names with
-- their counts, arrows and grey (inside a building or underground),
-- sorted. An arrow Scan.arrowLevel does not explain shows its texture
-- escape, to be looked at.
local function readText(dots)
    local counts, keys = {}, {}
    for _, dot in ipairs(dots) do
        local key = dot.name
        if dot.level ~= nil then
            key = key .. " " .. dot.level
        elseif dot.arrow ~= nil then
            key = key .. " arrow " .. dot.arrow.spec
        end
        if dot.otherLevel then
            key = key .. " grey"
        end
        if counts[key] == nil then
            counts[key] = 0
            tinsert(keys, key)
        end
        counts[key] = counts[key] + 1
    end
    table.sort(keys)
    local parts = {}
    for _, key in ipairs(keys) do
        tinsert(parts, counts[key] > 1 and (key .. " x" .. counts[key]) or key)
    end
    return #parts > 0 and table.concat(parts, ", ") or "no names"
end

-- The game's above and below arrows as the scanner reads them.
local function arrowAtlasText()
    local parts = {}
    local atlases = Engine.arrowAtlases()
    for _, level in ipairs({ "above", "below" }) do
        local a = atlases[level]
        if a == nil then
            tinsert(parts, level .. " not known")
        else
            tinsert(
                parts,
                string.format("%s %s, %.3f %.3f %.3f %.3f", level, tostring(a.file), a.left, a.right, a.top, a.bottom)
            )
        end
    end
    return "arrow atlases (left right top bottom): " .. table.concat(parts, "; ")
end

-- True when every dot of the name in the read is grey: inside a building
-- or underground while the player is not (Warcraft Wiki, Minimap).
local function nameIndoors(dots, name)
    local any = false
    for _, dot in ipairs(dots) do
        if dot.name == name then
            if not dot.otherLevel then
                return false
            end
            any = true
        end
    end
    return any
end

-- "above" or "below" when every dot of the name in the read has that
-- arrow; nil otherwise (no arrow, or the new one cannot be told apart).
local function nameLevel(dots, name)
    local level = nil
    for _, dot in ipairs(dots) do
        if dot.name == name then
            if dot.level == nil or (level ~= nil and level ~= dot.level) then
                return nil
            end
            level = dot.level
        end
    end
    return level
end

local function eventText(e)
    if e.kind == "new" then
        return string.format("new: %s, read %d, remembered %d", e.name, e.count, e.remembered)
    elseif e.kind == "fewer" then
        return string.format("fewer: %s, read %d of %d remembered", e.name, e.count, e.remembered)
    elseif e.kind == "back" then
        return string.format("back after %.1f s missing, silent: %s", e.missing, e.name)
    elseif e.kind == "gone" then
        return string.format("gone after %.1f s missing: %s, %d dropped", e.missing, e.name, e.dropped)
    elseif e.kind == "left" then
        return string.format("left range, %.0f yd from its place: %s", e.distance, e.name)
    elseif e.kind == "follows" then
        return string.format(
            "still in view %.0f yd from its place: %s, a town arrow or a walking NPC; name rule from now",
            e.distance,
            e.name
        )
    elseif e.kind == "jump" then
        return e.distance ~= nil and string.format("jumped %.0f yd: no follow check this read", e.distance)
            or "other continent: no follow check this read"
    elseif e.kind == "indoors" then
        return "indoors: missing clock stopped"
    elseif e.kind == "outdoors" then
        return "outdoors: missing clock runs"
    end
    return e.kind .. (e.name ~= nil and (": " .. e.name) or "")
end

local COMPASS = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" }

-- "231 yd north-west": a world point seen from the player.
local function fromPlayer(px, py, wx, wy)
    local north, east = wx - px, -(wy - py)
    local angle = math.deg(math.atan2(east, north)) % 360
    local word = COMPASS[math.floor(angle / 45 + 0.5) % 8 + 1]
    return string.format("%.0f yd %s", math.sqrt(north * north + east * east), word)
end

-- The outdoor view radius at zoom 0, read on each outdoor walking check.
module.outdoorRadius = Scan.Walk.RADIUS

-- A walking read: into the memory, the new names spoken. Returns the
-- names whose new dots want a place.
function module:walkJudge(dots, indoors)
    local counts = Scan.counts(dots)
    local text = readText(dots)
    if not atlasNoted then
        for _, dot in ipairs(dots) do
            if dot.arrow ~= nil then
                atlasNoted = true
                walkNote(arrowAtlasText())
                break
            end
        end
    end
    local where = indoors and "indoors" or "outdoors"
    if text .. where ~= lastReadText then
        lastReadText = text .. where
        walkNote("read " .. where .. ": " .. text)
    end
    -- Town arrows from the last scan: never placed.
    for _, name in ipairs(self.places) do
        self.walk.nameOnly[name] = true
    end
    local px, py, _, continent = UnitPosition("player")
    local events, locate = self.walk:update({
        counts = counts,
        now = GetTime(),
        indoors = indoors,
        px = px,
        py = py,
        continent = continent,
        radius = self.outdoorRadius,
    })
    for _, e in ipairs(events) do
        walkNote(eventText(e))
        if e.kind == "new" then
            local text = e.name
            local level = nameLevel(dots, e.name)
            if level ~= nil then
                text = text .. ", " .. L[level]
            end
            if nameIndoors(dots, e.name) then
                text = text .. ", " .. L["indoors"]
            end
            local kind = self.kinds[e.name]
            if kind ~= nil then
                text = text .. ", " .. kind
            end
            dotAlert:fire({ text = text })
        end
    end
    return locate
end

-- Inside the walking check: the sweep (as the scan does it) over the
-- full-size minimap for the names with new dots, while the player walks
-- on. Positions are taken from the player's position halfway through.
function module:walkLocate(task, state, cursorX, cursorY, names)
    task.locating = true
    task.cursorX, task.cursorY = cursorX, cursorY
    task.stats = { questions = 0, frames = 0, ms = 0, dots = 0, merged = 0 }
    local work = {}
    for _, name in ipairs(names) do
        tinsert(work, { name = name })
    end
    local viewRadius = C_Minimap.GetViewRadius()
    local facing = GetCVar("rotateMinimap") == "1" and (GetPlayerFacing() or 0) or 0
    local startX, startY, _, continent = UnitPosition("player")
    local started = GetTime()
    Engine.fullSize(state, cursorX, cursorY)
    Engine.wait(2)
    local radius = state.width / 2
    local found = sweepPositions(task, work, radius) or {}
    local endX, endY = UnitPosition("player")
    if endX == nil then
        endX, endY = startX, startY
    end
    local px, py = (startX + endX) / 2, (startY + endY) / 2
    local s = task.stats
    walkNote(
        string.format(
            "located %s: %d questions, %d extra frames, %.2f s, walked %.0f yd meanwhile",
            table.concat(names, ", "),
            s.questions,
            s.frames,
            GetTime() - started,
            math.sqrt((endX - startX) ^ 2 + (endY - startY) ^ 2)
        )
    )
    for _, name in ipairs(names) do
        local positions = {}
        for _, offset in ipairs(found[name] or {}) do
            local north, west = Scan.offsetToWorld(offset[1], offset[2], viewRadius / radius, facing)
            tinsert(positions, { wx = px + north, wy = py + west })
        end
        local result = self.walk:placed(name, positions, continent)
        local parts = {}
        for _, dot in ipairs(result.placed) do
            tinsert(parts, fromPlayer(px, py, dot.wx, dot.wy))
        end
        local line = "placed " .. name .. ": " .. (#parts > 0 and table.concat(parts, ", ") or "none")
        if result.refreshed > 0 then
            line = line .. string.format("; %d known found again", result.refreshed)
        end
        if result.unplaced > 0 then
            line = line .. string.format("; %d not found, name rule for them", result.unplaced)
        end
        if result.extra > 0 then
            line = line .. string.format("; %d more found than new", result.extra)
        end
        walkNote(line)
    end
end

function module:walkCheck()
    local task = {}
    self.walkTask = task
    task.body = function()
        if module.settings.centreCursor and not module.centredOnce then
            module.centredOnce = true
            Engine.centreCursor()
            Engine.wait()
        end
        if not Engine.cursorOverWorld() then
            local focus = GetMouseFoci ~= nil and GetMouseFoci()[1] or nil
            walkNote("skip: cursor over " .. tostring(focus and focus.GetName and focus:GetName() or "a frame"))
            return
        end
        local x, y = GetCursorPosition()
        local state = Engine.capture(false)
        Engine.onCleanup(function()
            Engine.restoreFrame(state)
        end)
        Minimap:SetZoom(0)
        Engine.shrink(x, y)
        Engine.wait(2)
        local dots = Engine.readDots()
        local indoors = IsIndoors ~= nil and IsIndoors() or false
        if not indoors then
            local radius = C_Minimap.GetViewRadius()
            if type(radius) == "number" and not WowVision.isSecret(radius) and radius > 0 then
                module.outdoorRadius = radius
            end
        end
        local locate = module:walkJudge(dots, indoors)
        if #locate > 0 then
            module:walkLocate(task, state, x, y, locate)
        end
    end
    task.check = function()
        if InCombatLockdown() then
            return "combat"
        end
        if task.locating then
            -- The sweep asks points of the minimap under the resting cursor.
            if IsMouselooking ~= nil and IsMouselooking() then
                return "mouselook"
            end
            local x, y = GetCursorPosition()
            if math.abs(x - task.cursorX) > 2 or math.abs(y - task.cursorY) > 2 then
                return "mouse"
            end
        end
        return nil
    end
    task.finish = function(ok, reason, err)
        self.walkTask = nil
        if not ok then
            walkNote(
                (task.locating and "locating stopped, new dots stay on the name rule: " or "check stopped: ")
                    .. tostring(reason or "error")
            )
            if err ~= nil then
                geterrorhandler()(err)
            end
        end
    end
    Engine.run(task)
end

local nextWalk = 0

function module:walkTick()
    local now = GetTime()
    if now < nextWalk then
        return
    end
    nextWalk = now + WALK_INTERVAL
    if not self.settings.announceWalking then
        walkNote("skip: switched off")
        return
    end
    if self.task ~= nil or self.walkTask ~= nil then
        walkNote("skip: scan running")
        return
    end
    if not moving() then
        walkNote("skip: standing")
        return
    end
    if InCombatLockdown() then
        walkNote("skip: combat")
        return
    end
    if IsMouselooking ~= nil and IsMouselooking() then
        walkNote("skip: mouselook")
        return
    end
    local ok, err = pcall(self.walkCheck, self)
    if not ok then
        self.walkTask = nil
        geterrorhandler()(err)
    end
end

function module:onEnable()
    if Engine.available() then
        self:hasUpdate(function(self)
            self:walkTick()
        end)
    end
end

-- ---- real names on arrival ----

-- Some NPCs show their title as the minimap name (see Scan.pickName).
-- When a beacon to a seen NPC arrives, the NPCs around the player are
-- read once: one carrying the dot's name as its title gives its real
-- name, kept on the entry for the session (entry.name stays the dot name,
-- so later scans still match it). Nothing runs until an arrival.
function module:learnName(entryId)
    local entry = nil
    for _, candidate in ipairs(self.store.entries) do
        if candidate.id == entryId then
            entry = candidate
            break
        end
    end
    if entry == nil then
        return
    end
    if entry.realName ~= nil then
        speak(entry.realName .. ", " .. entry.name)
        return
    end
    local name, reason = Scan.pickName(entry.name, Engine.nearbyNpcs())
    if name ~= nil then
        entry.realName = name
        speak(name .. ", " .. entry.name)
    elseif reason == "none" and not self.plateHintGiven and not Engine.friendlyPlatesShown() then
        self.plateHintGiven = true
        speak(L["Turn on friendly NPC nameplates to learn NPC names"])
    end
end

-- A seen entry as the quest system shows it: the real name once learned,
-- the dot's name (a title) then as its title.
local function displayName(entry)
    return entry.realName or entry.name
end

local function displayTitle(entry)
    if entry.realName ~= nil then
        return entry.name
    end
    return entry.subtitle
end

local function arriveAt(entry)
    local id = entry.id
    return function()
        module:learnName(id)
    end
end

-- ---- feeding the quest system ----

-- World points of finished quests on the player's map (the game moves a
-- finished quest's point onto its turn-in NPC).
local function turnInPoints()
    local points = {}
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId == nil or C_QuestLog.GetQuestsOnMap == nil then
        return points
    end
    local ok, list = pcall(C_QuestLog.GetQuestsOnMap, mapId)
    if not ok or type(list) ~= "table" then
        return points
    end
    for _, info in ipairs(list) do
        local done = C_QuestLog.ReadyForTurnIn ~= nil and C_QuestLog.ReadyForTurnIn(info.questID)
        if not done and C_QuestLog.IsComplete ~= nil then
            done = C_QuestLog.IsComplete(info.questID)
        end
        if done then
            local _, position = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(info.x, info.y))
            if position ~= nil then
                local wx, wy = position:GetXY()
                tinsert(points, { wx = wx, wy = wy })
            end
        end
    end
    return points
end

-- Seen NPCs of one role, as quest system targets (the NPC categories).
function module:seenTargets(category, radius)
    local px, py, _, continent = UnitPosition("player")
    local out = {}
    if px == nil then
        return out
    end
    for _, near in ipairs(self.store:around(px, py, continent, radius, category)) do
        local entry = near.entry
        if entry.mapId ~= nil then
            local spawn = {
                mapId = entry.mapId,
                x = entry.x,
                y = entry.y,
                wx = entry.wx,
                wy = entry.wy,
                continent = entry.continent,
                distance = near.distance,
            }
            tinsert(out, {
                kind = "seen",
                id = entry.id,
                name = displayName(entry),
                subName = displayTitle(entry),
                onArrive = arriveAt(entry),
                spawns = { spawn },
                nearest = spawn,
                distance = near.distance,
                seen = true,
                indoors = entry.indoors,
            })
        end
    end
    return out
end

-- Seen quest givers, for the native quest source's Nearby list.
function module:seenGivers()
    local out = {}
    local points = nil
    for _, entry in ipairs(self.store:byCategory("questGiver")) do
        if entry.mapId ~= nil then
            points = points or turnInPoints()
            tinsert(out, {
                guid = "minimap:" .. entry.id,
                name = displayName(entry),
                subName = displayTitle(entry),
                onArrive = arriveAt(entry),
                mapId = entry.mapId,
                x = entry.x,
                y = entry.y,
                wx = entry.wx,
                wy = entry.wy,
                continent = entry.continent,
                status = Scan.giverStatus(entry.wx, entry.wy, points, TURN_IN_RADIUS),
                flag = entry.flag,
                indoors = entry.indoors,
            })
        end
    end
    return out
end

WowVision.quests.seen:register({
    hasGivers = function()
        return #module.store:byCategory("questGiver") > 0
    end,
    givers = function()
        return module:seenGivers()
    end,
    npcs = function(category, radius)
        return module:seenTargets(category, radius)
    end,
})

-- ---- commands ----

function module:listText()
    local px, py = UnitPosition("player")
    local lines = { "WowVision minimap scanner, " .. #self.store.entries .. " seen entries" }
    local points = turnInPoints()
    local statusText = { available = L["quest available"], turnIn = L["turn in"] }
    for _, entry in ipairs(self.store.entries) do
        local distance = px ~= nil and math.sqrt((entry.wx - px) ^ 2 + (entry.wy - py) ^ 2) or 0
        local status = ""
        if entry.category == "questGiver" then
            status = ", " .. statusText[Scan.giverStatus(entry.wx, entry.wy, points, TURN_IN_RADIUS)]
        end
        if entry.indoors then
            status = status .. ", " .. L["indoors"]
        end
        tinsert(
            lines,
            string.format(
                "%s: %s%s, %.0f yards, world %.1f %.1f, map %s %.1f %.1f%s%s",
                self:categoryLabel(entry.category),
                displayName(entry),
                displayTitle(entry) ~= nil and (" <" .. displayTitle(entry) .. ">") or "",
                distance,
                entry.wx,
                entry.wy,
                tostring(entry.mapId),
                entry.x or 0,
                entry.y or 0,
                status,
                entry.flag ~= nil and (", " .. entry.flag) or ""
            )
        )
    end
    if #self.places > 0 then
        tinsert(lines, self:categoryLabel("poi") .. ": " .. table.concat(self.places, ", "))
    end
    return table.concat(lines, "\n")
end

-- /wv mscan log: how the last scan went, then the walking check's log.
function module:logText()
    local lines = {}
    local s = self.lastStats
    if s == nil then
        tinsert(lines, "WowVision minimap scanner: no scan yet this session")
    else
        tinsert(lines, "WowVision minimap scanner, last scan")
        tinsert(lines, string.format("%s after %.1f s; tracking filters with anything here: %s", s.outcome, s.seconds or 0, tostring(s.anyFiltered)))
        tinsert(lines, "positions by: " .. s.method)
        if s.questions > 0 then
            tinsert(
                lines,
                string.format(
                    "sweep: %d questions over %d extra frames, %.1f ms Lua, %.4f ms per question, budget %.2f ms a frame",
                    s.questions,
                    s.frames,
                    s.ms,
                    s.ms / s.questions,
                    s.budget or 0
                )
            )
            tinsert(lines, string.format("dots placed %d, %d of them split from touching dots of one name; one dot's half size %s units", s.dots, s.merged, s.half and string.format("%.2f", s.half) or "not measured"))
        end
        if s.limits ~= nil then
            local parts = {}
            for key, value in pairs(s.limits) do
                tinsert(parts, key .. " " .. tostring(value))
            end
            table.sort(parts)
            tinsert(lines, "script limits: " .. table.concat(parts, ", "))
        end
    end
    tinsert(lines, arrowAtlasText())
    tinsert(lines, "")
    local walkLines = walkLogLines()
    local first = math.max(1, #walkLines - WALK_LOG_SHOWN + 1)
    tinsert(
        lines,
        string.format(
            "Walking check, newest last, lines %d to %d of %d; all of them in WowVisionDump minimapWalk after /reload",
            first,
            #walkLines,
            #walkLines
        )
    )
    for i = first, #walkLines do
        tinsert(lines, walkLines[i])
    end
    return table.concat(lines, "\n")
end

-- /wv mscan walk: what the walking memory holds now.
function module:walkText()
    local lines = {
        string.format(
            "WowVision minimap walking memory; outdoor view radius %.0f yd, in view within %.0f, out of range past %.0f",
            self.outdoorRadius,
            self.outdoorRadius - Scan.Walk.INNER,
            self.outdoorRadius + Scan.Walk.MARGIN
        ),
    }
    local px, py, _, continent = UnitPosition("player")
    local described = self.walk:describe(px, py, continent)
    if #described == 0 then
        tinsert(lines, "nothing remembered")
    end
    for _, line in ipairs(described) do
        tinsert(lines, line)
    end
    return table.concat(lines, "\n")
end

local RAW_READ_FRAMES = 30

-- /wv mscan raw: reads of the shrunk minimap exactly as the game sends
-- them (each line's colour, escapes visible), then every tracking type. For
-- the day the tooltip layout changes and the scanner reads nothing.
function module:rawRead()
    if self.task ~= nil or self.walkTask ~= nil then
        speak(L["Scan already running"])
        return
    end
    if not Engine.available() then
        speak(L["Minimap scanner not available on this client"])
        return
    end
    if InCombatLockdown() then
        speak(L["Not in combat"])
        return
    end
    local task = {}
    self.task = task
    task.body = function()
        -- The scan's own start: cursor centred, then the minimap under it.
        if module.settings.centreCursor then
            Engine.centreCursor()
        end
        Engine.wait()
        local x, y = GetCursorPosition()
        task.overWorld = Engine.cursorOverWorld()
        local state = Engine.capture()
        task.state = state
        Engine.onCleanup(function()
            Engine.restoreFrame(state)
        end)
        Engine.onCleanup(function()
            Engine.restoreTracking(state, false)
        end)
        Minimap:SetZoom(0)
        Engine.shrink(x, y)
        -- Half a second of reads; every read that differs from the one
        -- before is kept, so late dots show up.
        task.reads = {}
        local function readFrames(title)
            local lastSig = nil
            for frame = 1, RAW_READ_FRAMES do
                Engine.wait()
                local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
                data = ok and data or nil
                local sig = Scan.signature(Scan.parseMouseover(data, WowVision.isSecret))
                if sig ~= lastSig then
                    lastSig = sig
                    tinsert(task.reads, { label = string.format("%s, frame %d of %d", title, frame, RAW_READ_FRAMES), data = data })
                end
            end
        end
        readFrames("Your tracking")
        -- The scan's baseline: every tracking filter off, spells as they
        -- are (town arrows, vendors and the like gone).
        local filters = {}
        for _, t in ipairs(state.tracking) do
            if not t.isSpell then
                tinsert(filters, t)
            end
        end
        setFilters(filters, nil)
        readFrames("Every filter off")
        Engine.restoreTracking(state, false)
        Engine.wait()
        -- Then the game asked to name the centre point itself: does the
        -- cursor's own read miss dots while nothing moves?
        local cx, cy = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        local asked = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, cx * scale, cy * scale)
        local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
        tinsert(task.reads, { label = "Asked at the centre (" .. (asked and "ok" or "failed") .. ")", data = ok and data or nil })
    end
    task.check = function()
        return InCombatLockdown() and "combat" or nil
    end
    task.finish = function(ok, reason, err)
        self.task = nil
        if not ok then
            speak(tostring(reason or L["Minimap scan failed"]))
            if err ~= nil then
                geterrorhandler()(err)
            end
            return
        end
        local lines = { "WowVision minimap raw read, cursor over the game world: " .. tostring(task.overWorld) }
        for _, read in ipairs(task.reads) do
            tinsert(lines, read.label)
            for _, line in ipairs(Scan.rawLines(read.data, WowVision.isSecret)) do
                tinsert(lines, line)
            end
            tinsert(lines, "Parsed: " .. Scan.signature(Scan.parseMouseover(read.data, WowVision.isSecret)):gsub("\n", ", "))
        end
        tinsert(lines, arrowAtlasText())
        tinsert(lines, "Tracking types")
        for _, t in ipairs(task.state.tracking) do
            tinsert(
                lines,
                string.format(
                    "%d %s, %s, %s",
                    t.index,
                    t.name,
                    t.active and "on" or "off",
                    t.isSpell and ("spell " .. tostring(t.spellID)) or ("filter " .. tostring(t.filter))
                )
            )
        end
        WowVision.testing.showResults(table.concat(lines, "\n"))
    end
    Engine.run(task)
end

local COMMANDS = {
    list = function()
        WowVision.testing.showResults(module:listText())
    end,
    clear = function()
        module.store:clear()
        module.places = {}
        module.walk = Scan.Walk.new()
        walkNote("cleared: seen entries and walking memory")
        speak(L["Seen entries cleared"])
    end,
    log = function()
        WowVision.testing.showResults(module:logText())
    end,
    walk = function()
        WowVision.testing.showResults(module:walkText())
    end,
    raw = function()
        module:rawRead()
    end,
}

module:registerCommand({
    name = "mscan",
    scope = "WowVision",
    description = "Minimap scanner: scan now; 'list' shows every seen entry, 'clear' forgets them and the walking memory, 'log' shows how the last scan and the walking check went, 'walk' what the walking check remembers, 'raw' one unparsed minimap read",
    func = function(args)
        local word = (args or ""):lower():match("^%s*(%S+)")
        local command = word ~= nil and COMMANDS[word] or nil
        if command ~= nil then
            command()
        else
            module:scan()
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "minimap/scan",
    label = L["Scan Minimap"],
    inputs = { "CTRL-SHIFT-F" },
    func = function()
        module:scan()
    end,
})
