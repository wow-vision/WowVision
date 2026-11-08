local testRunner = WowVision.testing.testRunner
local petTraining = WowVision.petTraining

-- The hunter's pet training window (petTraining.lua): the class trainer frame of WoW: Forever opened by the Beast
-- Training spell. The frame and the game are stand-ins.

local GLOBALS = {
    "ClassTrainerFrame",
    "ClassTrainerFrameTitleText",
    "ClassTrainerFrameTrainingPointsLabel",
    "C_PlayerInteractionManager",
    "Enum",
}

local function region(text)
    return {
        GetText = function()
            return text
        end,
    }
end

local function frame(shown, parts)
    local result = {
        IsShown = function()
            return shown
        end,
    }
    for key, value in pairs(parts or {}) do
        result[key] = value
    end
    return result
end

-- Runs fn with the pet's window open (a trainer frame showing 19 training points), then puts the globals back.
-- options.interacting = true: a trainer NPC is open too.
local function withWindow(fn, options)
    options = options or {}
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
    end
    local points = region("Points d'entraînement : 19")
    ClassTrainerFrame = frame(true, { trainingPoints = frame(true, { text = points }) })
    ClassTrainerFrameTitleText = region("Scorpide")
    ClassTrainerFrameTrainingPointsLabel = points
    Enum = { PlayerInteractionType = { Trainer = 43 } }
    C_PlayerInteractionManager = {
        IsInteractingWithNpcOfType = function(kind)
            return options.interacting == true and kind == 43
        end,
    }
    local ok, err = pcall(fn)
    for _, name in ipairs(GLOBALS) do
        _G[name] = saved[name]
    end
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("Pet training", {
    ["the trainer window showing training points, with no trainer open, is the pet's"] = function(t)
        withWindow(function()
            t:assertTrue(petTraining.isActive())
        end)
    end,

    ["a trainer NPC's window is not the pet's even if the frame shows points"] = function(t)
        withWindow(function()
            t:assertFalse(petTraining.isActive())
        end, { interacting = true })
    end,

    ["a trainer window that shows no training points is not the pet's"] = function(t)
        withWindow(function()
            ClassTrainerFrame.trainingPoints = frame(false, { text = region("x") })
            t:assertFalse(petTraining.isActive())
            ClassTrainerFrame.trainingPoints = nil
            t:assertFalse(petTraining.isActive())
        end)
    end,

    ["a closed or missing window is not the pet's"] = function(t)
        withWindow(function()
            ClassTrainerFrame = frame(false, { trainingPoints = frame(true) })
            t:assertFalse(petTraining.isActive())
            ClassTrainerFrame = nil
            t:assertFalse(petTraining.isActive())
        end)
    end,

    ["a client without the interaction manager still finds the pet's window"] = function(t)
        withWindow(function()
            C_PlayerInteractionManager = nil
            t:assertTrue(petTraining.isActive())
            C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function() error("boom") end }
            t:assertTrue(petTraining.isActive())
        end)
    end,

    ["the points and the title are the game's own text"] = function(t)
        withWindow(function()
            t:assertEqual(petTraining.pointsText(), "Points d'entraînement : 19")
            t:assertEqual(petTraining.title(), "Scorpide")
        end)
    end,

    ["the points fall back to the named label, and to nothing"] = function(t)
        withWindow(function()
            ClassTrainerFrame.trainingPoints.text = nil
            t:assertEqual(petTraining.pointsText(), "Points d'entraînement : 19")
            ClassTrainerFrameTrainingPointsLabel = nil
            t:assertNil(petTraining.pointsText())
            ClassTrainerFrameTitleText = region("")
            t:assertNil(petTraining.title())
        end)
    end,

    ["a cost is said in training points"] = function(t)
        t:assertEqual(petTraining.costText(5), "Training point cost: 5")
    end,
})
