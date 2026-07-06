local module = WowVision.base.windows:createModule("socketing")
local L = module.L
module:setLabel(L["Socketing"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- TBC Anniversary uses unnamed child frames for sockets and the apply button.
-- The socket buttons (IDs 1..N) and the apply button (ID 0 with text) live inside
-- an unnamed container frame that is a direct child of ItemSocketingFrame.
local function findSocketContainer()
    local children = { ItemSocketingFrame:GetChildren() }
    for _, child in ipairs(children) do
        if not child:GetName() and child:IsShown() then
            local grandchildren = { child:GetChildren() }
            -- The socket container has buttons with sequential IDs starting at 1
            for _, gc in ipairs(grandchildren) do
                if gc:GetObjectType() == "Button" and gc:GetID() == 1 then
                    return child
                end
            end
        end
    end
end

local function findSocketButtons(container)
    local buttons = {}
    local children = { container:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "Button" then
            local id = child:GetID()
            if id > 0 then
                buttons[id] = child
            end
        end
    end
    return buttons
end

local function findApplyButton(container)
    local children = { container:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "Button" and child:GetID() == 0 and child:GetText() then
            return child
        end
    end
end

local function getSocketLabel(id)
    local color = ""
    local colorKey = GetSocketTypes(id)
    if colorKey then
        color = _G[strupper(colorKey .. "_GEM")] or colorKey
    end
    local label = color .. ": "
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
    builder:pushContext("socketing", L["Socketing"])

    local container = findSocketContainer()

    builder:beginStop("sockets")
    builder:pushContext("sockets", L["Socketing"])
    local buttons = container ~= nil and findSocketButtons(container) or {}
    local emitted = 0
    for i = 1, GetNumSockets() do
        local button = buttons[i]
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
                emitted = emitted + 1
            end
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("socketsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    if container ~= nil then
        local applyButton = findApplyButton(container)
        if applyButton ~= nil and applyButton:IsShown() then
            builder:beginStop("apply")
            builder:addItem(ControlId.forObject(applyButton), nodes.proxyButton({ target = applyButton }))
        end
    end
    if ItemSocketingFrameCloseButton ~= nil then
        builder:beginStop("close")
        builder:addItem(
            ControlId.forObject(ItemSocketingFrameCloseButton),
            nodes.proxyButton({ target = ItemSocketingFrameCloseButton, label = L["Close"] })
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
