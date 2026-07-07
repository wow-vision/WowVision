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
})

settings:addRef("announce", alert.parameters)

function module.onMessage(frame, message, r, g, b, typeID)
    alert:fire({ text = message })
end

function module.onFlash(frame, message)
    alert:fire({ text = message:GetText() })
end

-- Lua script errors: the default error dialog is not accessible, so capture
-- them for TTS and a copyable window. /wv errors speaks the most recent error
-- and shows the full list with stacks; /wv errors clear resets it.
module.luaErrors = {}
local MAX_LUA_ERRORS = 20
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
    WowVision.UIHost:hookFunc(UIErrorsFrame, "AddMessage", module.onMessage)
    WowVision.UIHost:hookFunc(UIErrorsFrame, "FlashFontString", module.onFlash)
    previousHandler = geterrorhandler()
    seterrorhandler(onLuaError)
end

function module:onDisable()
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "AddMessage", module.onMessage)
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "FlashFontString", module.onFlash)
    if previousHandler then
        seterrorhandler(previousHandler)
        previousHandler = nil
    end
end
