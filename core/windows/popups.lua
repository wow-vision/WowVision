local module = WowVision.base.windows:createModule("popups")
local L = module.L
module:setLabel(L["Popups"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- StaticPopup dialogs. Modern clients pool them (StaticPopup_ForEachShownDialog
-- is the authority on what is shown); older clients keep the numbered frames.
-- One window renders every shown dialog: each dialog is a context holding its
-- text (live: countdown popups rewrite it in place), its edit box when
-- present (the real one -- Enter hands it keyboard focus and the popup's own
-- handlers take Enter and Escape from there), and its buttons as stops.

local function forEachShownDialog(func)
    if StaticPopup_ForEachShownDialog ~= nil then
        StaticPopup_ForEachShownDialog(func)
        return
    end
    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local frame = _G["StaticPopup" .. i]
        if frame ~= nil and frame:IsShown() then
            func(frame)
        end
    end
end

local function getPopupText(frame)
    if frame.GetTextFontString ~= nil then
        return frame:GetTextFontString()
    end
    return frame.text
end

local function getPopupEditBox(frame)
    if frame.GetEditBox ~= nil then
        return frame:GetEditBox()
    end
    return frame.editBox
end

local function getPopupButtons(frame)
    if frame.GetButtons ~= nil then
        return frame:GetButtons()
    end
    local buttons = {}
    for i = 1, frame.numButtons or 0 do
        local button = _G[frame:GetName() .. "Button" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function renderDialog(builder, frame, index)
    local contextKey = "popup:" .. tostring(frame.which or index)
    builder:pushContext(contextKey, L["Popup"])

    local text = getPopupText(frame)
    if text ~= nil and text:IsShown() then
        builder:beginStop()
        builder:addItem(
            ControlId.structural(contextKey .. ":text"),
            nodes.text({
                label = function()
                    return text:GetText()
                end,
            })
        )
    end

    local editBox = getPopupEditBox(frame)
    if editBox ~= nil and editBox:IsShown() then
        builder:beginStop()
        builder:addItem(
            ControlId.forObject(editBox),
            nodes.button({
                label = function()
                    if editBox.Instructions ~= nil then
                        return editBox.Instructions:GetText()
                    end
                    return nil
                end,
                value = function()
                    return editBox:GetText()
                end,
                onActivate = function()
                    editBox:SetFocus()
                end,
            })
        )
    end

    for _, button in ipairs(getPopupButtons(frame)) do
        if button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

local function render(builder, screen)
    local index = 0
    forEachShownDialog(function(frame)
        index = index + 1
        renderDialog(builder, frame, index)
    end)
end

module:registerWindow({
    type = "CustomWindow",
    name = "popups",
    isOpen = function(self)
        local any = false
        forEachShownDialog(function()
            any = true
        end)
        return any
    end,
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
