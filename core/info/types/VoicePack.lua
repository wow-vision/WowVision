local info = WowVision.info
local L = WowVision:getLocale()

local VoicePackField, parent = info:CreateFieldClass("VoicePack")

function VoicePackField:getValueString(obj, value)
    if value then
        local voicePacks = WowVision.audio.packs:get("Voice")
        local pack = voicePacks.packs:get(value)
        if pack then
            return pack:getLabel()
        end
    end
    return nil
end
