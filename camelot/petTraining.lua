local L = WowVision:getLocale()

-- The hunter's Beast Training on WoW: Forever. The game opens its pet's skills
-- in the class trainer window (ClassTrainerFrame): the same list, filter and
-- Train button, but nobody trained you. The hunter's Beast Training spell opens
-- it, so there is no trainer interaction for the interaction window of
-- training.lua to wait for, and what the services cost is the pet's training
-- points, shown in the frame's trainingPoints part where the money would be.
local petTraining = {}
WowVision.petTraining = petTraining

local function trainerFrame()
    return rawget(_G, "ClassTrainerFrame")
end

-- Whether a trainer NPC is open: its window is the interaction window's.
local function interactingWithTrainer()
    local manager = rawget(_G, "C_PlayerInteractionManager")
    local enum = rawget(_G, "Enum")
    if manager == nil or manager.IsInteractingWithNpcOfType == nil then
        return false
    end
    if enum == nil or enum.PlayerInteractionType == nil or enum.PlayerInteractionType.Trainer == nil then
        return false
    end
    local ok, interacting = pcall(manager.IsInteractingWithNpcOfType, enum.PlayerInteractionType.Trainer)
    return ok and interacting == true
end

-- True while the pet's training window is on screen: the trainer window shows
-- training points and no trainer NPC is open.
function petTraining.isActive()
    local frame = trainerFrame()
    if frame == nil or not frame:IsShown() then
        return false
    end
    local points = frame.trainingPoints
    if points == nil or not points:IsShown() then
        return false
    end
    return not interactingWithTrainer()
end

local function textOf(region)
    if region == nil or region.GetText == nil then
        return nil
    end
    local text = region:GetText()
    if type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end

-- "Training Points: 19", as the game writes it.
function petTraining.pointsText()
    local frame = trainerFrame()
    local points = frame ~= nil and frame.trainingPoints or nil
    return textOf(points ~= nil and points.text or nil) or textOf(rawget(_G, "ClassTrainerFrameTrainingPointsLabel"))
end

-- The window's title: the pet's name.
function petTraining.title()
    return textOf(rawget(_G, "ClassTrainerFrameTitleText"))
end

-- What a skill costs, in the pet's training points rather than coins.
function petTraining.costText(cost)
    return string.format(L["Training point cost: %d"], cost)
end
