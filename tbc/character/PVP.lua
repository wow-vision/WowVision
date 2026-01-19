local char = WowVision.tbc.character
local gen = char.gen
local L = char.L

gen:Element("character/PVP", function(props)
    local children = {}

    -- Honor Points
    local honorLabel = PVPFrameHonorLabel and PVPFrameHonorLabel:GetText() or ""
    local honorPoints = PVPFrameHonorPoints and PVPFrameHonorPoints:GetText() or "0"
    if honorLabel ~= "" then
        tinsert(children, {
            "Text",
            text = honorLabel .. " " .. honorPoints,
        })
    end

    -- Arena Points
    local arenaLabel = PVPFrameArenaLabel and PVPFrameArenaLabel:GetText() or ""
    local arenaPoints = PVPFrameArenaPoints and PVPFrameArenaPoints:GetText() or "0"
    if arenaLabel ~= "" then
        tinsert(children, {
            "Text",
            text = arenaLabel .. " " .. arenaPoints,
        })
    end

    -- Kill Statistics
    local killsChildren = {}

    -- Today
    local todayLabel = PVPHonorTodayLabel and PVPHonorTodayLabel:GetText() or L["Today"]
    local todayKills = PVPHonorTodayKills and PVPHonorTodayKills:GetText() or "0"
    tinsert(killsChildren, {
        "Text",
        text = todayLabel .. ": " .. todayKills,
    })

    -- Yesterday
    local yesterdayLabel = PVPHonorYesterdayLabel and PVPHonorYesterdayLabel:GetText() or L["Yesterday"]
    local yesterdayKills = PVPHonorYesterdayKills and PVPHonorYesterdayKills:GetText() or "0"
    tinsert(killsChildren, {
        "Text",
        text = yesterdayLabel .. ": " .. yesterdayKills,
    })

    -- Lifetime
    local lifetimeLabel = PVPHonorLifetimeLabel and PVPHonorLifetimeLabel:GetText() or L["Lifetime"]
    local lifetimeKills = PVPHonorLifetimeKills and PVPHonorLifetimeKills:GetText() or "0"
    tinsert(killsChildren, {
        "Text",
        text = lifetimeLabel .. ": " .. lifetimeKills,
    })

    tinsert(children, {
        "List",
        label = L["Honorable Kills"],
        children = killsChildren,
    })

    -- Toggle Stats Button (Week vs Season)
    if PVPFrameToggleButton and PVPFrameToggleButton:IsShown() then
        tinsert(children, {
            "ProxyButton",
            frame = PVPFrameToggleButton,
        })
    end

    if #children == 0 then
        return nil
    end

    return {
        "List",
        label = L["PVP"],
        children = children,
    }
end)
