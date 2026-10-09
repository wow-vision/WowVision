local module = WowVision.base.windows:createModule("legacy")
local L = module.L
module:setLabel(L["Legacy"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The WoW: Forever Legacy window (LegacySystemFrame, loaded on demand; the
-- Toggle Legacy key, the micro menu, and the achievements key open it):
-- three side tabs over three pages, each in its own file. The reward track
-- lists the Legacy renown levels and their rewards (rewardTrack.lua); the
-- challenges page is the achievement list Forever calls challenges
-- (challenges.lua); the tree page holds the three Legacy talent trees
-- (tree.lua). The window title names the page shown.

-- The side tabs are plain frames that switch on mouse up through a custom
-- handler, so a secure click cannot reach them; Enter runs the tab's own
-- mouse up script as a left click releases it (the tab sound, then the
-- page switch), as the cooldown manager runs its items'. Drawn down the
-- window's side, they read as a row like every other tab bar.
local function renderTabs(builder, frame)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(frame.Tabs) do
        if tab:IsShown() then
            local captured = tab
            local pageID = tab:GetID()
            builder:addItem(
                ControlId.structural("tab:" .. pageID),
                nodes.button({
                    label = tab.tooltipText,
                    selected = function()
                        return frame.currentPage == pageID
                    end,
                    onActivate = function()
                        local script = captured:GetScript("OnMouseUp")
                        if script ~= nil then
                            script(captured, "LeftButton", true)
                        end
                    end,
                })
            )
        end
    end
    builder:endRow()
    builder:popContext()
end

local function render(builder, screen)
    local frame = LegacySystemFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("legacy", frame:GetTitleText():GetText() or L["Legacy"])
    renderTabs(builder, frame)
    if frame.RewardTrackPage:IsShown() then
        module.renderRewardTrack(builder, frame.RewardTrackPage)
    elseif frame.ChallengesPage:IsShown() then
        module.renderChallenges(builder, frame.ChallengesPage)
    elseif frame.TreePage:IsShown() then
        module.renderTree(builder, frame.TreePage)
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "legacy",
    frameName = "LegacySystemFrame",
    graphScreen = { render = render },
})
