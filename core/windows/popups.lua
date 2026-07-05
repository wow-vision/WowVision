local module = WowVision.base.windows:createModule("popups")
local L = module.L
module:setLabel(L["Popups"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The four StaticPopup dialogs, each its own window (simultaneous popups are
-- separate stacks; ctrl-tab moves between them). Text is live: countdown
-- popups rewrite it in place. Edit boxes are the real ones -- Enter on the
-- node hands them keyboard focus, and the popup's own handlers take Enter
-- and Escape from there.

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

local function makeRender(frame)
    return function(builder, screen)
        if frame == nil or not frame:IsShown() then
            return
        end
        builder:pushContext(L["Popup"])

        local text = getPopupText(frame)
        if text ~= nil and text:IsShown() then
            builder:beginStop()
            builder:addItem(
                ControlId.structural("text"),
                nodes.text({
                    label = function()
                        return text:GetText()
                    end,
                    live = "focus",
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
end

--Don't show popups if sku is enabled since Sku handles them
--There are 4 StaticPopup frames; each gets a window opening a graph stack
--when its frame shows.
for i = 1, 4 do
    local frameName = "StaticPopup" .. i
    module:registerWindow({
        type = "FrameWindow",
        name = frameName,
        frameName = frameName,
        conflictingAddons = { "Sku" },
        graphScreen = {
            render = function(builder, screen)
                local frame = _G[frameName]
                makeRender(frame)(builder, screen)
            end,
        },
    })
end
