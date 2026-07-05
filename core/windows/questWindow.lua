local module = WowVision.base.windows:createModule("questWindow")
local L = module.L
module:setLabel(L["Quest Window"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The NPC quest window: greeting, detail, progress, and reward panels of
-- QuestFrame, whichever is shown. Panel content lives in plain ScrollFrames,
-- so nodes scroll the real viewport into place as focus moves; item rewards
-- are real buttons (choosing a reward is a genuine click).

local function textNode(builder, id, region, scrollFrame)
    if region == nil or not region:IsShown() then
        return
    end
    local text = region:GetText()
    if text == nil or text == "" then
        return
    end
    builder:beginStop()
    local vtable = nodes.text({
        label = function()
            return region:GetText()
        end,
    })
    if scrollFrame ~= nil then
        nodes.attachScrollFrame(vtable, scrollFrame, region)
    end
    builder:addItem(id, vtable)
end

local function buttonNode(builder, button, scrollFrame, label)
    if button == nil or not button:IsShown() then
        return
    end
    builder:beginStop()
    local vtable = nodes.proxyButton({ target = button, label = label })
    if scrollFrame ~= nil then
        nodes.attachScrollFrame(vtable, scrollFrame, button)
    end
    builder:addItem(ControlId.forObject(button), vtable)
end

local function getItemLabel(item)
    local label = item.Name ~= nil and item.Name:GetText() or nil
    if label == nil then
        return nil
    end
    if item.Count ~= nil and item.Count:IsShown() then
        label = label .. " x " .. (item.Count:GetText() or "")
    end
    return label
end

-- A row of quest item buttons (choices or received rewards) under a context.
local function itemRow(builder, contextLabel, buttons, scrollFrame)
    if #buttons == 0 then
        return
    end
    builder:beginStop()
    builder:pushContext(contextLabel or "")
    builder:startRow()
    for _, button in ipairs(buttons) do
        local captured = button
        local vtable = nodes.proxyButton({
            target = captured,
            label = function()
                return getItemLabel(captured)
            end,
        })
        if scrollFrame ~= nil then
            nodes.attachScrollFrame(vtable, scrollFrame, captured)
        end
        builder:addItem(ControlId.forObject(captured), vtable)
    end
    builder:endRow()
    builder:popContext()
end

local function renderGreeting(builder)
    local scrollFrame = QuestGreetingScrollFrame
    if GreetingText ~= nil and GreetingText:IsShown() then
        textNode(builder, ControlId.structural("greetingText"), GreetingText, scrollFrame)
    end
    for i = 1, 32 do
        local button = _G["QuestTitleButton" .. i]
        if button ~= nil and button:IsShown() then
            local captured = button
            buttonNode(builder, captured, scrollFrame, function()
                local title = captured:GetText() or ""
                if captured.isActive == 1 then
                    return L["Accepted Quest"] .. ": " .. title
                end
                return L["Available Quest"] .. ": " .. title
            end)
        end
    end
    buttonNode(builder, QuestFrameGreetingGoodbyeButton)
end

local function renderDetail(builder)
    local scrollFrame = QuestDetailScrollFrame
    textNode(builder, ControlId.structural("title"), QuestInfoTitleHeader, scrollFrame)
    textNode(builder, ControlId.structural("description"), QuestInfoDescriptionText, scrollFrame)
    textNode(builder, ControlId.structural("objectivesHeader"), QuestInfoObjectivesHeader, scrollFrame)
    textNode(builder, ControlId.structural("objectives"), QuestInfoObjectivesText, scrollFrame)
    buttonNode(builder, QuestFrameAcceptButton)
    buttonNode(builder, QuestFrameDeclineButton)
end

local function renderProgress(builder)
    local scrollFrame = QuestProgressScrollFrame
    textNode(builder, ControlId.structural("progressTitle"), QuestProgressTitleText, scrollFrame)
    textNode(builder, ControlId.structural("progressText"), QuestProgressText, scrollFrame)

    if
        QuestProgressScrollChildFrame ~= nil
        and QuestProgressScrollChildFrame:IsVisible()
        and QuestProgressRequiredItemsText ~= nil
        and QuestProgressRequiredItemsText:IsShown()
    then
        local items = {}
        local children = { QuestProgressScrollChildFrame:GetChildren() }
        for i = 2, #children do
            local item = children[i]
            if item:IsShown() and getItemLabel(item) ~= nil then
                tinsert(items, item)
            end
        end
        itemRow(builder, QuestProgressRequiredItemsText:GetText(), items, scrollFrame)
    end

    buttonNode(builder, QuestFrameCompleteButton)
    buttonNode(builder, QuestFrameGoodbyeButton)
end

local function renderReward(builder)
    local scrollFrame = QuestRewardScrollFrame
    textNode(builder, ControlId.structural("rewardTitle"), QuestInfoTitleHeader, scrollFrame)
    textNode(builder, ControlId.structural("rewardText"), QuestInfoRewardText, scrollFrame)

    local rewards = QuestInfoRewardsFrame
    if rewards ~= nil and rewards:IsShown() then
        local choiceButtons = {}
        local rewardButtons = {}
        for _, button in ipairs(rewards.RewardButtons or {}) do
            if button:IsShown() and getItemLabel(button) ~= nil then
                if button.type == "choice" then
                    tinsert(choiceButtons, button)
                elseif button.type == "reward" then
                    tinsert(rewardButtons, button)
                end
            end
        end
        itemRow(
            builder,
            rewards.ItemChooseText ~= nil and rewards.ItemChooseText:GetText() or nil,
            choiceButtons,
            scrollFrame
        )
        itemRow(
            builder,
            rewards.ItemReceiveText ~= nil and rewards.ItemReceiveText:GetText() or nil,
            rewardButtons,
            scrollFrame
        )

        if rewards.MoneyFrame ~= nil and rewards.MoneyFrame:IsShown() and rewards.MoneyFrame.staticMoney then
            builder:beginStop()
            builder:addItem(
                ControlId.structural("money"),
                nodes.text({
                    label = function()
                        return C_CurrencyInfo.GetCoinText(rewards.MoneyFrame.staticMoney)
                    end,
                })
            )
        end
        local xp = rewards.XPFrame
        if xp ~= nil and xp:IsShown() and xp:IsVisible() then
            builder:beginStop()
            builder:addItem(
                ControlId.structural("xp"),
                nodes.text({
                    label = function()
                        return (xp.ReceiveText:GetText() or "") .. " " .. (xp.ValueText:GetText() or "")
                    end,
                })
            )
        end
    end

    buttonNode(builder, QuestFrameCompleteQuestButton)
    buttonNode(builder, QuestFrameCancelButton)
end

local function getWindowTitle()
    if QuestFrameNpcNameText ~= nil then
        return QuestFrameNpcNameText:GetText()
    end
    return QuestFrame:GetTitleText():GetText()
end

local function render(builder, screen)
    local frame = QuestFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext(getWindowTitle() or L["Quest Window"])

    if QuestFrameGreetingPanel ~= nil and QuestFrameGreetingPanel:IsShown() then
        renderGreeting(builder)
    end
    if QuestFrameDetailPanel ~= nil and QuestFrameDetailPanel:IsShown() then
        renderDetail(builder)
    end
    if QuestFrameProgressPanel ~= nil and QuestFrameProgressPanel:IsShown() then
        renderProgress(builder)
    end
    if QuestFrameRewardPanel ~= nil and QuestFrameRewardPanel:IsShown() then
        renderReward(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "questWindow",
    frameName = "QuestFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
