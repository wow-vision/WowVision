local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC character panel: five tabs (paper doll, pet, reputation, skills,
-- PVP), each body provided by its file through char.render* functions.
WowVision.tbc = WowVision.tbc or {}
local char = {
    module = module,
    L = L,
}
WowVision.tbc.character = char

local function render(builder, screen)
    if CharacterFrame == nil or not CharacterFrame:IsShown() then
        return
    end
    builder:pushContext("character", L["Character"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if CharacterFrame.selectedTab == tabIndex then
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

    local tab = CharacterFrame.selectedTab
    if tab == 1 and char.renderPaperDoll ~= nil then
        char.renderPaperDoll(builder)
    elseif tab == 2 and char.renderPet ~= nil then
        char.renderPet(builder)
    elseif tab == 3 and char.renderReputation ~= nil then
        char.renderReputation(builder)
    elseif tab == 4 and char.renderSkills ~= nil then
        char.renderSkills(builder)
    elseif tab == 5 and char.renderPVP ~= nil then
        char.renderPVP(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
