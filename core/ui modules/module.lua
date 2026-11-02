local module = WowVision.base:createModule("ui")
local L = module.L
module:setLabel(L["UI"])
module:setVital(true)

local settings = module:hasSettings()

settings:add({
    type = "Bool",
    key = "interruptSpeechOnWindowClose",
    label = L["Interrupt Speech on Window Close"],
    default = false,
})

-- Chasing stuck movement keys with testers: prints when windows take, wait
-- for and release the navigation keys, and what the held check saw.
module:registerCommand({
    name = "keylog",
    description = "Toggle logging of when windows take and release the navigation keys",
    func = function()
        local host = WowVision.graphHost
        host.keyLog = not host.keyLog
        print("WowVision key log " .. (host.keyLog and "on" or "off"))
    end,
})

-- Chasing controller problems with testers: the pad log (core/ui/input/
-- pad.lua) runs by itself with the gamepad interface on; this starts it
-- afresh.
module:registerCommand({
    name = "padlog",
    description = "Start the controller log afresh",
    func = function()
        if WowVision.pad.restartLog() then
            print("WowVision pad log started afresh")
        else
            print("WowVision pad log: only with the gamepad interface on")
        end
    end,
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
        type = "Flexible",
        key = "scrollUp",
        vital = true,
        dorment = true,
        label = L["Scroll Up"],
        inputs = { "PAGEUP" },
    },
    {
        type = "Flexible",
        key = "scrollDown",
        vital = true,
        dorment = true,
        label = L["Scroll Down"],
        inputs = { "PAGEDOWN" },
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
        func = function() end,
    },
    -- The controller's Escape (B) where Escape stays with the game; no
    -- keyboard input, the keyboard's Escape is the game's own.
    {
        type = "Function",
        key = "gameClose",
        dorment = true,
        label = L["Close (Controller)"],
        inputs = {},
        func = function() end,
    },
    -- Opens the WowVision menu, which otherwise needs /wv typed: Shift-F1,
    -- and the controller's way in (the shortcut layer).
    {
        type = "Function",
        key = "wowvision/menu",
        label = L["WowVision Menu"],
        inputs = { "SHIFT-F1" },
        interruptSpeech = true,
        func = function()
            WowVision.graph.settings.openMenu()
        end,
    },
})
