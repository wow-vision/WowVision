-- Everything this feature asks of the game, of WowVision and of other addons, in one place, so the rest can be tested
-- with this table replaced. Each function guards its own call: a missing piece gives nil, never an error.
local ns = WowVision.restedXP
local Source = ns.Source

local Game = {}
ns.Game = Game

-- ------------------------------------------------------------- the others

function Game.rxp()
    return Source.rxp()
end

function Game.hbd()
    local stub = rawget(_G, "LibStub")
    if stub == nil then
        return nil
    end
    local ok, lib = pcall(stub, "HereBeDragons-2.0", true)
    if ok then
        return lib
    end
    return nil
end

-- The way the player faces, in radians counter clockwise from north; nil when the game does not say (or hides it).
function Game.facing()
    if GetPlayerFacing == nil then
        return nil
    end
    local ok, value = pcall(GetPlayerFacing)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

-- The game's clock in seconds, nil where there is none.
function Game.now()
    return Source.now()
end

function Game.playerLevel()
    if UnitLevel == nil then
        return nil
    end
    local ok, value = pcall(UnitLevel, "player")
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

function Game.inCombat()
    return InCombatLockdown ~= nil and InCombatLockdown() == true
end

-- WowVision's maps module (beacon, routes), nil when WowVision has none.
function Game.maps()
    local wowVision = rawget(_G, "WowVision")
    local base = wowVision ~= nil and wowVision.base or nil
    local navigation = base ~= nil and base.navigation or nil
    return navigation ~= nil and navigation.maps or nil
end

function Game.speak(text)
    if text == nil or text == "" then
        return
    end
    local wowVision = rawget(_G, "WowVision")
    if wowVision ~= nil and wowVision.speak ~= nil then
        wowVision:speak(text)
    else
        print(text)
    end
end

-- Runs fn on the next frame: a screen is not closed or replaced from inside the key press that is using it.
function Game.defer(fn)
    if C_Timer ~= nil and C_Timer.After ~= nil then
        C_Timer.After(0, fn)
    else
        fn()
    end
end

-- Runs fn after some seconds.
function Game.after(seconds, fn)
    if C_Timer ~= nil and C_Timer.After ~= nil then
        C_Timer.After(seconds, fn)
    else
        fn()
    end
end

-- Reloads the game's interface (what /reload does).
function Game.reload()
    local reload = rawget(_G, "ReloadUI")
    if type(reload) == "function" then
        reload()
    end
end

-- ---------------------------------------------------------------- windows

local function windowManager()
    local wowVision = rawget(_G, "WowVision")
    local host = wowVision ~= nil and wowVision.UIHost or nil
    return host ~= nil and host.windowManager or nil
end

function Game.isOpen(name)
    local manager = windowManager()
    if manager == nil then
        return false
    end
    for _, instance in ipairs(manager.openWindows) do
        if instance.name == name then
            return true
        end
    end
    return false
end

-- Opens a frameless graph window of the given name. screen is the graphScreen config (render, captureClose...).
function Game.open(name, screen)
    local wowVision = rawget(_G, "WowVision")
    local host = wowVision ~= nil and wowVision.UIHost or nil
    if host == nil then
        return false
    end
    host:openTemporaryWindow({ name = name, graphScreen = screen })
    return true
end

function Game.close(name)
    local wowVision = rawget(_G, "WowVision")
    local host = wowVision ~= nil and wowVision.UIHost or nil
    if host ~= nil then
        host:closeWindow(name)
    end
end

-- A window WowVision polls: it is open while isOpenFunc says so, and shows the graph screen given. Registered once.
-- Returns false when WowVision has no window manager.
function Game.registerWindow(name, isOpenFunc, screen)
    local wowVision = rawget(_G, "WowVision")
    local host = wowVision ~= nil and wowVision.UIHost or nil
    local manager = host ~= nil and host.windowManager or nil
    local windows = wowVision ~= nil and wowVision.WindowManager or nil
    if manager == nil or windows == nil then
        return false
    end
    if manager.getWindow ~= nil and manager:getWindow(name) ~= nil then
        return true
    end
    local window = windows:CreateWindow("CustomWindow", {
        name = name,
        isOpenFunc = isOpenFunc,
        graphScreen = screen,
    })
    manager:RegisterWindow(window)
    return true
end

-- ---------------------------------------------------------------- options

-- Whether RestedXP's page of the game's options window (Options, AddOns, RestedXP Guides) is on screen. RestedXP
-- gives that page to the game as a canvas frame it keeps as RXPOptions; the frame is visible while its page is
-- selected and the window is open.
function Game.optionsShown()
    local rxp = Game.rxp()
    local frame = rxp ~= nil and rxp.RXPOptions or nil
    if type(frame) ~= "table" or frame.IsVisible == nil then
        return false
    end
    local ok, visible = pcall(frame.IsVisible, frame)
    return ok and visible == true
end

-- Tells AceConfig that a setting changed, so the page the game draws for sighted players shows the new value and
-- the options that depend on it follow.
function Game.notifyOptionsChanged(appName)
    local stub = rawget(_G, "LibStub")
    if stub == nil or appName == nil then
        return
    end
    local ok, registry = pcall(stub, "AceConfigRegistry-3.0", true)
    if ok and registry ~= nil and registry.NotifyChange ~= nil then
        pcall(registry.NotifyChange, registry, appName)
    end
end

-- --------------------------------------------------------------- settings

local DEFAULTS = {
    announceSteps = true,
    announceDestination = false,
    -- the beacon or the route is redone toward the new destination when RestedXP's arrow moves to one
    recalculate = true,
    -- off: any move of the arrow counts; on: only a move of more than 10 yards from where the guidance was aimed
    ignoreSmallMoves = false,
}
Game.defaults = DEFAULTS

-- The module's settings (module.lua).
function Game.getSetting(key)
    local settings = ns.settings
    if settings ~= nil and settings[key] ~= nil then
        return settings[key]
    end
    return DEFAULTS[key]
end

function Game.setSetting(key, value)
    if ns.settings ~= nil then
        ns.settings[key] = value
    end
end
