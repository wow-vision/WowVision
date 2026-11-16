local module = WowVision.base.ui:createModule("tooltip")
local L = module.L
module:setLabel(L["Tooltip"])

module:registerBinding({
    type = "Function",
    key = "tooltip/previousLine",
    inputs = { "SHIFT-UP" },
    label = L["Previous Tooltip Line"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:previousLine()
    end,
})

module:registerBinding({
    type = "Function",
    key = "tooltip/nextLine",
    inputs = { "SHIFT-DOWN" },
    label = L["Next Tooltip Line"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:nextLine()
    end,
})

module:registerBinding({
    type = "Function",
    key = "tooltip/previousBlock",
    inputs = { "CTRL-SHIFT-UP" },
    label = L["Previous Tooltip Block"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:previousBlock()
    end,
})

module:registerBinding({
    type = "Function",
    key = "tooltip/nextBlock",
    inputs = { "CTRL-SHIFT-DOWN" },
    label = L["Next Tooltip Block"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:nextBlock()
    end,
})

module:registerBinding({
    type = "Function",
    key = "tooltip/readLeft",
    inputs = { "SHIFT-LEFT" },
    label = L["Read Tooltip Left"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:speakCurrentLeft()
    end,
})

module:registerBinding({
    type = "Function",
    key = "tooltip/readRight",
    inputs = { "SHIFT-RIGHT" },
    label = L["Read Tooltip Right"],
    interruptSpeech = true,
    conflictingAddons = { "Sku" },
    func = function()
        WowVision.UIHost.tooltip:speakCurrentRight()
    end,
})
