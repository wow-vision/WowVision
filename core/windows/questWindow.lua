local module = WowVision.base.windows:createModule("questWindow")
local L = module.L
module:setLabel(L["Quest Window"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The NPC quest window: greeting, detail, progress, and reward panels of
-- QuestFrame, whichever is shown. Each panel's content (header, text,
-- objectives, rewards) is one vertical list in a single tab stop; the action
-- buttons follow as their own stops. Panel content lives in plain
-- ScrollFrames, so nodes scroll the real viewport as focus moves; item
-- rewards are real buttons (choosing a reward is a genuine click).

-- One line of panel content, added into the current stop.
local function contentText(builder, id, region, scrollFrame)
    if region == nil or not region:IsShown() then
        return
    end
    local text = region:GetText()
    if text == nil or text == "" then
        return
    end
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

-- An action button as its own tab stop.
local function actionButton(builder, button, scrollFrame, label)
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

-- A vertical list of quest item buttons under a context, within the current
-- stop.
local function itemList(builder, key, contextLabel, buttons, scrollFrame)
    if #buttons == 0 then
        return
    end
    builder:pushContext(key, contextLabel or "")
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
    builder:popContext()
end

-- The rewards block (choices, received items, money, experience), shared by
-- the detail preview and the reward panel. Adds into the current stop.
local function rewardsContent(builder, scrollFrame)
    local rewards = QuestInfoRewardsFrame
    if rewards == nil or not rewards:IsShown() or not rewards:IsVisible() then
        return
    end
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
    itemList(
        builder,
        "choices",
        rewards.ItemChooseText ~= nil and rewards.ItemChooseText:GetText() or nil,
        choiceButtons,
        scrollFrame
    )
    itemList(
        builder,
        "received",
        rewards.ItemReceiveText ~= nil and rewards.ItemReceiveText:GetText() or nil,
        rewardButtons,
        scrollFrame
    )

    if rewards.MoneyFrame ~= nil and rewards.MoneyFrame:IsShown() and rewards.MoneyFrame.staticMoney then
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

local function renderGreeting(builder)
    local scrollFrame = QuestGreetingScrollFrame
    builder:beginStop()
    if GreetingText ~= nil and GreetingText:IsShown() then
        contentText(builder, ControlId.structural("greetingText"), GreetingText, scrollFrame)
    end
    builder:pushContext("greetingQuests", L["Quests"])
    for i = 1, 32 do
        local button = _G["QuestTitleButton" .. i]
        if button ~= nil and button:IsShown() then
            local captured = button
            builder:beginStop()
            local vtable = nodes.proxyButton({
                target = captured,
                label = function()
                    local title = captured:GetText() or ""
                    if captured.isActive == 1 then
                        return L["Accepted Quest"] .. ": " .. title
                    end
                    return L["Available Quest"] .. ": " .. title
                end,
            })
            nodes.attachScrollFrame(vtable, scrollFrame, captured)
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    builder:popContext()
    actionButton(builder, QuestFrameGreetingGoodbyeButton)
end

local function renderDetail(builder)
    local scrollFrame = QuestDetailScrollFrame
    builder:beginStop()
    builder:pushContext("details", L["Details"])
    contentText(builder, ControlId.structural("title"), QuestInfoTitleHeader, scrollFrame)
    contentText(builder, ControlId.structural("description"), QuestInfoDescriptionText, scrollFrame)
    contentText(builder, ControlId.structural("objectivesHeader"), QuestInfoObjectivesHeader, scrollFrame)
    contentText(builder, ControlId.structural("objectives"), QuestInfoObjectivesText, scrollFrame)
    rewardsContent(builder, scrollFrame)
    builder:popContext()
    actionButton(builder, QuestFrameAcceptButton)
    actionButton(builder, QuestFrameDeclineButton)
end

local function renderProgress(builder)
    local scrollFrame = QuestProgressScrollFrame
    builder:beginStop()
    builder:pushContext("progress", L["Progress"])
    contentText(builder, ControlId.structural("progressTitle"), QuestProgressTitleText, scrollFrame)
    contentText(builder, ControlId.structural("progressText"), QuestProgressText, scrollFrame)

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
        itemList(builder, "required", QuestProgressRequiredItemsText:GetText(), items, scrollFrame)
    end
    builder:popContext()

    actionButton(builder, QuestFrameCompleteButton)
    actionButton(builder, QuestFrameGoodbyeButton)
end

local function renderReward(builder)
    local scrollFrame = QuestRewardScrollFrame
    builder:beginStop()
    builder:pushContext("reward", L["Reward"])
    contentText(builder, ControlId.structural("rewardTitle"), QuestInfoTitleHeader, scrollFrame)
    contentText(builder, ControlId.structural("rewardText"), QuestInfoRewardText, scrollFrame)
    rewardsContent(builder, scrollFrame)
    builder:popContext()

    actionButton(builder, QuestFrameCompleteQuestButton)
    actionButton(builder, QuestFrameCancelButton)
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
    builder:pushContext("questWindow", getWindowTitle() or L["Quest Window"])

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
