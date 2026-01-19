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

gen:Element("character", function(props)
    local result = { "Panel", label = L["Character"], wrap = true, children = {} }
    local tab = CharacterFrame.selectedTab
    if tab == 1 then
        tinsert(result.children, { "character/PaperDoll", frame = PaperDollFrame })
    elseif tab == 3 then
        tinsert(result.children, { "character/Reputation", frame = ReputationFrame })
    elseif tab == 4 then
        tinsert(result.children, { "character/Skills", frame = SkillFrame })
    elseif tab == 5 then
        tinsert(result.children, { "character/PVP", frame = PVPFrame })
    else
        tinsert(result.children, { "Text", text = "Not yet implemented" })
    end
    tinsert(result.children, { "character/Tabs" })
    -- Add detail panels after tabs (only shows when applicable)
    if tab == 3 then
        tinsert(result.children, { "character/ReputationDetail" })
    elseif tab == 4 then
        tinsert(result.children, { "character/SkillsDetail" })
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
