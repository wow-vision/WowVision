local module = WowVision.base:createModule("ui")
local L = module.L
module:setLabel(L["UI"])
module:setVital(true)

local function BindingsButton_Click(source, button)
    local root = { "binding/List", bindings = WowVision.input.bindings }
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
end

function module:getAdditionalMenuUI()
    return { "Button", label = L["Bindings"], events = {
        click = BindingsButton_Click,
    } }
end

local settings = module:hasSettings()

settings:add({
    type = "Bool",
    key = "interruptSpeechOnWindowClose",
    label = L["Interrupt Speech on Window Close"],
    default = false,
})

module:registerBindings({
    {
        type = "Virtual",
        key = "up",
        vital = true,
        dorment = true,
        label = L["Up"],
        inputs = { "UP" },
        emulatedKey = "UP",
    },
    {
        type = "Virtual",
        key = "down",
        vital = true,
        dorment = true,
        label = L["Down"],
        inputs = { "DOWN" },
        emulatedKey = "DOWN",
    },
    {
        type = "Virtual",
        key = "left",
        vital = true,
        dorment = true,
        label = L["Left"],
        inputs = { "LEFT" },
        emulatedKey = "LEFT",
    },
    {
        type = "Virtual",
        key = "right",
        vital = true,
        dorment = true,
        label = L["Right"],
        inputs = { "RIGHT" },
        emulatedKey = "RIGHT",
    },
    {
        type = "Virtual",
        key = "next",
        vital = true,
        dorment = true,
        label = L["Next"],
        inputs = { "TAB" },
        emulatedKey = "TAB",
    },
    {
        type = "Virtual",
        key = "previous",
        vital = true,
        dorment = true,
        label = L["Previous"],
        inputs = { "SHIFT-TAB" },
        emulatedKey = "SHIFT-TAB",
    },
    {
        type = "Virtual",
        key = "nextWindow",
        vital = true,
        dorment = true,
        label = L["Next Window"],
        inputs = { "CTRL-TAB" },
        emulatedKey = "CTRL-TAB",
    },
    {
        type = "Virtual",
        key = "previousWindow",
        vital = true,
        dorment = true,
        label = L["Previous Window"],
        inputs = { "CTRL-SHIFT-TAB" },
        emulatedKey = "CTRL-SHIFT-TAB",
    },
    {
        type = "Virtual",
        key = "close",
        vital = true,
        dorment = true,
        label = L["Close"],
        inputs = { "ESCAPE" },
        emulatedKey = "ESCAPE",
    },
    {
        type = "Flexible",
        key = "leftClick",
        vital = true,
        dorment = true,
        label = L["Left Click"],
        inputs = { "ENTER" },
        emulatedKey = "LeftButton",
    },
    {
        type = "Flexible",
        key = "rightClick",
        vital = true,
        dorment = true,
        label = L["Right Click"],
        inputs = { "BACKSPACE" },
        emulatedKey = "RightButton",
    },
    {
        type = "Flexible",
        key = "drag",
        vital = true,
        dorment = true,
        label = L["Drag"],
        inputs = { "\\", "CTRL-D" },
        emulatedKey = "\\",
    },
    {
        type = "Virtual",
        key = "home",
        dorment = true,
        label = L["Jump to Beginning"],
        inputs = { "HOME" },
        emulatedKey = "HOME",
    },
    {
        type = "Virtual",
        key = "end",
        dorment = true,
        label = L["Jump to End"],
        inputs = { "END" },
        emulatedKey = "END",
    },
    {
        type = "Flexible",
        key = "tooltip",
        dorment = true,
        label = L["Read Tooltip"],
        inputs = { "SPACE" },
        emulatedKey = "SPACE",
    },
    {
        type = "Function",
        key = "contextMenu",
        vital = true,
        dorment = true,
        label = L["Context Menu"],
        inputs = { "SHIFT-F10" },
    },
})
