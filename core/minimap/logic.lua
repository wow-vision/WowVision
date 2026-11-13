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
--   dot's hit area is about 9 units around it (see the sweep below).
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

local function channels(code)
    return tonumber(code:sub(1, 2), 16), tonumber(code:sub(3, 4), 16), tonumber(code:sub(5, 6), 16)
end

-- A colour code of equal grey channels ("|cffb0b0b0"): the game greys the
-- names of dots on another level than the player (measured: NPCs inside
-- the Northshire abbey read grey from outside, gold from inside).
local function isGreyCode(code)
    local r, g, b = channels(code)
    return r == g and g == b and r < 0xe0
end

-- White text inside a gold line ("|cffffffff"): a detail under the dot
-- before it, such as a quest objective under a quest's name.
local function isWhiteCode(code)
    local r, g, b = channels(code)
    return r >= 0xe0 and g >= 0xe0 and b >= 0xe0
end

-- The colour code (6 hex digits, nil: the line's own colour) in force
-- where a part's text starts, and the one in force after it. A code runs
-- until its "|r", across parts.
local function partColour(part, carried)
    local atStart = part:match("^%s*|c%x%x(%x%x%x%x%x%x)") or carried
    local after = carried
    for kind, hex in part:gmatch("|([cr])(%x*)") do
        if kind == "c" then
            after = hex:sub(3, 8)
        else
            after = nil
        end
    end
    return atStart, after
end

-- A texture escape's inside ("path:height:width:x:y:texWidth:texHeight:
-- left:right:top:bottom") -> { spec, left, right, top, bottom } with the
-- corners as fractions of the texture, or nil without them.
function Scan.textureCoords(spec)
    local fields = {}
    for field in (spec .. ":"):gmatch("([^:]*):") do
        tinsert(fields, field)
    end
    local texWidth, texHeight = tonumber(fields[6]), tonumber(fields[7])
    local left, right = tonumber(fields[8]), tonumber(fields[9])
    local top, bottom = tonumber(fields[10]), tonumber(fields[11])
    if texWidth == nil or texHeight == nil or texWidth <= 0 or texHeight <= 0 or bottom == nil then
        return nil
    end
    return {
        spec = spec,
        left = left / texWidth,
        right = right / texWidth,
        top = top / texHeight,
        bottom = bottom / texHeight,
    }
end

-- "above", "below" or nil for a dot's arrow. Minimap-PositionArrows holds
-- two arrows one over the other. Measured on Forever (2026-09-28): diving
-- in a lake under a Silberblatt seen on the shore just before, the dot
-- read with the top half; the bottom half showed from higher ground.
-- (The atlases MiniMap-PositionArrowUp/Down did not match these halves.)
function Scan.arrowLevel(arrow)
    if arrow == nil or arrow.top == nil or not arrow.spec:find("PositionArrows", 1, true) then
        return nil
    end
    if arrow.bottom <= 0.55 then
        return "above"
    elseif arrow.top >= 0.45 then
        return "below"
    end
    return nil
end

-- Tooltip data -> list of dots { name, subtitle, otherLevel, arrow }. White
-- text, a whole line or a colour code inside one, is detail under the dot
-- before it (measured on Forever: "Quest name|cffffffff\n-Objective: 1/8|r"
-- from quest objective tracking), so it never becomes a dot itself.
function Scan.parseMouseover(data, isSecret)
    local dots = {}
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return dots
    end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text ~= nil and not (isSecret ~= nil and isSecret(text)) then
            local detailLine = isWhite(line.leftColor) and not isGold(line.leftColor) and #dots > 0
            local carried = nil
            for part in tostring(text):gmatch("[^\n]+") do
                local code, after = partColour(part, carried)
                carried = after
                -- A texture before a name is a small arrow (measured on
                -- Forever 2026-09-28: gathering nodes read as
                -- "|TInterface\Minimap\Minimap-PositionArrows:...|tSilberblatt"
                -- from some spots): the dot is above or below the player
                -- (Warcraft Wiki, Minimap). The dot is the same, only the
                -- name counts; the arrow is kept (Scan.arrowLevel).
                local texture = part:match("|T([^|]*)|t")
                local arrow = texture ~= nil and (Scan.textureCoords(texture) or { spec = texture }) or nil
                local clean = trim(
                    part:gsub("|T[^|]*|t", ""):gsub("|A[^|]*|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                )
                if clean ~= "" then
                    local last = dots[#dots]
                    if clean:match("^<.*>$") then
                        if last ~= nil and last.subtitle == nil then
                            last.subtitle = clean:sub(2, -2)
                        end
                    elseif not detailLine and not (code ~= nil and isWhiteCode(code)) then
                        tinsert(dots, { name = clean, otherLevel = code ~= nil and isGreyCode(code), arrow = arrow })
                    end
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
                hex = string.format(
                    "%02x%02x%02x",
                    math.floor(color.r * 255 + 0.5),
                    math.floor(color.g * 255 + 0.5),
                    math.floor(color.b * 255 + 0.5)
                )
            end
            local shown = tostring(text):gsub("|", "||"):gsub("\n", "\\n")
            tinsert(out, "[" .. hex .. "] " .. shown)
        end
        local extra = Scan.otherFields(line, { leftText = true, leftColor = true }, isSecret)
        if extra ~= nil then
            tinsert(out, "  fields: " .. extra)
        end
    end
    local extra = Scan.otherFields(data, { lines = true }, isSecret)
    if extra ~= nil then
        tinsert(out, "data fields: " .. extra)
    end
    return out
end

-- Every field of a tooltip table except the skipped ones, sorted, one
-- level of nested tables shown; nil when there are none. For spotting
-- what the game sends besides the text (a line type, an icon).
local function fieldValue(value, isSecret)
    if isSecret ~= nil and isSecret(value) then
        return "(secret value)"
    elseif type(value) == "string" then
        return (value:gsub("|", "||"):gsub("\n", "\\n"))
    end
    return tostring(value)
end

function Scan.otherFields(tbl, skip, isSecret)
    if type(tbl) ~= "table" then
        return nil
    end
    local parts = {}
    for key, value in pairs(tbl) do
        if not skip[key] then
            if type(value) == "table" then
                local inner = {}
                for k, v in pairs(value) do
                    tinsert(inner, tostring(k) .. "=" .. (type(v) == "table" and "table" or fieldValue(v, isSecret)))
                end
                table.sort(inner)
                tinsert(parts, tostring(key) .. "={" .. table.concat(inner, ", ") .. "}")
            else
                tinsert(parts, tostring(key) .. "=" .. fieldValue(value, isSecret))
            end
        end
    end
    if #parts == 0 then
        return nil
    end
    table.sort(parts)
    return table.concat(parts, ", ")
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

-- The other way: yards north and west of the player -> minimap offset.
function Scan.worldToOffset(north, west, yardsPerUnit, facing)
    local a = facing or 0
    local n, w = north / yardsPerUnit, west / yardsPerUnit
    return n * math.sin(a) - w * math.cos(a), n * math.cos(a) + w * math.sin(a)
end

-- ---- the sweep ----
-- One pass asks every grid cell (the engine moves the minimap so each
-- lies under the cursor, a frame each); a dot answers over a patch
-- around it (about 9.4 units each way at effective scale 0.85, measured
-- 2026-09-24), and the middle of its patch is the dot. Cells are integer
-- (ix, iy), offsets ix and iy times the step.

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

-- How many dots each group of one name holds when the shrunk read said how
-- many there are (count: the read names each dot once). Every group holds
-- at least the dots answering at once (maxN); more groups than dots: the
-- largest keep theirs, the rest hold none (a sliver at the rim); fewer:
-- the extra dots go one at a time to the group largest per dot. Without
-- a count, the size estimate (dotsInComponent). Returns ks by index.
-- (2026-11-10 Stormwind: the size estimate split 2 mailboxes into 4.)
function Scan.dotsByCount(components, count, singleSize)
    local ks = {}
    if count == nil or count < 1 then
        for i, comp in ipairs(components) do
            ks[i] = Scan.dotsInComponent(comp, singleSize)
        end
        return ks
    end
    local order = {}
    for i = 1, #components do
        order[i] = i
        ks[i] = 0
    end
    table.sort(order, function(a, b)
        return components[a].size > components[b].size
    end)
    local left = count
    for _, i in ipairs(order) do
        if left <= 0 then
            break
        end
        local k = math.min(math.max(components[i].maxN or 1, 1), left)
        ks[i] = k
        left = left - k
    end
    while left > 0 and #order > 0 do
        local best, bestShare = nil, -1
        for _, i in ipairs(order) do
            if ks[i] > 0 then
                local share = components[i].size / ks[i]
                if share > bestShare then
                    best, bestShare = i, share
                end
            end
        end
        if best == nil then
            break
        end
        ks[best] = ks[best] + 1
        left = left - 1
    end
    return ks
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

-- The gathering kinds the active tracking spells show, for classify:
-- { category = "spell:<id>", label = spell name, needles = lower-case
-- names } in spell order (names from gatheringNames.lua, the client's
-- locale or enUS). Second result: true when another tracking spell is on
-- (hunter tracking and the like), whose dots no list sorts.
-- Tracking spells are never switched, by choice: C_Minimap.SetTracking
-- cannot turn a spell back on outside a key press, but CastSpellByID can
-- out of combat (measured 2026-09-28; other spells are forbidden). Each
-- switch costs a global cooldown, about 3 s per scan for two gathering
-- spells, while the name lists already sort what the minimap shows.
function Scan.gatheringKinds(spells, names, locale)
    local bySpell = {}
    for _, kind in pairs(names or {}) do
        for _, id in ipairs(kind.spells) do
            bySpell[id] = kind
        end
    end
    local kinds, other = {}, false
    for _, s in ipairs(spells) do
        if s.active then
            local kind = bySpell[s.spellID]
            if kind == nil then
                other = true
            else
                local needles = {}
                for _, name in ipairs(kind[locale] or kind.enUS) do
                    tinsert(needles, name:lower())
                end
                tinsert(kinds, { category = "spell:" .. tostring(s.spellID), label = s.name, needles = needles })
            end
        end
    end
    return kinds, other
end

-- The kind whose list a dot name contains ("Verkümmertes Silberblatt"
-- holds Silberblatt), or nil.
function Scan.gatheringCategory(name, kinds)
    local lowered = name:lower()
    for _, kind in ipairs(kinds) do
        for _, needle in ipairs(kind.needles) do
            if lowered:find(needle, 1, true) ~= nil then
                return kind
            end
        end
    end
    return nil
end

-- passes.baseline: dots with every tracking filter off (spells as found):
--   quest givers, plus whatever the active tracking spells show.
-- passes.filters: { category, dots, flag? } one per filter switched on
--   alone; names beyond the baseline are that category (flag marks quest
--   givers only shown by that filter, such as "trivial").
-- passes.gathering: kinds from Scan.gatheringKinds; baseline names
--   matching one are that kind's. Empty or nil when no gathering spell
--   is on, and the name check is skipped.
-- passes.baselineCategory: what the baseline's unexplained names are,
--   "questGiver" unless another tracking spell adds dots no list sorts.
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
    if passes.gathering ~= nil and #passes.gathering > 0 then
        for name, count in pairs(base) do
            local kind = Scan.gatheringCategory(name, passes.gathering)
            if kind ~= nil then
                add(name, kind.category, count)
                givers[name] = 0
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

-- category -> name -> count, for Store:dropMissing.
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

-- ---- the walking memory ----
-- What the walking check announced, per name: its dots, placed where the
-- walking check could find them. A name is spoken when a read shows more
-- dots of it than can be in view.
-- - A placed dot counts as in view within the view radius less INNER,
--   and as out of range once the player is MARGIN yards beyond the
--   radius from it; between the two it may or may not show. So what is
--   said again depends on the distance walked, not on what one read
--   shows: a flicker at the rim, a building (the minimap indoors shows
--   only the building, with a shorter range) and standing change nothing.
-- - A dot without a place (not found, locating stopped, or a name that
--   stays in view past its range, such as a town's arrow) falls back to
--   the name rule: it counts as gone after GONE_AFTER seconds of walking
--   outdoors with fewer in view. Standing, combat and a window under the
--   cursor stop the reads; time indoors does not count either.
-- - A placed dot in view that stays missing that long is gone as well (a
--   herb picked).
-- - The view radius changes on the way (2026-11-10 Stormwind: 150 and
--   233 yards a few steps apart). Each placed dot keeps the largest radius
--   it was judged with (reach); it is out of range only past its reach
--   plus MARGIN, and beyond the current radius it may or may not show. So
--   a smaller radius does not forget it and a larger one again does not
--   announce it again.

local Walk = {}
Walk.__index = Walk
Scan.Walk = Walk

Walk.GONE_AFTER = 30
-- The most one gap between two reads adds to the clock.
Walk.MAX_GAP = 1
-- Yards, see above; the outdoor view radius at zoom 0 when none is read.
Walk.MARGIN = 25
Walk.INNER = 10
Walk.RADIUS = 233
-- Yards: a found dot this close to a placed one of its name is that one.
Walk.MATCH = 25
-- A far place is less sure: several dots of one name far out overlap on
-- the walking check's smaller minimap and are split by count (walk
-- 2026-11-10 03:21 Stormwind, third size then: one mailbox 100 to 230
-- yards out came out 30 to 90 yards apart in two sweeps; standing NPCs
-- near by, 5 to 12).
-- The match grows by this share of the place's distance from the player,
-- up to MATCH_MAX (the mailboxes there stood 70 yards apart and more).
Walk.MATCH_GROWTH = 0.25
Walk.MATCH_MAX = 60

-- Yards within which a found place is a remembered dot, for a place this
-- far from the player.
function Walk.matchFor(distance)
    return math.min(Walk.MATCH + (distance or 0) * Walk.MATCH_GROWTH, Walk.MATCH_MAX)
end
-- Yards between two reads that mean a hearthstone, portal or loading
-- screen, not walking.
Walk.JUMP = 60

function Walk.new()
    return setmetatable({ names = {}, nameOnly = {} }, Walk)
end

local function sortedKeys(...)
    local seen, keys = {}, {}
    for _, tbl in ipairs({ ... }) do
        for key in pairs(tbl) do
            if not seen[key] then
                seen[key] = true
                tinsert(keys, key)
            end
        end
    end
    table.sort(keys)
    return keys
end

local function unplace(dot)
    dot.wx, dot.wy, dot.continent, dot.distance = nil, nil, nil, nil
end

-- read: { counts = name -> dots read, now = seconds, indoors, px, py,
-- continent (player; nil: every dot judged by the name rule), radius
-- (outdoor view radius) }.
-- Returns events in name order, each { kind, name, ... }, the names
-- whose dots want a place (Walk:placed), and the set of those among them
-- that came back (verify: the place says whether it is the same dot):
-- - new: count, remembered (dots that could be in view); the one to speak
-- - fewer: count, remembered (dots that should be in view)
-- - back: missing (clock seconds); they showed again in time, silent
-- - gone: dropped (dots), missing; missing too long, out of range now
-- - left: distance; a placed dot the player walked away from
-- - follows: distance; a placed dot still in view past its range: its
--   name goes to the name rule for the session
-- - indoors / outdoors: the clock stopped or runs again
-- - jump: distance (nil: another continent); no follow check this read
function Walk:update(read)
    local events, locate, verify = {}, {}, {}
    local dt = 0
    if self.lastAt ~= nil and not read.indoors and not self.lastIndoors then
        dt = math.max(0, math.min(read.now - self.lastAt, Walk.MAX_GAP))
    end
    if self.lastAt ~= nil and (read.indoors and true or false) ~= (self.lastIndoors and true or false) then
        tinsert(events, { kind = read.indoors and "indoors" or "outdoors" })
    end
    local jumped = false
    if read.px ~= nil and self.lastPx ~= nil then
        if read.continent ~= self.lastContinent then
            jumped = true
            tinsert(events, { kind = "jump" })
        else
            local step = math.sqrt(distanceSq(read.px, read.py, self.lastPx, self.lastPy))
            if step > Walk.JUMP then
                jumped = true
                tinsert(events, { kind = "jump", distance = step })
            end
        end
    end
    self.lastAt, self.lastIndoors = read.now, read.indoors
    self.lastPx, self.lastPy, self.lastContinent = read.px, read.py, read.continent
    local radius = read.radius or Walk.RADIUS
    for _, name in ipairs(sortedKeys(read.counts, self.names)) do
        local rec = self.names[name]
        if rec == nil then
            rec = { dots = {}, missing = 0 }
            self.names[name] = rec
        end
        local count = read.counts[name] or 0
        local near, band, far, loose = {}, {}, {}, {}
        for _, dot in ipairs(rec.dots) do
            if dot.wx == nil or read.px == nil then
                tinsert(loose, dot)
            else
                dot.distance = dot.continent == read.continent
                        and math.sqrt(distanceSq(dot.wx, dot.wy, read.px, read.py))
                    or math.huge
                dot.reach = math.max(dot.reach or radius, radius)
                if dot.distance > dot.reach + Walk.MARGIN then
                    tinsert(far, dot)
                elseif dot.distance > radius - Walk.INNER then
                    tinsert(band, dot)
                else
                    tinsert(near, dot)
                end
            end
        end
        if #far > 0 then
            -- A real dot leaves view before the player is that far from
            -- it; one the reads still show was drawn at a fixed distance
            -- (a town's arrow) or walked along.
            if count > #near + #band + #loose and not jumped and not rec.short then
                self.nameOnly[name] = true
                tinsert(events, { kind = "follows", name = name, distance = far[1].distance })
                for _, dot in ipairs(rec.dots) do
                    unplace(dot)
                end
                near, band, loose = {}, {}, rec.dots
            else
                for _, dot in ipairs(far) do
                    tinsert(events, { kind = "left", name = name, distance = dot.distance })
                end
                rec.dots = {}
                for _, list in ipairs({ near, band, loose }) do
                    for _, dot in ipairs(list) do
                        tinsert(rec.dots, dot)
                    end
                end
            end
        end
        local inView = #near + #loose
        local canShow = inView + #band
        if count > canShow then
            for _ = canShow + 1, count do
                tinsert(rec.dots, { fresh = true })
            end
            tinsert(events, { kind = "new", name = name, count = count, remembered = canShow })
            rec.short, rec.missing, rec.hiddenIndoors = false, 0, nil
            if read.px ~= nil and not self.nameOnly[name] then
                tinsert(locate, name)
            end
        elseif count < inView then
            if not rec.short then
                rec.short = true
                tinsert(events, { kind = "fewer", name = name, count = count, remembered = inView })
            end
            if read.indoors then
                rec.hiddenIndoors = true
            end
            rec.missing = rec.missing + dt
            if rec.missing >= Walk.GONE_AFTER then
                -- Unplaced dots first, then the nearest: the ones that
                -- should show most surely.
                table.sort(near, function(a, b)
                    return a.distance < b.distance
                end)
                local drop = {}
                for i = 1, inView - count do
                    drop[loose[i] or near[i - #loose]] = true
                end
                local kept = {}
                for _, dot in ipairs(rec.dots) do
                    if not drop[dot] then
                        tinsert(kept, dot)
                    end
                end
                rec.dots = kept
                tinsert(events, { kind = "gone", name = name, dropped = inView - count, missing = rec.missing })
                rec.short, rec.missing, rec.hiddenIndoors = false, 0, nil
            end
        elseif rec.short then
            tinsert(events, { kind = "back", name = name, missing = rec.missing })
            rec.short, rec.missing = false, 0
            -- The count alone cannot tell the dot that left from another
            -- one of the name coming into view (2026-11-10 Stormwind: a
            -- new mailbox counted as one back and was never said). Not
            -- when it went missing indoors, nor while indoors now: the
            -- minimap shows only the building, the dots outside are
            -- hidden, not gone.
            if read.px ~= nil and not self.nameOnly[name] and not rec.hiddenIndoors and not read.indoors then
                verify[name] = true
                tinsert(locate, name)
            end
            rec.hiddenIndoors = nil
        end
        if #rec.dots == 0 then
            self.names[name] = nil
        end
    end
    return events, locate, verify
end

-- Where the dots of a name are, found by the sweep: positions { wx, wy,
-- match? } of every dot of it in view. A placed dot takes the nearest
-- within the position's match (Walk.matchFor its distance; MATCH without
-- one; the dot may have walked); the rest go to unplaced dots, new ones
-- first.
-- Returns { placed = dots just placed, refreshed, extra (positions left
-- over), unplaced (dots still without a place), new, dropped }.
-- check { px, py, radius } (a name back in view, Walk:update's verify):
-- a position no remembered dot matches is a new dot, placed and counted
-- in new (the caller announces it); a placed dot in view that matched no
-- position is gone (dropped), unless the sweep found none at all (no
-- proof of anything: a cancelled or empty sweep).
function Walk:placed(name, positions, continent, check)
    local result = { placed = {}, refreshed = 0, extra = 0, unplaced = 0, new = 0, dropped = 0 }
    local rec = self.names[name]
    if rec == nil or self.nameOnly[name] then
        return result
    end
    -- Every pair of a placed dot and a position within the position's
    -- match, the closest pairs first: dot by dot, a dot could take the
    -- position of its neighbour and leave the neighbour without one
    -- (2026-11-10 Stormwind: three mailboxes 37 to 70 yards apart).
    local pairs_ = {}
    for di, dot in ipairs(rec.dots) do
        if dot.wx ~= nil and dot.continent == continent then
            for i, pos in ipairs(positions) do
                local d = distanceSq(dot.wx, dot.wy, pos.wx, pos.wy)
                local match = pos.match or Walk.MATCH
                if d <= match * match then
                    tinsert(pairs_, { dot = di, pos = i, d = d })
                end
            end
        end
    end
    table.sort(pairs_, function(a, b)
        return a.d < b.d
    end)
    local used, taken = {}, {}
    for _, p in ipairs(pairs_) do
        if not used[p.pos] and not taken[p.dot] then
            used[p.pos], taken[p.dot] = true, true
            local dot = rec.dots[p.dot]
            dot.wx, dot.wy = positions[p.pos].wx, positions[p.pos].wy
            dot.matched = true
            result.refreshed = result.refreshed + 1
        end
    end
    local loose = {}
    for _, dot in ipairs(rec.dots) do
        if dot.wx == nil then
            tinsert(loose, dot)
        end
    end
    table.sort(loose, function(a, b)
        return (a.fresh and 1 or 0) > (b.fresh and 1 or 0)
    end)
    local nextPos = 1
    for _, dot in ipairs(loose) do
        while used[nextPos] do
            nextPos = nextPos + 1
        end
        local pos = positions[nextPos]
        if pos == nil then
            result.unplaced = result.unplaced + 1
        else
            used[nextPos] = true
            dot.wx, dot.wy, dot.continent, dot.fresh = pos.wx, pos.wy, continent, nil
            dot.justPlaced = true
            tinsert(result.placed, dot)
        end
    end
    if check ~= nil and #positions > 0 then
        local inside = (check.radius or Walk.RADIUS) - Walk.INNER
        local kept = {}
        for _, dot in ipairs(rec.dots) do
            local inView = dot.wx ~= nil
                and dot.continent == continent
                and distanceSq(dot.wx, dot.wy, check.px, check.py) <= inside * inside
            if inView and not dot.matched and not dot.justPlaced then
                result.dropped = result.dropped + 1
            else
                tinsert(kept, dot)
            end
        end
        rec.dots = kept
        for i, pos in ipairs(positions) do
            if not used[i] then
                used[i] = true
                local dot = { wx = pos.wx, wy = pos.wy, continent = continent }
                tinsert(rec.dots, dot)
                tinsert(result.placed, dot)
                result.new = result.new + 1
            end
        end
    end
    for _, dot in ipairs(rec.dots) do
        dot.matched, dot.justPlaced = nil, nil
    end
    for i = 1, #positions do
        if not used[i] then
            result.extra = result.extra + 1
        end
    end
    return result
end

-- One line per remembered name, sorted, for /wv mscan walk: its dots
-- with distance (from px, py when given), the missing clock, the rule.
function Walk:describe(px, py, continent)
    local lines = {}
    for _, name in ipairs(sortedKeys(self.names)) do
        local rec = self.names[name]
        local parts = {}
        for _, dot in ipairs(rec.dots) do
            if dot.wx == nil then
                tinsert(parts, "not placed")
            elseif px == nil or dot.continent ~= continent then
                tinsert(parts, "placed elsewhere")
            else
                tinsert(parts, string.format("%.0f yd", math.sqrt(distanceSq(dot.wx, dot.wy, px, py))))
            end
        end
        local line = string.format("%s: %d remembered, %s", name, #rec.dots, table.concat(parts, ", "))
        if rec.short then
            line = line .. string.format("; fewer in view for %.1f s", rec.missing)
        end
        if self.nameOnly[name] then
            line = line .. "; name rule"
        end
        tinsert(lines, line)
    end
    return lines
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
