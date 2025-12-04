local module = WowVision.base.windows:createModule("socketing")
local L = module.L
module:setLabel(L["Socketing"])
local gen = module:hasUI()

gen:Element("socketing", function(props)
    return {
        "Panel",
        label = L["Socketing"],
        wrap = true,
        children = {
            { "socketing/Sockets", frame = props.frame.Sockets },
            { "ProxyButton", frame = ItemSocketingSocketButton },
            { "ProxyButton", frame = ItemSocketingFrameCloseButton, label = L["Close"] },
        },
    }
end)

local function getSocketLabel(button)
    local id = button:GetID()
    local colorKey = GetSocketTypes(id)
    if colorKey then
        color = _G[strupper(colorKey .. "_GEM")] or colorKey
    end
    local label = color .. ": "
    local name, icon, _ = GetExistingSocketInfo(id)
    if not name then
        name, icon, _ = GetNewSocketInfo(id)
    end
    if name then
        label = label .. name
    else
        label = label .. L["Empty"]
    end
    return label
end

gen:Element("socketing/Socket", function(props)
    local frame = props.frame
    return { "ProxyButton", frame = frame, label = getSocketLabel(frame) }
end)

gen:Element("socketing/Sockets", function(props)
    local frame = props.frame
    local result = { "List", children = {} }
    for i = 1, GetNumSockets() do
        local button = frame[i]
        tinsert(result.children, { "socketing/Socket", frame = button })
    end
    return result
end)

module:registerWindow({
    name = "socketing",
    auto = true,
    generated = true,
    rootElement = "socketing",
    frameName = "ItemSocketingFrame",
})
