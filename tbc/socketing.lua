local module = WowVision.base.windows:createModule("socketing")
local L = module.L
module:setLabel(L["Socketing"])
local gen = module:hasUI()

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

local function getSocketLabel(button)
    local id = button:GetID()
    local color = ""
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

gen:Element("socketing", function(props)
    local container = findSocketContainer()
    local children = {
        { "socketing/Sockets", container = container },
    }
    if container then
        local applyButton = findApplyButton(container)
        if applyButton then
            tinsert(children, { "ProxyButton", frame = applyButton })
        end
    end
    tinsert(children, { "ProxyButton", frame = ItemSocketingFrameCloseButton, label = L["Close"] })
    return {
        "Panel",
        label = L["Socketing"],
        wrap = true,
        children = children,
    }
end)

gen:Element("socketing/Socket", function(props)
    local frame = props.frame
    return { "ItemButton", frame = frame, label = getSocketLabel(frame) }
end)

gen:Element("socketing/Sockets", function(props)
    local result = { "List", children = {} }
    local container = props.container
    if not container then
        return result
    end
    local buttons = findSocketButtons(container)
    for i = 1, GetNumSockets() do
        if buttons[i] then
            tinsert(result.children, { "socketing/Socket", frame = buttons[i] })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "socketing",
    generated = true,
    rootElement = "socketing",
    frameName = "ItemSocketingFrame",
})
