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
    -- Token of the pending "continuing" close, nil when none is pending.
    pendingClose = nil,
}

-- How long a close flagged as continuing may wait for the next page before
-- the window is given up as closed.
local CONTINUING_GRACE = 1.0

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

-- The continuing flag of GOSSIP_CLOSED is not a promise of a next page.
-- The modern client (retail and WoW: Forever) also sets it when the
-- conversation hands over to another interaction (trainer, flight master,
-- merchant, quest giver), and Forever sets it when the game itself closes
-- the gossip (Escape, walking away). No GOSSIP_SHOW ever follows those, and
-- the window would stay open as a ghost until reload. So a continuing close
-- only holds the window until the next page arrives, another interaction
-- opens, or a short grace period runs out, whichever comes first.
local function clearState()
    state.snapshot = nil
    state.waiting = false
    state.screen = nil
    state.pendingClose = nil
end

local function giveUp()
    clearState()
    WowVision.UIHost.windowManager:closeWindow("gossip")
end

local function beginContinuingClose()
    state.waiting = true
    local token = {}
    state.pendingClose = token
    C_Timer.After(CONTINUING_GRACE, function()
        if state.pendingClose == token then
            giveUp()
        end
    end)
end

-- Another interaction took over the conversation.
local function handOver()
    if state.pendingClose ~= nil then
        giveUp()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("GOSSIP_CLOSED")
-- Not present on every client; GOSSIP_SHOW and the timeout carry those.
pcall(eventFrame.RegisterEvent, eventFrame, "GOSSIP_OPTIONS_REFRESHED")
-- The interactions that can take over a continuing close.
eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
eventFrame:RegisterEvent("QUEST_GREETING")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("QUEST_PROGRESS")
eventFrame:RegisterEvent("QUEST_COMPLETE")

-- Page changes arrive as a fresh GOSSIP_SHOW on every client (retail
-- included -- GOSSIP_OPTIONS_REFRESHED there only covers options changing
-- in place), so a show while a transition is pending always refreshes;
-- gating it on the refresh event's absence left retail waiting out the
-- timeout on every page. A close flagged as continuing (retail, between
-- pages of one conversation) keeps the snapshot and the pending state
-- until a page follows or the close is given up (see above).
eventFrame:SetScript("OnEvent", function(frame, event, arg1)
    if event == "GOSSIP_CLOSED" then
        -- arg1: interactionIsContinuing
        if arg1 then
            beginContinuingClose()
        else
            clearState()
        end
    elseif event == "GOSSIP_OPTIONS_REFRESHED" then
        state.pendingClose = nil
        refresh()
    elseif event == "GOSSIP_SHOW" then
        state.pendingClose = nil
        if state.waiting or state.snapshot == nil then
            refresh()
        end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        -- arg1: the interaction type
        if arg1 ~= Enum.PlayerInteractionType.Gossip then
            handOver()
        end
    else
        -- One of the quest events.
        handOver()
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
    builder:pushContext("npc", npcName)

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
    -- Retail closes and reshows between pages of one conversation; the
    -- window stays open across that so the page change reads as a refresh.
    -- The event handler above closes it itself when no page follows.
    shouldClose = function(interactionIsContinuing)
        return not interactionIsContinuing
    end,
    graphScreen = { render = render },
})
