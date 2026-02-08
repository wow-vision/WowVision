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

local function choiceButton_Click(event, button)
    button.context:pop()
end

local function dropdownButton_Click(event, button)
    button.context:addGenerated(button.userdata)
end

function VoicePackField:buildDropdown(obj)
    local field = self
    local result = { "List", label = self:getLabel() or L["Voice Pack"], children = {} }
    local voicePacks = WowVision.audio.packs:get("Voice")
    for _, v in ipairs(voicePacks.packs.items) do
        tinsert(result.children, {
            "Button",
            key = v.key,
            label = v:getLabel(),
            events = {
                click = function(event, button)
                    field:set(obj, v.key)
                    button.context:pop()
                end,
            },
        })
    end
    return result
end

function VoicePackField:getGenerator(obj)
    local field = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)
    return {
        "Button",
        label = label,
        extras = valueStr,
        userdata = self:buildDropdown(obj),
        events = {
            click = dropdownButton_Click,
        },
    }
end
