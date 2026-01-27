local module = WowVision.base.windows:createModule("questWindow")
local L = module.L
module:setLabel(L["Quest Window"])
local gen = module:hasUI()

local function getWindowTitle()
    if QuestFrameNpcNameText then
        return QuestFrameNpcNameText:GetText()
    end
    return QuestFrame:GetTitleText():GetText()
end

gen:Element("QuestWindow", function(props)
    local result = { "Panel", label = getWindowTitle(), wrap = true, children = {} }

    -- Check if greeting panel is shown (NPC with only quests, no other gossip)
    if QuestFrameGreetingPanel and QuestFrameGreetingPanel:IsShown() then
        tinsert(result.children, { "QuestWindow/greeting" })
    end

    if QuestFrameDetailPanel:IsShown() then
        tinsert(result.children, { "QuestWindow/detail", frame = QuestFrameDetailPanel })
    end
    if QuestFrameProgressPanel:IsShown() then
        tinsert(result.children, { "QuestWindow/progress", frame = QuestFrameProgressPanel })
    end
    if QuestFrameRewardPanel:IsShown() then
        tinsert(result.children, { "QuestWindow/reward", frame = QuestFrameRewardPanel })
    end
    return result
end)

gen:Element("QuestWindow/greeting", function(props)
    local result = { "Panel", label = L["Quests"], wrap = true, children = {} }

    -- Greeting text
    if GreetingText and GreetingText:IsShown() then
        local greetingContent = GreetingText:GetText()
        if greetingContent and greetingContent ~= "" then
            tinsert(result.children, { "Text", text = greetingContent })
        end
    end

    -- Add quest buttons in a flat list like gossip window
    for i = 1, 25 do
        local button = _G["QuestTitleButton" .. i]
        if button and button:IsShown() then
            local questTitle = button:GetText() or ""
            local label
            if button.isActive == 1 then
                label = L["Accepted Quest"] .. ": " .. questTitle
            else
                label = L["Available Quest"] .. ": " .. questTitle
            end
            tinsert(result.children, { "ProxyButton", frame = button, label = label })
        end
    end

    -- Goodbye button
    tinsert(result.children, { "ProxyButton", frame = QuestFrameGreetingGoodbyeButton })

    return result
end)

gen:Element("QuestWindow/detail", function(props)
    local result = { "Panel", label = L["Details"], wrap = true, children = {} }
    local text = { "List", shouldAnnounce = false, children = {} }

    -- Quest name
    if QuestInfoTitleHeader and QuestInfoTitleHeader:IsShown() then
        local titleText = QuestInfoTitleHeader:GetText()
        if titleText and titleText ~= "" then
            tinsert(text.children, { "Text", key = "title", text = titleText })
        end
    end

    -- Quest description
    if QuestInfoDescriptionText and QuestInfoDescriptionText:IsShown() then
        local descText = QuestInfoDescriptionText:GetText()
        if descText and descText ~= "" then
            tinsert(text.children, { "Text", key = "description", text = descText })
        end
    end

    -- Objectives header (requirements label)
    if QuestInfoObjectivesHeader and QuestInfoObjectivesHeader:IsShown() then
        local headerText = QuestInfoObjectivesHeader:GetText()
        if headerText and headerText ~= "" then
            tinsert(text.children, { "Text", key = "objectivesHeader", text = headerText })
        end
    end

    -- Objectives text (actual requirements)
    if QuestInfoObjectivesText and QuestInfoObjectivesText:IsShown() then
        local objText = QuestInfoObjectivesText:GetText()
        if objText and objText ~= "" then
            tinsert(text.children, { "Text", key = "objectives", text = objText })
        end
    end

    tinsert(result.children, text)
    tinsert(result.children, { "ProxyButton", frame = QuestFrameAcceptButton })
    tinsert(result.children, { "ProxyButton", frame = QuestFrameDeclineButton })
    return result
end)

gen:Element("QuestWindow/progress", function(props)
    local text = {
        "List",
        shouldAnnounce = false,
        children = {
            { "Text", text = QuestProgressTitleText:GetText() },
            { "Text", text = QuestProgressText:GetText() },
            { "QuestWindow/progress/items", frame = QuestProgressScrollChildFrame },
        },
    }
    local result = {
        "Panel",
        label = L["Progress"],
        wrap = true,
        children = {
            text,
            { "ProxyButton", frame = QuestFrameCompleteButton },
            { "ProxyButton", frame = QuestFrameGoodbyeButton },
        },
    }
    return result
end)

local function getItemLabel(item)
    local label = item.Name:GetText() or "it broke"
    if item.Count:IsShown() then
        label = label .. " x " .. (item.Count:GetText() or "count broke")
    end
    return label
end

gen:Element("QuestWindow/progress/items", function(props)
    if not props.frame or not props.frame:IsShown() or not props.frame:IsVisible() then
        return nil
    end

    local text = QuestProgressRequiredItemsText
    if not text:IsShown() then
        return nil
    end
    local result = { "List", label = text:GetText(), children = {} }
    local children = { props.frame:GetChildren() }
    for i = 2, #children do
        local item = children[i]
        if item:IsShown() then
            tinsert(result.children, { "Text", text = getItemLabel(item) })
        end
    end
    return result
end)

gen:Element("QuestWindow/item", function(props)
    if not props.frame or not props.frame:IsShown() or not props.frame:IsVisible() then
        return nil
    end
    if not props.frame.Name:GetText() then
        return nil
    end

    return { "ProxyButton", frame = props.frame, label = getItemLabel(props.frame) }
end)

gen:Element("QuestWindow/reward/rewards", function(props)
    local result = { "Panel", shouldAnnounce = false, children = {} }
    local choiceButtons = {}
    local rewardButtons = {}
    for _, button in ipairs(props.frame.RewardButtons) do
        if button.type == "reward" then
            tinsert(rewardButtons, button)
        elseif button.type == "choice" then
            tinsert(choiceButtons, button)
        end
    end

    if #choiceButtons > 0 then
        local choiceList = { "List", label = props.frame.ItemChooseText:GetText(), children = {} }
        for _, button in ipairs(choiceButtons) do
            tinsert(choiceList.children, { "QuestWindow/item", frame = button })
        end
        tinsert(result.children, choiceList)
    end

    local rewardList = { "List", label = props.frame.ItemReceiveText:GetText(), children = {} }

    for _, button in ipairs(rewardButtons) do
        tinsert(rewardList.children, { "QuestWindow/item", frame = button })
    end

    if props.frame.MoneyFrame:IsShown() and props.frame.MoneyFrame.staticMoney then
        tinsert(rewardList.children, {
            "Text",
            text = C_CurrencyInfo.GetCoinText(props.frame.MoneyFrame.staticMoney),
        })
    end

    local frame = props.frame.XPFrame
    if frame:IsShown() and frame:IsVisible() then
        tinsert(rewardList.children, {
            "Text",
            text = frame.ReceiveText:GetText() .. " " .. frame.ValueText:GetText(),
        })
    end
    tinsert(result.children, rewardList)

    return result
end)

gen:Element("QuestWindow/reward", function(props)
    local text = {
        "List",
        shouldAnnounce = false,
        children = {
            { "Text", text = QuestInfoTitleHeader:GetText() },
            { "Text", text = QuestInfoRewardText:GetText() },
        },
    }
    local result = {
        "Panel",
        label = L["Reward"],
        wrap = true,
        children = {
            text,
            { "QuestWindow/reward/rewards", frame = QuestInfoRewardsFrame },
            { "ProxyButton", frame = QuestFrameCompleteQuestButton },
            { "ProxyButton", frame = QuestFrameCancelButton },
        },
    }
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "questWindow",
    generated = true,
    rootElement = "QuestWindow",
    frameName = "QuestFrame",
    conflictingAddons = { "Sku" },
})
