local module = WowVision.base.windows.bars
local L = module.L

WowVision.components.createComponent("bars", {
    key = "mainActionBar",
    type = "MainActionBar",
    label = L["Action Bar"],
})

WowVision.components.createComponent("bars", {
    key = "petActionBar",
    type = "PetActionBar",
    label = L["Pet Bar"],
})

WowVision.components.createComponent("bars", {
    key = "stanceBar",
    type = "StanceBar",
    label = L["Stance Bar"],
})

WowVision.components.createComponent("bars", {
    key = "bottomLeftBar",
    type = "GenericActionBar",
    label = L["Bottom Left Bar"],
    frame = MultiBarBottomLeft,
})

WowVision.components.createComponent("bars", {
    key = "bottomRightBar",
    type = "GenericActionBar",
    label = L["Bottom Right Bar"],
    frame = MultiBarBottomRight,
})

WowVision.components.createComponent("bars", {
    key = "rightBar",
    type = "GenericActionBar",
    label = L["Right Bar"],
    frame = MultiBarRight,
})

WowVision.components.createComponent("bars", {
    key = "rightBar2",
    type = "GenericActionBar",
    label = L["Right Bar 2"],
    frame = MultiBarLeft,
})
