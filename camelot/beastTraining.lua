-- The hunter's Beast Training on WoW: Forever opens the pet's skills in the
-- class trainer window with no trainer to interact with, so the frame itself
-- says it is open (petTraining.lua). The screen is the class trainer's
-- (core/windows/training.lua), which reads the pet's title, points and costs
-- from WowVision.petTraining.
local training = WowVision.base.windows.training

training:registerWindow({
    type = "CustomWindow",
    name = "beastTraining",
    isOpen = WowVision.petTraining.isActive,
    conflictingAddons = { "Sku" },
    graphScreen = { render = training.renderTrainer },
})
