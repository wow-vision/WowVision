-- Writes the bump data (mapdata/bumps/<client>/, read by core/navigation/bumps.lua) from the surroundings data:
-- per zone only what naming the thing the player bumps into needs, the objects' footprints and names, the
-- buildings' room floors, outlines and doorways, and the structures' floor cells (gates, city walls, bridges).
-- The source is the WowVision_Surroundings data repository (format 4 zone files, generated offline from each
-- client's own map files by the wv-surroundings tools); its folders era/, tbc/ and forever/ become the folders of
-- the same name here. The output is plain Lua, one file per zone and a data.xml per client, kept in git.
--
--   luajit tools/bumps/pack.lua <WowVision_Surroundings folder>            (from the repo root)
--   luajit tools/bumps/pack.lua <WowVision_Surroundings folder> --check    (only report; exit code 1 when stale)

local TARGET = "mapdata/bumps"
local CLIENTS = { "era", "tbc", "forever" }
local LOCALES = { "enUS", "deDE", "frFR" }

local source, check = nil, false
for _, a in ipairs(arg or {}) do
    if a == "--check" then
        check = true
    else
        source = a:gsub("\\", "/"):gsub("/$", "")
    end
end
if source == nil then
    print("usage: luajit tools/bumps/pack.lua <WowVision_Surroundings folder> [--check]")
    os.exit(2)
end

local windows = package.config:sub(1, 1) == "\\"

local function native(path)
    return windows and path:gsub("/", "\\") or path
end

local function listFiles(path)
    local command = windows and ('dir /b /a-d "' .. native(path) .. '" 2>nul')
        or ('ls -1p "' .. path .. '" 2>/dev/null | grep -v /')
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
    -- (git may check the files out with Windows line endings: compared without them)
    return (text:gsub("\r\n", "\n"))
end

-- A plain JSON decoder (objects, arrays, strings, numbers, true, false, null): enough for the zone files.
local function decodeJson(text)
    local pos = 1
    local value
    local function skip()
        pos = text:find("[^ \t\r\n]", pos) or #text + 1
    end
    local escapes = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
    local function utf8(code)
        if code < 0x80 then
            return string.char(code)
        elseif code < 0x800 then
            return string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40)
        end
        return string.char(0xE0 + math.floor(code / 0x1000), 0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40)
    end
    local function str()
        local out = {}
        pos = pos + 1
        while true do
            local s, e = text:find('["\\]', pos)
            out[#out + 1] = text:sub(pos, s - 1)
            if text:sub(s, s) == '"' then
                pos = s + 1
                return table.concat(out)
            end
            local c = text:sub(s + 1, s + 1)
            if c == "u" then
                local code = tonumber(text:sub(s + 2, s + 5), 16)
                assert(code < 0xD800 or code > 0xDFFF, "JSON: surrogate pairs are not read (none in the zone files)")
                out[#out + 1] = utf8(code)
                pos = s + 6
            else
                out[#out + 1] = escapes[c]
                pos = s + 2
            end
        end
    end
    value = function()
        skip()
        local c = text:sub(pos, pos)
        if c == "{" then
            local t = {}
            pos = pos + 1
            skip()
            if text:sub(pos, pos) == "}" then
                pos = pos + 1
                return t
            end
            while true do
                skip()
                local key = str()
                skip()
                pos = pos + 1 -- :
                t[key] = value()
                skip()
                local d = text:sub(pos, pos)
                pos = pos + 1
                if d == "}" then
                    return t
                end
            end
        elseif c == "[" then
            local t = {}
            pos = pos + 1
            skip()
            if text:sub(pos, pos) == "]" then
                pos = pos + 1
                return t
            end
            local n = 0
            while true do
                n = n + 1
                t[n] = value() -- (a null leaves its slot empty, the rest keep their places)
                skip()
                local d = text:sub(pos, pos)
                pos = pos + 1
                if d == "]" then
                    return t
                end
            end
        elseif c == '"' then
            return str()
        elseif text:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif text:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif text:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end
        local s, e = text:find("^-?[%d.eE+-]+", pos)
        assert(s, "JSON: unexpected character at " .. pos)
        pos = e + 1
        return tonumber(text:sub(s, e))
    end
    return value()
end

-- A number as short text: integers without a point, the rest as the source wrote them (LuaJIT keeps 14 digits).
local function num(v)
    if v == math.floor(v) and math.abs(v) < 1e15 then
        return string.format("%d", v)
    end
    return string.format("%.14g", v)
end

local function numbers(list)
    local out = {}
    for i, v in ipairs(list) do
        out[i] = num(v)
    end
    return table.concat(out, " ")
end

local function quote(s)
    return string.format("%q", s):gsub("\\\n", "\\n")
end

-- A list of strings as Lua, one table per locale ({} entries left out where the locale has none: English then).
local function stringList(list)
    local out = {}
    for i = 1, #list do
        out[i] = quote(list[i] or "")
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end

local function sparseList(map)
    local keys = {}
    for k in pairs(map or {}) do
        keys[#keys + 1] = tonumber(k)
    end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = "[" .. k .. "] = " .. quote(map[tostring(k)])
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end

local function perLocale(data, get, write)
    local out = {}
    for _, locale in ipairs(LOCALES) do
        local v = get(locale)
        if v ~= nil then
            out[#out + 1] = "        " .. locale .. " = " .. write(v) .. ","
        end
    end
    return "{\n" .. table.concat(out, "\n") .. "\n    }"
end

-- A checksum of a text (to tell whether two packs hold the same rooms).
local function fingerprint(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + text:byte(i)) % 2147483629
    end
    return string.format("%d", h)
end

-- One zone file of the pack from a format 4 zone file's text, or nil when it holds no zone.
local function packZone(text, origin)
    local header = text:match("addZone%((%b{})")
    local json = text:match("%[=%[(.*)%]=%]")
    if header == nil or json == nil then
        return nil
    end
    local data = decodeJson(json)
    assert(data.format == 4, "not a format 4 zone file")
    local frame = {}
    for _, key in ipairs({ "key", "label", "map", "top", "left", "cell", "rows", "cols" }) do
        local v = header:match("[{,]%s*" .. key .. '%s*=%s*("[^"]*")')
            or header:match("[{,]%s*" .. key .. "%s*=%s*([-%d.]+)")
        assert(v, "zone frame without " .. key)
        frame[#frame + 1] = key .. " = " .. v
    end
    local names = data.names
    local b = data.buildings

    -- objects: x, y (tenths of a yard), half length, half width (tenths), angle (degrees), name, room (0 outdoors)
    local objects = {}
    local shapes, list = data.objects.shapes, data.objects.list
    for i = 1, #list, 5 do
        local s = 3 * (list[i + 3] - 1)
        local record = { list[i], list[i + 1], shapes[s + 1], shapes[s + 2], list[i + 2], shapes[s + 3], list[i + 4] }
        for _, v in ipairs(record) do
            objects[#objects + 1] = v
        end
    end
    -- interiors: the building frame, ox, oy, scale, m00, m01, m10, m11
    local interiors = {}
    for _, f in ipairs(b.interiors) do
        for k = 1, 7 do
            interiors[#interiors + 1] = f[k]
        end
    end
    -- rooms: interior, hall map (the UI map of a hall the game calls outdoors, 0 none), the count of box values and
    -- the floor boxes (x0, y0, x1, y1 in the building frame), the count of outline values (0 or 4) and the outline box
    local rooms = {}
    for _, r in ipairs(b.rooms) do
        rooms[#rooms + 1] = r.i
        rooms[#rooms + 1] = r.g or 0
        rooms[#rooms + 1] = #r.b
        for _, v in ipairs(r.b) do
            rooms[#rooms + 1] = v
        end
        local o = r.o or {}
        rooms[#rooms + 1] = #o
        for _, v in ipairs(o) do
            rooms[#rooms + 1] = v
        end
    end
    -- doors: room a, room b (0 outside), interior, x, y, plane normal nx, ny, side, half width (building frame)
    local doors = {}
    for _, d in ipairs(b.doors) do
        for k = 1, 9 do
            doors[#doors + 1] = d[k]
        end
    end
    local ground = data.layers.ground
    local structCells = ground.cells and ground.cells.struct or {}

    local function localeNames(key)
        return function(locale)
            local n = names[locale]
            return n and n[key]
        end
    end
    -- the game's area of each hall (its subzone text, per locale): a hall counts only where the game names it
    local function hallAreas(locale)
        local n = names[locale]
        local areas = {}
        for i, r in ipairs(b.rooms) do
            local a = r.g and n and n.roomsArea and n.roomsArea[tostring(i)]
            if a and a ~= "" then
                areas[tostring(i)] = a
            end
        end
        return next(areas) and areas or nil
    end
    local roomsText, doorsText = numbers(rooms), numbers(doors)
    local out = {
        "-- Generated by tools/bumps/pack.lua from " .. origin .. "; do not edit.",
        "WowVision.bumpLogic.addZone({",
        "    " .. table.concat(frame, ", ") .. ",",
        -- (the rooms' and doorways' fingerprint: a room kept over a reload, or handed over by another module, is
        -- one of these rooms only while it is the same)
        "    roomsId = " .. fingerprint(roomsText .. "|" .. doorsText) .. ",",
        "    objects = " .. quote(numbers(objects)) .. ",",
        "    objectNames = " .. perLocale(names, localeNames("objectNames"), stringList) .. ",",
        "    interiors = " .. quote(numbers(interiors)) .. ",",
        "    interiorNames = " .. perLocale(names, localeNames("interiors"), stringList) .. ",",
        "    interiorWalls = " .. perLocale(names, localeNames("interiorWalls"), sparseList) .. ",",
        "    rooms = " .. quote(roomsText) .. ",",
        "    roomAreas = " .. perLocale(names, hallAreas, sparseList) .. ",",
        "    doors = " .. quote(doorsText) .. ",",
        "    structCells = " .. quote(numbers(structCells)) .. ",",
        "    waterStructs = { " .. table.concat(ground.waterStructs or {}, ", ") .. " },",
        "    structNames = " .. perLocale(names, localeNames("structs"), stringList) .. ",",
        "    ofTemplate = " .. perLocale(names, function(locale)
            return data.words[locale] and data.words[locale].ofTemplate
        end, quote) .. ",",
        "})",
        "",
    }
    return (table.concat(out, "\n"):gsub("\r", ""))
end

local stale, written = 0, 0
for _, client in ipairs(CLIENTS) do
    local zonesDir = source .. "/" .. client .. "/zones"
    local files = {}
    for _, name in ipairs(listFiles(zonesDir)) do
        if name:match("%.lua$") and not name:match("%-surfaces%.lua$") then
            files[#files + 1] = name
        end
    end
    if #files > 0 then
        local dir = TARGET .. "/" .. client
        if not check then
            mkdir(dir)
        end
        local scripts = {}
        for _, name in ipairs(files) do
            local origin = "WowVision_Surroundings " .. client .. "/zones/" .. name
            local packed = packZone(read(zonesDir .. "/" .. name), origin)
            if packed then
                scripts[#scripts + 1] = '  <Script file="' .. name .. '" />'
                local path = dir .. "/" .. name
                if read(path) ~= packed then
                    stale = stale + 1
                    if check then
                        print("stale: " .. path)
                    else
                        local f = assert(io.open(path, "wb"))
                        f:write(packed)
                        f:close()
                        written = written + 1
                        print(string.format("%s: %d KB", path, math.floor(#packed / 1024 + 0.5)))
                    end
                end
            end
        end
        -- a zone file whose source is gone (named; removed when writing)
        local kept = {}
        for _, name in ipairs(files) do
            kept[name] = true
        end
        for _, name in ipairs(listFiles(dir)) do
            if name:match("%.lua$") and not kept[name] then
                stale = stale + 1
                print((check and "orphan: " or "removed (its source is gone): ") .. dir .. "/" .. name)
                if not check then
                    os.remove(dir .. "/" .. name)
                end
            end
        end
        local xml = '<Ui xmlns="http://www.blizzard.com/wow/ui/">\n' .. table.concat(scripts, "\n") .. "\n</Ui>\n"
        if read(dir .. "/data.xml") ~= xml then
            stale = stale + 1
            if check then
                print("stale: " .. dir .. "/data.xml")
            else
                local f = assert(io.open(dir .. "/data.xml", "wb"))
                f:write(xml)
                f:close()
            end
        end
    end
end
if check then
    print(stale == 0 and "bump data up to date" or (stale .. " file(s) stale"))
    os.exit(stale == 0 and 0 or 1)
end
print(written .. " zone file(s) written")
