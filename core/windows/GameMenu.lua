local module = WowVision.base.windows:createModule("GameMenu")
local L = module.L
module:setLabel(L["Game Menu"])

local graph = WowVision.graph

local function render(builder, screen)
    local frame = GameMenuFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    graph.nodes.proxyButtonMenu(builder, { label = L["Menu"], frame = frame })
end

module:registerWindow({
    type = "FrameWindow",
    name = "GameMenuFrame",
    frameName = "GameMenuFrame",
    graphScreen = { render = render },
})
