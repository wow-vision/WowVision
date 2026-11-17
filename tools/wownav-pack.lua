-- Packs the WowNav navigation data (the submodule mapdata/WoW_NavigationData, Broesel's public data repo) for the
-- game: every zone file is kept as one long string until a route, a list or a target needs that zone, instead of
-- building all its tables at login (concept chapter 7 point 2 of WowNav: "at login all files are in memory as compact
-- strings"). The data itself is not changed: a packed file holds the original file text byte for byte, and
-- camelot/wownav/engine/NavNetwork.lua compiles it on first use.
--
--   WVN7Src[zoneId]        = [[ <navdata.lua> ]]
--   WVN7LogicalSrc[zoneId] = [[ <logical_targets.lua> ]]
--   WVN7DynSrc[zoneId]     = [[ <dyn_targets.lua> ]]
--
-- The continent indexes stay as they are (small, read at login). actions.lua (WVN7ActionEnds) lists every action of the
-- data with the exact positions of its two waypoints, decoded here with the engine, for the engine's estimate (see
-- camelot/wownav/engine/README.md). The output goes to mapdata/WowNavPacked/ (not in git) with a data.xml that loads
-- it, included from camelot/modules.xml. Until the data repo ships packed files, run
-- this after every update of the submodule:
--
--   luajit tools/wownav-pack.lua            (from the repo root)
--   luajit tools/wownav-pack.lua --check    (only report; exit code 1 when the output is stale)

local SOURCE = "mapdata/WoW_NavigationData/Forever"
local TARGET = "mapdata/WowNavPacked"
local MARKER = "-- WVN7 packed"

local check = false
for _, a in ipairs(arg or {}) do
    if a == "--check" then
        check = true
    end
end

local windows = package.config:sub(1, 1) == "\\"

local function native(path)
    return windows and path:gsub("/", "\\") or path
end

local function listDirs(path)
    local command = windows and ('dir /b /ad "' .. native(path) .. '" 2>nul') or ('ls -1 "' .. path .. '" 2>/dev/null')
    local pipe = assert(io.popen(command))
    local out = {}
    for line in pipe:lines() do
        line = line:gsub("[\r\n]", "")
        if line ~= "" then
            out[#out + 1] = line
        end
    end
    pipe:close()
    table.sort(out)
    return out
end

local function mkdir(path)
    local command = windows and ('if not exist "' .. native(path) .. '" mkdir "' .. native(path) .. '"')
        or ('mkdir -p "' .. path .. '"')
    os.execute(command)
end

local function read(path)
    local f = io.open(path, "rb")
    if f == nil then
        return nil
    end
    local text = f:read("*a")
    f:close()
    return text
end

local function write(path, text)
    local f = assert(io.open(path, "wb"))
    f:write(text)
    f:close()
end

-- file name -> (registration line of the original file, source table of the packed file)
local KINDS = {
    ["navdata.lua"] = { "\nWVN7%[(%d+)%]%s*=%s*W%s*\r?\n", "WVN7Src" },
    ["logical_targets.lua"] = { "\nWVN7Logical%[(%d+)%]%s*=%s*LogicalTargets%s*\r?\n", "WVN7LogicalSrc" },
    ["dyn_targets.lua"] = { "\nWVN7Dyn%[(%d+)%]%s*=%s*DynTargets%s*\r?\n", "WVN7DynSrc" },
}

-- The lowest long bracket level whose brackets occur nowhere in the text (Lua 5.1 refuses a nested "[[" inside a
-- level-0 long string).
local function longLevel(text)
    local level = 0
    while text:find("]" .. string.rep("=", level) .. "]", 1, true) or text:find("[" .. string.rep("=", level) .. "[", 1, true) do
        level = level + 1
    end
    return level
end

local function pack(text, kind, name)
    local spec = KINDS[kind]
    local zoneId = text:match(spec[1])
    if zoneId == nil then
        error(name .. ": no registration line found")
    end
    local eq = string.rep("=", longLevel(text))
    local packed = MARKER .. " by tools/wownav-pack.lua: the source below is compiled only when WowVision needs this zone.\n"
        .. spec[2] .. " = " .. spec[2] .. " or {}\n"
        .. spec[2] .. "[" .. zoneId .. "] = [" .. eq .. "[\n" .. text .. "]" .. eq .. "]\n"
    -- the packed file must load, and its string must compile (the game's loader does the same)
    local chunk, err = loadstring(packed, "=" .. name)
    if chunk == nil then
        error(name .. ": packed file does not compile: " .. tostring(err))
    end
    local env = {}
    setfenv(chunk, env)
    chunk()
    local source = env[spec[2]][tonumber(zoneId)]
    if source:gsub("\r\n", "\n") ~= text:gsub("\r\n", "\n") then
        error(name .. ": packed text differs from the original")
    end
    assert(loadstring(source, "=" .. name .. " (inner)"))
    return packed
end

-- The zones of a continent index in the order of their folders.
local function indexZones(path)
    local chunk = assert(loadfile(path))
    local env = {}
    setfenv(chunk, env)
    chunk()
    local zones = {}
    for continent, entry in pairs(env.WVN7Index or {}) do
        for _, zone in pairs(entry.zones or {}) do
            zones[#zones + 1] = zone
        end
    end
    table.sort(zones, function(a, b)
        return a.dir < b.dir
    end)
    return zones
end

local xml = {
    '<Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        .. 'xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\\FrameXML\\UI.xsd">',
    "  <!-- Generated by tools/wownav-pack.lua from mapdata/WoW_NavigationData: the continent indexes and the packed",
    "       zone files of WowNav's navigation data. Not in git; run the tool after updating the submodule. -->",
}
local changed, files = 0, 0
-- the navigation data of every zone by zone id (for the action ends below) and the continent indexes
local navTexts, indexTexts = {}, {}
for _, continent in ipairs(listDirs(SOURCE)) do
    local indexPath = SOURCE .. "/" .. continent .. "/index.lua"
    local indexText = read(indexPath)
    if indexText ~= nil then
        indexTexts[#indexTexts + 1] = indexText
        mkdir(TARGET .. "/" .. continent)
        local outIndex = TARGET .. "/" .. continent .. "/index.lua"
        if read(outIndex) ~= indexText then
            changed = changed + 1
            if not check then
                write(outIndex, indexText)
            end
        end
        xml[#xml + 1] = '  <Script file="' .. continent .. '\\index.lua" />'
        for _, zone in ipairs(indexZones(indexPath)) do
            mkdir(TARGET .. "/" .. continent .. "/" .. zone.dir)
            for _, kind in ipairs({ "navdata.lua", "logical_targets.lua", "dyn_targets.lua" }) do
                local rel = continent .. "/" .. zone.dir .. "/" .. kind
                local text = assert(read(SOURCE .. "/" .. rel), "missing " .. rel)
                local packed = pack(text, kind, rel)
                if kind == "navdata.lua" then
                    navTexts[tonumber(text:match(KINDS[kind][1]))] = text
                end
                files = files + 1
                if read(TARGET .. "/" .. rel) ~= packed then
                    changed = changed + 1
                    if not check then
                        write(TARGET .. "/" .. rel, packed)
                    end
                end
                xml[#xml + 1] = '  <Script file="' .. rel:gsub("/", "\\") .. '" />'
            end
        end
    end
end
-- The action ends (actions.lua, WVN7ActionEnds): every action of the data with the exact positions of its two waypoints,
-- its cost and the maps of both ends. The engine's estimate (NavNetwork.lua, Pass) needs them for the whole data before
-- any zone is decoded: an action that costs less than the straight line between its ends (a tram into another map,
-- the portal between Teldrassil and Darnassus) makes the straight line too high for a waypoint behind it. Only the
-- zones with actions and the zones they lead into are decoded here, with the engine itself.
local function actionEnds()
    local saved = { WVN7Src = _G.WVN7Src, WVN7Index = _G.WVN7Index, WVN7 = _G.WVN7 }
    _G.WVN7Src, _G.WVN7Index, _G.WVN7 = navTexts, {}, nil
    for _, text in ipairs(indexTexts) do
        assert(loadstring(text, "=index"))()
    end
    local engine = assert(loadfile("camelot/wownav/engine/NavNetwork.lua"))
    local previousEngine = _G.WowVisionNavigationNavNetwork
    _G.WowVisionNavigationNavNetwork = nil
    engine("WowVision", {})
    local N = _G.WowVisionNavigationNavNetwork
    N.LoadIndex()
    local function mapOf(zoneId)
        local entry = N.index[zoneId]
        return entry and entry.mapId
    end
    local zoneIds = {}
    for zoneId, text in pairs(navTexts) do
        -- every action record has an activation; a zone without one has no actions
        if text:find('["activation"]', 1, true) then
            zoneIds[#zoneIds + 1] = zoneId
        end
    end
    table.sort(zoneIds)
    local lines = {}
    for _, zoneId in ipairs(zoneIds) do
        local zone = assert(N.LoadZone(zoneId), "zone " .. zoneId .. " does not decode")
        for _, action in ipairs(zone.actions) do
            local toZone = math.floor(action.toNode / N.ZONE_BASE)
            assert(N.zones[toZone] or N.LoadZone(toZone), "zone " .. toZone .. " does not decode")
            local fx, fy, fz = N.Position(action.fromNode)
            local tx, ty, tz = N.Position(action.toNode)
            lines[#lines + 1] = string.format(
                "    { from = %.0f, to = %.0f, cost = %.17g, fromMap = %s, toMap = %s, fx = %.17g, fy = %.17g, fz = %.17g, "
                    .. "tx = %.17g, ty = %.17g, tz = %.17g },",
                action.fromNode, action.toNode, action.cost, tostring(mapOf(zoneId)), tostring(mapOf(toZone)),
                fx, fy, fz, tx, ty, tz)
        end
        -- keep the tool's memory small: a zone is not needed once its actions are read
        N.UnloadZone(zoneId)
    end
    _G.WowVisionNavigationNavNetwork = previousEngine
    _G.WVN7Src, _G.WVN7Index, _G.WVN7 = saved.WVN7Src, saved.WVN7Index, saved.WVN7
    return "-- WVN7 action ends, written by tools/wownav-pack.lua from mapdata/WoW_NavigationData (the engine's estimate,\n"
        .. "-- NavNetwork.lua Pass): every action with the positions of its waypoints, its cost and the maps of both ends.\n"
        .. "WVN7ActionEnds = {\n" .. table.concat(lines, "\n") .. "\n}\n", #lines
end

local actionsText, actionCount = actionEnds()
if read(TARGET .. "/actions.lua") ~= actionsText then
    changed = changed + 1
    if not check then
        write(TARGET .. "/actions.lua", actionsText)
    end
end
table.insert(xml, 4, '  <Script file="actions.lua" />')

xml[#xml + 1] = "</Ui>"
local xmlText = table.concat(xml, "\n") .. "\n"
if read(TARGET .. "/data.xml") ~= xmlText then
    changed = changed + 1
    if not check then
        write(TARGET .. "/data.xml", xmlText)
    end
end
print(string.format("%d zone files, %d actions; %d file(s) %s", files, actionCount, changed,
    check and "stale" or "written"))
if check and changed > 0 then
    os.exit(1)
end
