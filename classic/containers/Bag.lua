local module = WowVision.base.windows.containers
local L = module.L

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

function Bag:getGenerator()
    local frame = self:getFrame()
    local button = self.button
    if not frame:IsShown() then
        return nil
    end
    local id = self.id
    local bagName = C_Container.GetBagName(id)
    if bagName == nil then
        error("Nil bag name for bag with id " .. (id or "nil") .. " button " .. button:GetName())
    end
    local label
    if self.prefix then
        label = self.prefix .. ": " .. bagName
    else
        label = bagName
    end
    local result = { "List", label = label, children = {} }
    if button then
        tinsert(result.children, { "ItemButton", frame = button, label = L["Bag Slot"] .. " " .. bagName })
    end
    for i = frame.size, 1, -1 do
        local itemButton = _G[frame:GetName() .. "Item" .. i]
        tinsert(result.children, {
            "ItemButton",
            frame = itemButton,
            label = module.getBagItemLabel(itemButton),
        })
    end
    return result
end
