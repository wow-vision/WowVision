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
-- WoW: Forever loads this file too. Its stable is the same window on a newer
-- build: the slots keep their global names, but Purchase, the diet icon and
-- the model are unnamed parts of the frame (purchaseButton, diet,
-- modelScene), there is no GetNextStableSlotCost (the price is only in the
-- cost money frame), and an experience bar (expBar) is added. Every lookup
-- below tries the TBC name first, so TBC reads exactly what it did.
--
-- Everything goes through the slots' own scripts, as the mouse does. Enter
-- on a slot is its left click (ClickStablePet): it selects the pet there,
-- or, while a pet is on the cursor, puts it down in that slot. Drag (the
-- drag key, or Drag in a slot's context menu) runs its drag script
-- (PickupStablePet), which picks the pet up. So: Drag on the current pet, Enter on a free stable slot
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
    -- The drag key does what Drag in the context menu does: the slot's own
    -- drag script picks the pet up, or with a pet held, its drop script.
    tinsert(vtable.bindings, { binding = "drag", type = "Function", func = nodes.dragScript(button) })
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

-- The frame's part under a TBC global name, else under Forever's parent key.
local function part(globalName, key)
    local frame = rawget(_G, globalName)
    if frame ~= nil then
        return frame
    end
    return PetStableFrame[key]
end

-- What the next stable slot costs, in copper. TBC asks the game; Forever
-- has no such function, so this reads the cost money frame the window shows.
local function nextSlotCost()
    local getCost = rawget(_G, "GetNextStableSlotCost")
    if getCost ~= nil then
        return getCost()
    end
    local moneyFrame = rawget(_G, "PetStableCostMoneyFrame")
    if moneyFrame == nil then
        return nil
    end
    if type(moneyFrame.staticMoney) == "number" then
        return moneyFrame.staticMoney
    end
    local total, found = 0, false
    for unit, factor in pairs({ Gold = 10000, Silver = 100, Copper = 1 }) do
        local button = rawget(_G, "PetStableCostMoneyFrame" .. unit .. "Button")
        if button ~= nil and button:IsShown() then
            local digits = tostring(button:GetText() or ""):gsub("%D", "")
            total = total + (tonumber(digits) or 0) * factor
            found = true
        end
    end
    return found and total or nil
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
    -- Forever's experience bar ("XP 1257/2525").
    local experience = PetStableFrame.expBar
    if experience ~= nil and experience:IsShown() then
        shownText(builder, "pet:experience", experience.Text)
    end
    local model = part("PetStableModel", "modelScene")
    local modelShown = model ~= nil and model:IsShown()
    local diet = part("PetStablePetInfo", "diet")
    if diet ~= nil and diet.tooltip ~= nil and modelShown then
        builder:addItem(
            ControlId.structural("pet:diet"),
            nodes.text({
                label = function()
                    return diet.tooltip
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

    local purchase = part("PetStablePurchaseButton", "purchaseButton")
    if purchase ~= nil and purchase:IsShown() then
        builder:beginStop("purchase")
        local vtable = nodes.proxyButton({
            target = purchase,
            label = function()
                local cost = nextSlotCost()
                return nodes.joinLabel(purchase:GetText(), cost ~= nil and C_CurrencyInfo.GetCoinText(cost) or nil)
            end,
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(purchase), vtable)
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
