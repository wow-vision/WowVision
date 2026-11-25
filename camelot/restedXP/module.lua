-- RestedXP with WowVision: optional (OptionalDeps in WowVision_Camelot.toc), only with RXPGuides installed. The keys,
-- /wv rxp, the hooks into RestedXP (its menus, its importer, its steps) and the follower that keeps the guidance on the
-- arrow.
local loaded = WowVision.loadedAddons
if loaded == nil or not (loaded["RXPGuides"] or loaded["rxpguides"]) then
    return
end

local ns = WowVision.restedXP
local L = ns.L
local Text = ns.Text
local Source = ns.Source
local Guidance = ns.Guidance
local Import = ns.Import
local Screens = ns.Screens
local Game = ns.Game

-- An error here must never break the keys, and must not repeat on every press either: report each distinct
-- message once.
local reported = {}
local function report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("RestedXP with WowVision: " .. err)
end
ns.report = report

local function guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            report(err)
        end
    end
end

local module = WowVision.base.windows:createModule("restedXP")
module:setLabel(L["RestedXP"])
ns.module = module

local settings = module:hasSettings()
local defaults = Game.defaults
settings:add({ type = "Bool", key = "announceSteps", label = L["Say each new step"], default = defaults.announceSteps })
settings:add({
    type = "Bool",
    key = "announceDestination",
    label = L["Say where the arrow points when it changes"],
    default = defaults.announceDestination,
})
settings:add({
    type = "Bool",
    key = "recalculate",
    label = L["Recalculate the guidance when the arrow changes destination"],
    default = defaults.recalculate,
})
settings:add({
    type = "Bool",
    key = "ignoreSmallMoves",
    label = string.format(L["Ignore small moves of the arrow (under %s)"], Text.yards(Guidance.smallMove)),
    default = defaults.ignoreSmallMoves,
})
ns.settings = module.settings

-- ------------------------------------------------------------- the actions

local function withRxp(action)
    local rxp = Game.rxp()
    if rxp == nil then
        Game.speak(L["RestedXP is not loaded."])
        return
    end
    return action(rxp)
end

function ns.sayStep()
    withRxp(function(rxp)
        if not Source.hasGuide(rxp) then
            Game.speak(L["No guide chosen. Open the menu to choose one."])
            return
        end
        local text = Source.activeSpeech(rxp)
        if text == "" then
            text = L["No step to show right now."]
        end
        Game.speak(text)
    end)
end

function ns.sayArrow()
    withRxp(function(rxp)
        Game.speak(Screens.arrowSpeech(rxp))
    end)
end

-- A guidance key: starts the guidance in this mode, or ends it when that mode already guides.
function ns.toggleGuidance(mode)
    withRxp(function(rxp)
        local maps = Game.maps()
        if Guidance.following == mode then
            Guidance.stop(maps)
            Game.speak(L["Guidance stopped."])
            return
        end
        local arrow = Source.arrow(rxp, Game.hbd(), Game.facing())
        local ok, why = Guidance.start(maps, arrow, mode)
        if not ok then
            Game.speak(why)
        end
    end)
end

-- What a right click on RestedXP's window does: its menu (the guides, the tips, the settings). Opened from the
-- menu RestedXP builds, so it needs neither its drop-down nor the mouse.
function ns.guideMenu()
    withRxp(function(rxp)
        local list = Source.menu(rxp)
        if list == nil then
            Game.speak(L["RestedXP has no menu to show."])
            return
        end
        if Game.isOpen(Screens.MAIN) then
            Game.speak(L["The RestedXP menu is in the main screen."])
            return
        end
        if Game.inCombat() then
            Game.speak(L["Not available in combat."])
            return
        end
        Screens.openMenu(list)
    end)
end

function ns.stopGuidance()
    local maps = Game.maps()
    if not Guidance.stop(maps) then
        Game.speak(L["Guidance stopped."])
    end
end

function ns.skipStep()
    withRxp(function(rxp)
        if Source.skipActive(rxp) == 0 then
            Game.speak(L["Nothing to skip."])
        end
    end)
end

local function stepBy(offset)
    withRxp(function(rxp)
        local info = Source.guide(rxp)
        if info == nil then
            Game.speak(L["No guide chosen. Open the menu to choose one."])
            return
        end
        Source.goToStep(rxp, info.step + offset)
    end)
end

function ns.nextStep()
    stepBy(1)
end

function ns.previousStep()
    stepBy(-1)
end

-- ----------------------------------------------------- the steps, announced

-- RestedXP says nothing out loud when the step changes. This says the new step once the window has been
-- rebuilt, and not twice in a row for the same text.
local pending = false
local lastText, lastTime = nil, nil

local function announceStep()
    pending = false
    if Game.getSetting("announceSteps") == false then
        return
    end
    local rxp = Game.rxp()
    if rxp == nil or not Source.hasGuide(rxp) then
        return
    end
    local text = Source.activeSpeech(rxp)
    if text == "" then
        return
    end
    local now = GetTime ~= nil and GetTime() or 0
    if text == lastText and lastTime ~= nil and now - lastTime < 3 then
        return
    end
    lastText, lastTime = text, now
    Game.speak(text)
end
ns.announceStep = announceStep

function ns.stepChanged()
    if pending then
        return
    end
    pending = true
    Game.after(0.5, guarded(function()
        announceStep()
    end))
end

-- --------------------------------------------------------------------- keys

ns.bindings = {
    {
        type = "Function",
        key = "restedxp/menu",
        label = "RestedXP Menu",
        inputs = { "SHIFT-F2" },
        interruptSpeech = true,
        func = function()
            Screens.toggleMain()
        end,
    },
    {
        type = "Function",
        key = "restedxp/guides",
        label = "Right-Click Menu of RestedXP (Guides)",
        inputs = { "ALT-CTRL-F2" },
        interruptSpeech = true,
        func = function()
            ns.guideMenu()
        end,
    },
    {
        type = "Function",
        key = "restedxp/step",
        label = "Say the RestedXP Step",
        inputs = { "ALT-F2" },
        interruptSpeech = true,
        func = function()
            ns.sayStep()
        end,
    },
    {
        type = "Function",
        key = "restedxp/arrow",
        label = "Say Where the RestedXP Arrow Points",
        inputs = { "CTRL-F2" },
        interruptSpeech = true,
        func = function()
            ns.sayArrow()
        end,
    },
    {
        type = "Function",
        key = "restedxp/beacon",
        label = "Sound Beacon Toward the RestedXP Arrow",
        inputs = { "CTRL-SHIFT-F2" },
        interruptSpeech = true,
        func = function()
            ns.toggleGuidance("beacon")
        end,
    },
    {
        type = "Function",
        key = "restedxp/route",
        label = "WowVision Route to the RestedXP Arrow",
        inputs = { "ALT-SHIFT-F2" },
        interruptSpeech = true,
        func = function()
            ns.toggleGuidance("route")
        end,
    },
    {
        type = "Function",
        key = "restedxp/stop",
        label = "Stop Guiding to the RestedXP Arrow",
        inputs = {},
        interruptSpeech = true,
        func = function()
            ns.stopGuidance()
        end,
    },
    {
        type = "Function",
        key = "restedxp/skip",
        label = "Skip the RestedXP Step",
        inputs = {},
        interruptSpeech = true,
        func = function()
            ns.skipStep()
        end,
    },
    {
        type = "Function",
        key = "restedxp/next",
        label = "Next RestedXP Step",
        inputs = {},
        interruptSpeech = true,
        func = function()
            ns.nextStep()
        end,
    },
    {
        type = "Function",
        key = "restedxp/previous",
        label = "Previous RestedXP Step",
        inputs = {},
        interruptSpeech = true,
        func = function()
            ns.previousStep()
        end,
    },
}

for _, info in ipairs(ns.bindings) do
    local copy = {}
    for key, value in pairs(info) do
        copy[key] = value
    end
    copy.label = L[info.label]
    copy.func = guarded(info.func)
    module:registerBinding(copy)
end

-- ------------------------------------------------------------------ hooks

-- RestedXP shows its menus (the right-click menu of its window, its cog, the minimap button, the tips window)
-- through addon:ShowMenu(menu, ...). The drop-down is still shown, for anyone who sees it; a WowVision screen with
-- the same entries opens beside it.
function ns.hookMenus(rxp)
    if rxp == nil or ns.menusHooked or type(rxp.ShowMenu) ~= "function" then
        return false
    end
    local original = rxp.ShowMenu
    rxp.ShowMenu = function(self, menu, ...)
        local result = { original(self, menu, ...) }
        local ok, err = pcall(Screens.openMenu, menu)
        if not ok then
            report(err)
        end
        return unpack(result)
    end
    ns.menusHooked = true
    return true
end

-- RestedXP's importer reports in its own window (the size of a paste, how many guides are loaded, the errors): the
-- same news is said out loud.
function ns.hookImport(rxp)
    if rxp == nil then
        return false
    end
    local hooked = Import.hook(rxp, function(text)
        Game.speak(text)
    end)
    if hooked then
        ns.importHooked = true
    end
    return hooked
end

-- RestedXP sends a message each time a guide step becomes the current one and when a guide is loaded.
function ns.hookSteps()
    if ns.stepsHooked then
        return false
    end
    local stub = rawget(_G, "LibStub")
    if stub == nil then
        return false
    end
    local ok, events = pcall(stub, "AceEvent-3.0", true)
    if not ok or events == nil or events.Embed == nil then
        return false
    end
    local listener = {}
    events:Embed(listener)
    listener:RegisterMessage("RXP_STEP_ACTIVATED", guarded(ns.stepChanged))
    listener:RegisterMessage("RXP_GUIDE_LOADED", guarded(ns.stepChanged))
    ns.stepListener = listener
    ns.stepsHooked = true
    return true
end

-- WowVision's own "cancel navigation" (Shift+F12) also ends the following of the arrow.
function ns.hookCancel()
    local maps = Game.maps()
    if maps == nil or ns.cancelHooked or type(maps.cancelNavigation) ~= "function" then
        return false
    end
    hooksecurefunc(maps, "cancelNavigation", function()
        Guidance.following = nil
        Guidance.lastPoint = nil
    end)
    ns.cancelHooked = true
    return true
end

-- ---------------------------------------------------------------- follower

-- Where the arrow last pointed that the player knows of: said, or guided to.
local lastDestination = nil

-- Every half second: when the arrow points somewhere else, the guidance goes there too (unless the player turned
-- that off: then the beacon or the route keeps the destination it was started with); and, if asked, the new
-- destination is said, except while the guidance goes there by itself, since WowVision says it then. "Somewhere
-- else" is any move of the arrow, or only a move of more than Guidance.smallMove yards from where the guidance last
-- aimed when the player asked to ignore small moves.
function ns.follow()
    local rxp = Game.rxp()
    if rxp == nil then
        return
    end
    local recalculating = Guidance.following ~= nil and Game.getSetting("recalculate") ~= false
    local announcing = Game.getSetting("announceDestination") == true
    if not recalculating and not announcing then
        return
    end
    local tolerance = Game.getSetting("ignoreSmallMoves") == true and Guidance.smallMove or nil
    local arrow = Source.arrow(rxp, Game.hbd(), Game.facing())
    if recalculating then
        Guidance.follow(Game.maps(), arrow, tolerance)
    end
    local point = Guidance.point(arrow)
    if point == nil then
        lastDestination = nil
    elseif recalculating then
        lastDestination = point
    elseif Guidance.moved(lastDestination, point, tolerance) then
        -- (only here, so that small drifts add up against what was last said)
        Game.speak(Text.arrow(arrow))
        lastDestination = point
    end
end

-- ---------------------------------------------------------------- windows

-- RestedXP's page in the game's options (Options, AddOns, RestedXP Guides) is a canvas the keyboard cannot reach: the
-- same settings tree opens as a WowVision screen while that page is shown.
module:registerWindow({
    type = "CustomWindow",
    name = "restedxp-settings",
    isOpen = function()
        return Game.optionsShown()
    end,
    graphScreen = Screens.optionsConfig(),
})

-- ------------------------------------------------------------------ module

-- RestedXP may finish loading after WowVision: the hooks that need it are tried again when the player enters the world.
function ns.installRxpHooks()
    local rxp = Game.rxp()
    if rxp ~= nil then
        ns.hookMenus(rxp)
        ns.hookImport(rxp)
    end
    ns.hookSteps()
    ns.hookCancel()
end

module:registerEvent("event", "PLAYER_ENTERING_WORLD")

function module:onEvent()
    guarded(ns.installRxpHooks)()
end

-- How often the follower looks at the arrow (seconds).
module.FOLLOW_EVERY = 0.5

function module:followIfDue()
    local now = GetTime()
    if self.nextFollow ~= nil and now < self.nextFollow then
        return
    end
    self.nextFollow = now + self.FOLLOW_EVERY
    guarded(ns.follow)()
end

function module:onEnable()
    guarded(ns.installRxpHooks)()
    self:hasUpdate(function(self)
        self:followIfDue()
    end)
end

-- ----------------------------------------------------------------- command

-- (string.lower leaves an accented capital as it is, so the capitalised forms are there too)
local STEP = { step = true, etape = true, ["étape"] = true, ["Étape"] = true, schritt = true }
local ARROW = { arrow = true, fleche = true, ["flèche"] = true, ["flÈche"] = true, pfeil = true }
local BEACON = { beacon = true, balise = true, signal = true }
local ROUTE = { route = true, itineraire = true, ["itinéraire"] = true, ["itinÉraire"] = true }
local STOP = { stop = true, arret = true, ["arrêt"] = true, ["arrÊt"] = true, stopp = true }

function ns.handleCommand(message)
    local word = (message or ""):lower():match("^%s*(%S*)")
    word = word or ""
    if STEP[word] then
        ns.sayStep()
    elseif ARROW[word] then
        ns.sayArrow()
    elseif BEACON[word] then
        ns.toggleGuidance("beacon")
    elseif ROUTE[word] then
        ns.toggleGuidance("route")
    elseif STOP[word] then
        ns.stopGuidance()
    elseif word == "" or word == "menu" or word == "menü" then
        Screens.toggleMain()
    else
        Game.speak(
            L["RestedXP: /wv rxp opens the menu, /wv rxp step says the step, /wv rxp arrow says where the arrow points, /wv rxp beacon starts a sound beacon, /wv rxp route a WowVision route, /wv rxp stop ends the guidance."]
        )
    end
end

module:registerCommand({
    name = "rxp",
    description = L["RestedXP: menu, step, arrow, beacon, route, stop."],
    func = function(args)
        ns.handleCommand(args)
    end,
})
