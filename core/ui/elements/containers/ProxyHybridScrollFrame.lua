local gen = WowVision.ui.generator
local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")

local function ScrollButtonUp_Click(event, button)
    local frame = button.userdata
    DEFAULT_CHAT_FRAME.editBox:SetText("/run HybridScrollFrame_OnMouseWheel(" .. frame:GetName() .. ", 1)")
    ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end

local function ScrollButtonDown_Click(event, button)
    local frame = button.userdata
    DEFAULT_CHAT_FRAME.editBox:SetText("/run CastGlyph(4)")
    DEFAULT_CHAT_FRAME.editBox:Show()
    DEFAULT_CHAT_FRAME.editBox:SetFocus()
end

gen:Element("ProxyHybridScrollFrame", function(props)
    local result = {
        "List",
        label = props.label,
        children = {
            {
                "Button",
                label = L["Scroll Up"],
                userdata = props.frame,
                events = {
                    click = ScrollButtonUp_Click,
                },
            },
        },
    }
    for _, button in ipairs(props.frame.buttons) do
        tinsert(result.children, { "ProxyButton", frame = button })
    end
    tinsert(result.children, {
        "Button",
        label = L["Scroll Down"],
        userdata = props.frame,
        events = {
            click = ScrollButtonDown_Click,
        },
    })
    return result
end)
