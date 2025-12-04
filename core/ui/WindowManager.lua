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

function WindowManager:RegisterWindow(window)
    self.windows[window.name] = window
    if window.auto then
        self.autoWindows[#self.autoWindows + 1] = window
    end
end

function WindowManager:UnregisterWindow(name)
    local window = self.windows[name]
    self.windows[name] = nil
    if window and window.auto then
        for i = #self.autoWindows, 1, -1 do
            if self.autoWindows[i] == window then
                table.remove(self.autoWindows, i)
                break
            end
        end
    end
end

function WindowManager:openWindow(window, props)
    local window = window
    local props = props or {}
    if type(window) == "string" then
        local windowObj = self.windows[window]
        if not windowObj then
            return
        end
        window = windowObj
    end
    if window.conflictingAddons then
        for _, v in ipairs(window.conflictingAddons) do
            if C_AddOns.IsAddOnLoaded(v) then
                return
            end
        end
    end
    if window.auto and self.openWindows.autoWindows[window.name] then
        return
    end
    local newWindow = {
        ref = window,
        name = window.name,
        hookEscape = window.hookEscape,
        onClose = window.onClose,
    }
    local windowContext = WowVision.ui:CreateElement("WindowContext", newWindow)
    windowContext:setHookEscape(newWindow.hookEscape)
    windowContext.innate = window.innate
    windowContext.onClose = newWindow.onClose
    newWindow.context = windowContext
    if window.generated then
        local generated = {}
        local frame = window.getFrame and window:getFrame()
        if frame then
            generated.frame = frame
        end
        if type(window.rootElement) == "string" then
            generated[1] = window.rootElement
        elseif type(window.rootElement) == "table" then
            for k, v in pairs(window.rootElement) do
                generated[k] = v
            end
        else
            error("WindowManager: invalid root generated element format")
        end
        for k, v in pairs(props) do
            generated[k] = v
        end
        windowContext:addGenerated(generated)
    else
        for k, v in pairs(props) do
            window.rootElement:setProp(k, v)
        end
        windowContext:add(window.rootElement)
    end

    tinsert(self.openWindows, newWindow)
    if window.auto then
        self.openWindows.autoWindows[window.name] = true
    end
    self.windowContext:add(windowContext)
    WowVision.UIHost:open()
    return newWindow
end

function WindowManager:closeWindow(ref, shouldHandleContext)
    local window = nil
    for i, v in ipairs(self.openWindows) do
        if ref == v or ref == v.ref or ref == v.name then
            if WowVision.base.ui.settings.interruptSpeechOnWindowClose then
                WowVision.base.speech:uiStop()
            end
            window = v
            table.remove(self.openWindows, i)
            if v.name then
                self.openWindows.autoWindows[v.name] = nil
            end
            break
        end
    end
    if not window then
        return
    end
    if shouldHandleContext ~= false then
        self.windowContext:remove(window.context)
        if WowVision.UIHost:shouldClose() then
            WowVision.UIHost:close()
        end
    end
end

function WindowManager:update()
    local autoWindows = self.autoWindows
    for i = 1, #autoWindows do
        local window = autoWindows[i]
        local changed, isOpen = window:checkState()
        if changed then
            if isOpen then
                self:openWindow(window)
            else
                self:closeWindow(window)
            end
        end
    end
end

WowVision.WindowManager = WindowManager
