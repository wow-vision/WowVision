local char = WowVision.tbc.character
local L = char.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The TBC PVP tab: honor and arena points, the kill statistics, and the
-- week/season toggle. All live text.

local function pairText(labelRegion, valueRegion, fallbackLabel, separator)
    return function()
        local label = labelRegion ~= nil and labelRegion:GetText() or fallbackLabel
        if label == nil or label == "" then
            return nil
        end
        local value = valueRegion ~= nil and valueRegion:GetText() or "0"
        return label .. (separator or " ") .. value
    end
end

function char.renderPVP(builder)
    builder:beginStop("pvp")
    builder:pushContext("pvp", L["PVP"])

    builder:addItem(
        ControlId.structural("honor"),
        nodes.text({ label = pairText(PVPFrameHonorLabel, PVPFrameHonorPoints) })
    )
    builder:addItem(
        ControlId.structural("arena"),
        nodes.text({ label = pairText(PVPFrameArenaLabel, PVPFrameArenaPoints) })
    )

    builder:pushContext("kills", L["Honorable Kills"])
    builder:addItem(
        ControlId.structural("today"),
        nodes.text({ label = pairText(PVPHonorTodayLabel, PVPHonorTodayKills, L["Today"], ": ") })
    )
    builder:addItem(
        ControlId.structural("yesterday"),
        nodes.text({ label = pairText(PVPHonorYesterdayLabel, PVPHonorYesterdayKills, L["Yesterday"], ": ") })
    )
    builder:addItem(
        ControlId.structural("lifetime"),
        nodes.text({ label = pairText(PVPHonorLifetimeLabel, PVPHonorLifetimeKills, L["Lifetime"], ": ") })
    )
    builder:popContext()
    builder:popContext()

    if PVPFrameToggleButton ~= nil and PVPFrameToggleButton:IsShown() then
        builder:beginStop("toggle")
        builder:addItem(ControlId.forObject(PVPFrameToggleButton), nodes.proxyButton({ target = PVPFrameToggleButton }))
    end
end
