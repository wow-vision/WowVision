local module = WowVision.base.windows:createModule("gossip")
local L = module.L
module:setLabel(L["Gossip"])
local gen = module:hasUI()

gen:Element("gossip", function(props)
    local npcName = UnitName("npc") or L["Gossip"]
    local result = {
        "Panel",
        label = npcName,
        wrap = true,
        children = {},
    }

    -- NPC greeting text
    local greetingText = C_GossipInfo.GetText()
    if greetingText and greetingText ~= "" then
        tinsert(result.children, {
            "Text",
            key = "greeting",
            text = greetingText,
        })
    end

    -- Gossip options (dialogue choices)
    local options = C_GossipInfo.GetOptions()
    for _, option in ipairs(options) do
        tinsert(result.children, {
            "Button",
            key = "option_" .. option.gossipOptionID,
            label = option.name,
            events = {
                click = function()
                    C_GossipInfo.SelectOption(option.gossipOptionID)
                end,
            },
        })
    end

    -- Available quests (quests the NPC can give)
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    for _, quest in ipairs(availableQuests) do
        tinsert(result.children, {
            "Button",
            key = "available_" .. quest.questID,
            label = L["Available Quest"] .. ": " .. quest.title,
            events = {
                click = function()
                    C_GossipInfo.SelectAvailableQuest(quest.questID)
                end,
            },
        })
    end

    -- Active quests (quests in progress with this NPC)
    local activeQuests = C_GossipInfo.GetActiveQuests()
    for _, quest in ipairs(activeQuests) do
        tinsert(result.children, {
            "Button",
            key = "active_" .. quest.questID,
            label = L["Accepted Quest"] .. ": " .. quest.title,
            events = {
                click = function()
                    C_GossipInfo.SelectActiveQuest(quest.questID)
                end,
            },
        })
    end

    -- Goodbye button
    tinsert(result.children, {
        "Button",
        key = "goodbye",
        label = L["Goodbye"],
        events = {
            click = function()
                C_GossipInfo.CloseGossip()
            end,
        },
    })

    return result
end)

module:registerWindow({
    type = "EventWindow",
    name = "gossip",
    generated = true,
    rootElement = "gossip",
    conflictingAddons = { "Sku" },
    openEvent = "GOSSIP_SHOW",
    closeEvent = "GOSSIP_CLOSED",
})
