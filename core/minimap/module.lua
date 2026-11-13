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
--   finds nothing new it stops there. Otherwise the sweep asks a
--   half-size minimap every 16 units, moving it under the cursor (one
--   frame a point, about six seconds), and finds each new dot's edges by
--   halving.
--   Moving, turning, the mouse moving, mouselook and combat abort it;
--   everything half-measured is dropped.
-- - The walking check (a setting): twice a second while moving, one read
--   of the shrunk minimap with the player's own tracking; a name that
--   comes into range is announced once, with its kind when a scan
--   already sorted it. A new dot, or one back in view, gets a place while
--   walking on (the scan's sweep on a half-size minimap, each question
--   corrected for the player's walk), only to tell the dots of one name
--   apart; its name is said again only after the player walked out of
--   its range (Scan.Walk). Dots without a place fall back to 30 seconds
--   out of view while walking outdoors. The minimap's indoor scale shows
--   only the building: it counts as indoors.
--
-- Entries live for the session. Quest givers go to the quest system's
-- seen givers (Quests > Nearby, NPCs > Quest Givers), other NPCs to the
-- NPC categories, gathering nodes (known by name while their tracking
-- spell is on; the scan never switches spells) to Gathering; a database
-- entry of the same name wins over a seen one.

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

-- A quest of the log shows on the minimap under its title: its area as a
-- patch inside the minimap, or an arrow at the rim toward an area further
-- away (2026-11-10 Stormwind: "Bingles' verschwundene Werkzeuge", a Loch
-- Modan quest beyond a mountain, at 126 of 150 yards). The quest system
-- already has both from the game: the quest's map points with distance
-- (Quests > In Progress) and entering or leaving its area (Quest Area
-- Alert, PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED). So the scanner leaves
-- these names out: no quest giver, no place, no announcement. (Arrows at
-- the rim were already names only for towns, 2026-09-24.)
local function questLogTitles()
    local titles = {}
    if C_QuestLog == nil or C_QuestLog.GetNumQuestLogEntries == nil or C_QuestLog.GetInfo == nil then
        return titles
    end
    for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
        local info = C_QuestLog.GetInfo(i)
        if info ~= nil and not info.isHeader and type(info.title) == "string" and not WowVision.isSecret(info.title) then
            titles[info.title] = true
        end
    end
    return titles
end

-- The names that are quest titles of the log, left out (see above).
function module:withoutQuestTitles(list)
    local titles = questLogTitles()
    local out = {}
    for _, item in ipairs(list) do
        if not titles[item.name] then
            tinsert(out, item)
        end
    end
    return out
end

local function speak(text)
    WowVision:notify(text)
end

-- "Scan canceled, moved": the reason in one word.
local function canceled(reason)
    return L["Scan canceled"] .. ", " .. reason
end

-- The cancel word for Engine.cursorBusy's reasons.
local function busyWord(reason)
    return reason == "targeting" and L["targeting"] or L["mouse"]
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
    local allOn = Engine.readSettled()
    -- How many dots each name has with every filter on, the sweep's own
    -- setup (one name can stand in several classified entries).
    task.allOnCounts = Scan.counts(allOn)
    task.stats.anyFiltered = Scan.hasExtras(passes.baseline, allOn)
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
-- Each question takes a frame (the minimap moved under the cursor). At
-- full size a dot answers about 9 units each way (2 to 9 cells of 8,
-- measured 2026-11-10, 476 cells in 8 s at 60 frames a second). The dots
-- keep their size when the minimap shrinks, so on a half-size minimap a
-- dot answers over twice as many full-size units and cells of 16 are as
-- safe. How many dots a name has comes from the shrunk read (the scan's
-- every-filter-on read, else the work item's count), not from patch
-- sizes. Measured 2026-11-10 01:51 in
-- Stormwind (/wv mscan sku, 13 dots, no two of one name): full size 840
-- questions 14.0 s; half size 340 questions 5.7 s, 12 dots within 2.3
-- yards of full size (mean 1.3), the 13th an arrow at the rim; third
-- size 4.4 s, up to 4 yards off.
-- opts: { scale, step, halvings, reader? }; all offsets in full-size
-- units. reader: a function () -> ask(ox, oy), instead of the plain
-- Engine.pointReader (the walking check corrects for walking).
local SWEEP = { scale = 0.5, step = 16, halvings = 3 }

local function sweepPositions(task, work, radius, opts)
    opts = opts or SWEEP
    local SWEEP_STEP, EDGE_HALVINGS = opts.step, opts.halvings
    local stats = task.stats
    local expected, counts = {}, {}
    for _, item in ipairs(work) do
        expected[item.name] = true
        counts[item.name] = task.allOnCounts ~= nil and task.allOnCounts[item.name] or item.count
    end
    local read = opts.reader ~= nil and opts.reader() or Engine.pointReader(task.state, task.cursorX, task.cursorY, opts.scale)
    -- Every question goes through here; each one is a frame.
    local function ask(ox, oy)
        stats.questions = stats.questions + 1
        return read(ox, oy)
    end
    local function has(dots, name)
        for _, dot in ipairs(dots) do
            if dot.name == name then
                return true
            end
        end
        return false
    end

    -- The pass: a margin of a dot's reach past the rim, for dots there
    -- (in full-size units the reach grows as the minimap shrinks).
    local hits, any = {}, false
    for _, cell in ipairs(Scan.sweepCells(radius + 10 / opts.scale, SWEEP_STEP)) do
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
        local ks = Scan.dotsByCount(list, counts[name], singleSize)
        for index, comp in ipairs(list) do
            local grey = false
            for _, c in ipairs(comp.cells) do
                grey = grey or c.grey == true
            end
            local k = ks[index]
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
            elseif k > 1 then
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
    local overWorld, blocker = Engine.cursorOverWorld()
    if not overWorld then
        task.stats.blocker = blocker
        Engine.abort(canceled(L["window"]) .. ": " .. blocker)
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
    local viewRadius = Engine.viewRadius()
    if viewRadius == nil then
        Engine.abort(L["Minimap scan failed"])
    end

    local filters, spells = {}, {}
    for _, t in ipairs(state.tracking) do
        tinsert(t.isSpell and spells or filters, t)
    end
    local classified, places = Scan.splitCategory(sortingPasses(task, filters, spells), "poi")
    -- Indoors the minimap shows only this building: what it cannot see
    -- outside is not gone, and everything it does see is indoors. Its
    -- indoor scale counts too (Engine.minimapIndoors).
    local indoors = (IsIndoors ~= nil and IsIndoors()) or Engine.minimapIndoors()
    classified = self:withoutQuestTitles(classified)

    local store = self.store
    local dropped = store:dropMissing(Scan.presentByCategory(classified), px, py, continent, viewRadius * 0.9, indoors)
    local work = Scan.missingWork(classified, store, px, py, continent, viewRadius)
    local counts, order = {}, {}
    local function count(category)
        if counts[category] == nil then
            counts[category] = 0
            tinsert(order, category)
        end
        counts[category] = counts[category] + 1
    end
    -- Indoors the minimap shows only this building; keep the last list.
    if not indoors then
        local known = {}
        for _, name in ipairs(self.places) do
            known[name] = true
        end
        for _, name in ipairs(places) do
            if not known[name] then
                count("poi")
            end
        end
        self.places = places
    end
    if #work > 0 then
        -- Every kind on, so every name answers in the sweep.
        local _, on = sortableFilters(filters)
        setFilters(filters, on)
        local radius = state.width / 2
        local yardsPerUnit = viewRadius / radius
        local facing = task.rotating and task.facing or 0
        task.stats.method = string.format("sweep at size %.2f, step %d, %d halvings", SWEEP.scale, SWEEP.step, SWEEP.halvings)
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
                    count(item.category)
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
    local busy = Engine.cursorBusy()
    if busy ~= nil then
        speak(canceled(busyWord(busy)))
        return
    end
    if UnitPosition("player") == nil or C_Map.GetBestMapForUnit("player") == nil then
        speak(L["No position here"])
        return
    end
    local task = {
        -- What the scan did, for /wv mscan log.
        stats = {
            started = GetTime(),
            method = "none (nothing new to place)",
            questions = 0,
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
        local busy = Engine.cursorBusy()
        if busy ~= nil then
            return canceled(busyWord(busy))
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

-- What the walking check announced (Scan.Walk): a placed dot is spoken
-- again only after the player walked out of its range, one without a
-- place after 30 seconds of walking outdoors out of view.
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

-- The outdoor view radius at zoom 0, read on each outdoor walking check.
module.outdoorRadius = Scan.Walk.RADIUS

-- "Olivia Burnside, above, Banker": a new dot of the walking check.
function module:announceDot(name, dots)
    local text = name
    local level = nameLevel(dots, name)
    if level ~= nil then
        text = text .. ", " .. L[level]
    end
    if nameIndoors(dots, name) then
        text = text .. ", " .. L["indoors"]
    end
    local kind = self.kinds[name]
    if kind ~= nil then
        text = text .. ", " .. kind
    end
    dotAlert:fire({ text = text })
end

-- A walking read: into the memory, the new names spoken. Returns the
-- names whose dots want a place, and the set of those back in view
-- (Walk:update's verify).
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
    local events, locate, verify = self.walk:update({
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
            self:announceDot(e.name, dots)
        end
    end
    return locate, verify
end

-- "231 yd north-west": a world point seen from the player (walk log).
local COMPASS = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" }

local function fromPlayer(px, py, wx, wy)
    local north, east = wx - px, -(wy - py)
    local angle = math.deg(math.atan2(east, north)) % 360
    local word = COMPASS[math.floor(angle / 45 + 0.5) % 8 + 1]
    return string.format("%.0f yd %s", math.sqrt(north * north + east * east), word)
end

-- The walking check's sweep: the scan's own (sweepPositions) on a
-- half-size minimap every 16 units with two halvings. Without halvings
-- each dot answered in one cell only (third size: up to 18 yards off in
-- Stormwind, /wv mscan sku 2026-11-10 03:00); at third size with them,
-- nine mailboxes 100 to 230 yards out still came out 30 to 90 yards apart
-- in two sweeps (several dots of one name overlap there and are split by
-- count). Half size overlaps over half the distance. The player walks
-- meanwhile: every question is asked where its point of the world lies
-- now (the offsets are taken at the sweep's start, then moved by the
-- player's walk and turn since, and scaled by the view radius of that
-- frame: it jumps between 150 and 233 yards in Stormwind), so the dots
-- stand still for the sweep.
-- The places only tell dots apart (Walk.MATCH), they are never spoken.
local SWEEP_WALK = { scale = 0.5, step = 16, halvings = 2 }
-- Places further out than this share of the view radius are pulled in to
-- it (see walkPositions): just inside the rim, where a dot may or may not
-- show.
local RIM_PLACE = 0.97

-- Inside a running task: name -> list of { wx, wy } for the work items
-- ({ name, count }), and the continent.
function module:walkPositions(task, state, cursorX, cursorY, work)
    local radius = state.width / 2
    local viewRadius = Engine.viewRadius()
    task.stats.viewRadius = viewRadius
    if viewRadius == nil then
        return {}, nil
    end
    local yardsPerUnit = viewRadius / radius
    local rotating = GetCVar("rotateMinimap") == "1"
    local startX, startY, _, continent = UnitPosition("player")
    if startX == nil then
        return {}, nil
    end
    local startFacing = rotating and (GetPlayerFacing() or 0) or 0
    local opts = {
        scale = SWEEP_WALK.scale,
        step = SWEEP_WALK.step,
        halvings = SWEEP_WALK.halvings,
        reader = function()
            local read = Engine.pointReader(state, cursorX, cursorY, SWEEP_WALK.scale)
            return function(ox, oy)
                local px, py = UnitPosition("player")
                if px == nil then
                    return read(ox, oy)
                end
                local north, west = Scan.offsetToWorld(ox, oy, yardsPerUnit, startFacing)
                local facing = rotating and (GetPlayerFacing() or 0) or 0
                local nowRadius = Engine.viewRadius() or viewRadius
                if nowRadius ~= viewRadius then
                    task.stats.radiusChanged = nowRadius
                end
                return read(Scan.worldToOffset(startX + north - px, startY + west - py, nowRadius / radius, facing))
            end
        end,
    }
    local offsets = sweepPositions(task, work, radius, opts) or {}
    -- A dot at the rim answers mostly from cells beyond it, so its middle
    -- can land too far out. No dot shows beyond the view radius: such a
    -- place is pulled in to just inside it, in its direction from the
    -- player (the larger radius, when it changed during the sweep).
    local rim = math.max(viewRadius, task.stats.radiusChanged or 0) * RIM_PLACE
    local px, py = UnitPosition("player")
    px, py = px or startX, py or startY
    local found = {}
    for name, list in pairs(offsets) do
        found[name] = {}
        for _, offset in ipairs(list) do
            local north, west = Scan.offsetToWorld(offset[1], offset[2], yardsPerUnit, startFacing)
            local wx, wy = startX + north, startY + west
            local dx, dy = wx - px, wy - py
            local d = math.sqrt(dx * dx + dy * dy)
            if d > rim then
                wx, wy = px + dx * rim / d, py + dy * rim / d
                task.stats.pulledIn = (task.stats.pulledIn or 0) + 1
                d = rim
            end
            tinsert(found[name], { wx = wx, wy = wy, match = Scan.Walk.matchFor(d) })
        end
    end
    return found, continent
end

-- Inside the walking check: places for the names with new dots or back in
-- view (verify), while the player walks on. dots: the read, for the
-- announcement of a dot the place shows to be new.
function module:walkLocate(task, state, cursorX, cursorY, names, dots, verify)
    task.locating = true
    task.cursorX, task.cursorY = cursorX, cursorY
    task.stats = { questions = 0, dots = 0, merged = 0 }
    local counts = Scan.counts(dots)
    local work = {}
    for _, name in ipairs(names) do
        tinsert(work, { name = name, count = counts[name] })
    end
    local startX, startY = UnitPosition("player")
    local started = GetTime()
    local found, continent = self:walkPositions(task, state, cursorX, cursorY, work)
    local px, py = UnitPosition("player")
    if px == nil or startX == nil then
        walkNote("located nothing: no player position, new dots stay on the name rule")
        return
    end
    walkNote(
        string.format(
            "located %s: %d questions, %.2f s, walked %.0f yd meanwhile%s; view radius %s at the start, %s now (each question scaled by its own), the walking memory's %s",
            table.concat(names, ", "),
            task.stats.questions,
            GetTime() - started,
            math.sqrt((px - startX) ^ 2 + (py - startY) ^ 2),
            task.stats.pulledIn ~= nil and string.format(", %d pulled in from beyond the rim", task.stats.pulledIn) or "",
            tostring(task.stats.viewRadius),
            tostring(C_Minimap.GetViewRadius()),
            tostring(self.outdoorRadius)
        )
    )
    for _, name in ipairs(names) do
        local check = verify[name] and { px = px, py = py, radius = task.stats.viewRadius } or nil
        local result = self.walk:placed(name, found[name] or {}, continent, check)
        -- World points too, to compare one standing NPC's place across
        -- view radius modes (2026-11-10 Stormwind: places from the
        -- 233-yard mode matched none from the 150-yard mode).
        local parts, world = {}, {}
        for _, dot in ipairs(result.placed) do
            tinsert(parts, fromPlayer(px, py, dot.wx, dot.wy))
        end
        for _, place in ipairs(found[name] or {}) do
            tinsert(world, string.format("%.1f %.1f", place.wx, place.wy))
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
        if check ~= nil then
            line = line .. string.format("; back in view: %d new, %d gone", result.new, result.dropped)
        end
        line = line .. string.format(
            "; found at world %s; player %.1f %.1f, radius %s",
            #world > 0 and table.concat(world, ", ") or "none",
            px,
            py,
            tostring(task.stats.viewRadius)
        )
        walkNote(line)
        if result.new > 0 then
            self:announceDot(name, dots)
        end
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
        local overWorld, blocker = Engine.cursorOverWorld()
        if not overWorld then
            walkNote("skip: cursor over " .. tostring(blocker))
            return
        end
        local x, y = GetCursorPosition()
        local state = Engine.capture(false)
        Engine.onCleanup(function()
            Engine.restoreFrame(state)
        end)
        Minimap:SetZoom(0)
        Engine.shrink(x, y)
        local dots = module:withoutQuestTitles(Engine.readFirst(6))
        local indoors = (IsIndoors ~= nil and IsIndoors()) or Engine.minimapIndoors()
        if not indoors then
            local radius = C_Minimap.GetViewRadius()
            if type(radius) == "number" and not WowVision.isSecret(radius) and radius > 0 then
                module.outdoorRadius = radius
            end
        end
        local locate, verify = module:walkJudge(dots, indoors)
        if #locate > 0 then
            module:walkLocate(task, state, x, y, locate, dots, verify)
        end
    end
    task.check = function()
        if InCombatLockdown() then
            return "combat"
        end
        local busy = Engine.cursorBusy()
        if busy ~= nil then
            return "cursor busy (" .. busy .. ")"
        end
        if task.locating then
            -- The sweep asks points of the minimap under the resting cursor.
            if IsMouselooking ~= nil and IsMouselooking() then
                return "mouselook"
            end
            local cx, cy = GetCursorPosition()
            if math.abs(cx - task.cursorX) > 2 or math.abs(cy - task.cursorY) > 2 then
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
    local busy = Engine.cursorBusy()
    if busy ~= nil then
        walkNote("skip: cursor busy (" .. busy .. ")")
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
        WowVision:speak(entry.realName .. ", " .. entry.name)
        return
    end
    local name, reason = Scan.pickName(entry.name, Engine.nearbyNpcs())
    if name ~= nil then
        entry.realName = name
        WowVision:speak(name .. ", " .. entry.name)
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
        tinsert(
            lines,
            string.format("%s after %.1f s; tracking filters with anything here: %s", s.outcome, s.seconds or 0, tostring(s.anyFiltered))
        )
        tinsert(lines, "positions by: " .. s.method)
        if s.questions > 0 then
            tinsert(lines, string.format("sweep: %d questions, one frame each", s.questions))
            tinsert(
                lines,
                string.format(
                    "dots placed %d, %d of them split from touching dots of one name; one dot's half size %s units",
                    s.dots,
                    s.merged,
                    s.half and string.format("%.2f", s.half) or "not measured"
                )
            )
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

-- The frames under the cursor, by name.
local function mouseFocusText()
    local foci = {}
    for _, focus in ipairs(GetMouseFoci ~= nil and GetMouseFoci() or {}) do
        local ok, name = pcall(function()
            return focus.GetDebugName ~= nil and focus:GetDebugName() or focus:GetName()
        end)
        tinsert(foci, ok and name ~= nil and name ~= "" and tostring(name) or "unnamed frame")
    end
    return #foci > 0 and table.concat(foci, ", ") or "none"
end

-- /wv mscan raw: reads of the shrunk minimap exactly as the game sends
-- them (each line's colour, escapes visible), read the way the scan and
-- the walking check read (nudged, the cursor's own mouseover), then every
-- tracking type. For the day the tooltip layout changes and the scanner
-- reads nothing. The last read is also kept in WowVisionDump (key
-- minimapRaw), so a player can send the SavedVariables file instead of
-- copying the window.
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
        -- Switching filters reads as leaving and entering quest areas, as
        -- in the scan; registered first, so it lifts last (cleanups run
        -- newest first), after the tracking is back.
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
        Minimap:SetZoom(0)
        task.hiddenChildren = Engine.clearWay()
        Engine.shrink(x, y)
        -- Half a second of reads; every read that differs from the one
        -- before is kept, so late dots show up.
        task.reads = {}
        local function readFrames(title)
            local lastSig = nil
            for frame = 1, RAW_READ_FRAMES do
                Engine.nudge()
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
        -- What the client says about the mouse while the shrunk minimap
        -- sits under the parked cursor.
        local function flag(fn)
            if fn == nil then
                return "unknown"
            end
            local ok, value = pcall(fn)
            return ok and tostring(value) or "error"
        end
        task.facts = string.format(
            "Mouse over the minimap %s, minimap mouse enabled %s, using mouse %s, cursor visible %s, hybrid minimap %s",
            tostring(Minimap:IsMouseOver()),
            tostring(Minimap:IsMouseEnabled()),
            flag(IsUsingMouse),
            flag(IsCursorVisible),
            flag(C_Minimap.ShouldUseHybridMinimap)
        )
        -- What lies over the shrunk minimap under the cursor: other
        -- addons' minimap icons (Questie's, for one) gather there and are
        -- hidden for the read (Engine.clearWay).
        task.mouse = string.format(
            "Mouse focus: %s; minimap children hidden for the read: %d",
            mouseFocusText(),
            task.hiddenChildren
        )
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
    end
    task.check = function()
        if InCombatLockdown() then
            return "combat"
        end
        local busy = Engine.cursorBusy()
        return busy ~= nil and canceled(busyWord(busy)) or nil
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
        if task.facts ~= nil then
            tinsert(lines, task.facts)
            tinsert(lines, task.mouse)
        end
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
        WowVisionDump = WowVisionDump or {}
        WowVisionDump.minimapRaw = { date("%Y-%m-%d %H:%M:%S"), unpack(lines) }
        WowVision.testing.showResults(table.concat(lines, "\n"))
    end
    Engine.run(task)
end

-- /wv mscan sku: Sku's own ways, read only as the game sends them (no
-- UpdateMouseoverAtPoint anywhere; the raw read's old setups of
-- 2026-11-07 asked through it, a no-op since build 70862, so they never
-- tested these). Now: the view radius around the zoom switch, Sku's fast
-- read (the minimap shrunk under the resting cursor), then on the same
-- spot the sweep at full size (the reference), the scan's, a third-size
-- one and the walking check's, timed, each compared with the reference.
-- (Earlier runs measured: 1 frame a point, names from the second frame
-- after the minimap arrives, filters switch without a nudge.) As in Sku the
-- minimap cluster goes on top and the minimap's mouse-taking children
-- (Questie's icons) are hidden while it runs. Saved to
-- WowVisionDump.minimapSku.
local SKU_READ_FRAMES = 10

-- The game's GameTooltip lines, the channel Sku reads.
local function gameTooltipLines()
    if not GameTooltip:IsShown() then
        return {}
    end
    local lines = {}
    for i = 1, GameTooltip:NumLines() do
        local region = _G["GameTooltipTextLeft" .. i]
        local ok, text = pcall(function()
            return region ~= nil and region:GetText() or nil
        end)
        if ok and text ~= nil then
            tinsert(lines, WowVision.isSecret(text) and "(secret)" or tostring(text))
        end
    end
    return lines
end

-- Inside a running task: frames of the cursor's own reads, the fullest
-- one of each channel kept.
local function naturalRead(frames)
    local best = { count = 0, dots = 0, names = "none", tooltip = {} }
    for _ = 1, frames do
        Engine.wait()
        local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
        data = ok and data or nil
        local count = data ~= nil and type(data.lines) == "table" and #data.lines or 0
        best.count = math.max(best.count, count)
        -- One tooltip line holds every name (first run, 2026-11-10).
        local dots = Scan.parseMouseover(data, WowVision.isSecret)
        if #dots > best.dots then
            best.dots = #dots
            best.names = Scan.signature(dots):gsub("\n", ", ")
        end
        local tip = gameTooltipLines()
        if #tip > #best.tooltip then
            best.tooltip = tip
        end
    end
    best.focus = mouseFocusText()
    best.over = tostring(Minimap:IsMouseOver())
    return best
end

local function skuReadText(label, read)
    return string.format(
        "%s: mouse over the minimap %s, focus %s: %d minimap lines, names: %s; GameTooltip %d lines: %s",
        label,
        read.over,
        read.focus,
        read.count,
        read.names,
        #read.tooltip,
        #read.tooltip > 0 and table.concat(read.tooltip, " / ") or "none"
    )
end

function module:skuTest()
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
    local task = { lines = {} }
    self.task = task
    local function add(line)
        tinsert(task.lines, line)
    end
    task.body = function()
        speak("Sku minimap test, keep still")
        -- Sku centres the cursor once, then it rests.
        Engine.centreCursor()
        Engine.wait(10)
        local x, y = GetCursorPosition()
        task.cursorX, task.cursorY = x, y
        local state = Engine.capture()
        task.state = state
        Engine.onCleanup(function()
            Engine.restoreFrame(state)
        end)
        local hidden = Engine.clearWay()
        -- The view radius frame by frame after the zoom goes to 0: does the
        -- game report the old zoom's radius for a while? (Walk 2026-11-10
        -- 02:52: a rough place at 171 yards passed a pull-in at 0.97 of
        -- the radius read then, while the walking memory used 150.)
        local zoomBefore = Minimap:GetZoom()
        local radii = { tostring(C_Minimap.GetViewRadius()) }
        Minimap:SetZoom(0)
        for _ = 1, 6 do
            tinsert(radii, tostring(C_Minimap.GetViewRadius()))
            Engine.wait()
        end
        add(string.format(
            "Cursor resting at %.0f %.0f; hidden minimap children: %d; zoom before %s; view radius before the zoom, then right after it and the next 5 frames: %s; indoors %s",
            x,
            y,
            hidden,
            tostring(zoomBefore),
            table.concat(radii, " "),
            tostring(IsIndoors ~= nil and IsIndoors())
        ))

        -- The fast read (Sku's way): every name in range, the work for the
        -- sweeps below.
        Engine.shrink(x, y)
        Engine.wait(3)
        local fastRead = naturalRead(SKU_READ_FRAMES)
        add(skuReadText("Fast read, shrunk", fastRead))
        local work, named = {}, {}
        for _, dot in ipairs(Engine.readFirst(10)) do
            if named[dot.name] == nil then
                named[dot.name] = { name = dot.name, count = 0 }
                tinsert(work, named[dot.name])
            end
            named[dot.name].count = named[dot.name].count + 1
        end

        -- The scanner's sweep at several minimap sizes on the same spot:
        -- the first (full size, step 8, the sweep of 2026-11-10 morning)
        -- is the reference; the others report how far their dots lie
        -- from its dots of the same name.
        local radius = state.width / 2
        local yardsPerUnit = (C_Minimap.GetViewRadius() or 0) / radius
        local facing = GetCVar("rotateMinimap") == "1" and (GetPlayerFacing() or 0) or 0
        local variants = {
            { label = "reference, full size", scale = 1, step = 8, halvings = 4 },
            { label = "the scan's", scale = SWEEP.scale, step = SWEEP.step, halvings = SWEEP.halvings },
            { label = "third size", scale = 1 / 3, step = 24, halvings = 3 },
            { label = "the walking check's", walk = true },
        }
        local reference = nil
        task.sweeps = {}
        for _, v in ipairs(variants) do
            task.stats = { questions = 0, dots = 0, merged = 0 }
            if v.walk then
                -- The walking sweep starts from the shrunk minimap, as in
                -- the walking check.
                Engine.restoreFrame(state)
                Minimap:SetZoom(0)
                Engine.shrink(x, y)
                Engine.wait(2)
            end
            local started = GetTime()
            local spots = {}
            if v.walk then
                local px, py = UnitPosition("player")
                local found = module:walkPositions(task, state, x, y, work)
                for name, list in pairs(found) do
                    for _, place in ipairs(list) do
                        tinsert(spots, { name = name, north = place.wx - px, east = -(place.wy - py) })
                    end
                end
            else
                local found = sweepPositions(task, work, radius, v) or {}
                for name, list in pairs(found) do
                    for _, offset in ipairs(list) do
                        local north, west = Scan.offsetToWorld(offset[1], offset[2], yardsPerUnit, facing)
                        tinsert(spots, { name = name, north = north, east = -west })
                    end
                end
            end
            local seconds = GetTime() - started
            table.sort(spots, function(p, q)
                return p.name < q.name or (p.name == q.name and p.north < q.north)
            end)
            local function nearest(spot, list)
                local best = nil
                for _, other in ipairs(list) do
                    if other.name == spot.name then
                        local d = math.sqrt((other.north - spot.north) ^ 2 + (other.east - spot.east) ^ 2)
                        if best == nil or d < best then
                            best = d
                        end
                    end
                end
                return best
            end
            local compare = ""
            if reference ~= nil then
                local sum, max, matched, extra, missing = 0, 0, 0, 0, 0
                for _, spot in ipairs(spots) do
                    local d = nearest(spot, reference)
                    spot.off = d
                    if d == nil or d > 10 then
                        extra = extra + 1
                    else
                        matched = matched + 1
                        sum = sum + d
                        max = math.max(max, d)
                    end
                end
                for _, spot in ipairs(reference) do
                    local d = nearest(spot, spots)
                    if d == nil or d > 10 then
                        missing = missing + 1
                    end
                end
                compare = string.format(
                    "; against the reference: %d within 10 yd (mean %.1f yd, max %.1f yd), %d extra, %d missing",
                    matched,
                    matched > 0 and sum / matched or 0,
                    max,
                    extra,
                    missing
                )
                tinsert(task.sweeps, { label = v.label, seconds = seconds, missing = missing, extra = extra, max = max })
            else
                tinsert(task.sweeps, { label = v.label, seconds = seconds, missing = 0, extra = 0, max = 0 })
            end
            add(string.format(
                "Sweep %s (size %.2f, step %d, %d halvings): %d questions, %.1f s, %d dots, %d split from touching dots%s",
                v.label,
                v.scale or SWEEP_WALK.scale,
                v.step or SWEEP_WALK.step,
                v.halvings or SWEEP_WALK.halvings,
                task.stats.questions,
                seconds,
                #spots,
                task.stats.merged,
                compare
            ))
            for _, spot in ipairs(spots) do
                add(string.format(
                    "  %s: %.0f yd %s, %.0f yd %s%s",
                    spot.name,
                    math.abs(spot.north),
                    spot.north >= 0 and "north" or "south",
                    math.abs(spot.east),
                    spot.east >= 0 and "east" or "west",
                    spot.off ~= nil and string.format(", %.1f yd from the reference", spot.off) or ""
                ))
            end
            reference = reference or spots
        end
    end
    -- As the scan: moving, mouselook or the mouse would make the numbers
    -- junk.
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
            local cx, cy = GetCursorPosition()
            if math.abs(cx - task.cursorX) > 2 or math.abs(cy - task.cursorY) > 2 then
                return canceled(L["mouse"])
            end
        end
        return nil
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
        local lines = { "WowVision Sku minimap test" }
        for _, line in ipairs(task.lines) do
            tinsert(lines, line)
        end
        tinsert(lines, "Tracking types on")
        for _, t in ipairs(task.state.tracking) do
            if t.active then
                tinsert(lines, string.format("%d %s", t.index, t.name))
            end
        end
        WowVisionDump = WowVisionDump or {}
        WowVisionDump.minimapSku = { date("%Y-%m-%d %H:%M:%S"), unpack(lines) }
        WowVision.testing.showResults(table.concat(lines, "\n"))
        local parts = {}
        for _, sw in ipairs(task.sweeps or {}) do
            tinsert(parts, string.format("%s %.0f seconds, %d missing, %d extra", sw.label, sw.seconds, sw.missing, sw.extra))
        end
        speak("Sku test done. " .. table.concat(parts, "; "))
    end
    Engine.run(task)
end

local COMMANDS = {
    sku = function()
        module:skuTest()
    end,
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
    description = "Minimap scanner: scan now; 'list' shows every seen entry, 'clear' forgets them and the walking memory, 'log' shows how the last scan and the walking check went, 'walk' what the walking check remembers, 'raw' one unparsed minimap read, 'sku' the sweep test (the scan's and the walking check's sweeps against a full-size one)",
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
