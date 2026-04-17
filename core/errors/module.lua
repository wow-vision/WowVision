local module = WowVision.base:createModule("errors")
local L = module.L
module:setLabel(L["Errors"])
local settings = module:hasSettings()
local utils = WowVision.errors.utils

function module:getDefaultData()
    return { errors = {} }
end

local perErrorAlerts = {}

local function lookupTemplate(messageType)
    if not GetGameMessageInfo or not messageType then
        return nil
    end
    local stringId = GetGameMessageInfo(messageType)
    if not stringId then
        return nil
    end
    return _G[stringId]
end

local function buildAlertFor(key, label)
    local alert = WowVision.alerts.Alert:new({
        key = "err_" .. key,
        label = label,
    })
    alert:addOutput({
        type = "TTS",
        key = "tts",
        label = L["TTS Alert"],
        buildMessage = function(self, message)
            return message.text
        end,
    })
    alert:addOutput({
        type = "Sound",
        key = "sound",
        label = L["Sound Alert"],
        enabled = false,
    })
    return alert
end

local function getErrorEntry(key, label)
    local data = module.data
    if not data.errors then
        data.errors = {}
    end
    local entry = data.errors[key]
    if not entry then
        entry = { label = label }
        data.errors[key] = entry
    elseif label and entry.label ~= label then
        entry.label = label
    end
    return entry
end

local function getOrCreateAlert(key, label)
    local existing = perErrorAlerts[key]
    if existing then
        if label and existing.label ~= label then
            existing.label = label
            existing.parameters.label = label
        end
        return existing
    end
    local alert = buildAlertFor(key, label)
    perErrorAlerts[key] = alert
    local entry = getErrorEntry(key, label)
    if not entry.alert then
        entry.alert = alert:getDefaultDBRecursive()
    end
    alert:setDB(entry.alert)
    return alert
end

local prefilledLabels = nil
local function getPrefilledLabels()
    if prefilledLabels then
        return prefilledLabels
    end
    prefilledLabels = {}
    if not GetGameMessageInfo then
        return prefilledLabels
    end
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "number" and name:sub(1, 12) == "LE_GAME_ERR_" then
            local stringId = GetGameMessageInfo(value)
            if stringId then
                local text = _G[stringId]
                if text and utils.templateLiteral(text) ~= "" then
                    local pretty = utils.prettifyTemplate(text)
                    prefilledLabels[utils.makeKey(value, pretty)] = pretty
                end
            end
        end
    end
    return prefilledLabels
end

function module.onMessage(frame, message, r, g, b, alpha, messageType)
    if not module.data then
        return
    end
    local template = lookupTemplate(messageType)
    local normalized = utils.normalizeMessage(template, message)
    local key = utils.makeKey(messageType, normalized)
    local entry = getErrorEntry(key, normalized)
    local alert = getOrCreateAlert(key, entry.label)
    alert:fire({ text = message, messageType = messageType })
end

function module.onFlash(frame, fontString)
    local text = fontString:GetText()
    if text then
        WowVision:speak(text)
    end
end

function module:onEnable()
    WowVision.UIHost:hookFunc(UIErrorsFrame, "AddMessage", self.onMessage)
    WowVision.UIHost:hookFunc(UIErrorsFrame, "FlashFontString", self.onFlash)
end

function module:onDisable()
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "AddMessage", self.onMessage)
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "FlashFontString", self.onFlash)
end

local function buildList(showAll)
    local data = module.data
    local seen = (data and data.errors) or {}
    local source = {}
    for key, entry in pairs(seen) do
        source[key] = entry.label
    end
    if showAll then
        for key, label in pairs(getPrefilledLabels()) do
            if source[key] == nil then
                source[key] = label
            end
        end
    end

    local entries = {}
    for id, label in pairs(source) do
        tinsert(entries, { id = id, label = label })
    end
    table.sort(entries, function(a, b)
        return (a.label or ""):lower() < (b.label or ""):lower()
    end)

    local children = {
        {
            "Button",
            key = "toggleShowAll",
            label = showAll and L["Show Seen Only"] or L["Show All"],
            events = {
                click = function(event, button)
                    button.context:pop()
                    button.context:addGenerated(buildList(not showAll))
                end,
            },
        },
    }

    for _, entry in ipairs(entries) do
        local id = entry.id
        local label = entry.label
        tinsert(children, {
            "Button",
            key = "err_" .. id,
            label = label,
            events = {
                click = function(event, button)
                    local alert = getOrCreateAlert(id, label)
                    button.context:addGenerated(alert.parameters:getGenerator())
                end,
            },
        })
    end

    return { "List", label = L["Per-Error Filter"], children = children }
end

settings:addCustomView({
    key = "filter",
    label = L["Per-Error Filter"],
    generator = function()
        return buildList(false)
    end,
})
