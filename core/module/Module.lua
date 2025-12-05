local void, WowVisionNamespace = ...
local Module = WowVision.Class("Module")
local L = LibStub("AceLocale-3.0"):NewLocale("WowVision", "enUS", true)

-- Registry of modules with update handlers (avoids recursive tree walk every frame)
-- This is an ordered array, rebuilt when handlers change to preserve hierarchy order
local moduleUpdateHandlers = {}
local updateHandlersDirty = false

function Module:initialize(key)
    self.key = key
    self.enabled = true
    self.L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
    self.parent = nil
    self.vital = false
    self.submodules = {}
    self.keyFrame = CreateFrame("Frame")
    self.bindings = WowVision.input.BindingSet:new()
    self.alerts = {}
    self.registeredEvents = {}
    self.eventsFrame = CreateFrame("Frame")
    self.eventsFrame:SetScript("OnEvent", function(frame, event, ...)
        self:onEvent(event, ...)
    end)
    self.profiler = WowVision.Profiler:new()
end

function Module:setParent(module)
    self.parent = module
end

function Module:createModule(key)
    local submodule = Module:new(key)
    submodule:setParent(self)
    tinsert(self.submodules, submodule)
    if self[key] == nil then
        self[key] = submodule
    end
    return submodule
end

function Module:hasUI()
    if not self.elementGenerator then
        self.elementGenerator = WowVision.Generator:new()
        self.registeredWindows = {}
        self.registeredDropdownMenus = {}
    end
    return self.elementGenerator
end

function Module:hasSettings()
    if not self.settingsRoot then
        self.settingsRoot = WowVision.parameters.Category:new({
            key = "settings",
            label = "Settings",
        })
    end
    return self.settingsRoot
end

function Module:getDefaultSettings()
    if self.settingsRoot then
        return self.settingsRoot:getDefaultDB()
    end
    return {}
end

function Module:getDefaultBindings()
    return self.bindings:getDefaultDB()
end

function Module:getDefaultData()
    return {}
end

function Module:getDefaultDBRecursive()
    local db = {
        enabled = self.enabled,
        submodules = {},
        alerts = self:getDefaultAlerts(),
        bindings = self:getDefaultBindings(),
        settings = self:getDefaultSettings(),
        data = self:getDefaultData(),
    }
    for _, submodule in ipairs(self.submodules) do
        db.submodules[submodule.key] = submodule:getDefaultDBRecursive()
    end
    return db
end

function Module:setDBObj(db)
    self.enabled = db.enabled
    self.db = db
    if db.alerts == nil then
        error("No alerts db found for module " .. self.key .. ".")
    end
    self.bindings:setDB(db.bindings)
    for k, v in pairs(self.alerts) do
        local alertDB = db.alerts[k]
        if not alertDB then
            error("No alert db found for " .. k)
        end
        v:setDB(alertDB)
    end
    self.settings = db.settings
    if self.settingsRoot then
        self.settingsRoot:setDB(db.settings)
    end
    self.data = db.data
    for _, submodule in ipairs(self.submodules) do
        submodule:setDBObj(db.submodules[submodule.key])
    end
end

function Module:isVital()
    return self.vital
end

function Module:setVital(value)
    self.vital = value
end

function Module:addAlert(info)
    local alert = WowVision.alerts.Alert:new(info)
    self.alerts[info.key] = alert
    return alert
end

function Module:fireAlert(alert, message)
    local alertObj = self.alerts[alert]
    if not alertObj then
        error("No alert " .. alert .. " found for module " .. self:getLabel())
    end
    alertObj:fire(message)
end

function Module:getDefaultAlerts()
    local db = {}
    for k, v in pairs(self.alerts) do
        db[k] = v:getDefaultDBRecursive()
    end
    return db
end

function Module:registerEvent(eventType, event, ...)
    if eventType ~= "event" and eventType ~= "unit" then
        error("Registered event type must be one of {event, unit}.")
    end
    local newEvent = {
        type = eventType,
        event = event,
        args = { ... },
    }
    tinsert(self.registeredEvents, newEvent)
end

function Module:_addEvent(event)
    if event.type == "event" then
        self.eventsFrame:RegisterEvent(event.event)
    elseif event.type == "unit" then
        self.eventsFrame:RegisterUnitEvent(event.event, unpack(event.args))
    end
end

function Module:onEvent(event, ...) end

function Module:registerWindow(config)
    local window
    -- If already a Window instance, use it directly
    if config.checkState then
        window = config
    elseif config.type then
        -- CustomWindow uses isOpenFunc internally, but isOpen in config
        if config.type == "CustomWindow" and config.isOpen then
            config.isOpenFunc = config.isOpen
            config.isOpen = nil
        end
        window = WowVision.WindowManager:CreateWindow(config.type, config)
    else
        error(
            "Window config must specify 'type' field. Available types: FrameWindow, CustomWindow, ManualWindow, EventWindow, PlayerInteractionWindow"
        )
    end
    self.registeredWindows[window.name] = window
end

function Module:unregisterWindow(name)
    self.windows[name] = nil
end

function Module:registerDropdownMenu(menu, description)
    self.registeredDropdownMenus[menu] = description
end

function Module:unregisterDropdownMenu(menu)
    self.registeredDropdownMenus[menu] = nil
end

function Module:getEnabled()
    return self.enabled
end

function Module:setEnabled(enabled)
    if enabled == true and self.enabled == false then
        self.enabled = true
        self.db.enabled = true
        self:enable()
    end
    if enabled == false and self.enabled == true then
        self.enabled = false
        self.db.enabled = false
        self:disable()
    end
end

function Module:registerBinding(info)
    local instance = WowVision.input:createBinding(info)
    self.bindings:add(instance)
    return instance
end

function Module:registerBindings(bindings)
    local result = {}
    for _, binding in ipairs(bindings) do
        local newBinding = self:registerBinding(binding)
        if newBinding then
            tinsert(result, newBinding)
        end
    end
    return result
end

function Module:enable()
    if not self:getEnabled() then
        return
    end
    if self.elementGenerator then
        WowVision.ui.generator:include(self.elementGenerator)
        for _, v in pairs(self.registeredWindows) do
            WowVision.UIHost.windowManager:RegisterWindow(v)
        end

        for k, v in pairs(self.registeredDropdownMenus) do
            WowVision.UIHost.menuManager:registerMenu(k, v)
        end
    end

    self.bindings:activateAll()

    for _, v in ipairs(self.registeredEvents) do
        self:_addEvent(v)
    end

    self:onEnable()
    self:_markUpdateHandlersDirty()
    if WowVision.fullEnable then
        self:fullEnable()
    end

    for _, submodule in ipairs(self.submodules) do
        submodule:enable()
    end
end

function Module:fullEnable()
    if not self:getEnabled() then
        return
    end
    self:onFullEnable()
    for _, submodule in ipairs(self.submodules) do
        submodule:fullEnable()
    end
end

function Module:onEnable() end

function Module:disable()
    if self.elementGenerator then
        WowVision.ui.generator:exclude(self.elementGenerator)

        for k, _ in pairs(self.registeredWindows) do
            WowVision.UIHost.windowManager:UnregisterWindow(k)
        end

        for k, _ in pairs(self.registeredDropdownMenus) do
            WowVision.UIHost.menuManager:unregisterMenu(k)
        end
    end

    self.eventsFrame:UnregisterAllEvents()
    self:onDisable()
    self:_markUpdateHandlersDirty()

    self.bindings:deactivateAll()

    for _, submodule in ipairs(self.submodules) do
        submodule:disable()
    end
end

function Module:onDisable() end

function Module:onFullEnable() end

function Module:getAdditionalMenuUI()
    return nil
end

function Module:getMenuPanel()
    local ui = self:getAdditionalMenuUI()
    return { "ModulePanel", module = self, additionalUI = ui }
end

-- Register an update handler for this module (call in onEnable)
-- This avoids the recursive tree walk - only modules with handlers are called
function Module:hasUpdate(func)
    self._updateFunc = func
end

-- Called when module is enabled/disabled - marks handlers as needing rebuild
function Module:_markUpdateHandlersDirty()
    updateHandlersDirty = true
end

-- Rebuild the ordered handlers list by walking the module tree (depth-first)
local function rebuildUpdateHandlers(module, handlers)
    if not module:getEnabled() then
        return
    end
    if module._updateFunc then
        tinsert(handlers, { module = module, func = module._updateFunc })
    end
    for _, submodule in ipairs(module.submodules) do
        rebuildUpdateHandlers(submodule, handlers)
    end
end

function Module.rebuildAllUpdateHandlers()
    moduleUpdateHandlers = {}
    rebuildUpdateHandlers(WowVision.base, moduleUpdateHandlers)
    updateHandlersDirty = false
end

-- Run all registered update handlers (called from WowVision:OnUpdate)
-- Each module's profiler automatically times its update when profiling is enabled
function Module.runAllUpdates()
    if updateHandlersDirty then
        Module.rebuildAllUpdateHandlers()
    end
    for _, handler in ipairs(moduleUpdateHandlers) do
        local profiler = handler.module.profiler
        if profiler.enabled then
            profiler:start("update")
            handler.func(handler.module)
            profiler:stop("update")
        else
            handler.func(handler.module)
        end
    end
end

function Module:getLabel()
    return self.label
end

function Module:setLabel(label)
    self.label = label
end

WowVision.Module = Module
WowVision.base = Module:new("Accessible  UI")
WowVision.base:setLabel("WowVision")
WowVision.base:setVital(true)
