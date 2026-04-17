local module = WowVision.base:createModule("errors")
local L = module.L
module:setLabel(L["Errors"])
local settings = module:hasSettings()

local alert = module:addAlert({
    key = "announce",
    label = L["Announce Errors"],
})

alert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    shouldFire = function(self, message)
        return message.config.tts
    end,
    buildMessage = function(self, message)
        return message.text
    end,
})

alert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    shouldFire = function(self, message)
        return message.config.sound and message.config.soundPath ~= nil
    end,
    getPath = function(self, message)
        return message.config.soundPath
    end,
})

settings:addRef("announce", alert.parameters)

local FALLBACK_CONFIG = { tts = true, sound = false }

local function defaultConfig()
    return { tts = true, sound = false, soundPath = nil }
end

function module:getDefaultData()
    return {
        errorLabels = {},
        errorConfigs = {},
    }
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
                if text then
                    prefilledLabels[value] = text
                end
            end
        end
    end
    return prefilledLabels
end

function module.onMessage(frame, message, r, g, b, alpha, messageType)
    if not messageType or not module.data then
        alert:fire({ text = message, messageType = messageType, config = FALLBACK_CONFIG })
        return
    end
    local data = module.data
    if not data.errorLabels[messageType] then
        data.errorLabels[messageType] = message
    end
    local config = data.errorConfigs[messageType]
    if not config then
        config = defaultConfig()
        data.errorConfigs[messageType] = config
    end
    alert:fire({ text = message, messageType = messageType, config = config })
end

function module.onFlash(frame, fontString)
    alert:fire({
        text = fontString:GetText(),
        messageType = nil,
        config = FALLBACK_CONFIG,
    })
end

function module:onEnable()
    WowVision.UIHost:hookFunc(UIErrorsFrame, "AddMessage", self.onMessage)
    WowVision.UIHost:hookFunc(UIErrorsFrame, "FlashFontString", self.onFlash)
end

function module:onDisable()
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "AddMessage", self.onMessage)
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "FlashFontString", self.onFlash)
end

local function buildItemEditor(messageType, label)
    local data = module.data
    local config = data.errorConfigs[messageType]
    if not config then
        config = defaultConfig()
        data.errorConfigs[messageType] = config
    end

    return {
        "List",
        label = label,
        children = {
            {
                "Checkbox",
                key = "tts",
                label = L["TTS Alert"],
                bind = { type = "Property", target = config, property = "tts" },
            },
            {
                "Checkbox",
                key = "sound",
                label = L["Sound Alert"],
                bind = { type = "Property", target = config, property = "sound" },
            },
            {
                "Button",
                key = "soundPath",
                label = L["Sound"],
                extras = config.soundPath or L["None"],
                events = {
                    click = function(event, button)
                        local browseContext = WowVision.ui:CreateElement("DataBrowseContext", {
                            directory = WowVision.audio.directory,
                        })
                        browseContext.events.confirm:subscribe(nil, function(event, context, source, path)
                            config.soundPath = path
                            button.context:pop()
                        end)
                        browseContext.events.cancel:subscribe(nil, function(event, context)
                            button.context:pop()
                        end)
                        button.context:add(browseContext)
                    end,
                },
            },
        },
    }
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
                    button.context:addGenerated(buildItemEditor(id, label))
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
