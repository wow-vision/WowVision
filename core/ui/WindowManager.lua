local WindowManager = WowVision.Class("WindowManager")

-- Class-level registry for window types (must be available before instances are created)
WindowManager.windowTypes = WowVision.Registry:new()

function WindowManager:initialize(windowContext)
    self.windowContext = windowContext
    self.windows = {}
    self.autoWindows = {} -- Separate list for auto windows (faster iteration)
    self.openWindows = { autoWindows = {} }
    self.dropdownMenuFrame = nil
    self.dropdownMenuIndex = nil
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
    local newClass = WowVision.Class(typeKey, parentClass):include(WowVision.InfoClass)
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

function WindowManager:notifyOpened(window, instance)
    tinsert(self.openWindows, instance)
    if window:needsPolling() then
        self.openWindows.autoWindows[window.name] = true
    end
    self.windowContext:add(instance.context)
    WowVision.UIHost:open()
end

function WindowManager:notifyClosed(window, instance, shouldHandleContext)
    if WowVision.base.ui.settings.interruptSpeechOnWindowClose then
        WowVision.base.speech:uiStop()
    end

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

    if shouldHandleContext ~= false then
        self.windowContext:remove(instance.context)
        if WowVision.UIHost:shouldClose() then
            WowVision.UIHost:close()
        end
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
