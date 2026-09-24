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
--   already sorted it.
--
-- Entries live for the session. Quest givers go to the quest system's
-- seen givers (Quests > Nearby, NPCs > Quest Givers), other NPCs to the
-- NPC categories, gathering nodes to Gathering; a database entry of the
-- same name wins over a seen one.

settings:add({
    key = "announceWalking",
    type = "Bool",
    label = L["Announce Tracked Dots While Walking"],
    -- On while it is being tried out: addon settings still reset often.
    default = true,
})
settings:add({
    key = "sortGathering",
    type = "Bool",
    label = L["Switch Gathering Tracking Off To Sort Nodes"],
    default = true,
})
settings:add({
    key = "centreCursor",
    type = "Bool",
    label = L["Centre Mouse Cursor Before Scanning"],
    default = true,
})

local dotAlert = module:addAlert({
    key = "newDot",
    label = L["New Minimap Dot Alert"],
})
local dotTTS = dotAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return message.text
    end,
})

-- For the moment the walking announcements speak with game voice 0, not
-- the player's speech voice: with an NVDA SAPI voice there they were cut
-- off by the screen reader's own speech.
local WALK_VOICE = 0

-- The walking check's log (/wv mscan log): each step it took or why
-- it did not run, repeats of the same skip folded into one line. A
-- diagnostic while the announcement is being tried out.
local WALK_LOG_SIZE = 60
module.walkLog = {}
local lastWalkNote = nil

local function walkNote(text)
    if text == lastWalkNote then
        return
    end
    lastWalkNote = text
    tinsert(module.walkLog, string.format("%.1f %s", GetTime(), text))
    if #module.walkLog > WALK_LOG_SIZE then
        tremove(module.walkLog, 1)
    end
end

function dotTTS:onFire(message)
    local text = message.text
    if text == nil then
        return
    end
    local speech = WowVision.base.speech
    local volume = math.max(0, math.min(100, speech.settings.speechVolume or 100))
    text = WowVision.ttsCacheBust.bust(text)
    walkNote("spoken: " .. text)
    C_VoiceChat.SpeakText(WALK_VOICE, text, speech.settings.speechRate, volume, false)
end
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

-- Seconds before a name that left the walking check's range is announced
-- again, against flicker at the edge.
local REANNOUNCE_AFTER = 30
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
-- names. task.spellsSwitched is set BEFORE a spell is touched, so an
-- abort in between still switches it back on.
local function sortingPasses(task, filters, spells)
    local passes = { filters = {}, spells = {} }
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
    local spellActive = false
    for _, s in ipairs(spells) do
        spellActive = spellActive or s.active
    end
    if spellActive and not module.settings.sortGathering then
        -- Gathering nodes stay mixed in with the quest givers.
        passes.baselineCategory = "unsorted"
    end
    if module.settings.sortGathering then
        local baseSig = Scan.signature(passes.baseline)
        for _, s in ipairs(spells) do
            if s.active then
                task.spellsSwitched = true
                C_Minimap.SetTracking(s.index, false)
                local category = "spell:" .. tostring(s.spellID or s.name)
                module.spellLabels[category] = s.name
                tinsert(passes.spells, { category = category, label = s.name, dots = Engine.readSettled(12) })
                C_Minimap.SetTracking(s.index, true)
                -- Casting the spell again takes longer than a filter
                -- switch; wait until the baseline is back (3 s at most).
                for _ = 1, 180 do
                    Engine.wait()
                    if Scan.signature(Engine.readDots()) == baseSig then
                        break
                    end
                end
            end
        end
    end
    local classified = Scan.classify(passes)
    -- The walking check's names for each kind.
    local labels = {}
    for _, pass in ipairs(passes.filters) do
        labels[pass.category] = labels[pass.category] or pass.label
    end
    for _, pass in ipairs(passes.spells) do
        labels[pass.category] = pass.label
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
    Engine.onCleanup(function()
        Engine.restoreFrame(state)
    end)
    Engine.onCleanup(function()
        Engine.restoreTracking(state, task.spellsSwitched)
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
        -- A tracking spell switched back on is a cast; give it a second,
        -- then say so if it did not come back.
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

module.lastNames = {}
module.announcedAt = {}
module.centredOnce = false

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
        task.dots = Engine.readDots()
    end
    task.check = function()
        if InCombatLockdown() then
            return "combat"
        end
        return nil
    end
    task.finish = function(ok)
        self.walkTask = nil
        if not ok or task.dots == nil then
            walkNote(ok and "read nothing" or "check failed")
            return
        end
        local read = {}
        for _, dot in ipairs(task.dots) do
            tinsert(read, dot.name)
        end
        walkNote("read: " .. (#read > 0 and table.concat(read, ", ") or "no names"))
        local now = GetTime()
        local names = {}
        for _, dot in ipairs(task.dots) do
            names[dot.name] = true
            if not self.lastNames[dot.name] then
                local last = self.announcedAt[dot.name]
                if last == nil or now - last > REANNOUNCE_AFTER then
                    self.announcedAt[dot.name] = now
                    local kind = self.kinds[dot.name]
                    walkNote("announce: " .. dot.name)
                    dotAlert:fire({ text = kind ~= nil and (dot.name .. ", " .. kind) or dot.name })
                end
            end
        end
        self.lastNames = names
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
    tinsert(lines, "")
    tinsert(lines, "Walking check, newest last")
    for _, line in ipairs(self.walkLog) do
        tinsert(lines, line)
    end
    return table.concat(lines, "\n")
end

-- /wv mscan raw: one read of the shrunk minimap exactly as the game sends
-- it (each line's colour, escapes visible), then every tracking type. For
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
        local x, y = GetCursorPosition()
        task.overWorld = Engine.cursorOverWorld()
        local state = Engine.capture()
        task.state = state
        Engine.onCleanup(function()
            Engine.restoreFrame(state)
        end)
        Minimap:SetZoom(0)
        Engine.shrink(x, y)
        Engine.wait(2)
        local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
        task.data = ok and data or nil
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
        for _, line in ipairs(Scan.rawLines(task.data, WowVision.isSecret)) do
            tinsert(lines, line)
        end
        tinsert(lines, "Parsed: " .. Scan.signature(Scan.parseMouseover(task.data, WowVision.isSecret)):gsub("\n", ", "))
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
        speak(L["Seen entries cleared"])
    end,
    log = function()
        WowVision.testing.showResults(module:logText())
    end,
    raw = function()
        module:rawRead()
    end,
}

module:registerCommand({
    name = "mscan",
    scope = "WowVision",
    description = "Minimap scanner: scan now; 'list' shows every seen entry, 'clear' forgets them, 'log' shows how the last scan and the walking check went, 'raw' one unparsed minimap read",
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
