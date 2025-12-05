local module = WowVision.base.windows:createModule("GameMenu")
local L = module.L
module:setLabel(L["Game Menu"])
local gen = module:hasUI()

gen:Element("GameMenu", {
    dynamicValues = function()
        return {}
    end, -- Static menu, never changes
}, function(props)
    local buttons = { GameMenuFrame:GetChildren() }
    local result = { "Panel", label = L["Menu"], wrap = true, children = {} }
    for i, v in ipairs(buttons) do
        tinsert(result.children, { "ProxyButton", key = "btn_" .. i, frame = v })
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "GameMenuFrame",
    generated = true,
    rootElement = "GameMenu",
    frameName = "GameMenuFrame",
})
