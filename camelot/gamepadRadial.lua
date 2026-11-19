-- Blizzard's gamepad main menu (GamepadRadial, the Start button in the
-- world) as a WowVision window. Sighted players see a wheel of eight
-- slices and pick one with the right stick; the shoulders turn its three
-- pages, the D-pad holds sit and the emotes, B closes it.
--
-- Here the slices are a grid of two rows. The upper row is the wheel's
-- right half clockwise from the top (north, north-east, east, south-east),
-- the lower row its left half going on (south, south-west, west,
-- north-west). The left stick moves in the grid while the wheel is open and
-- does not walk; A (and Enter) runs the slice. Every other pad key stays
-- with the wheel (padKeys), so the shoulders, the D-pad, B and Start work as
-- Blizzard made them.
--
-- A slice closes the wheel, as picking one does for everyone, then runs
-- through the game: the micro menu button behind it is clicked, tracking
-- opens the scanner and chat the chat window (WowVision's own windows for
-- them), anything else (bags, social, clock, PvP, the emotes) runs the
-- slice's own action. Buffs is not supported yet. B or Start closes the
-- wheel as Blizzard made them.
local module = WowVision.base.windows:createModule("gamepadRadial")
local L = module.L
module:setLabel(L["Gamepad Main Menu"])

local graph = WowVision.graph
local nodes = graph.nodes
local kinds = graph.kinds
local ControlId = graph.ControlId

local WINDOW = "gamepadRadial"

-- Slice numbers (Blizzard's SegmentList: 1 east, counter-clockwise).
local ROWS = {
    { 3, 2, 1, 8 },
    { 7, 6, 5, 4 },
}

-- Slices by the key Blizzard's pages use for them.
local WINDOWS = { tracking = "scanner", chat = "chat" }
local UNSUPPORTED = { buffs = true }
local BUTTONS = { calendar = "GameTimeFrame", time = "TimeManagerClockButton" }

local function call(handler, method)
    local fn = handler[method]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, value = pcall(fn, handler)
    if ok then
        return value
    end
    return nil
end

-- The slice's name as the wheel shows it, greyed out or pressed.
local function slotLabel(handler)
    return function()
        local text = nodes.plainText(call(handler, "GetLabel")) or ""
        if not call(handler, "IsEnabled") then
            return text .. ", " .. L["Disabled"]
        end
        if call(handler, "IsDown") then
            return text .. ", " .. L["opened"]
        end
        return text
    end
end

-- Blizzard's wheel runs a slice and closes; a slice run with the wheel
-- open did nothing (the micro menu buttons) or opened behind it (the
-- bags). WowVision must not hide the wheel itself (its hide runs
-- Blizzard's binding manager, which addon code would taint), so a slice is
-- a secure macro that first clicks the button behind the B binding, the
-- way pressing B does (on an emote page B goes back to the main page
-- first, so twice there), and then runs the slice as without a wheel.
local NEWLINE = string.char(10)

local function closeLines(radial)
    local line = "/click InputFunctionBindingButton_" .. (GAMEPAD_FACE_RIGHT or "PAD2") .. " LeftButton true"
    if radial.currentMainMenuPageIndex == nil then
        return line .. NEWLINE .. line
    end
    return line
end

-- Slices whose action is not a button: the wheel's own action, run after
-- the wheel is gone from the macro's "/run" line, by slot number (the wheel
-- shows one page at a time; each render fills in the page shown).
local pendingSlices = {}

function module.runSlice(id)
    local handler = pendingSlices[id]
    if handler ~= nil then
        call(handler, "Trigger")
    end
end

local function macroNode(label, script)
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = label, kind = kinds.label } },
        bindings = { { binding = "leftClick", type = "Script", script = script } },
    }
end

local function buttonName(button)
    if type(button) ~= "table" or button.GetName == nil then
        return nil
    end
    local ok, name = pcall(button.GetName, button)
    return ok and name or nil
end

local function slotNode(radial, index)
    local segment = radial.SegmentList ~= nil and radial.SegmentList[index] or nil
    local handler = segment ~= nil and segment.handler or nil
    if handler == nil then
        return nodes.text({ label = L["Empty"] })
    end
    local page = radial.currentPage
    local key = page ~= nil and page.buttons ~= nil and page.buttons[index] or nil
    local label = slotLabel(handler)
    if UNSUPPORTED[key] then
        return nodes.button({
            label = label,
            onActivate = function()
                WowVision:notify(L["Not supported yet"])
            end,
        })
    end
    local close = closeLines(radial)
    if WINDOWS[key] ~= nil then
        return macroNode(label, close .. NEWLINE .. "/run WowVision.UIHost:openWindow('" .. WINDOWS[key] .. "')")
    end
    -- A micro menu button (or the clock's and calendar's own) is clicked,
    -- securely, as the wheel clicks it.
    local name = buttonName(handler.button) or BUTTONS[key]
    if name ~= nil then
        return macroNode(label, close .. NEWLINE .. "/click " .. name)
    end
    pendingSlices[index] = handler
    return macroNode(label, close .. NEWLINE .. "/run WowVision.base.windows.gamepadRadial.runSlice(" .. index .. ")")
end

-- "Main Menu, page 2 of 3"; the emote wheel has no pages.
local function pageLabel(radial)
    local header = radial.HeaderText ~= nil and nodes.plainText(radial.HeaderText:GetText()) or nil
    header = header or L["Gamepad Main Menu"]
    local index = radial.currentMainMenuPageIndex
    if index ~= nil and radial.mainMenuPages ~= nil then
        return header .. ", " .. string.format(L["Page %d of %d"], index, #radial.mainMenuPages)
    end
    return header
end

-- A page of its own per context and per id: turning a page lands on the new
-- page's slices, and the announcer reads the new page's name.
local function render(builder, screen)
    local radial = GamepadRadial
    if radial == nil or not radial:IsShown() or radial.currentPage == nil then
        return
    end
    local pageKey = tostring(radial.currentMainMenuPageIndex or radial.currentPage.header or "custom")
    builder:beginStop("radial")
    builder:pushContext("radial:" .. pageKey, pageLabel(radial))
    for _, row in ipairs(ROWS) do
        builder:startRow()
        for _, index in ipairs(row) do
            builder:addItem(ControlId.structural(pageKey .. ":" .. index), slotNode(radial, index))
        end
        builder:endRow()
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = WINDOW,
    frameName = "GamepadRadial",
    graphScreen = { render = render, padKeys = { PAD1 = true } },
})

-- The left stick, while the wheel's window has the focus: one step per push,
-- the next one after the stick came back to the middle. While the handler
-- has the sticks the game gets none of them, whatever it returns (pad log
-- 2026-10-23: both sticks dead while it had them), so it has them only
-- while the wheel is shown; the character does not walk then, the way the
-- wheel holds the right stick. Taking the sticks is protected, so it
-- switches out of combat only.
local STEP = 0.6
local CENTER = 0.3

local function radialFocused()
    local host = WowVision.graphHost
    local stack = host ~= nil and host:focusedStack() or nil
    return stack ~= nil and stack.config ~= nil and stack.config.key == WINDOW
end

local stickFrame = CreateFrame("Frame")
local armed = true
local stickOn = false

stickFrame:SetScript("OnGamepadStick", function(_, stick, x, y)
    if stick ~= "Movement" or not radialFocused() then
        return true
    end
    local length = math.sqrt(x * x + y * y)
    if length < CENTER then
        armed = true
        return false
    end
    if armed and length >= STEP then
        armed = false
        local key
        if math.abs(x) > math.abs(y) then
            key = x > 0 and "right" or "left"
        else
            key = y > 0 and "up" or "down"
        end
        WowVision.pad.log("left stick %s", key)
        WowVision.graphHost:onKey(key)
    end
    return false
end)

-- Compared with the frame's own state, never an assumed one: the frame has
-- the sticks from the start once it has its stick script (pad log
-- 2026-10-23: taken at login with the wheel closed).
local function syncStick()
    local want = GamepadRadial ~= nil and GamepadRadial:IsShown() or false
    local read, enabled = pcall(stickFrame.IsGamePadStickEnabled, stickFrame)
    if read then
        stickOn = enabled == true
    end
    if want == stickOn or InCombatLockdown() then
        return
    end
    stickOn = want
    armed = true
    local ok, err = pcall(stickFrame.EnableGamePadStick, stickFrame, want)
    WowVision.pad.log("left stick taken %s%s", tostring(want), ok and "" or (", failed: " .. tostring(err)))
end

local hooked = false
local function hookRadial()
    if hooked or GamepadRadial == nil then
        return
    end
    hooked = true
    GamepadRadial:HookScript("OnShow", syncStick)
    GamepadRadial:HookScript("OnHide", syncStick)
    syncStick()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    hookRadial()
    syncStick()
end)
syncStick()
