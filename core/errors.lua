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

function module:onEnable()
    WowVision.UIHost:hookFunc(UIErrorsFrame, "AddMessage", module.onMessage)
    WowVision.UIHost:hookFunc(UIErrorsFrame, "FlashFontString", module.onFlash)
end

function module:onDisable()
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "AddMessage", module.onMessage)
    WowVision.UIHost:unhookFunc(UIErrorsFrame, "FlashFontString", module.onFlash)
end
