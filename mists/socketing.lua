local module = WowVision.base.windows:createModule("socketing")
local L = module.L
module:setLabel(L["Socketing"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The gem socketing window: each socket reads its color and its gem (the
-- pending one when a new gem is placed), live; clicking a socket with a gem
-- on the cursor places it. Then apply and close.

local function getSocketLabel(id)
    local color
    local colorKey = GetSocketTypes(id)
    if colorKey then
        color = _G[strupper(colorKey .. "_GEM")] or colorKey
    end
    local label = (color or "") .. ": "
    local name = GetExistingSocketInfo(id)
    if not name then
        name = GetNewSocketInfo(id)
    end
    if name then
        label = label .. name
    else
        label = label .. L["Empty"]
    end
    return label
end

local function render(builder, screen)
    if ItemSocketingFrame == nil or not ItemSocketingFrame:IsShown() then
        return
    end
    local container = ItemSocketingFrame.SocketingContainer
    builder:pushContext("socketing", L["Socketing"])

    builder:beginStop("sockets")
    builder:pushContext("sockets", L["Socketing"])
    for i = 1, GetNumSockets() do
        local button = container.SocketFrames[i]
        if button ~= nil then
            local socketId = i
            local vtable = nodes.proxyButton({
                target = button,
                label = function()
                    return getSocketLabel(socketId)
                end,
            })
            if vtable ~= nil then
                tinsert(vtable.bindings, {
                    binding = "drag",
                    type = "Function",
                    func = function()
                        local script = button:GetScript("OnDragStart")
                        if script ~= nil then
                            script(button)
                        end
                    end,
                })
                builder:addItem(ControlId.forObject(button), vtable)
            end
        end
    end
    builder:popContext()

    if container.ApplySocketsButton ~= nil and container.ApplySocketsButton:IsShown() then
        builder:beginStop("apply")
        builder:addItem(
            ControlId.forObject(container.ApplySocketsButton),
            nodes.proxyButton({ target = container.ApplySocketsButton })
        )
    end
    if ItemSocketingFrame.CloseButton ~= nil then
        builder:beginStop("close")
        builder:addItem(
            ControlId.forObject(ItemSocketingFrame.CloseButton),
            nodes.proxyButton({ target = ItemSocketingFrame.CloseButton, label = L["Close"] })
        )
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "socketing",
    frameName = "ItemSocketingFrame",
    graphScreen = { render = render },
})
