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

local function record(event, addon, func)
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
        WowVision:speak("Blocked: " .. tostring(func))
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
        description = "Show blocked protected calls recorded in WowVisionDump ('clear' resets); /reload writes them to disk",
        func = function(args)
            WowVisionDump = WowVisionDump or {}
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
