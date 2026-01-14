local module = WowVision.base.windows:createModule("QuestChoice")
local L = module.L
module:setLabel(L["Quest Choice"])
local gen = module:hasUI()

gen:Element("QuestChoice", function(props)
    local frame = props.frame
    local result = {
        "Panel",
        label = L["Quest Choice"],
        wrap = true,
        children = {
            { "Text", text = frame.QuestionText:GetText() },
            { "QuestChoice/Options", frame = frame },
            { "ProxyButton", frame = frame.CloseButton, label = L["Close"] },
        },
    }
    return result
end)

gen:Element("QuestChoice/Options", function(props)
    local frame = props.frame
    local choiceID, questionText, numOptions = C_QuestChoice.GetQuestChoiceInfo()
    local result = { "Panel", layout = true, shouldAnnounce = false, children = {} }
    for i = 1, numOptions do
        local optionFrame = frame["Option" .. i]
        if optionFrame then
            tinsert(result.children, { "QuestChoice/Option", frame = optionFrame })
        end
    end
    return result
end)

gen:Element("QuestChoice/Option", function(props)
    local frame = props.frame
    return {
        "List",
        children = {
            { "Text", text = frame.OptionText:GetText() },
            { "QuestChoice/Rewards", frame = frame.Rewards },
            { "ProxyButton", frame = frame.OptionButton },
        },
    }
end)

gen:Element("QuestChoice/Rewards", function(props)
    local frame = props.frame
    return {
        "List",
        label = L["Rewards"],
        children = {
            { "QuestChoice/Rewards/ReputationsFrame", frame = frame.ReputationsFrame },
            { "QuestChoice/Rewards/Item", frame = frame.Item },
            { "QuestChoice/Rewards/Currencies", frame = frame.Currencies },
        },
    }
end)

gen:Element("QuestChoice/Rewards/ReputationsFrame", function(props)
    local frame = props.frame
    if not frame:IsVisible() then
        return nil
    end
    local result = { "List", layout = true, shouldAnnounce = false, children = {} }
    local children = { frame:GetChildren() }
    if #children == 0 then
        return nil
    end
    for _, child in ipairs(children) do
        local label = child.Faction:GetText() .. ": " .. child.Amount:GetText()
        tinsert(result.children, { "Text", text = label })
    end
    return result
end)

gen:Element("QuestChoice/Rewards/Item", function(props)
    local frame = props.frame
    if not frame:IsVisible() then
        return nil
    end
    local label = frame.Name:GetText()
    if frame.count then
        label = label .. " X" .. frame.count
    end
    return { "Text", text = label }
end)

gen:Element("QuestChoice/Rewards/Currencies", function(props)
    local frame = props.frame
    if not frame:IsVisible() then
        return nil
    end
    local children = { frame:GetChildren() }
    if #children == 0 then
        return nil
    end
    local result = { "List", layout = true, shouldAnnounce = false, children = {} }
    for _, child in ipairs(children) do
        local id = child.currencyID
        if id then
            local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(id)
            if currencyInfo then
                label = currencyInfo.name
                if child.Quantity:IsShown() then
                    label = label .. " x " .. child.Quantity:GetText()
                end
                tinsert(result.children, { "Text", text = label })
            end
        end
    end
    if #result.children > 0 then
        return result
    end
end)

module:registerWindow({
    type = "FrameWindow",
    name = "QuestChoice",
    generated = true,
    rootElement = "QuestChoice",
    frameName = "QuestChoiceFrame",
})
