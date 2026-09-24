-- The minimap scanner's game-independent half: reading the mouseover
-- tooltip, minimap geometry, grouping hits, sorting names by tracking
-- pass, and the store of dots seen this session. No WoW API in here, so
-- the headless suite covers it (core/minimap/tests.lua).
--
-- Measured on WoW: Forever (1.60.1, 2026-09-24):
-- - C_TooltipInfo.GetMinimapMouseover() names every dot under the cursor
--   in ONE gold line, one name per "\n"-separated part. A title follows
--   its name as its own part, led by a space: "Llane Beshere\n <Warrior
--   Trainer>\nMarshal McBride". Several dots of one name repeat the name
--   ("Mailbox\nMailbox").
-- - At zoom 0 the view radius is 150 yards indoors and 233 outdoors (the
--   game switches; read it live) across the 198 unit wide minimap; a
--   dot's hit area is roughly 8 units around it.
-- - Indoors the minimap shows only the building the player is in. From
--   outside, dots inside a building (another level) read grey.
-- - Quest givers show whatever tracking is switched on; every other kind
--   of NPC belongs to one tracking type.

local Scan = {}
WowVision.minimapScan = Scan

local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isGold(color)
    return type(color) == "table"
        and color.r ~= nil
        and color.r > 0.9
        and color.g > 0.7
        and color.g < 0.9
        and color.b < 0.2
end

local function isWhite(color)
    return type(color) == "table" and color.r ~= nil and color.r > 0.9 and color.g > 0.9 and color.b > 0.9
end

-- A colour code of equal grey channels ("|cffb0b0b0"): the game greys the
-- names of dots on another level than the player (measured: NPCs inside
-- the Northshire abbey read grey from outside, gold from inside).
local function isGreyCode(code)
    local r, g, b = code:sub(1, 2), code:sub(3, 4), code:sub(5, 6)
    return r == g and g == b and tonumber(r, 16) < 0xe0
end

-- Tooltip data -> list of dots { name, subtitle, otherLevel }. White
-- lines are detail lines under the dot before them (never seen on Forever
-- yet, but that is the tooltip layout elsewhere), so they never become
-- dots themselves. A colour code runs until its "|r", across parts.
function Scan.parseMouseover(data, isSecret)
    local dots = {}
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return dots
    end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text ~= nil and not (isSecret ~= nil and isSecret(text)) then
            local detailLine = isWhite(line.leftColor) and not isGold(line.leftColor) and #dots > 0
            local grey = false
            for part in tostring(text):gmatch("[^\n]+") do
                local code = part:match("|c%x%x(%x%x%x%x%x%x)")
                if code ~= nil then
                    grey = isGreyCode(code)
                end
                local clean = trim(part:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
                if clean ~= "" then
                    local last = dots[#dots]
                    if clean:match("^<.*>$") then
                        if last ~= nil and last.subtitle == nil then
                            last.subtitle = clean:sub(2, -2)
                        end
                    elseif not detailLine then
                        tinsert(dots, { name = clean, otherLevel = grey })
                    end
                end
                if part:find("|r", 1, true) then
                    grey = false
                end
            end
        end
    end
    return dots
end

-- Tooltip data as the game sent it, one text per line: the line colour
-- as hex, then the text with "|" doubled and newlines as "\n", so colour
-- codes survive into a copyable report (/wv mscan raw).
function Scan.rawLines(data, isSecret)
    local out = {}
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        tinsert(out, "no tooltip data")
        return out
    end
    for _, line in ipairs(data.lines) do
        local text, color = line.leftText, line.leftColor
        if text ~= nil and isSecret ~= nil and isSecret(text) then
            tinsert(out, "(secret value)")
        elseif text ~= nil then
            local hex = "none"
            if type(color) == "table" and color.r ~= nil then
                hex = string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
            end
            local shown = tostring(text):gsub("|", "||"):gsub("\n", "\\n")
            tinsert(out, "[" .. hex .. "] " .. shown)
        end
    end
    return out
end

-- name -> number of dots with that name.
function Scan.counts(dots)
    local out = {}
    for _, dot in ipairs(dots) do
        out[dot.name] = (out[dot.name] or 0) + 1
    end
    return out
end

-- An order-free fingerprint of a read, to tell when the dots settled.
function Scan.signature(dots)
    local names = {}
    for i, dot in ipairs(dots) do
        names[i] = dot.name
    end
    table.sort(names)
    return table.concat(names, "\n")
end

-- ---- geometry ----

-- Minimap offset -> yards north and west of the player. Minimap up is
-- north, or the facing when the minimap rotates. World x points north,
-- world y west (UnitPosition).
function Scan.offsetToWorld(ox, oy, yardsPerUnit, facing)
    local a = facing or 0
    local north = (oy * math.cos(a) + ox * math.sin(a)) * yardsPerUnit
    local west = (oy * math.sin(a) - ox * math.cos(a)) * yardsPerUnit
    return north, west
end

-- ---- the sweep ----
-- Measured on WoW: Forever (2026-09-24):
-- Minimap:UpdateMouseoverAtPoint names the dots at any point in the frame
-- it is called in, each call on its own, for a few microseconds. So one
-- dense pass asks every grid cell; a dot answers over a patch around it
-- (about 9.4 units each way at effective scale 0.85), and the middle of
-- its patch is the dot. Cells are integer (ix, iy), offsets ix and iy
-- times the step.

-- Every cell whose offset lies within radius.
function Scan.sweepCells(radius, step)
    local cells = {}
    local n = math.floor(radius / step)
    for iy = -n, n do
        for ix = -n, n do
            local x, y = ix * step, iy * step
            if x * x + y * y <= radius * radius then
                tinsert(cells, { ix, iy })
            end
        end
    end
    return cells
end

function Scan.cellKey(ix, iy)
    return ix .. "," .. iy
end

-- The cells where one name answered (key -> { ix, iy, n }, n = how often
-- the name was in the answer) -> groups of touching cells (diagonals
-- count): { cells, size, maxN, minX, maxX, minY, maxY }.
function Scan.components(hits)
    local keys = {}
    for key in pairs(hits) do
        tinsert(keys, key)
    end
    table.sort(keys)
    local seen, out = {}, {}
    for _, key in ipairs(keys) do
        if not seen[key] then
            seen[key] = true
            local comp = { cells = {}, size = 0, maxN = 0 }
            local stack = { hits[key] }
            while #stack > 0 do
                local c = table.remove(stack)
                tinsert(comp.cells, c)
                comp.size = comp.size + 1
                comp.maxN = math.max(comp.maxN, c.n)
                comp.minX = math.min(comp.minX or c.ix, c.ix)
                comp.maxX = math.max(comp.maxX or c.ix, c.ix)
                comp.minY = math.min(comp.minY or c.iy, c.iy)
                comp.maxY = math.max(comp.maxY or c.iy, c.iy)
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        local k = Scan.cellKey(c.ix + dx, c.iy + dy)
                        if hits[k] ~= nil and not seen[k] then
                            seen[k] = true
                            tinsert(stack, hits[k])
                        end
                    end
                end
            end
            tinsert(out, comp)
        end
    end
    return out
end

local function median(values)
    if #values == 0 then
        return nil
    end
    local copy = {}
    for i, v in ipairs(values) do
        copy[i] = v
    end
    table.sort(copy)
    local mid = math.floor((#copy + 1) / 2)
    if #copy % 2 == 0 then
        return (copy[mid] + copy[mid + 1]) / 2
    end
    return copy[mid]
end
Scan.median = median

-- Cells one dot covers: the median size of the groups that look like one
-- dot (no answer named it twice, an outline as wide as high and mostly
-- filled; touching dots make a long or hollow outline). Nil when none.
function Scan.singleSize(components)
    local sizes = {}
    for _, comp in ipairs(components) do
        local w, h = comp.maxX - comp.minX + 1, comp.maxY - comp.minY + 1
        if comp.maxN == 1 and math.abs(w - h) <= 1 and comp.size >= 0.7 * w * h then
            tinsert(sizes, comp.size)
        end
    end
    return median(sizes)
end

-- How many dots of the name one group holds: dots overlapping show as an
-- answer naming it twice, dots only touching as a group about twice as
-- large as one dot's.
function Scan.dotsInComponent(comp, singleSize)
    local k = comp.maxN
    if singleSize ~= nil and singleSize > 0 then
        k = math.max(k, math.floor(comp.size / singleSize + 0.5))
    end
    return math.max(k, 1)
end

-- Centres (offsets) of k dots merged in one group: a k-means over its
-- cells weighted by how many dots answered there, started from cells far
-- apart. Good to a few yards; only used where dots of one name touch.
function Scan.splitComponent(comp, k, step)
    local cells = comp.cells
    local first = cells[1]
    for _, c in ipairs(cells) do
        if c.ix < first.ix or (c.ix == first.ix and c.iy < first.iy) then
            first = c
        end
    end
    local centres = { { x = first.ix, y = first.iy } }
    while #centres < k do
        local best, bestD = nil, -1
        for _, c in ipairs(cells) do
            local nearest = math.huge
            for _, centre in ipairs(centres) do
                local dx, dy = c.ix - centre.x, c.iy - centre.y
                nearest = math.min(nearest, dx * dx + dy * dy)
            end
            if nearest > bestD then
                best, bestD = c, nearest
            end
        end
        tinsert(centres, { x = best.ix, y = best.iy })
    end
    for _ = 1, 12 do
        local sums = {}
        for i = 1, k do
            sums[i] = { x = 0, y = 0, w = 0 }
        end
        for _, c in ipairs(cells) do
            local home, homeD = 1, math.huge
            for i, centre in ipairs(centres) do
                local dx, dy = c.ix - centre.x, c.iy - centre.y
                local d = dx * dx + dy * dy
                if d < homeD then
                    home, homeD = i, d
                end
            end
            local s = sums[home]
            s.x = s.x + c.ix * c.n
            s.y = s.y + c.iy * c.n
            s.w = s.w + c.n
        end
        for i, s in ipairs(sums) do
            if s.w > 0 then
                centres[i] = { x = s.x / s.w, y = s.y / s.w }
            end
        end
    end
    local out = {}
    for i, centre in ipairs(centres) do
        out[i] = { centre.x * step, centre.y * step }
    end
    return out
end

-- The group's row nearest its middle: iy, first and last ix.
function Scan.middleRow(comp)
    local rows = {}
    for _, c in ipairs(comp.cells) do
        local r = rows[c.iy]
        if r == nil then
            rows[c.iy] = { minX = c.ix, maxX = c.ix }
        else
            r.minX = math.min(r.minX, c.ix)
            r.maxX = math.max(r.maxX, c.ix)
        end
    end
    local mid = (comp.minY + comp.maxY) / 2
    local bestY, bestD = nil, nil
    for iy in pairs(rows) do
        local d = math.abs(iy - mid)
        if bestD == nil or d < bestD or (d == bestD and iy < bestY) then
            bestY, bestD = iy, d
        end
    end
    return bestY, rows[bestY].minX, rows[bestY].maxX
end

-- The group's first and last iy in column ix, or nil.
function Scan.column(comp, ix)
    local minY, maxY = nil, nil
    for _, c in ipairs(comp.cells) do
        if c.ix == ix then
            minY = math.min(minY or c.iy, c.iy)
            maxY = math.max(maxY or c.iy, c.iy)
        end
    end
    return minY, maxY
end

-- The middle between two edges on one axis. A dot at the rim answers only
-- up to where the minimap ends, so its patch is short on the far side:
-- when the patch is clearly shorter than a full one (half = one dot's
-- half size), the middle comes from the edge nearer the player.
function Scan.edgeCentre(low, high, half)
    if half == nil or (high - low) / 2 >= half - 0.5 then
        return (low + high) / 2
    end
    if math.abs(low) > math.abs(high) then
        return high - half
    end
    return low + half
end

-- ---- sorting by tracking pass ----

-- True when a read shows any name more often than the baseline did.
function Scan.hasExtras(baseline, dots)
    local base = Scan.counts(baseline)
    for name, count in pairs(Scan.counts(dots)) do
        if count > (base[name] or 0) then
            return true
        end
    end
    return false
end

-- passes.baseline: dots with every tracking filter off (spells as found):
--   quest givers, plus whatever the active tracking spells show.
-- passes.filters: { category, dots, flag? } one per filter switched on
--   alone; names beyond the baseline are that category (flag marks quest
--   givers only shown by that filter, such as "trivial").
-- passes.spells: { category, dots } one per tracking spell switched off
--   with the filters; names that vanish are that spell's.
-- passes.baselineCategory: what the baseline's unexplained names are,
--   "questGiver" unless tracking spells were left unsorted.
-- Returns entries { name, category, count, subtitle?, flag? }.
function Scan.classify(passes)
    local subtitles = {}
    local function noteSubtitles(dots)
        for _, dot in ipairs(dots) do
            if dot.subtitle ~= nil then
                subtitles[dot.name] = dot.subtitle
            end
        end
    end
    local base = Scan.counts(passes.baseline or {})
    noteSubtitles(passes.baseline or {})
    local out = {}
    local function add(name, category, count, flag)
        tinsert(out, { name = name, category = category, count = count, subtitle = subtitles[name], flag = flag })
    end

    local givers = {}
    for name, count in pairs(base) do
        givers[name] = count
    end
    for _, pass in ipairs(passes.spells or {}) do
        local counts = Scan.counts(pass.dots)
        for name, count in pairs(base) do
            local gone = count - (counts[name] or 0)
            if gone > 0 then
                add(name, pass.category, gone)
                givers[name] = givers[name] - gone
            end
        end
    end
    for name, count in pairs(givers) do
        if count > 0 then
            add(name, passes.baselineCategory or "questGiver", count)
        end
    end
    for _, pass in ipairs(passes.filters or {}) do
        noteSubtitles(pass.dots)
        for name, count in pairs(Scan.counts(pass.dots)) do
            local extra = count - (base[name] or 0)
            if extra > 0 then
                add(name, pass.category, extra, pass.flag)
            end
        end
    end
    -- Subtitles found after an entry was added.
    for _, entry in ipairs(out) do
        entry.subtitle = entry.subtitle or subtitles[entry.name]
    end
    table.sort(out, function(a, b)
        if a.category ~= b.category then
            return a.category < b.category
        end
        return a.name < b.name
    end)
    return out
end

-- ---- the seen store ----

local Store = {}
Store.__index = Store
Scan.Store = Store

function Store.new()
    return setmetatable({ entries = {}, nextId = 1 }, Store)
end

local function distanceSq(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- Insert a dot, or move the entry of that name and category already
-- within matchRadius yards onto it. Returns the entry and whether it is new.
function Store:upsert(dot, matchRadius)
    for _, entry in ipairs(self.entries) do
        if entry.name == dot.name
            and entry.category == dot.category
            and entry.continent == dot.continent
            and distanceSq(entry.wx, entry.wy, dot.wx, dot.wy) <= matchRadius * matchRadius
        then
            for key, value in pairs(dot) do
                entry[key] = value
            end
            return entry, false
        end
    end
    local entry = {}
    for key, value in pairs(dot) do
        entry[key] = value
    end
    entry.id = self.nextId
    self.nextId = self.nextId + 1
    tinsert(self.entries, entry)
    return entry, true
end

-- Entries of one category (nil: every one) on the continent within
-- radius yards of a point (nil: any distance), nearest first, as
-- { entry, distance }.
function Store:around(wx, wy, continent, radius, category)
    local out = {}
    for _, entry in ipairs(self.entries) do
        if entry.continent == continent and (category == nil or entry.category == category) then
            local distance = math.sqrt(distanceSq(entry.wx, entry.wy, wx, wy))
            if radius == nil or distance <= radius then
                tinsert(out, { entry = entry, distance = distance })
            end
        end
    end
    table.sort(out, function(a, b)
        return a.distance < b.distance
    end)
    return out
end

-- Entries within radius yards of a point, optionally of one name and category.
function Store:near(wx, wy, continent, radius, name, category)
    local out = {}
    for _, entry in ipairs(self.entries) do
        if entry.continent == continent
            and (name == nil or entry.name == name)
            and (category == nil or entry.category == category)
            and distanceSq(entry.wx, entry.wy, wx, wy) <= radius * radius
        then
            tinsert(out, entry)
        end
    end
    return out
end

-- Drop entries within radius whose name no sorting pass found any more
-- (a herb picked, a quest taken). present: category -> name -> count.
-- indoorsOnly: the scan ran indoors, where the minimap shows only the
-- building the player is in, so only indoor entries can be judged.
-- Returns the number dropped.
function Store:dropMissing(present, wx, wy, continent, radius, indoorsOnly)
    local kept, dropped = {}, 0
    for _, entry in ipairs(self.entries) do
        local inRange = entry.continent == continent
            and distanceSq(entry.wx, entry.wy, wx, wy) <= radius * radius
            and (not indoorsOnly or entry.indoors == true)
        local counts = present[entry.category]
        if inRange and (counts == nil or (counts[entry.name] or 0) == 0) then
            dropped = dropped + 1
        else
            tinsert(kept, entry)
        end
    end
    self.entries = kept
    return dropped
end

function Store:byCategory(category)
    local out = {}
    for _, entry in ipairs(self.entries) do
        if entry.category == category then
            tinsert(out, entry)
        end
    end
    return out
end

function Store:clear()
    self.entries = {}
end

-- Sorted entries whose count in range falls short of what the passes
-- found: the names the position scan still has to place.
function Scan.missingWork(classified, store, wx, wy, continent, radius)
    local work = {}
    for _, item in ipairs(classified) do
        local known = #store:near(wx, wy, continent, radius, item.name, item.category)
        if item.count > known then
            tinsert(work, item)
        end
    end
    return work
end

-- category -> name -> count, for Store:dropMissing.
-- Splits one category out of classified entries: returns the rest and
-- that category's names, sorted and each once.
function Scan.splitCategory(classified, category)
    local rest, names, seen = {}, {}, {}
    for _, item in ipairs(classified) do
        if item.category ~= category then
            tinsert(rest, item)
        elseif not seen[item.name] then
            seen[item.name] = true
            tinsert(names, item.name)
        end
    end
    table.sort(names)
    return rest, names
end

function Scan.presentByCategory(classified)
    local present = {}
    for _, item in ipairs(classified) do
        present[item.category] = present[item.category] or {}
        present[item.category][item.name] = (present[item.category][item.name] or 0) + item.count
    end
    return present
end

-- A quest giver dot standing on the turn-in point of a finished quest
-- hands that quest in; any other offers one, as far as the game shows
-- (it draws the same dot for a quest still a level or two away).
-- points: { wx, wy } list.
function Scan.giverStatus(wx, wy, points, radius)
    for _, point in ipairs(points or {}) do
        if distanceSq(wx, wy, point.wx, point.wy) <= radius * radius then
            return "turnIn"
        end
    end
    return "available"
end

-- ---- real names for title-only dots ----

-- Measured on WoW: Forever (2026-09-24): some NPCs new to Forever (a
-- skinning trainer "in Ausbildung" in Goldshire) show their TITLE as the
-- minimap name, not their own. Their unit tooltip has both, so on arrival
-- the scanner looks at the NPCs around the player (nameplates, target,
-- soft interact) for one whose tooltip carries the dot's name as a line
-- below its own name.

-- A tooltip line as plain text: colour codes and angle brackets gone.
function Scan.cleanLine(text)
    if type(text) ~= "string" then
        return nil
    end
    local clean = trim(text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    local inner = clean:match("^<(.*)>$")
    if inner ~= nil then
        clean = trim(inner)
    end
    return clean
end

-- The real name behind a dot name, from nearby NPCs.
-- candidates: { name, lines = { tooltip lines below the name }, minRange?,
-- maxRange? }. Returns the name, or nil and a reason: "named" (an NPC is
-- called that, so the dot name is already a real name), "none" (nobody
-- nearby has that title), "ambiguous" (several do and range cannot tell
-- which is closest).
function Scan.pickName(dotName, candidates)
    local wanted = Scan.cleanLine(dotName)
    local matches, names = {}, {}
    for _, candidate in ipairs(candidates or {}) do
        if candidate.name == wanted then
            return nil, "named"
        end
        for _, line in ipairs(candidate.lines or {}) do
            if Scan.cleanLine(line) == wanted then
                if not names[candidate.name] then
                    names[candidate.name] = true
                    tinsert(matches, candidate)
                end
                break
            end
        end
    end
    if #matches == 0 then
        return nil, "none"
    end
    if #matches == 1 then
        return matches[1].name
    end
    -- Several NPCs of that title: the closest wins when its range is
    -- clearly below every other's.
    table.sort(matches, function(a, b)
        return (a.maxRange or math.huge) < (b.maxRange or math.huge)
    end)
    local best = matches[1]
    if best.maxRange == nil then
        return nil, "ambiguous"
    end
    for i = 2, #matches do
        if (matches[i].minRange or 0) < best.maxRange then
            return nil, "ambiguous"
        end
    end
    return best.name
end

return Scan
