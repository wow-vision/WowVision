local module = WowVision.base.windows:createModule("petStable")
local L = module.L
module:setLabel(L["Stable"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The hunter's stable (PetStableFrame, the Classic file Vanilla and TBC
-- share): the selected pet's level, family, loyalty and diet, the three
-- slots (current pet and the two stable slots), Purchase with the price of
-- the next slot, and the money you carry.
--
-- Everything goes through the slots' own scripts, as the mouse does. Enter
-- on a slot is its left click (ClickStablePet): it selects the pet there,
-- or, while a pet is on the cursor, puts it down in that slot. Drag in a
-- slot's context menu runs its drag script (PickupStablePet), which picks
-- the pet up. So: Drag on the current pet, Enter on a free stable slot
-- stables it; Drag on a stabled pet, Enter on the current pet slot takes it
-- out (or swaps it with the pet you have).

local function slotButtons()
    local buttons = { PetStableCurrentPet }
    for i = 1, NUM_PET_STABLE_SLOTS or 2 do
        local button = _G["PetStableStabledPet" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

-- The slot's own tooltip lines, which Blizzard keeps on the button: the pet
-- name, then "Level N Family", or Empty Stable Slot.
local function slotLabel(button, index)
    return function()
        local heading = index == 1 and CURRENT_PET or format(L["Stable slot %d"], index - 1)
        return nodes.joinLabel(heading, button.tooltip, button.tooltipSubtext)
    end
end

local function addSlot(builder, button, index)
    local vtable = nodes.proxyButton({
        target = button,
        label = slotLabel(button, index),
        hover = false,
    })
    if vtable == nil then
        return
    end
    tinsert(vtable.announcements, {
        text = function()
            return button:GetChecked() and L["selected"] or nil
        end,
        kind = kinds.selected,
    })
    builder:addItem(ControlId.forObject(button), vtable)
end

local function shownText(builder, key, fontString)
    if fontString == nil or not fontString:IsShown() then
        return
    end
    local current = fontString:GetText()
    if current == nil or current == "" then
        return
    end
    builder:addItem(
        ControlId.structural(key),
        nodes.text({
            label = function()
                local text = fontString:GetText()
                if text ~= nil and text ~= "" then
                    return text
                end
                return nil
            end,
        })
    )
end

local function render(builder, screen)
    if PetStableFrame == nil or not PetStableFrame:IsShown() then
        return
    end
    builder:pushContext("petStable", STABLES or L["Stable"])

    -- The selected pet: what the window shows beside the model.
    builder:beginStop("pet")
    builder:pushContext("pet", L["Selected Pet"])
    shownText(builder, "pet:level", PetStableLevelText)
    shownText(builder, "pet:loyalty", PetStableLoyaltyText)
    local modelShown = PetStableModel ~= nil and PetStableModel:IsShown()
    if PetStablePetInfo ~= nil and PetStablePetInfo.tooltip ~= nil and modelShown then
        builder:addItem(
            ControlId.structural("pet:diet"),
            nodes.text({
                label = function()
                    return PetStablePetInfo.tooltip
                end,
            })
        )
    end
    builder:popContext()

    builder:beginStop("slots")
    builder:pushContext("slots", L["Slots"])
    for index, button in ipairs(slotButtons()) do
        addSlot(builder, button, index)
    end
    builder:popContext()

    if PetStablePurchaseButton ~= nil and PetStablePurchaseButton:IsShown() then
        builder:beginStop("purchase")
        local vtable = nodes.proxyButton({
            target = PetStablePurchaseButton,
            label = function()
                return nodes.joinLabel(
                    PetStablePurchaseButton:GetText(),
                    C_CurrencyInfo.GetCoinText(GetNextStableSlotCost() or 0)
                )
            end,
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(PetStablePurchaseButton), vtable)
        end
    end

    builder:beginStop("money")
    builder:addItem(
        ControlId.structural("money"),
        nodes.text({
            label = function()
                return L["Money"] .. " " .. C_CurrencyInfo.GetCoinText(GetMoney())
            end,
        })
    )

    builder:beginStop("close")
    builder:addItem(
        ControlId.forObject(PetStableFrameCloseButton),
        nodes.proxyButton({ target = PetStableFrameCloseButton, label = CLOSE })
    )

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "petStable",
    frameName = "PetStableFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
