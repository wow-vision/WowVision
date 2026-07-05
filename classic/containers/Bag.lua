local module = WowVision.base.windows.containers
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local Bag = WowVision.components.createType("containers", { key = "Bag" })
Bag.info:addFields({
    { key = "id", required = true, once = true },
    { key = "button" },
    { key = "prefix" },
})

function Bag:getFrame()
    for i = 1, 14 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:GetID() == self.id then
            return frame
        end
    end
    return nil
end

function Bag:isOpen()
    local frame = self:getFrame()
    if not frame then
        return false
    end
    return frame:IsShown()
end

-- One tab stop per bag: the bag slot button, then the item slots (the frames
-- lay slots out reversed, so size down to 1 reads slot order).
function Bag:renderGraph(builder)
    local frame = self:getFrame()
    if frame == nil or not frame:IsShown() then
        return
    end
    local bagName = C_Container.GetBagName(self.id) or ""
    local label = bagName
    if self.prefix then
        label = self.prefix .. ": " .. bagName
    end

    builder:beginStop("bag:" .. self.id)
    -- Keyed: two identical bags must not share a context identity, or moving
    -- between them never re-announces the bag level.
    builder:pushContext("bag:" .. self.id, label)
    if self.button ~= nil then
        -- Structural id: bank bag slot buttons also appear in the bank's own
        -- slot list, so the shared frame cannot be the identity.
        builder:addItem(
            ControlId.structural("bagButton:" .. self.id),
            module.itemSlotNode(self.button, L["Bag Slot"] .. " " .. bagName)
        )
    end
    for i = frame.size, 1, -1 do
        local itemButton = _G[frame:GetName() .. "Item" .. i]
        if itemButton ~= nil then
            builder:addItem(
                ControlId.forObject(itemButton),
                module.itemSlotNode(itemButton, function()
                    return module.getBagItemLabel(itemButton)
                end)
            )
        end
    end
    builder:popContext()
end
