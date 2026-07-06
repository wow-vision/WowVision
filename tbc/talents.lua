local module = WowVision.base.windows:createModule("talents")
local L = module.L
module:setLabel(L["Talents"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC talent frame: spec tabs, the three tree tabs, unspent points,
-- and the talent grid sorted top-to-bottom then left-to-right, each talent
-- reading name and rank live (clicking a talent re-speaks its new rank).

local NUM_TALENT_BUTTONS = 40

local function getTalentButtons()
    local buttons = {}
    for i = 1, NUM_TALENT_BUTTONS do
        local button = _G["PlayerTalentFrameTalent" .. i]
        if button and button:IsShown() then
            tinsert(buttons, button)
        end
    end
    table.sort(buttons, function(a, b)
        local aTop = a:GetTop() or 0
        local bTop = b:GetTop() or 0
        local aLeft = a:GetLeft() or 0
        local bLeft = b:GetLeft() or 0
        if math.abs(aTop - bTop) > 5 then
            return aTop > bTop
        end
        return aLeft < bLeft
    end)
    return buttons
end

local function render(builder, screen)
    if PlayerTalentFrame == nil or not PlayerTalentFrame:IsShown() then
        return
    end
    builder:pushContext("talents", L["Talents"])

    local specEmitted = false
    for i = 1, 3 do
        local tab = _G["PlayerSpecTab" .. i]
        if tab ~= nil and tab:IsVisible() then
            if not specEmitted then
                builder:beginStop("specTabs")
                builder:pushContext("specTabs", L["Specialization"])
                builder:startRow()
                specEmitted = true
            end
            builder:addItem(ControlId.forObject(tab), nodes.proxyCheckButton({ target = tab }))
        end
    end
    if specEmitted then
        builder:endRow()
        builder:popContext()
    end

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, GetNumTalentTabs() or 3 do
        local tab = _G["PlayerTalentFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if (PanelTemplates_GetSelectedTab(PlayerTalentFrame) or 1) == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()

    if PlayerTalentFrameTalentPointsText ~= nil then
        builder:beginStop("points")
        builder:addItem(
            ControlId.structural("points"),
            nodes.text({
                label = function()
                    return PlayerTalentFrameTalentPointsText:GetText()
                end,
            })
        )
    end

    builder:beginStop("grid")
    builder:pushContext("grid", L["Talent Grid"])
    local selectedTab = PanelTemplates_GetSelectedTab(PlayerTalentFrame) or 1
    for _, button in ipairs(getTalentButtons()) do
        local talentIndex = button:GetID()
        if talentIndex ~= nil and talentIndex > 0 then
            local captured = button
            local capturedIndex = talentIndex
            local vtable = nodes.proxyButton({
                target = captured,
                label = function()
                    local tab = PanelTemplates_GetSelectedTab(PlayerTalentFrame) or 1
                    local name, _, _, _, rank, maxRank = GetTalentInfo(tab, capturedIndex)
                    if name == nil or name == "" then
                        return nil
                    end
                    return name .. " " .. L["rank"] .. " " .. rank .. "/" .. maxRank
                end,
            })
            if vtable ~= nil then
                local name = GetTalentInfo(selectedTab, capturedIndex)
                if name ~= nil and name ~= "" then
                    builder:addItem(ControlId.forObject(captured), vtable)
                end
            end
        end
    end
    builder:popContext()

    if PlayerTalentFrameCloseButton ~= nil then
        builder:beginStop("close")
        builder:addItem(
            ControlId.forObject(PlayerTalentFrameCloseButton),
            nodes.proxyButton({ target = PlayerTalentFrameCloseButton, label = CLOSE or L["Close"] })
        )
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "talents",
    frameName = "PlayerTalentFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
