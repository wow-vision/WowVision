local char = WowVision.tbc.character
local L = char.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The TBC pet tab: name, level, loyalty, training points, experience, diet,
-- the stat and resistance readouts (all live), and close.

local function textOf(region)
    return function()
        local text = region ~= nil and region:GetText() or nil
        if text ~= nil and text ~= "" then
            return text
        end
        return nil
    end
end

local function pairText(labelRegion, valueRegion)
    return function()
        local label = labelRegion ~= nil and labelRegion:GetText() or nil
        if label == nil or label == "" then
            return nil
        end
        local value = valueRegion ~= nil and valueRegion:GetText() or ""
        return label .. " " .. value
    end
end

function char.renderPet(builder)
    if not HasPetUI() then
        builder:beginStop("noPet")
        builder:addItem(ControlId.structural("noPet"), nodes.text({ label = L["No pet"] }))
        return
    end

    builder:beginStop("pet")
    builder:pushContext("pet", L["Pet"])

    builder:addItem(ControlId.structural("petName"), nodes.text({ label = textOf(PetNameText) }))
    builder:addItem(ControlId.structural("petLevel"), nodes.text({ label = textOf(PetLevelText) }))
    builder:addItem(ControlId.structural("petLoyalty"), nodes.text({ label = textOf(PetLoyaltyText) }))
    builder:addItem(
        ControlId.structural("petTraining"),
        nodes.text({ label = pairText(PetTrainingPointLabel, PetTrainingPointText) })
    )
    builder:addItem(ControlId.structural("petXP"), nodes.text({ label = textOf(PetPaperDollFrameExpBarText) }))
    builder:addItem(
        ControlId.structural("petDiet"),
        nodes.text({
            label = function()
                if PetPaperDollPetInfo == nil or not PetPaperDollPetInfo:IsShown() then
                    return nil
                end
                local foodTypes = GetPetFoodTypes()
                if foodTypes == nil then
                    return nil
                end
                local dietText = BuildListString(foodTypes)
                if dietText ~= nil and dietText ~= "" then
                    return L["Diet"] .. ": " .. dietText
                end
                return nil
            end,
        })
    )

    builder:pushContext("petStats", L["Stats"])
    for i = 1, 5 do
        local statFrame = _G["PetStatFrame" .. i]
        if statFrame ~= nil and statFrame:IsShown() then
            builder:addItem(
                ControlId.structural("petStat:" .. i),
                nodes.text({
                    label = pairText(_G["PetStatFrame" .. i .. "Label"], _G["PetStatFrame" .. i .. "StatText"]),
                })
            )
        end
    end
    local combatStats = {
        { key = "attackPower", frame = PetAttackPowerFrame, label = PetAttackPowerFrameLabel, value = PetAttackPowerFrameStatText },
        { key = "damage", frame = PetDamageFrame, label = PetDamageFrameLabel, value = PetDamageFrameStatText },
        { key = "spellDamage", frame = PetSpellDamageFrame, label = PetSpellDamageFrameLabel, value = PetSpellDamageFrameStatText },
        { key = "armor", frame = PetArmorFrame, label = PetArmorFrameLabel, value = PetArmorFrameStatText },
    }
    for _, stat in ipairs(combatStats) do
        if stat.frame ~= nil and stat.frame:IsShown() then
            builder:addItem(
                ControlId.structural("petStat:" .. stat.key),
                nodes.text({ label = pairText(stat.label, stat.value) })
            )
        end
    end
    builder:popContext()

    builder:pushContext("petResistances", L["Resistances"])
    local resNames = { RESISTANCE6_NAME, RESISTANCE2_NAME, RESISTANCE3_NAME, RESISTANCE4_NAME, RESISTANCE5_NAME }
    for i = 1, 5 do
        local resText = _G["PetMagicResText" .. i]
        local resName = resNames[i]
        local index = i
        builder:addItem(
            ControlId.structural("petRes:" .. i),
            nodes.text({
                label = function()
                    local region = _G["PetMagicResText" .. index]
                    local value = region ~= nil and region:GetText() or nil
                    if value ~= nil and value ~= "" and value ~= "0" then
                        return (resName or "") .. " " .. value
                    end
                    return nil
                end,
            })
        )
    end
    builder:popContext()
    builder:popContext()

    if PetPaperDollCloseButton ~= nil and PetPaperDollCloseButton:IsShown() then
        builder:beginStop("petClose")
        builder:addItem(
            ControlId.forObject(PetPaperDollCloseButton),
            nodes.proxyButton({ target = PetPaperDollCloseButton, label = CLOSE })
        )
    end
end
