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

function Module:registerCommand(config)
    if not self.registeredCommands then
        self.registeredCommands = {}
    end
    local command = WowVision.SlashCommandManager:createCommand(config, self)
    self.registeredCommands[command.name:lower()] = command
    return command
end

function Module:unregisterCommand(name)
    if self.registeredCommands then
        self.registeredCommands[name:lower()] = nil
    end
end

-- Settings are fields on a per-module settings class; module.settings.rate
-- reads a managed field. hasSettings returns a facade keeping the old
-- declaration API: settings:add(def) declares a persisted field and returns
-- it; settings:addRef links an alert's parameter frame into the screen.
function Module:hasSettings()
    if self.settingsFacade == nil then
        local settingsClass = WowVision.Class("Settings:" .. self.key)
        local settingsObj = settingsClass:new()
        self.settingsObj = settingsObj
        self.settings = settingsObj
        local facade = { refs = {} }
        function facade:add(def)
            def.persist = true
            def.setting = true
            settingsClass:addFields({ def })
            return settingsClass:getField(def.key)
        end
        function facade:addRef(key, target)
            tinsert(self.refs, { key = key, target = target })
        end
        self.settingsFacade = facade
    end
    return self.settingsFacade
end

function Module:createComponentRegistry(config)
    local registry = WowVision.components.createRegistry(config)
    self[config.key] = registry
    return registry
end

function Module:getDefaultSettings()
    if self.settingsObj then
        return WowVision.classes.instanceConfig(self.settingsObj)
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
        settings = self:getDefaultSettings(),
        settingScopes = {},
        data = self:getDefaultData(),
    }
    for _, submodule in ipairs(self.submodules) do
        db.submodules[submodule.key] = submodule:getDefaultDBRecursive()
    end
    return db
end

-- The account-wide default tree: module skeletons with only the
-- global-scoped settings defaults. Data and alerts stay per-character in
-- this phase.
function Module:getDefaultGlobalDBRecursive()
    local db = {
        submodules = {},
        settings = self.settingsObj ~= nil and self.settingsObj:getDefaultDB("global") or {},
        data = {},
    }
    for _, submodule in ipairs(self.submodules) do
        db.submodules[submodule.key] = submodule:getDefaultGlobalDBRecursive()
    end
    return db
end

-- First-login seeding: the account store adopts this character's settings
-- values wholesale (per-character copies stay behind, so this is
-- reversible). Guarded by the _seeded stamp at the caller.
function Module:seedGlobalDB(db, globalDB)
    if db.settings ~= nil then
        globalDB.settings = WowVision.classes.deepCopy(db.settings)
    end
    for _, submodule in ipairs(self.submodules) do
        if db.submodules[submodule.key] ~= nil and globalDB.submodules[submodule.key] ~= nil then
            submodule:seedGlobalDB(db.submodules[submodule.key], globalDB.submodules[submodule.key])
        end
    end
end

function Module:setDBObj(db, globalDB)
    self.enabled = db.enabled
    self.db = db
    self.globalDB = globalDB
    if db.alerts == nil then
        error("No alerts db found for module " .. self.key .. ".")
    end
    for k, v in pairs(self.alerts) do
        local alertDB = db.alerts[k]
        if not alertDB then
            error("No alert db found for " .. k)
        end
        v:setDB(alertDB)
    end
    if self.settingsObj then
        if db.settingScopes == nil then
            db.settingScopes = {}
        end
        self.settingsObj:setDB({
            char = db.settings,
            global = globalDB ~= nil and globalDB.settings or nil,
            -- Per-character scope overrides: this character's choices about
            -- which settings follow the account and which stay local.
            overrides = db.settingScopes,
        })
    end
    self.data = db.data
    for _, submodule in ipairs(self.submodules) do
        submodule:setDBObj(
            db.submodules[submodule.key],
            globalDB ~= nil and globalDB.submodules[submodule.key] or nil
        )
    end
end

-- Module-level scope: the whole module's persisted state at once. Covers
-- the settings object automatically; modules whose state lives elsewhere
-- (component containers) implement onSetScope(scope)/getScopeState().
function Module:hasScope()
    return self.settingsObj ~= nil or self.onSetScope ~= nil
end

function Module:setScope(scope)
    if self.settingsObj ~= nil then
        WowVision.classes.setObjectScope(self.settingsObj, scope)
    end
    if self.onSetScope ~= nil then
        self:onSetScope(scope)
    end
end

-- "global" or "char" when uniform; nil when mixed (neither radio reads
-- checked).
function Module:getScope()
    local scopes = {}
    if self.settingsObj ~= nil then
        tinsert(scopes, WowVision.classes.effectiveObjectScope(self.settingsObj))
    end
    if self.getScopeState ~= nil then
        tinsert(scopes, self:getScopeState())
    end
    local result = nil
    for _, scope in ipairs(scopes) do
        if result == nil then
            result = scope
        elseif result ~= scope then
            return nil
        end
    end
    return result
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
    self.registeredWindows = self.registeredWindows or {}
    self.registeredWindows[window.name] = window
end

function Module:unregisterWindow(name)
    if not self.registeredWindows or not self.registeredWindows[name] then
        return
    end
    local window = self.registeredWindows[name]
    self.registeredWindows[name] = nil
    -- Event-driven windows hook the shared dispatcher at creation; detach or
    -- the orphan keeps opening on events.
    if window.destroy ~= nil then
        window:destroy()
    end
    -- If the module is already enabled, the window is live in the window manager
    -- (registered in fullEnable), so remove it there too.
    if self:getEnabled() then
        WowVision.UIHost.windowManager:UnregisterWindow(name)
    end
end

function Module:registerDropdownMenu(menu, description)
    self.registeredDropdownMenus = self.registeredDropdownMenus or {}
    self.registeredDropdownMenus[menu] = description
end

function Module:unregisterDropdownMenu(menu)
    if self.registeredDropdownMenus then
        self.registeredDropdownMenus[menu] = nil
    end
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
    if self.registeredWindows then
        for _, v in pairs(self.registeredWindows) do
            WowVision.UIHost.windowManager:RegisterWindow(v)
        end
    end
    if self.registeredDropdownMenus then
        for k, v in pairs(self.registeredDropdownMenus) do
            WowVision.graph.dropdown.registerMenu(k, v)
        end
    end

    -- Register slash commands with the manager
    if self.registeredCommands then
        for _, command in pairs(self.registeredCommands) do
            WowVision.SlashCommandManager:registerCommand(command)
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
    if self.registeredWindows then
        for k, _ in pairs(self.registeredWindows) do
            WowVision.UIHost.windowManager:UnregisterWindow(k)
        end
    end
    if self.registeredDropdownMenus then
        for k, _ in pairs(self.registeredDropdownMenus) do
            WowVision.graph.dropdown.unregisterMenu(k)
        end
    end

    -- Unregister slash commands from the manager
    if self.registeredCommands then
        for _, command in pairs(self.registeredCommands) do
            WowVision.SlashCommandManager:unregisterCommand(command)
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
