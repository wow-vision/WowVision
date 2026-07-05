local module = WowVision.base.windows:createModule("QuestChoice")
local L = module.L
module:setLabel(L["Quest Choice"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The quest choice dialog (pick one of several rewards): the question, then
-- each option as its own stop -- option text, its reputation, item, and
-- currency rewards, and the real choose button -- then close.

local function rewardTexts(builder, optionIndex, rewards)
    if rewards == nil then
        return
    end
    if rewards.ReputationsFrame ~= nil and rewards.ReputationsFrame:IsVisible() then
        for i, child in ipairs({ rewards.ReputationsFrame:GetChildren() }) do
            local captured = child
            builder:addItem(
                ControlId.structural("option:" .. optionIndex .. ":rep:" .. i),
                nodes.text({
                    label = function()
                        return (captured.Faction:GetText() or "") .. ": " .. (captured.Amount:GetText() or "")
                    end,
                })
            )
        end
    end
    if rewards.Item ~= nil and rewards.Item:IsVisible() then
        builder:addItem(
            ControlId.structural("option:" .. optionIndex .. ":item"),
            nodes.text({
                label = function()
                    local label = rewards.Item.Name:GetText() or ""
                    if rewards.Item.count then
                        label = label .. " x " .. rewards.Item.count
                    end
                    return label
                end,
            })
        )
    end
    if rewards.Currencies ~= nil and rewards.Currencies:IsVisible() then
        for i, child in ipairs({ rewards.Currencies:GetChildren() }) do
            local captured = child
            if captured.currencyID then
                builder:addItem(
                    ControlId.structural("option:" .. optionIndex .. ":currency:" .. i),
                    nodes.text({
                        label = function()
                            local info = C_CurrencyInfo.GetCurrencyInfo(captured.currencyID)
                            if info == nil then
                                return nil
                            end
                            local label = info.name
                            if captured.Quantity:IsShown() then
                                label = label .. " x " .. (captured.Quantity:GetText() or "")
                            end
                            return label
                        end,
                    })
                )
            end
        end
    end
end

local function render(builder, screen)
    local frame = QuestChoiceFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("questChoice", L["Quest Choice"])

    builder:beginStop("question")
    builder:addItem(
        ControlId.structural("question"),
        nodes.text({
            label = function()
                return frame.QuestionText:GetText()
            end,
        })
    )

    local _, _, numOptions = C_QuestChoice.GetQuestChoiceInfo()
    for i = 1, numOptions or 0 do
        local optionFrame = frame["Option" .. i]
        if optionFrame ~= nil and optionFrame:IsShown() then
            local optionIndex = i
            builder:beginStop("option:" .. i)
            builder:pushContext("option:" .. i, optionFrame.OptionText:GetText() or "")
            rewardTexts(builder, optionIndex, optionFrame.Rewards)
            builder:addItem(
                ControlId.forObject(optionFrame.OptionButton),
                nodes.proxyButton({ target = optionFrame.OptionButton })
            )
            builder:popContext()
        end
    end

    if frame.CloseButton ~= nil then
        builder:beginStop("close")
        builder:addItem(
            ControlId.forObject(frame.CloseButton),
            nodes.proxyButton({ target = frame.CloseButton, label = L["Close"] })
        )
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "QuestChoice",
    frameName = "QuestChoiceFrame",
    graphScreen = { render = render },
})
