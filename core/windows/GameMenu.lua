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
    name = "GameMenuFrame", --The name in the window manager to reference this window
    auto = true, --will automatically open on escape menu
    generated = true,
    rootElement = "GameMenu", --Root generator for the virtual UI
    frameName = "GameMenuFrame", --Global of the blizzard frame to detect
})
