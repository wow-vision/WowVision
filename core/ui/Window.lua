-- Base Window class
local Window, _ = WowVision.WindowManager:CreateWindowType("Window")

Window.info:addFields({
    { key = "name", required = true },
    { key = "auto", default = false },
    { key = "generated", default = false },
    { key = "rootElement" },
    { key = "hookEscape", default = false },
    { key = "innate", default = false },
    { key = "conflictingAddons" },
    { key = "onClose" },
})

function Window:initialize(config)
    self:setInfo(config)
    self._isCurrentlyOpen = false
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
