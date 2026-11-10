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

-- A short sound when a WowVision window opens and another when it closes
-- (the WowVision menu, the scanner, navigation, the action bars, chat), as
-- Sku plays for its menu. The game's own windows make their own sounds.
settings:add({
    type = "Bool",
    key = "menuSounds",
    label = L["Sounds on Opening and Closing WowVision Menus"],
    default = true,
})

-- Letters jump to the next entry starting with them in the lists that own the keyboard: the WowVision menu, context
-- and dropdown menus (graph/typeAhead.lua, graph/Host.lua).
settings:add({
    type = "Bool",
    key = "letterNavigation",
    label = L["Letter Navigation in Menus"],
    default = true,
})

-- The game sound channel every WowVision sound and beacon plays on
-- (core/audio/channels.lua): its volume is that channel's game slider,
-- so a channel the player keeps for WowVision alone gives WowVision a volume of
-- its own. The list and the default live in WowVision.audio (a version adds
-- the channels its sound options have a slider for).
local soundChannel = settings:add({
    type = "Choice",
    key = "soundChannel",
    label = L["WowVision Sound Channel"],
    default = WowVision.audio.defaultChannel,
    choices = WowVision.audio.channels,
    validate = WowVision.audio.validateChannel,
})
soundChannel.events.valueChange:subscribe(module, function(_, _, _, _, value)
    WowVision.audio.selectedChannel = value
end)

-- The same arrow pressed twice quickly skips the empty slots of a bag or action bar (graph/doublePress.lua).
settings:add({
    type = "Bool",
    key = "skipEmptySlots",
    label = L["Skip Empty Slots on Double Arrow"],
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

-- Testing the dropdown reader on a menu long enough to scroll, which the
-- game's own scrolling menus (Group Finder, Delves, Guild Control) need a
-- high character for: a real Blizzard context menu in scroll mode with a
-- title, checkboxes, radio buttons, N buttons (default 60) and a scrolling
-- submenu at the end; entries 1 and 50 and the submenu row have tooltips.
-- Custom rows: a level range (two edit boxes), a row with a check button
-- and a button, and a voice-style row with a button and a slider. A pick
-- prints what was picked.
module:registerCommand({
    name = "bigmenu",
    description = "Open a long scrolling test menu (optional number of entries)",
    func = function(args)
        if MenuUtil == nil or MenuUtil.CreateContextMenu == nil then
            print("WowVision test menu: this client has no menu system")
            return
        end
        local count = tonumber(args) or 60
        -- "/wv bigmenu dump": the reader's view of the menu (/wv gdrop) a second
        -- after it opens, since a command cannot be typed while it has the keys
        if args == "dump" then
            C_Timer.After(1, function()
                WowVision:SlashCommand("gdrop")
            end)
        end
        local checked = {}
        local radio = 1
        MenuUtil.CreateContextMenu(nil, function(_, root)
            root:SetTag("MENU_WOWVISION_TEST")
            root:SetScrollMode(200)
            root:CreateTitle("WowVision test menu")
            for i = 1, 3 do
                root:CreateCheckbox("Checkbox " .. i, function()
                    return checked[i] == true
                end, function()
                    checked[i] = not checked[i]
                    print("Checkbox " .. i .. (checked[i] and " checked" or " unchecked"))
                end)
            end
            for i = 1, 3 do
                root:CreateRadio("Radio " .. i, function()
                    return radio == i
                end, function()
                    radio = i
                    print("Radio " .. i .. " selected")
                end)
            end
            -- custom rows: Blizzard's level range (two edit boxes) and a row
            -- with a check button and a button of its own
            root:CreateTitle("Level range")
            local levelRange = root:CreateTemplate("LevelRangeFrameTemplate")
            levelRange:AddInitializer(function(frame)
                if frame.Reset ~= nil then
                    frame:Reset()
                end
            end)
            local custom = root:CreateFrame()
            custom:AddInitializer(function(frame)
                local check = frame:AttachTemplate("UICheckButtonTemplate")
                check:SetPoint("LEFT", frame, "LEFT", 0, 0)
                check:SetScript("OnClick", function(self)
                    print("Inner checkbox " .. (self:GetChecked() and "checked" or "unchecked"))
                end)
                local button = frame:AttachTemplate("UIPanelButtonTemplate")
                button:SetSize(100, 22)
                button:SetPoint("LEFT", check, "RIGHT", 4, 0)
                button:SetText("Inner button")
                button:SetScript("OnClick", function()
                    print("Inner button clicked")
                end)
                return 160, 26
            end)
            -- a row shaped like the unit menu's voice volume rows: a toggle
            -- button and a slider (0 to 100) with a label of its own
            local volume = root:CreateFrame()
            volume:AddInitializer(function(frame)
                local mute = frame:AttachTemplate("UIPanelButtonTemplate")
                mute:SetSize(60, 20)
                mute:SetPoint("LEFT", frame, "LEFT", 0, 0)
                mute:SetText("Test mute")
                mute:SetScript("OnClick", function()
                    print("Test mute clicked")
                end)
                local slider = frame:AttachTemplate("UISliderTemplate")
                slider:SetSize(120, 17)
                slider:SetPoint("LEFT", mute, "RIGHT", 6, 0)
                slider:SetMinMaxValues(0, 100)
                slider:SetValueStep(1)
                if slider.SetObeyStepOnDrag ~= nil then
                    slider:SetObeyStepOnDrag(true)
                end
                if slider.Label == nil then
                    slider.Label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                    slider.Label:SetPoint("BOTTOM", slider, "TOP", 0, 0)
                end
                slider.Label:SetText("Test volume")
                slider:SetValue(50)
                return 200, 30
            end)
            root:CreateTitle("Entries")
            for i = 1, count do
                local entry = root:CreateButton("Entry " .. i, function()
                    print("Picked entry " .. i)
                end)
                -- a tooltip on the first entry and on one far down (the tooltip key)
                if (i == 1 or i == 50) and entry.SetTitleAndTextTooltip ~= nil then
                    entry:SetTitleAndTextTooltip("Entry " .. i, "Tooltip text of entry " .. i)
                end
            end
            local submenu = root:CreateButton("Submenu")
            if submenu.SetTitleAndTextTooltip ~= nil then
                submenu:SetTitleAndTextTooltip("Submenu", "Tooltip text of the submenu row")
            end
            submenu:SetScrollMode(200)
            for i = 1, 30 do
                submenu:CreateButton("Sub entry " .. i, function()
                    print("Picked sub entry " .. i)
                end)
            end
        end)
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
    -- Closes every WowVision window and every window of the game at once.
    {
        type = "Function",
        key = "wowvision/closeAll",
        label = L["Close All Windows"],
        inputs = { "SHIFT-ESCAPE" },
        interruptSpeech = true,
        func = function()
            if WowVision.UIHost:closeAllWindows() then
                WowVision:notify(L["All windows closed"])
            end
        end,
    },
})
