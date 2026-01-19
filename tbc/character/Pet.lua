local char = WowVision.tbc.character
local gen = char.gen
local L = char.L

gen:Element("character/Pet", function(props)
    -- Only show if player has a pet
    if not HasPetUI() then
        return {
            "Text",
            text = L["No pet"],
        }
    end

    local children = {}

    -- Pet Name
    local petName = PetNameText and PetNameText:GetText() or ""
    if petName ~= "" then
        tinsert(children, {
            "Text",
            text = petName,
        })
    end

    -- Pet Level/Family
    local petLevel = PetLevelText and PetLevelText:GetText() or ""
    if petLevel ~= "" then
        tinsert(children, {
            "Text",
            text = petLevel,
        })
    end

    -- Pet Loyalty (hunter pets)
    local petLoyalty = PetLoyaltyText and PetLoyaltyText:GetText() or ""
    if petLoyalty ~= "" then
        tinsert(children, {
            "Text",
            text = petLoyalty,
        })
    end

    -- Training Points (hunter pets)
    local trainingLabel = PetTrainingPointLabel and PetTrainingPointLabel:GetText() or ""
    local trainingPoints = PetTrainingPointText and PetTrainingPointText:GetText() or ""
    if trainingLabel ~= "" and trainingPoints ~= "" then
        tinsert(children, {
            "Text",
            text = trainingLabel .. " " .. trainingPoints,
        })
    end

    -- Experience Bar
    local xpText = PetPaperDollFrameExpBarText and PetPaperDollFrameExpBarText:GetText() or ""
    if xpText ~= "" then
        tinsert(children, {
            "Text",
            text = xpText,
        })
    end

    -- Happiness/Diet info
    if PetPaperDollPetInfo and PetPaperDollPetInfo:IsShown() then
        local foodTypes = GetPetFoodTypes()
        if foodTypes then
            local dietText = BuildListString(foodTypes)
            if dietText and dietText ~= "" then
                tinsert(children, {
                    "Text",
                    text = L["Diet"] .. ": " .. dietText,
                })
            end
        end
    end

    -- Base Stats (left column)
    local statsChildren = {}
    for i = 1, 5 do
        local statFrame = _G["PetStatFrame" .. i]
        if statFrame and statFrame:IsShown() then
            local label = _G["PetStatFrame" .. i .. "Label"]
            local statText = _G["PetStatFrame" .. i .. "StatText"]
            local labelText = label and label:GetText() or ""
            local valueText = statText and statText:GetText() or ""
            if labelText ~= "" then
                tinsert(statsChildren, {
                    "Text",
                    text = labelText .. " " .. valueText,
                })
            end
        end
    end

    -- Combat Stats (right column)
    -- Attack Power
    if PetAttackPowerFrame and PetAttackPowerFrame:IsShown() then
        local label = PetAttackPowerFrameLabel and PetAttackPowerFrameLabel:GetText() or ""
        local value = PetAttackPowerFrameStatText and PetAttackPowerFrameStatText:GetText() or ""
        if label ~= "" then
            tinsert(statsChildren, {
                "Text",
                text = label .. " " .. value,
            })
        end
    end

    -- Damage
    if PetDamageFrame and PetDamageFrame:IsShown() then
        local label = PetDamageFrameLabel and PetDamageFrameLabel:GetText() or ""
        local value = PetDamageFrameStatText and PetDamageFrameStatText:GetText() or ""
        if label ~= "" then
            tinsert(statsChildren, {
                "Text",
                text = label .. " " .. value,
            })
        end
    end

    -- Spell Damage
    if PetSpellDamageFrame and PetSpellDamageFrame:IsShown() then
        local label = PetSpellDamageFrameLabel and PetSpellDamageFrameLabel:GetText() or ""
        local value = PetSpellDamageFrameStatText and PetSpellDamageFrameStatText:GetText() or ""
        if label ~= "" then
            tinsert(statsChildren, {
                "Text",
                text = label .. " " .. value,
            })
        end
    end

    -- Armor
    if PetArmorFrame and PetArmorFrame:IsShown() then
        local label = PetArmorFrameLabel and PetArmorFrameLabel:GetText() or ""
        local value = PetArmorFrameStatText and PetArmorFrameStatText:GetText() or ""
        if label ~= "" then
            tinsert(statsChildren, {
                "Text",
                text = label .. " " .. value,
            })
        end
    end

    if #statsChildren > 0 then
        tinsert(children, {
            "List",
            label = L["Stats"],
            children = statsChildren,
        })
    end

    -- Resistances
    local resChildren = {}
    local resNames = { RESISTANCE6_NAME, RESISTANCE2_NAME, RESISTANCE3_NAME, RESISTANCE4_NAME, RESISTANCE5_NAME }
    for i = 1, 5 do
        local resText = _G["PetMagicResText" .. i]
        local value = resText and resText:GetText() or ""
        if value ~= "" and value ~= "0" then
            local resName = resNames[i] or ""
            tinsert(resChildren, {
                "Text",
                text = resName .. " " .. value,
            })
        end
    end

    if #resChildren > 0 then
        tinsert(children, {
            "List",
            label = L["Resistances"],
            children = resChildren,
        })
    end

    -- Close Button
    if PetPaperDollCloseButton and PetPaperDollCloseButton:IsShown() then
        tinsert(children, {
            "ProxyButton",
            frame = PetPaperDollCloseButton,
            label = CLOSE,
        })
    end

    if #children == 0 then
        return nil
    end

    return {
        "List",
        label = L["Pet"],
        children = children,
    }
end)
