-- Taint watch: records every blocked or forbidden protected call into the
-- WowVisionDump saved variable, with the stack and what the graph had
-- focused. Saved variables reach disk on /reload, unlike Logs\taint.log,
-- which a reload starts fresh (and which Forever does not keep enabled
-- across launches). Loaded right after WowVision.lua so the frame listens
-- from the first moment. Read with /wv taint; /wv taint clear resets.
--
-- Every block is recorded, but only WowVision's own are spoken: the game
-- blames the addon whose code made the call, and other addons' blocks are
-- theirs to fix. Macro blocks carry no addon and are always spoken
-- (WowVision clicks through secure macros).

local MAX_ENTRIES = 30

local function focusDescription()
    local host = WowVision.graphHost
    if host == nil then
        return "no graph host"
    end
    local screen = host:focusedScreen()
    if screen == nil then
        return "no focused screen"
    end
    local parts = { "screen " .. tostring(screen.key) }
    local node = screen.keyGraph ~= nil and screen.keyGraph:currentNode() or nil
    if node ~= nil then
        tinsert(parts, "node " .. tostring(node.id ~= nil and node.id.key or nil))
        local debug = WowVision.graph.scrollBoxDebug ~= nil and WowVision.graph.scrollBoxDebug[tostring(node.id.key)]
            or nil
        if debug ~= nil then
            tinsert(parts, "row " .. tostring(debug.template) .. " '" .. tostring(debug.name) .. "'")
        end
        local first = node.vtable ~= nil and node.vtable.announcements ~= nil and node.vtable.announcements[1] or nil
        if first ~= nil and type(first.text) == "string" then
            tinsert(parts, "label '" .. first.text .. "'")
        end
    end
    return table.concat(parts, ", ")
end

-- Taint scan: a developer tool for the blocks whose stack names no addon
-- code (the game's own refresh read something an addon wrote earlier).
-- /wv taint scan <expression> watches the table or frame the expression
-- gives, three levels deep, five times a second for two minutes, and logs
-- every field that turns insecure (and who the game blames), with the
-- seconds since the scan began and what the graph had focused. A block
-- recorded meanwhile is logged between them. The log is
-- WowVisionDump.taintScan, on disk after /reload. /wv taint scan stop ends it.
local SCAN_INTERVAL = 0.2
local SCAN_SECONDS = 120
local SCAN_DEPTH = 3
local MAX_SCAN_ENTRIES = 600

local scan = { ticker = nil, state = {}, started = 0, log = nil, resolved = false }

local function scanLog(path, by)
    if scan.log == nil or #scan.log.entries >= MAX_SCAN_ENTRIES then
        return
    end
    local okFocus, focus = pcall(focusDescription)
    tinsert(scan.log.entries, {
        t = floor((GetTime() - scan.started) * 100 + 0.5) / 100,
        path = path,
        by = by,
        focus = okFocus and focus or nil,
    })
end

local function scanFields(tbl, path, depth, seen, found)
    if seen[tbl] then
        return
    end
    seen[tbl] = true
    for key, value in pairs(tbl) do
        if type(key) == "string" then
            local secure, by = issecurevariable(tbl, key)
            local childPath = path .. "." .. key
            if not secure then
                found[childPath] = tostring(by)
            end
            if depth > 1 and type(value) == "table" then
                pcall(scanFields, value, childPath, depth - 1, seen, found)
            end
        end
    end
end

local function scanTick()
    if GetTime() - scan.started > SCAN_SECONDS then
        scan.stop("time up")
        return
    end
    local ok, root = pcall(scan.resolve)
    if not ok or type(root) ~= "table" then
        return
    end
    if not scan.resolved then
        scan.resolved = true
        scanLog("(root found)", nil)
    end
    local found = {}
    pcall(scanFields, root, "root", SCAN_DEPTH, {}, found)
    for path, by in pairs(found) do
        if scan.state[path] ~= by then
            scanLog(path, by)
        end
    end
    for path in pairs(scan.state) do
        if found[path] == nil then
            scanLog(path, "secure again or gone")
        end
    end
    scan.state = found
end

function scan.stop(reason)
    if scan.ticker ~= nil then
        scan.ticker:Cancel()
        scan.ticker = nil
        WowVision:speak("Taint scan ended, " .. tostring(reason) .. ", " .. #scan.log.entries .. " entries")
    end
end

function scan.start(expression)
    local chunk, err = loadstring("return " .. expression)
    if chunk == nil then
        WowVision:speak("Taint scan: " .. tostring(err))
        return
    end
    scan.stop("restarted")
    WowVisionDump = WowVisionDump or {}
    scan.log = { root = expression, time = date("%Y-%m-%d %H:%M:%S"), entries = {} }
    WowVisionDump.taintScan = scan.log
    scan.resolve, scan.state, scan.started, scan.resolved = chunk, {}, GetTime(), false
    scan.ticker = C_Timer.NewTicker(SCAN_INTERVAL, scanTick)
    WowVision:speak("Taint scan started")
end

local function record(event, addon, func)
    if scan.ticker ~= nil then
        scanLog("BLOCKED " .. tostring(func), tostring(addon))
    end
    WowVisionDump = WowVisionDump or {}
    local list = WowVisionDump.taint or {}
    WowVisionDump.taint = list
    local okFocus, focus = pcall(focusDescription)
    tinsert(list, {
        time = date("%Y-%m-%d %H:%M:%S"),
        event = event,
        addon = tostring(addon),
        func = tostring(func),
        focus = okFocus and focus or ("focus error: " .. tostring(focus)),
        stack = debugstack(3, 30, 0),
    })
    while #list > MAX_ENTRIES do
        tremove(list, 1)
    end
    local ours = addon == nil or addon == "WowVision"
    if ours and WowVision.base ~= nil and WowVision.base.speech ~= nil then
        WowVision:notify("Blocked: " .. tostring(func))
    end
end

local frame = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_ACTION_BLOCKED",
    "ADDON_ACTION_FORBIDDEN",
    "MACRO_ACTION_BLOCKED",
    "MACRO_ACTION_FORBIDDEN",
}) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, ...)
    -- Macro events carry only the function; the addon ones name the addon first.
    local addon, func = ...
    if event:find("^MACRO") then
        addon, func = nil, ...
    end
    pcall(record, event, addon, func)
end)

function WowVision:registerTaintCommand()
    self.base:registerCommand({
        name = "taint",
        description = "Show blocked protected calls recorded in WowVisionDump ('clear' resets, 'scan <expression>' "
            .. "logs the fields of a table that turn insecure, 'scan stop' ends it); /reload writes them to disk",
        func = function(args)
            WowVisionDump = WowVisionDump or {}
            local expression = type(args) == "string" and args:match("^scan%s+(.+)$") or nil
            if expression == "stop" then
                scan.stop("stopped")
                return
            elseif expression ~= nil then
                scan.start(expression)
                return
            end
            if args == "clear" then
                WowVisionDump.taint = {}
                print("Taint records cleared")
                return
            end
            local list = WowVisionDump.taint or {}
            if #list == 0 then
                WowVision:speak("No blocked calls recorded")
                return
            end
            local lines = { #list .. " blocked calls" }
            for _, entry in ipairs(list) do
                tinsert(lines, entry.time .. " " .. entry.event .. " " .. entry.addon .. " " .. entry.func)
                tinsert(lines, "  " .. entry.focus)
            end
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
        end,
    })
end
