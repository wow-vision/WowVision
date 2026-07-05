local module = WowVision.base.windows:createModule("gossip")
local L = module.L
module:setLabel(L["Gossip"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- NPC dialogue, fully data-driven through C_GossipInfo like the old screen:
-- greeting text, dialogue options, available and active quests, goodbye. One
-- tab stop per entry, matching the old tab-cycled panel.

local function addEntry(builder, id, vtable)
    builder:beginStop()
    builder:addItem(id, vtable)
end

local function render(builder, screen)
    local npcName = UnitName("npc") or L["Gossip"]
    builder:pushContext(npcName)

    local greetingText = C_GossipInfo.GetText()
    if greetingText ~= nil and greetingText ~= "" then
        -- Live: selecting an option changes the text under focus after a
        -- server round trip, and the node's identity doesn't change.
        addEntry(
            builder,
            ControlId.structural("greeting"),
            nodes.text({
                label = function()
                    return C_GossipInfo.GetText()
                end,
                live = "focus",
            })
        )
    end

    for _, option in ipairs(C_GossipInfo.GetOptions()) do
        local optionID = option.gossipOptionID
        addEntry(
            builder,
            ControlId.structural("option:" .. tostring(optionID)),
            nodes.button({
                label = option.name,
                onActivate = function()
                    C_GossipInfo.SelectOption(optionID)
                end,
            })
        )
    end

    for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
        local questID = quest.questID
        addEntry(
            builder,
            ControlId.structural("available:" .. tostring(questID)),
            nodes.button({
                label = L["Available Quest"] .. ": " .. quest.title,
                onActivate = function()
                    C_GossipInfo.SelectAvailableQuest(questID)
                end,
            })
        )
    end

    for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
        local questID = quest.questID
        addEntry(
            builder,
            ControlId.structural("active:" .. tostring(questID)),
            nodes.button({
                label = L["Accepted Quest"] .. ": " .. quest.title,
                onActivate = function()
                    C_GossipInfo.SelectActiveQuest(questID)
                end,
            })
        )
    end

    addEntry(
        builder,
        ControlId.structural("goodbye"),
        nodes.button({
            label = L["Goodbye"],
            onActivate = function()
                C_GossipInfo.CloseGossip()
            end,
        })
    )

    builder:popContext()
end

module:registerWindow({
    type = "EventWindow",
    name = "gossip",
    conflictingAddons = { "Sku" },
    openEvent = "GOSSIP_SHOW",
    closeEvent = "GOSSIP_CLOSED",
    graphScreen = { render = render },
})
