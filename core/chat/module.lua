local module = WowVision.base:createModule("chat")
local L = module.L
module:setLabel(L["Chat"])
local settings = module:hasSettings()
local chatTabs = WowVision.chatTabs

local speakChoices = {
    { value = "shown", label = L["When the Tab Is Shown"] },
    { value = "always", label = L["Always"] },
}

-- The message alert of one chat tab (or of all whisper tabs): what the tab
-- receives is the game's choice, how it sounds is this alert's.
local function addMessageAlert(key, label, speakDefault)
    local alert = module:addAlert({
        key = key,
        label = label,
    })
    alert:addOutput({
        type = "TTS",
        key = "tts",
        label = L["TTS Alert"],
        buildMessage = function(self, message)
            return message.message
        end,
    })
    alert:addOutput({
        type = "Sound",
        key = "sound",
        label = L["Sound Alert"],
        path = "Sound/WowVision/alerts/chat.mp3",
    })
    alert.parameters:add({
        key = "speak",
        type = "Choice",
        label = L["Speak Messages"],
        choices = speakChoices,
        default = speakDefault,
    })
    return alert
end

-- One alert per permanent chat window. The first keeps the key of the single
-- chat alert there used to be, so its settings carry over.
local tabAlerts = {}
for index = 1, chatTabs.MAX_WINDOWS do
    local key = index == 1 and "message" or ("tab" .. index)
    tabAlerts[index] = addMessageAlert(key, L["Message Alert"], "shown")
end

-- Whisper tabs come and go with conversations; they share one alert. They
-- speak always by default: in the game's "popout" whisper mode the whisper
-- leaves every other tab, so a tab that waits to be shown would never say it.
local whisperAlert = addMessageAlert("whisperTabs", L["Whisper Tabs"], "always")

-- The game's chat box (where messages are typed) taking and losing keyboard
-- focus. Focus rather than visibility: in the classic chat style the box
-- stays on screen while idle.
local editBoxOpenAlert = module:addAlert({
    key = "editBoxOpen",
    label = L["Chat Box Opened"],
})
editBoxOpenAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    path = "Sound/WowVision/alerts/chatbox_open.mp3",
})
settings:addRef("editBoxOpenAlert", editBoxOpenAlert.parameters)

local editBoxCloseAlert = module:addAlert({
    key = "editBoxClose",
    label = L["Chat Box Closed"],
})
editBoxCloseAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    path = "Sound/WowVision/alerts/chatbox_close.mp3",
})
settings:addRef("editBoxCloseAlert", editBoxCloseAlert.parameters)

-- Script hooks cannot be removed, so each box is hooked once and the
-- handlers check the module state themselves.
local hookedEditBoxes = {}
local function hookEditBox(frame)
    local editBox = frame.editBox or _G[frame:GetName() .. "EditBox"]
    if editBox == nil or hookedEditBoxes[editBox] then
        return
    end
    hookedEditBoxes[editBox] = true
    editBox:HookScript("OnEditFocusGained", function()
        if module:getEnabled() then
            editBoxOpenAlert:fire({})
        end
    end)
    editBox:HookScript("OnEditFocusLost", function()
        if module:getEnabled() then
            editBoxCloseAlert:fire({})
        end
    end)
end

function module:getDefaultData()
    return {
        frames = {},
        whispers = { history = {} },
    }
end

function module.getMessageString(data)
    return data.message .. " " .. data.datetime
end

-- Stores live as long as the session: a tab closed and opened again (or a
-- temporary window reused for another conversation) refills the same one.
local function ensureStore(key, messages)
    local store = WowVision.getMessageStore(key)
    if store == nil then
        store = WowVision.createMessageStore(key, {
            messages = messages,
            maxMessages = 5000,
            getDataString = module.getMessageString,
        })
    end
    return store
end

local buffersByKey = {}
local function bufferFor(key)
    local buffer = buffersByKey[key]
    if buffer == nil then
        buffer = WowVision.buffers:create("Message", { sourceKey = key })
        buffersByKey[key] = buffer
    end
    return buffer
end

local claims = chatTabs.newClaims()

-- Which alert speaks for a tab. A temporary window can change what it is
-- for (the game reuses closed ones), so this runs again when it does.
local function classify(ref)
    local frame = ref.frame
    if frame.isTemporary then
        ref.whisper = chatTabs.isWhisperWindow(frame)
        -- The pet battle log has no alert of its own: it is read, not spoken.
        ref.alert = ref.whisper and whisperAlert or nil
    else
        ref.whisper = false
        ref.alert = tabAlerts[frame:GetID()]
    end
end

function module.onMessage(frame, message, r, g, b, typeID, accessID, lineTypeID, event, eventArgs)
    local ref = module.frames ~= nil and module.frames[frame:GetID()] or nil
    if ref == nil then
        return
    end
    local chatType = nil
    if typeID then
        chatType = C_ChatInfo.GetChatTypeName(typeID)
    end
    local data = {
        message = message,
        chatType = chatType,
        datetime = date("%m/%d/%y %H:%M:%S"),
    }
    ref.store:add(data)
    -- Lines already in a tab when it is picked up, or copied in as the game
    -- opens a whisper tab, were heard (or missed) before: keep them quiet.
    if ref.silent then
        return
    end
    if ref.whisper then
        module.whisperStore:add(data)
    end
    local alert = ref.alert
    if alert == nil or not alert.enabled then
        return
    end
    if not chatTabs.shouldSpeak(alert.parameters:getFieldValue("speak"), frame:IsShown()) then
        return
    end
    local key = chatTabs.lineKey(eventArgs, message)
    if key ~= nil and not claims:claim(key, GetTime(), frame) then
        return
    end
    alert:fire(data)
end

function module:onDisable()
    for _, ref in pairs(self.frames or {}) do
        WowVision.UIHost:unhookFunc(ref.frame, "AddMessage", self.onMessage)
    end
    self.frames = {}
end

function module:addFrame(frame, index)
    local storeKey = chatTabs.storeKey(index)
    local store
    if frame.isTemporary then
        -- Temporary windows are not saved: the game numbers them by reuse,
        -- not by conversation. Their lines persist in the whisper store.
        store = ensureStore(storeKey, {})
        store:clear()
    else
        local existing = WowVision.getMessageStore(storeKey)
        local data = self.data[index]
        if not data then
            -- A window opened again reuses its emptied store's table.
            data = { history = existing ~= nil and existing.messages or {} }
            self.data[index] = data
        end
        store = ensureStore(storeKey, data.history)
    end
    local ref = {
        frame = frame,
        exists = true,
        store = store,
        storeKey = storeKey,
        buffer = bufferFor(storeKey),
    }
    classify(ref)
    WowVision.UIHost:hookFunc(frame, "AddMessage", self.onMessage)
    hookEditBox(frame)
    self.frames[index] = ref

    -- Add any messages in the frame before it was registered
    ref.silent = true
    for i = 1, frame:GetNumMessages() do
        local message, r, g, b, id = frame:GetMessageInfo(i)
        self.onMessage(frame, message, r, g, b, id)
    end
    ref.silent = false
    return ref
end

function module:removeFrame(frame, index)
    local ref = self.frames[index]
    WowVision.UIHost:unhookFunc(ref.frame, "AddMessage", self.onMessage)
    ref.store:clear()
    self.frames[index] = nil
    if not frame.isTemporary then
        self.data[index] = nil
    end
end

function module:runCompareFrames(frame, i)
    local ref = self.frames[i]
    local validFrame = FCF_IsValidChatFrame(frame)
    if not ref and validFrame then
        self:addFrame(frame, i)
        return
    end
    if ref and not validFrame then
        self:removeFrame(frame, i)
    end
end

-- The game opening a whisper tab: the first whisper arrives right after, in
-- the same call stack, before the next tick could pick the window up. So it
-- is picked up here, as the game sets the window's conversation (a reused
-- window starts empty); the lines the game then copies in from the source
-- tab stay quiet until it is done.
local copying = nil

function module:onTemporaryWindow(frame)
    local index = frame:GetID()
    local ref = self.frames[index]
    if ref == nil then
        ref = self:addFrame(frame, index)
    else
        ref.store:clear()
        classify(ref)
    end
    ref.silent = true
    copying = ref
end

function module:onTemporaryWindowOpened()
    if copying ~= nil then
        copying.silent = false
        copying = nil
    end
end

local temporaryHooked = false
local function hookTemporaryWindows()
    if temporaryHooked then
        return
    end
    temporaryHooked = true
    if FCF_SetTemporaryWindowType ~= nil then
        hooksecurefunc("FCF_SetTemporaryWindowType", function(frame)
            if module:getEnabled() and module.frames ~= nil then
                module:onTemporaryWindow(frame)
            end
        end)
    end
    if FCF_OpenTemporaryWindow ~= nil then
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            if module:getEnabled() and module.frames ~= nil then
                module:onTemporaryWindowOpened()
            end
        end)
    end
end

-- The tabs in the order the game shows them: the docked tabs left to right,
-- then the windows standing on their own.
function module:orderedFrames()
    local result = {}
    local seen = {}
    local frames = self.frames or {}
    if GENERAL_CHAT_DOCK ~= nil and FCFDock_GetChatFrames ~= nil then
        for _, frame in ipairs(FCFDock_GetChatFrames(GENERAL_CHAT_DOCK) or {}) do
            if frames[frame:GetID()] ~= nil then
                seen[frame] = true
                tinsert(result, frame)
            end
        end
    end
    local rest = {}
    for index, ref in pairs(frames) do
        if not seen[ref.frame] then
            tinsert(rest, index)
        end
    end
    table.sort(rest)
    for _, index in ipairs(rest) do
        tinsert(result, frames[index].frame)
    end
    return result
end

-- Settings: one entry per open tab, named as the game names it, then the
-- whisper tabs.
local function alertButton(alert, label)
    return WowVision.graph.nodes.button({
        label = label,
        onActivate = function()
            alert.parameters.label = label
            WowVision.graph.settings.pushScreen("settings:chatAlert:" .. alert.key, function(builder)
                WowVision.graph.settings.renderInto(builder, alert.parameters)
            end)
        end,
    })
end

function module:getGraphMenuItems(builder)
    local ControlId = WowVision.graph.ControlId
    for _, frame in ipairs(self:orderedFrames()) do
        local index = frame:GetID()
        if not frame.isTemporary and tabAlerts[index] ~= nil then
            local label = chatTabs.tabLabel(index)
            builder:addItem(ControlId.structural("tabAlert:" .. index), alertButton(tabAlerts[index], label))
        end
    end
    builder:addItem(ControlId.structural("whisperTabsAlert"), alertButton(whisperAlert, L["Whisper Tabs"]))
end

function module:onEnable()
    self.frames = {}
    self.whisperStore = ensureStore(chatTabs.WHISPERS_KEY, self.data.whispers.history)
    hookTemporaryWindows()
    self:hasUpdate(function(self)
        -- Opening finished within its own call; a tick later nothing is
        -- being copied any more, whatever happened in between.
        self:onTemporaryWindowOpened()
        for i = 1, chatTabs.MAX_WINDOWS do
            local frame = _G["ChatFrame" .. i]
            if frame ~= nil then
                self:runCompareFrames(frame, i)
            end
        end
        for _, frameName in ipairs(CHAT_FRAMES or {}) do
            local frame = _G[frameName]
            if frame ~= nil and frame.isTemporary then
                self:runCompareFrames(frame, frame:GetID())
            end
        end
    end)
end
