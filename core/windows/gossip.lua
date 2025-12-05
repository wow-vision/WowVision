local module = WowVision.base.windows:createModule("gossip")
local L = module.L
module:setLabel(L["Gossip"])
local gen = module:hasUI()

gen:Element("gossip", function(props)
    local frame = GossipFrame.GreetingPanel.ScrollBox
    local result = { "Panel", label = GossipFrame:GetTitleText():GetText() or "", wrap = true, children = {} }
    local children = { frame.ScrollTarget:GetChildren() }
    for _, v in ipairs(children) do
        if v.GreetingText then
            tinsert(result.children, { "Text", text = v.GreetingText:GetText() })
        elseif v:GetObjectType() == "Button" then
            tinsert(result.children, { "ProxyButton", frame = v })
        end
    end
    tinsert(result.children, { "ProxyButton", frame = GossipFrame.GreetingPanel.GoodbyeButton })
    return result
end)

module:registerWindow({
    type = "EventWindow",
    name = "gossip",
    auto = true,
    generated = true,
    rootElement = "gossip",
    frameName = "GossipFrame",
    conflictingAddons = { "Sku" },
    openEvent = "GOSSIP_SHOW",
    closeEvent = "GOSSIP_CLOSED",
})
