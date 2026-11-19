-- Headless only (tools/headless-tests.lua; not in modules.xml): the menu
-- sounds play for WowVision's own windows, never for the game's.
local testRunner = WowVision.testing.testRunner

-- Run fn(manager, played) with the game and the WowVision pieces the
-- window manager touches faked.
local function withManager(settings, fn)
    local saved = {
        base = WowVision.base,
        host = WowVision.graphHost,
        PlaySound = PlaySound,
    }
    local played = {}
    WowVision.base = {
        ui = { settings = settings },
        speech = { uiStop = function() end },
    }
    WowVision.graphHost = { close = function() end }
    PlaySound = function(kit)
        tinsert(played, kit)
    end
    local ok, err = pcall(fn, WowVision.WindowManager:new(), played)
    WowVision.base, WowVision.graphHost, PlaySound = saved.base, saved.host, saved.PlaySound
    if not ok then
        error(err, 0)
    end
end

-- A window as if open, without building its graph screen.
local function opened(manager, typeKey, config)
    local window = manager:CreateWindow(typeKey, config)
    local instance = { ref = window, name = window.name }
    window._openInstance = instance
    window._isCurrentlyOpen = true
    manager:notifyOpened(window, instance)
    return window
end

testRunner:addSuite("MenuSounds", {
    ["a WowVision window plays the open sound, then the close sound"] = function(t)
        withManager({ menuSounds = true }, function(manager, played)
            opened(manager, "ManualWindow", { name = "scanner" })
            manager:closeWindow("scanner")
            t:assertEqual(table.concat(played, ","), "88,89")
        end)
    end,

    ["a game window opens and closes without them"] = function(t)
        withManager({ menuSounds = true }, function(manager, played)
            local window = opened(manager, "FrameWindow", { name = "merchant", frameName = "MerchantFrame" })
            window:close(manager)
            t:assertEqual(#played, 0)
        end)
    end,

    ["the setting switches them off"] = function(t)
        withManager({ menuSounds = false }, function(manager, played)
            opened(manager, "ManualWindow", { name = "chat" })
            manager:closeWindow("chat")
            t:assertEqual(#played, 0)
        end)
    end,
})
