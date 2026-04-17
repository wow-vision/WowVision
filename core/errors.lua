local module = WowVision.base:createModule("errors")
local L = module.L
module:setLabel(L["Errors"])
local settings = module:hasSettings()

local baseAlert = module:addAlert({
    key = "announce",
    label = L["Announce Errors"],
})

baseAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return message.text
    end,
})

baseAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
})

settings:addRef("announce", baseAlert.parameters)

function module:getDefaultData()
    return {
        errorLabels = {},
        errorAlerts = {},
    }
end

local perErrorAlerts = {}

local function makeKey(messageType, message)
    return tostring(messageType) .. ":" .. tostring(message)
end

local function getTemplateForType(messageType)
    if not GetGameMessageInfo or not messageType then
        return nil
    end
    local stringId = GetGameMessageInfo(messageType)
    if not stringId then
        return nil
    end
    return _G[stringId]
end

local function templateLiteral(template)
    if not template then return "" end
    local stripped = template:gsub("%%[%-%+%d%.%$]*[sdfioxXcug]", "")
    stripped = stripped:gsub("%s+", "")
    return stripped
end

local function prettifyTemplate(template)
    if not template then return template end
    return (template:gsub("%%[%-%+%d%.%$]*[sdfioxXcug]", "…"))
end

local function normalizeMessage(messageType, message)
    local template = getTemplateForType(messageType)
    if template and templateLiteral(template) ~= "" then
        return prettifyTemplate(template)
    end
    return message
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
    local data = module.data
    local alertDB = data.errorAlerts[key]
    if not alertDB then
        alertDB = alert:getDefaultDBRecursive()
        data.errorAlerts[key] = alertDB
    end
    alert:setDB(alertDB)
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
                if text and templateLiteral(text) ~= "" then
                    local pretty = prettifyTemplate(text)
                    prefilledLabels[makeKey(value, pretty)] = pretty
                end
            end
        end
    end
    return prefilledLabels
end

function module.onMessage(frame, message, r, g, b, alpha, messageType)
    if not messageType or not module.data then
        baseAlert:fire({ text = message })
        return
    end
    local data = module.data
    local normalized = normalizeMessage(messageType, message)
    local key = makeKey(messageType, normalized)
    if not data.errorLabels[key] then
        data.errorLabels[key] = normalized
    end
    local alert = getOrCreateAlert(key, data.errorLabels[key])
    alert:fire({ text = message, messageType = messageType })
end

function module.onFlash(frame, fontString)
    baseAlert:fire({ text = fontString:GetText() })
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
    local seen = data.errorLabels
    local source = seen
    if showAll then
        source = {}
        for id, lbl in pairs(getPrefilledLabels()) do
            source[id] = lbl
        end
        for id, lbl in pairs(seen) do
            source[id] = lbl
        end
    end

    local entries = {}
    for id, label in pairs(source) do
        tinsert(entries, { id = id, label = label })
    end
    table.sort(entries, function(a, b)
        return (a.label or "") < (b.label or "")
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

settings:addRef("filter", {
    label = L["Per-Error Filter"],
    getGenerator = function(self)
        return buildList(false)
    end,
})
