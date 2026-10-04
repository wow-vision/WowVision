-- Held bags, combined or individual: one component reads whatever the
-- game shows.
WowVision.components.createComponent("containers", {
    key = "bags",
    type = "RetailBags",
})

-- The modern bank: character and account bank in one frame.
WowVision.components.createComponent("containers", {
    key = "bank",
    type = "RetailBank",
})
