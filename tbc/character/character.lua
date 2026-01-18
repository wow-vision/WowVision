local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])
local gen = module:hasUI()

-- Export module and gen for sub-files
WowVision.tbc = WowVision.tbc or {}
WowVision.tbc.character = {
    module = module,
    gen = gen,
    L = L,
}

gen:Element("character", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "UPDATE_FACTION" },
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "Panel", label = L["Character"], wrap = true, children = {} }
    local tab = CharacterFrame.selectedTab
    if tab == 1 then
        tinsert(result.children, { "character/PaperDoll", frame = PaperDollFrame })
    elseif tab == 3 then
        tinsert(result.children, { "character/Reputation", frame = ReputationFrame })
    else
        tinsert(result.children, { "Text", text = "Not yet implemented" })
    end
    tinsert(result.children, { "character/Tabs" })
    -- Add reputation detail after tabs (only shows when a faction is selected)
    if tab == 3 then
        tinsert(result.children, { "character/ReputationDetail" })
    end
    return result
end)

gen:Element("character/Tabs", {
    regenerateOn = {
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    -- TBC has 5 tabs
    for i = 1, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab and tab:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = CharacterFrame.selectedTab == i,
            })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    generated = true,
    rootElement = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
})
