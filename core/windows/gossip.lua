local module = WowVision.base.windows:createModule("gossip")
local L = module.L
module:setLabel(L["Gossip"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- NPC dialogue, data-driven through C_GossipInfo. The screen renders from a
-- SNAPSHOT of the gossip data rather than live reads: selecting an option
-- starts a server round trip, and rendering live would show (and announce) a
-- half-updated page. The snapshot refreshes on GOSSIP_OPTIONS_REFRESHED (with
-- GOSSIP_SHOW and a timeout as fallbacks for clients without it), and every
-- refresh lands focus on the greeting text so the new page reads from the top.

local state = {
    snapshot = nil,
    waiting = false,
    screen = nil,
}

local function takeSnapshot()
    state.snapshot = {
        text = C_GossipInfo.GetText(),
        options = C_GossipInfo.GetOptions(),
        available = C_GossipInfo.GetAvailableQuests(),
        active = C_GossipInfo.GetActiveQuests(),
    }
end

local function refresh()
    takeSnapshot()
    state.waiting = false
    if state.screen ~= nil then
        state.screen.state.nextSuggestedMove = ControlId.structural("greeting")
    end
end

-- An option was selected: freeze on the current snapshot until the new page
-- arrives, with a timeout in case no refresh event ever fires.
local function beginTransition()
    state.waiting = true
    C_Timer.After(1.5, function()
        if state.waiting then
            refresh()
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("GOSSIP_CLOSED")
-- Not present on every client; the fallbacks carry those.
local hasRefreshEvent = pcall(eventFrame.RegisterEvent, eventFrame, "GOSSIP_OPTIONS_REFRESHED")
eventFrame:SetScript("OnEvent", function(frame, event)
    if event == "GOSSIP_CLOSED" then
        state.snapshot = nil
        state.waiting = false
        state.screen = nil
    elseif event == "GOSSIP_OPTIONS_REFRESHED" then
        refresh()
    elseif event == "GOSSIP_SHOW" then
        if state.waiting and not hasRefreshEvent then
            refresh()
        elseif state.snapshot == nil then
            takeSnapshot()
        end
    end
end)

local function addEntry(builder, id, vtable)
    builder:beginStop()
    builder:addItem(id, vtable)
end

local function render(builder, screen)
    state.screen = screen
    if state.snapshot == nil then
        takeSnapshot()
    end
    local snapshot = state.snapshot

    local npcName = UnitName("npc") or L["Gossip"]
    builder:pushContext(npcName)

    if snapshot.text ~= nil and snapshot.text ~= "" then
        addEntry(
            builder,
            ControlId.structural("greeting"),
            nodes.text({
                label = function()
                    return state.snapshot ~= nil and state.snapshot.text or nil
                end,
                live = "focus",
            })
        )
    end

    for _, option in ipairs(snapshot.options or {}) do
        local optionID = option.gossipOptionID
        addEntry(
            builder,
            ControlId.structural("option:" .. tostring(optionID)),
            nodes.button({
                label = option.name,
                onActivate = function()
                    beginTransition()
                    C_GossipInfo.SelectOption(optionID)
                end,
            })
        )
    end

    for _, quest in ipairs(snapshot.available or {}) do
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

    for _, quest in ipairs(snapshot.active or {}) do
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
