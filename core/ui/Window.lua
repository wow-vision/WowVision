-- Base Window class
local Window, _ = WowVision.WindowManager:CreateWindowType("Window")

Window.info:addFields({
    { key = "name", required = true },
    { key = "generated", default = false },
    { key = "rootElement" },
    { key = "hookEscape", default = false },
    { key = "innate", default = false },
    { key = "conflictingAddons" },
    { key = "onClose" },
})

-- Whether this window type needs to be polled each frame
-- Override in subclasses that need polling (FrameWindow, CustomWindow)
function Window:needsPolling()
    return false
end

function Window:initialize(config)
    self:setInfo(config)
    self._isCurrentlyOpen = false
    self._openInstance = nil
end

-- Abstract method - subclasses must override
function Window:isOpen()
    error("Window:isOpen() must be overridden by subclass")
end

-- Called by WindowManager to check and update state
-- Returns true if state changed, false otherwise
function Window:checkState()
    local nowOpen = self:isOpen()
    local wasOpen = self._isCurrentlyOpen
    if nowOpen ~= wasOpen then
        self._isCurrentlyOpen = nowOpen
        return true, nowOpen
    end
    return false, nowOpen
end

-- Check for conflicting addons before opening
function Window:canOpen()
    if self.conflictingAddons then
        for _, addonName in ipairs(self.conflictingAddons) do
            if C_AddOns.IsAddOnLoaded(addonName) then
                return false
            end
        end
    end
    return true
end

-- Build the root element configuration for generated windows
function Window:buildRootElement(props)
    local generated = {}
    local frame = self.getFrame and self:getFrame()
    if frame then
        generated.frame = frame
    end
    if type(self.rootElement) == "string" then
        generated[1] = self.rootElement
    elseif type(self.rootElement) == "table" then
        for k, v in pairs(self.rootElement) do
            generated[k] = v
        end
    else
        error("Window: invalid root element format")
    end
    if props then
        for k, v in pairs(props) do
            generated[k] = v
        end
    end
    return generated
end

-- Create and configure the WindowContext for this window
function Window:createContext()
    local context = WowVision.ui:CreateElement("WindowContext", {
        ref = self,
        name = self.name,
        hookEscape = self.hookEscape,
        onClose = self.onClose,
    })
    context:setHookEscape(self.hookEscape)
    context.innate = self.innate
    context.onClose = self.onClose
    return context
end

-- Open the window with optional props
-- Returns the open instance, or nil if window couldn't be opened
function Window:open(manager, props)
    if not self:canOpen() then
        return nil
    end
    if self._openInstance then
        return nil -- Already open
    end

    local context = self:createContext()
    local instance = {
        ref = self,
        name = self.name,
        hookEscape = self.hookEscape,
        onClose = self.onClose,
        context = context,
    }

    if self.generated then
        context:addGenerated(self:buildRootElement(props))
    else
        if props then
            for k, v in pairs(props) do
                self.rootElement:setProp(k, v)
            end
        end
        context:add(self.rootElement)
    end

    self._openInstance = instance
    manager:notifyOpened(self, instance)
    return instance
end

-- Close the window
function Window:close(manager)
    local instance = self._openInstance
    if not instance then
        return
    end
    self._openInstance = nil
    manager:notifyClosed(self, instance)
end

-- Get the current open instance (if any)
function Window:getOpenInstance()
    return self._openInstance
end

WowVision.Window = Window

-- FrameWindow - detects open state via frame visibility
local FrameWindow, _ = WowVision.WindowManager:CreateWindowType("FrameWindow", "Window")

FrameWindow.info:addFields({
    { key = "frameName", required = true },
    { key = "frame" },
})

function FrameWindow:initialize(config)
    Window.initialize(self, config)
    self._cachedFrame = nil
    self._frameCheckTime = 0
end

function FrameWindow:needsPolling()
    return true
end

local FRAME_RETRY_INTERVAL = 1.0 -- Only re-check _G every 1 second for missing frames

function FrameWindow:getFrame()
    local frame = self._cachedFrame
    if frame then
        return frame
    end
    -- Throttle _G lookups for frames that don't exist yet
    local now = GetTime()
    if now - self._frameCheckTime < FRAME_RETRY_INTERVAL then
        return nil
    end
    self._frameCheckTime = now
    frame = self.frame or rawget(_G, self.frameName)
    if frame then
        self._cachedFrame = frame
    end
    return frame
end

function FrameWindow:isOpen()
    local frame = self:getFrame()
    return frame and frame:IsShown() and frame:IsVisible()
end

-- Inlined checkState for performance - avoids method call overhead
function FrameWindow:checkState()
    -- Inline frame lookup
    local frame = self._cachedFrame
    if not frame then
        local now = GetTime()
        if now - self._frameCheckTime >= FRAME_RETRY_INTERVAL then
            self._frameCheckTime = now
            frame = self.frame or rawget(_G, self.frameName)
            if frame then
                self._cachedFrame = frame
            end
        end
    end
    -- Inline isOpen check
    local nowOpen = frame and frame:IsShown() and frame:IsVisible()
    local wasOpen = self._isCurrentlyOpen
    if nowOpen ~= wasOpen then
        self._isCurrentlyOpen = nowOpen
        return true, nowOpen
    end
    return false, nowOpen
end

WowVision.FrameWindow = FrameWindow

-- CustomWindow - uses a custom function to detect open state
local CustomWindow, _ = WowVision.WindowManager:CreateWindowType("CustomWindow", "Window")

CustomWindow.info:addFields({
    { key = "isOpenFunc", required = true },
})

function CustomWindow:initialize(config)
    Window.initialize(self, config)
end

function CustomWindow:needsPolling()
    return true
end

function CustomWindow:isOpen()
    return self.isOpenFunc(self)
end

WowVision.CustomWindow = CustomWindow

-- ManualWindow - opened/closed programmatically, no auto-detection
local ManualWindow, _ = WowVision.WindowManager:CreateWindowType("ManualWindow", "Window")

function ManualWindow:initialize(config)
    Window.initialize(self, config)
end

-- isOpen returns internal state - only changes when opened/closed externally
function ManualWindow:isOpen()
    return self._isCurrentlyOpen
end

WowVision.ManualWindow = ManualWindow

-- EventWindow - opens/closes based on WoW events
local EventWindow, _ = WowVision.WindowManager:CreateWindowType("EventWindow", "Window")

EventWindow.info:addFields({
    { key = "openEvent", required = true },
    { key = "closeEvent", required = true },
})

function EventWindow:initialize(config)
    Window.initialize(self, config)

    -- Create a frame to receive events
    self._eventFrame = CreateFrame("Frame")

    self:registerEvents()

    -- Set up event handler
    local window = self
    self._eventFrame:SetScript("OnEvent", function(frame, event, ...)
        window:onEvent(event, ...)
    end)
end

function EventWindow:registerEvents()
    self._eventFrame:UnregisterAllEvents()
    self._eventFrame:RegisterEvent(self.openEvent)
    self._eventFrame:RegisterEvent(self.closeEvent)
end

function EventWindow:onEvent(event, ...)
    if event == self.openEvent then
        self._isCurrentlyOpen = true
        self:open(WowVision.UIHost.windowManager)
    elseif event == self.closeEvent then
        self._isCurrentlyOpen = false
        self:close(WowVision.UIHost.windowManager)
    end
end

function EventWindow:isOpen()
    return self._isCurrentlyOpen
end

WowVision.EventWindow = EventWindow

-- PlayerInteractionWindow - opens/closes based on PLAYER_INTERACTION_MANAGER events
local PlayerInteractionWindow, _ = WowVision.WindowManager:CreateWindowType("PlayerInteractionWindow", "Window")

PlayerInteractionWindow.info:addFields({
    { key = "interactionType", required = true },
})

function PlayerInteractionWindow:initialize(config)
    Window.initialize(self, config)

    -- Create a frame to receive events
    self._eventFrame = CreateFrame("Frame")

    self._eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    self._eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

    -- Set up event handler
    local window = self
    self._eventFrame:SetScript("OnEvent", function(frame, event, interactionType)
        window:onEvent(event, interactionType)
    end)
end

function PlayerInteractionWindow:onEvent(event, interactionType)
    if interactionType ~= self.interactionType then
        return
    end

    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        self._isCurrentlyOpen = true
        self:open(WowVision.UIHost.windowManager)
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        self._isCurrentlyOpen = false
        self:close(WowVision.UIHost.windowManager)
    end
end

function PlayerInteractionWindow:isOpen()
    return self._isCurrentlyOpen
end

WowVision.PlayerInteractionWindow = PlayerInteractionWindow
