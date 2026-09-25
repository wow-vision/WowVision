local module = WowVision.base:createModule("errors")
local L = module.L
module:setLabel(L["Errors"])
local settings = module:hasSettings()
local utils = WowVision.errors.utils
local graph = WowVision.graph
local ControlId = graph.ControlId

-- Master switch, keyed "announce" so existing on/off choices carry over.
-- Its own speech voices what the per-error filter cannot route: Lua errors,
-- and retail messages that arrive as secret values.
local alert = module:addAlert({
    key = "announce",
    label = L["Announce Errors"],
})

alert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
})

settings:addRef("announce", alert.parameters)

settings:add({
    type = "Number",
    key = "repeatDelay",
    label = L["Repeat Delay"],
    default = 2,
    min = 0,
    max = 30,
})

-- ---- per-error filter ----

-- Account-wide: an error muted on one character stays muted on all of them.
local function getStore()
    local data = module.globalDB ~= nil and module.globalDB.data or module.data
    if data == nil then
        return nil
    end
    if data.errors == nil then
        data.errors = {}
    end
    return data.errors
end

local perErrorAlerts = {}

local function buildAlert(key, label)
    local errorAlert = WowVision.alerts.Alert:new({
        key = "error:" .. key,
        label = label,
    })
    errorAlert:addOutput({
        type = "TTS",
        key = "tts",
        label = L["TTS Alert"],
        buildMessage = function(self, message)
            return message.text
        end,
    })
    errorAlert:addOutput({
        type = "Sound",
        key = "sound",
        label = L["Sound Alert"],
        enabled = false,
    })
    return errorAlert
end

-- The alert behind one filter entry, bound to its saved record (created on
-- first sight). Labels follow the client's current wording.
local function getAlert(key, label)
    local store = getStore()
    if store == nil then
        return nil
    end
    local entry = store[key]
    if entry == nil then
        entry = {}
        store[key] = entry
    end
    if label ~= nil then
        entry.label = label
    end
    local errorAlert = perErrorAlerts[key]
    if errorAlert == nil then
        errorAlert = buildAlert(key, entry.label)
        entry.alert = WowVision.dbManager:reconcile(errorAlert:getDefaultDBRecursive(), entry.alert)
        errorAlert:setDB(entry.alert)
        perErrorAlerts[key] = errorAlert
    elseif label ~= nil and errorAlert.label ~= label then
        errorAlert.label = label
        errorAlert.parameters.label = label
    end
    return errorAlert
end

local function lookupMessageInfo(messageType)
    if messageType == nil or GetGameMessageInfo == nil or WowVision.isSecret(messageType) then
        return nil, nil
    end
    local ok, errorName = pcall(GetGameMessageInfo, messageType)
    if not ok or type(errorName) ~= "string" then
        return nil, nil
    end
    local template = _G[errorName]
    if type(template) ~= "string" then
        template = nil
    end
    return errorName, template
end

local throttle = utils.newThrottle()
local dedupe = utils.newFrameDedupe()

-- Every source funnels here: the UI_ERROR/UI_INFO/SYSMSG events and the
-- UIErrorsFrame display hooks.
function module.handleMessage(messageType, message)
    if not alert.enabled or message == nil then
        return
    end
    -- Retail may hand a secret string to the display hook: no table key or
    -- comparison is allowed on it, but speech accepts it as is.
    if WowVision.isSecret(message) then
        alert:fire({ text = message })
        return
    end
    if message == "" then
        return
    end
    local now = GetTime()
    if not dedupe:first(message, now) then
        return
    end
    local errorName, template = lookupMessageInfo(messageType)
    local key, label = utils.identify(errorName, template, message)
    if not throttle:allow(key, now, module.settings.repeatDelay) then
        return
    end
    local errorAlert = getAlert(key, label)
    if errorAlert ~= nil then
        errorAlert:fire({ text = message, messageType = messageType })
    end
end

-- Listening to the events directly, not only the display, matters on
-- retail: its UIErrorsFrame silently drops a blacklist of message types
-- (out of range, out of rage/energy/focus, spell and ability cooldowns)
-- before showing them. It also keeps errors audible when another addon
-- hides or unregisters the error frame.
module:registerEvent("event", "UI_ERROR_MESSAGE")
module:registerEvent("event", "UI_INFO_MESSAGE")
module:registerEvent("event", "SYSMSG")

function module:onEvent(event, ...)
    if event == "SYSMSG" then
        module.handleMessage(nil, (...))
    else
        local messageType, message = ...
        module.handleMessage(messageType, message)
    end
end

-- Display hook for what bypasses the events: UI code and addons calling
-- UIErrorsFrame:AddMessage (or AddExternalErrorMessage, which ends there)
-- directly. Messages from the events land here too; the frame dedupe drops
-- the second copy.
function module.onDisplay(frame, message, r, g, b, alpha, messageType)
    module.handleMessage(messageType, message)
end

-- ---- filter screen ----

local showAll = false
local knownErrors = nil

-- Every worded error the client knows, from its LE_GAME_ERR_* constants.
-- Walks _G once, on first use.
local function getKnownErrors()
    if knownErrors ~= nil then
        return knownErrors
    end
    knownErrors = {}
    if GetGameMessageInfo == nil then
        return knownErrors
    end
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "number" and name:sub(1, 12) == "LE_GAME_ERR_" then
            local errorName, template = lookupMessageInfo(value)
            if errorName ~= nil and utils.templateLiteral(template) ~= "" then
                local key, label = utils.identify(errorName, template, template)
                knownErrors[key] = label
            end
        end
    end
    return knownErrors
end

local function filterEntries()
    local labels = {}
    for key, entry in pairs(getStore() or {}) do
        labels[key] = entry.label or key
    end
    if showAll then
        for key, label in pairs(getKnownErrors()) do
            if labels[key] == nil then
                labels[key] = label
            end
        end
    end
    local entries = {}
    for key, label in pairs(labels) do
        tinsert(entries, { key = key, label = label })
    end
    table.sort(entries, function(a, b)
        return a.label:lower() < b.label:lower()
    end)
    return entries
end

-- What an entry does, read after its label: which outputs are on.
local function entryState(key)
    local errorAlert = perErrorAlerts[key]
    if errorAlert == nil then
        local store = getStore()
        if store == nil or store[key] == nil then
            return L["Speech"] -- never configured: the defaults
        end
        errorAlert = getAlert(key)
    end
    if errorAlert == nil then
        return L["Speech"]
    end
    if not errorAlert.enabled then
        return L["Muted"]
    end
    local speech, sound = false, false
    for _, output in ipairs(errorAlert.outputs) do
        if output.enabled then
            if output.key == "tts" then
                speech = true
            elseif output.key == "sound" then
                sound = true
            end
        end
    end
    if speech and sound then
        return L["Speech and Sound"]
    elseif speech then
        return L["Speech"]
    elseif sound then
        return L["Sound"]
    end
    return L["Muted"]
end

local function renderFilter(builder)
    builder:pushContext("errorFilter", L["Per-Error Filter"])
    builder:addItem(
        ControlId.structural("showAll"),
        graph.nodes.toggle({
            label = L["Show All Known Errors"],
            get = function()
                return showAll
            end,
            set = function(value)
                showAll = value
            end,
        })
    )
    for _, entry in ipairs(filterEntries()) do
        local key, label = entry.key, entry.label
        builder:addItem(
            ControlId.structural("error:" .. key),
            graph.nodes.button({
                label = label,
                value = function()
                    return entryState(key)
                end,
                onActivate = function()
                    local errorAlert = getAlert(key, label)
                    if errorAlert == nil then
                        return
                    end
                    graph.settings.pushScreen("errorAlert:" .. key, function(child)
                        graph.settings.renderInto(child, errorAlert.parameters)
                    end)
                end,
            })
        )
    end
    builder:popContext()
end

function module:getGraphMenuItems(builder)
    builder:addItem(
        ControlId.structural("errorFilter"),
        graph.nodes.button({
            label = L["Per-Error Filter"],
            onActivate = function()
                graph.settings.pushScreen("errorFilter", renderFilter)
            end,
        })
    )
end

-- ---- Lua errors ----

-- Lua script errors: the default error dialog is not accessible, so capture
-- them for TTS and a copyable window. /wv errors speaks the most recent error
-- and shows the full list with stacks; /wv errors clear resets it.
-- The list lives in the account-wide WowVisionDump saved variable, so errors
-- survive /reload and logout and can be read from the SavedVariables file.
local function persistentErrors()
    WowVisionDump = WowVisionDump or {}
    if type(WowVisionDump.luaErrors) ~= "table" then
        WowVisionDump.luaErrors = {}
    end
    return WowVisionDump.luaErrors
end

module.luaErrors = {}
local MAX_LUA_ERRORS = 20

function module:clearLuaErrors()
    self.luaErrors = {}
    WowVisionDump = WowVisionDump or {}
    WowVisionDump.luaErrors = self.luaErrors
end
local previousHandler = nil
local inHandler = false
local lastSpokenError = nil
local lastSpokenAt = 0

local function onLuaError(message)
    if inHandler then
        return
    end
    inHandler = true
    tinsert(module.luaErrors, {
        message = message,
        stack = debugstack(3),
        time = date("%H:%M:%S"),
        date = date("%Y-%m-%d"),
    })
    if #module.luaErrors > MAX_LUA_ERRORS then
        table.remove(module.luaErrors, 1)
    end
    -- A recurring per-frame error must not flood TTS.
    if message ~= lastSpokenError or GetTime() - lastSpokenAt > 5 then
        lastSpokenError = message
        lastSpokenAt = GetTime()
        pcall(function()
            alert:fire({ text = "Lua error: " .. message })
        end)
    end
    inHandler = false
    if previousHandler then
        return previousHandler(message)
    end
end

function module:onEnable()
    WowVision.UIHost:hookFunc(UIErrorsFrame, "AddMessage", module.onDisplay)
    module.luaErrors = persistentErrors()
    previousHandler = geterrorhandler()
    seterrorhandler(onLuaError)
end

function module:onDisable()
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "AddMessage", module.onDisplay)
    if previousHandler then
        seterrorhandler(previousHandler)
        previousHandler = nil
    end
end
