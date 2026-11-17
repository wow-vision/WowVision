local WindowManager = WowVision.Class("WindowManager")

-- Class-level registry for window types (must be available before instances are created)
WindowManager.windowTypes = WowVision.Registry:new()

function WindowManager:initialize()
    self.windows = {}
    self.autoWindows = {} -- Separate list for auto windows (faster iteration)
    self.openWindows = { autoWindows = {} }
    self.dropdownMenuFrame = nil
    self.dropdownMenuIndex = nil
    self.quietCloseUntil = 0 -- windows closing until then do not stop speech (closeAll)
end

-- Type registry methods

function WindowManager:CreateWindowType(typeKey, parentKey)
    local parent = nil
    if parentKey then
        parent = self.windowTypes:get(parentKey)
        if parent == nil then
            error("Parent window type " .. parentKey .. " not found.")
        end
    end

    local parentClass = parent or nil
    local newClass = WowVision.Class(typeKey, parentClass)
    self.windowTypes:register(typeKey, newClass)
    return newClass, parentClass
end

function WindowManager:CreateWindow(typeKey, config)
    local windowClass = self.windowTypes:get(typeKey)
    if windowClass == nil then
        error("Window type " .. typeKey .. " not found.")
    end
    return windowClass:new(config)
end

-- Window instance registry methods

function WindowManager:RegisterWindow(window)
    self.windows[window.name] = window
    if window:needsPolling() then
        self.autoWindows[#self.autoWindows + 1] = window
    end
end

function WindowManager:UnregisterWindow(name)
    local window = self.windows[name]
    self.windows[name] = nil
    if window and window:needsPolling() then
        for i = #self.autoWindows, 1, -1 do
            if self.autoWindows[i] == window then
                table.remove(self.autoWindows, i)
                break
            end
        end
    end
end

function WindowManager:getWindow(name)
    return self.windows[name]
end

-- Notification methods (called by Window when it opens/closes)

-- The game's sound kits Sku plays when its menu opens and closes.
WindowManager.OPEN_SOUND = 88
WindowManager.CLOSE_SOUND = 89

local function playMenuSound(window, kit)
    local settings = WowVision.base.ui.settings
    if settings.menuSounds and window.playsMenuSounds ~= nil and window:playsMenuSounds() and PlaySound ~= nil then
        PlaySound(kit)
    end
end

function WindowManager:notifyOpened(window, instance)
    playMenuSound(window, WindowManager.OPEN_SOUND)
    tinsert(self.openWindows, instance)
    if window:needsPolling() then
        self.openWindows.autoWindows[window.name] = true
    end
end

function WindowManager:notifyClosed(window, instance, shouldHandleContext)
    if WowVision.base.ui.settings.interruptSpeechOnWindowClose and GetTime() >= self.quietCloseUntil then
        WowVision.base.speech:uiStop()
    end
    playMenuSound(window, WindowManager.CLOSE_SOUND)

    -- Remove from open windows list
    for i, v in ipairs(self.openWindows) do
        if v == instance then
            table.remove(self.openWindows, i)
            break
        end
    end

    if window.name then
        self.openWindows.autoWindows[window.name] = nil
    end

    if instance.stack then
        WowVision.graphHost:close(instance.stack)
    end
end

-- Public API for opening/closing windows

function WindowManager:openWindow(windowOrName, props)
    local window = windowOrName
    if type(window) == "string" then
        window = self.windows[window]
        if not window then
            return nil
        end
    end

    -- Check if already open (for polling windows)
    if window:needsPolling() and self.openWindows.autoWindows[window.name] then
        return nil
    end

    return window:open(self, props)
end

-- Open an ad-hoc window from a raw config table (not registered)
function WindowManager:openTemporaryWindow(config)
    -- Generate a unique name if not provided
    if not config.name then
        config.name = "temp_" .. tostring(GetTime()) .. "_" .. math.random(1000, 9999)
    end

    -- Create a ManualWindow from the config
    local window = self:CreateWindow("ManualWindow", config)
    return window:open(self)
end

function WindowManager:closeWindow(ref, shouldHandleContext)
    -- Find the window by reference, instance, or name
    local window = nil
    local instance = nil

    for i, v in ipairs(self.openWindows) do
        if ref == v or ref == v.ref or ref == v.name then
            instance = v
            window = v.ref
            break
        end
    end

    if not window or not instance then
        return
    end

    -- Clear the instance and update state so checkState() can detect reopening
    window._openInstance = nil
    window._isCurrentlyOpen = false
    self:notifyClosed(window, instance, shouldHandleContext)
end

-- How long after closeAll a window going away keeps quiet: long enough for the game's frames to be seen closing, so
-- what is said next (a route's summary) is not cut off by Interrupt Speech on Window Close.
local CLOSE_ALL_QUIET = 0.5

-- True when one of the game's bag frames is on screen.
local function anyBagShown()
    local frames = { rawget(_G, "ContainerFrameCombinedBags") }
    for index = 1, (NUM_CONTAINER_FRAMES or 13) do
        tinsert(frames, rawget(_G, "ContainerFrame" .. index))
    end
    for _, frame in ipairs(frames) do
        if frame.IsShown ~= nil and frame:IsShown() then
            return true
        end
    end
    return false
end

-- Close every open bag the way the game's CloseAllBags does (the backpack, each bag, the keyring), but never through
-- CloseAllBags: its first step writes the game's private "which window opened the bags" value, and written by addon
-- code that value is WowVision's. The next window that opens the bags (bank, merchant, auction house) reads it and
-- runs as WowVision from then on: on WoW: Forever the bank's bank type is then WowVision's, every bag click reads it
-- after the bank closed (BankFrame:GetActiveBankType), and the use of an item that casts is refused ("UseContainerItem"
-- forbidden, 2026-11-17). CloseBackpack and CloseBag only hide the frames. True when a bag was open.
function WindowManager.closeGameBags()
    if CloseBackpack == nil or CloseBag == nil or not anyBagShown() then
        return false
    end
    CloseBackpack()
    for id = 1, (NUM_TOTAL_BAG_FRAMES or NUM_BAG_FRAMES or 4) do
        CloseBag(id)
    end
    if KEYRING_CONTAINER ~= nil and IsBagOpen ~= nil and IsBagOpen(KEYRING_CONTAINER) then
        CloseBag(KEYRING_CONTAINER)
    end
    return true
end

-- Close every open WowVision window and every window of the game. Popups that wait for an answer stay on screen. The
-- reason goes to every window's close request: "closeAllKey" from the Close All Windows key, which with Pending
-- Windows puts their windows aside (windows/pending.lua); none from a route start, which leaves them in front. In
-- combat the game's protected windows stay too. True when something was open.
function WindowManager:closeAll(reason)
    self.quietCloseUntil = GetTime() + CLOSE_ALL_QUIET
    local host = WowVision.graphHost
    local stacks = {}
    for _, stack in ipairs(host.stacks) do
        tinsert(stacks, stack)
    end
    local closed = #stacks > 0
    for i = #stacks, 1, -1 do
        local stack = stacks[i]
        if stack.config ~= nil and stack.config.onRequestClose ~= nil then
            local ok, err = pcall(stack.config.onRequestClose, stack, reason)
            if not ok then
                geterrorhandler()(err)
            end
        else
            host:close(stack)
        end
    end
    if not InCombatLockdown() then
        -- The game's windows first: a window that opened the bags (bank, merchant) closes them itself.
        if CloseWindows ~= nil and CloseWindows() then
            closed = true
        end
        if WindowManager.closeGameBags() then
            closed = true
        end
    end
    return closed
end

-- Close in combat: only what is WowVision's own -- its windows (ManualWindow:isOwnWindow) and the screens no game
-- window owns (context menus, text entries). A game window stays: in combat the game refuses addon code that shows or
-- hides its panels (CheckProtectedFunctionsAllowed in UIParentPanelManager.lua says "Interface action failed"), and its
-- screen is kept for after the fight. Returns the titles of the windows that stay.
function WindowManager:closeOwnWindows()
    local owners = {}
    for _, instance in ipairs(self.openWindows) do
        if instance.stack ~= nil then
            owners[instance.stack] = instance
        end
    end
    local host = WowVision.graphHost
    local stacks = {}
    for _, stack in ipairs(host.stacks) do
        tinsert(stacks, stack)
    end
    local remaining = {}
    for i = #stacks, 1, -1 do
        local stack = stacks[i]
        local instance = owners[stack]
        local mirrored = WowVision.graph.combatKeys ~= nil and WowVision.graph.combatKeys.isMirrorStack(stack)
        if mirrored then
            -- the equipment list in a fight: the secure side keeps it open and closes it (graph/combatKeys.lua)
            tinsert(remaining, 1, host:stackTitle(stack) or "")
        elseif instance ~= nil then
            local window = instance.ref
            if window.isOwnWindow ~= nil and window:isOwnWindow() then
                self:closeWindow(instance)
            else
                tinsert(remaining, 1, host:stackTitle(stack) or window.name)
            end
        elseif stack.config ~= nil and stack.config.onRequestClose ~= nil then
            local ok, err = pcall(stack.config.onRequestClose, stack)
            if not ok then
                geterrorhandler()(err)
            end
        else
            host:close(stack)
        end
    end
    return remaining
end

-- Update loop for auto-detecting window state changes

function WindowManager:update()
    local autoWindows = self.autoWindows
    for i = 1, #autoWindows do
        local window = autoWindows[i]
        local changed, isOpen = window:checkState()
        if changed then
            if isOpen then
                window:open(self)
            else
                window:close(self)
            end
        end
    end
end

WowVision.WindowManager = WindowManager
