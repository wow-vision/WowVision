local module = WowVision.base.windows:createModule("talents")
local L = module.L
module:setLabel(L["Talents"])
local gen = module:hasUI()

-- Export module and gen for potential sub-files
WowVision.tbc = WowVision.tbc or {}
WowVision.tbc.talents = {
    module = module,
    gen = gen,
    L = L,
}

gen:Element("talents", function(props)
    local result = { "Panel", label = L["Talents"], wrap = true, children = {} }

    -- Spec tabs (right side - player spec 1/2 and pet spec for hunters)
    tinsert(result.children, { "talents/SpecTabs" })

    -- Points display
    local pointsText = PlayerTalentFrameTalentPointsText
    if pointsText then
        local points = pointsText:GetText()
        if points and points ~= "" then
            tinsert(result.children, {
                "Text",
                text = points,
            })
        end
    end

    -- Talent grid
    tinsert(result.children, { "talents/Grid" })

    -- Tabs (bottom - talent tree tabs)
    tinsert(result.children, { "talents/Tabs" })

    -- Close button
    if PlayerTalentFrameCloseButton then
        tinsert(result.children, {
            "ProxyButton",
            frame = PlayerTalentFrameCloseButton,
            label = CLOSE or "Close",
        })
    end

    return result
end)

-- Talent grid - sorted top to bottom, left to right
local NUM_TALENT_BUTTONS = 40

local function getTalentButtons()
    local buttons = {}
    for i = 1, NUM_TALENT_BUTTONS do
        local button = _G["PlayerTalentFrameTalent" .. i]
        if button and button:IsShown() then
            tinsert(buttons, button)
        end
    end

    -- Sort by position: top to bottom, then left to right
    table.sort(buttons, function(a, b)
        local aTop = a:GetTop() or 0
        local bTop = b:GetTop() or 0
        local aLeft = a:GetLeft() or 0
        local bLeft = b:GetLeft() or 0

        -- Higher GetTop() means higher on screen, so we want descending order for top
        if math.abs(aTop - bTop) > 5 then -- Allow small tolerance for row alignment
            return aTop > bTop
        end
        -- Same row, sort by left (ascending)
        return aLeft < bLeft
    end)

    return buttons
end

gen:Element("talents/Grid", function(props)
    local children = {}
    local selectedTab = PanelTemplates_GetSelectedTab(PlayerTalentFrame) or 1
    local buttons = getTalentButtons()

    for _, button in ipairs(buttons) do
        local talentIndex = button:GetID()
        if talentIndex and talentIndex > 0 then
            local name, iconTexture, tier, column, rank, maxRank = GetTalentInfo(selectedTab, talentIndex)
            if name and name ~= "" then
                local label = name .. " " .. L["rank"] .. " " .. rank .. "/" .. maxRank
                tinsert(children, {
                    "ProxyButton",
                    frame = button,
                    label = label,
                })
            end
        end
    end

    if #children == 0 then
        return nil
    end

    return { "List", label = L["Talent Grid"], children = children }
end)

-- Spec tabs on the right side (player specs and pet spec for hunters)
gen:Element("talents/SpecTabs", function(props)
    local children = {}

    for i = 1, 3 do
        local tab = _G["PlayerSpecTab" .. i]
        if tab and tab:IsVisible() then
            tinsert(children, {
                "ProxyButton",
                key = "spec_" .. i,
                frame = tab,
                selected = tab:GetChecked(),
            })
        end
    end

    if #children == 0 then
        return nil
    end

    return { "List", label = L["Specialization"], children = children }
end)

gen:Element("talents/Tabs", {
    regenerateOn = {
        values = function(props)
            return { selectedTab = PlayerTalentFrame and PlayerTalentFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }

    -- Get number of talent tabs (usually 3 for the 3 talent trees)
    local numTabs = GetNumTalentTabs() or 3

    for i = 1, numTabs do
        local tab = _G["PlayerTalentFrameTab" .. i]
        if tab and tab:IsShown() then
            local selectedTab = PanelTemplates_GetSelectedTab(PlayerTalentFrame) or 1

            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = selectedTab == i,
            })
        end
    end

    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "talents",
    generated = true,
    rootElement = "talents",
    frameName = "PlayerTalentFrame",
    conflictingAddons = { "Sku" },
})
