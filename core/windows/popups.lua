local module = WowVision.base.windows:createModule("popups")
local L = module.L
module:setLabel(L["Popups"])
local gen = module:hasUI()

local function getPopupText(frame)
    if frame.GetTextFontString then
        return frame:GetTextFontString()
    end
    return frame.text
end

local function getPopupEditBox(frame)
    if frame.GetEditBox then
        return frame:GetEditBox()
    end
    return frame.editBox
end

local function getPopupButtons(frame)
    if frame.GetButtons then
        return frame:GetButtons()
    end
    local buttons = {}
    for i = 1, frame.numButtons do
        local button = _G[props.frame:GetName() .. "Button" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

--This describes the accessible elements that are created
gen:Element("StaticPopup", function(props)
    local frame = props.frame
    local result = { "Panel", label = L["Popup"], wrap = true, children = {} }
    local text = getPopupText(frame)
    if text and text:IsShown() then
        tinsert(result.children, { "Text", text = text:GetText() })
    end
    local editBox = getPopupEditBox(frame)
    if editBox:IsShown() then
        tinsert(
            result.children,
            { "ProxyEditBox", frame = editBox, fixAutoFocus = true, label = editBox.Instructions:GetText() }
        )
    end
    local buttons = getPopupButtons(frame)
    for i = 1, #buttons do
        local button = buttons[i]
        if button:IsShown() then
            tinsert(result.children, { "ProxyButton", frame = button })
        end
    end
    return result
end)

--Don't show popups if sku is enabled since Sku handles them
--There are 4 StaticPopup frames. Register a window to each; when the corresponding frame becomes shown, open a generated window with that frame attached.
for i = 1, 4 do
    module:registerWindow({
        name = "StaticPopup" .. i,
        auto = true, --Automatically open when frame is shown
        generated = true, --Use a generated descriptor as above
        rootElement = "StaticPopup", --Root path of the descriptor
        frameName = "StaticPopup" .. i, --The name of the Blizzard frame, IE StaticPopup1
        conflictingAddons = { "Sku" },
    })
end
