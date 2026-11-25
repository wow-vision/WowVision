-- Forever Fishing with WowVision: optional (OptionalDeps in WowVision_Camelot.toc), only with that addon installed.
-- Shift+F7 opens the screen, the WowVision menu has Start Fishing, what the window shows and hides is said, and
-- /wv fishing does the rest.
local loaded = WowVision.loadedAddons
if loaded == nil or not (loaded["ForeverFishing"] or loaded["foreverfishing"]) then
    return
end

local ns = WowVision.foreverFishing
local L = ns.L
local Game = ns.Game
local Fishing = ns.Fishing
local Screen = ns.Screen

local module = WowVision.base.windows:createModule("foreverFishing")
module:setLabel(L["Forever Fishing"])
ns.module = module
local settings = module:hasSettings()
settings:add({ type = "Bool", key = "messages", label = L["Say the Fishing Window's Messages"], default = true })

ns.BINDING_KEY = "foreverFishing/open"
ns.DEFAULT_KEY = "SHIFT-F7"

module:registerBinding({
    type = "Function",
    key = ns.BINDING_KEY,
    label = L["Open the fishing window screen"],
    inputs = { ns.DEFAULT_KEY },
    interruptSpeech = true,
    func = Game.guarded(function()
        Screen.toggle()
    end),
})

-- Whether the window's own messages (gear results, warnings) and its opening and closing are said by themselves.
function ns.messagesOn()
    return module.settings.messages ~= false
end

function ns.setMessages(on)
    module.settings.messages = on == true
end

-- The WowVision menu's entry and the command's: it does what /fish does and names the key that reads what opened.
function ns.startFishing()
    return Fishing.start(Game, Game.speak, ns.Screen.keyName())
end

WowVision.graph.settings.registerRootEntry(function(builder)
    if not module:getEnabled() then
        return
    end
    builder:addItem(
        WowVision.graph.ControlId.structural("foreverFishingStart"),
        WowVision.graph.nodes.button({
            label = L["Start fishing"],
            onActivate = Game.guarded(function()
                ns.startFishing()
            end),
        })
    )
end)

-- ------------------------------------------------------------- what is said

local lastNotice, lastNoticeAt = nil, nil

local function now()
    return GetTime ~= nil and GetTime() or 0
end

-- The same message is not said twice in a row within a few seconds (the window can put one up again and again).
local function sayNotice(message)
    if type(message) ~= "string" or message == "" then
        return
    end
    local when = now()
    if message == lastNotice and lastNoticeAt ~= nil and when - lastNoticeAt < 5 and when >= lastNoticeAt then
        return
    end
    lastNotice, lastNoticeAt = message, when
    Game.speak(message)
end
ns.sayNotice = sayNotice

-- The window opened: said once for each opening. The game also fires the show and hide of a frame when its PARENT is
-- shown or hidden (Forever Fishing hides the game's interface while you fish), so a hide that leaves the window shown
-- is not a closing, and a show while it is already announced as open is not an opening.
ns.announcedOpen = false

function ns.onShown()
    if ns.announcedOpen then
        return
    end
    ns.announcedOpen = true
    if not ns.messagesOn() then
        return
    end
    local info = Fishing.read(Game)
    Game.speak(Fishing.openedText(info, Screen.keyName()))
end

function ns.onHidden()
    if Game.isOpen() then
        return
    end
    local wasOpen = ns.announcedOpen
    ns.announcedOpen = false
    if not wasOpen or not ns.messagesOn() or Game.quiet then
        return
    end
    Game.speak(L["Fishing window closed."])
end

function ns.onNotice(message, kind)
    if ns.messagesOn() and Fishing.noticeWanted(kind) then
        sayNotice(message)
    end
end

function ns.onWarning(message)
    if ns.messagesOn() then
        sayNotice(message)
    end
end

-- The hooks need Forever Fishing's window, which is made a moment after the player logs in: tried at once, then again
-- a few times.
function ns.installHooks()
    local ok, installed = pcall(Game.installHooks, {
        shown = ns.onShown,
        hidden = ns.onHidden,
        notice = ns.onNotice,
        warning = ns.onWarning,
    })
    if not ok then
        Game.report(installed)
        return false
    end
    ns.hooked = installed == true
    return ns.hooked
end

local function retryHooks(attempt)
    if ns.installHooks() then
        -- the window may already be open: it was shown before the hook was there
        if Game.isOpen() and ns.messagesOn() then
            ns.onShown()
        end
        return
    end
    if attempt < 6 and C_Timer ~= nil and C_Timer.After ~= nil then
        C_Timer.After(5, function()
            retryHooks(attempt + 1)
        end)
    end
end
ns.retryHooks = retryHooks

-- ----------------------------------------------------------------- command

local function words(list)
    local set = {}
    for _, word in ipairs(list) do
        set[word] = true
    end
    return set
end

local START = words({ "start", "commencer", "beginnen", "demarrer", "démarrer", "pecher", "pêcher", "angeln" })
local CLOSE = words({ "close", "fermer", "schliessen", "schließen", "stop", "arreter", "arrêter" })
local READ = words({ "read", "lire", "lesen", "dire", "say" })
local MESSAGES = words({ "messages", "message", "meldungen" })
local GOLD = words({ "or", "gold", "argent", "gewinn" })
local HELP = words({ "help", "aide", "hilfe", "?" })
local ON = words({ "on", "oui", "yes", "an", "ja", "1", "true" })
local OFF = words({ "off", "non", "no", "aus", "nein", "0", "false" })

function ns.handleCommand(message)
    local word, rest = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    word, rest = word or "", rest or ""
    local argument = rest:match("^(%S*)") or ""
    if word == "" then
        Screen.toggle()
    elseif START[word] then
        ns.startFishing()
    elseif CLOSE[word] then
        Fishing.close(Game, Game.speak)
    elseif READ[word] then
        local info = Fishing.read(Game)
        Game.speak(Fishing.sentence(info))
    elseif GOLD[word] then
        -- the gold per hour and what the session holds, from Life on Azeroth Market and the vendor's prices
        local info = Fishing.read(Game)
        local texts = {}
        for _, line in ipairs(info.valueLines or {}) do
            texts[#texts + 1] = line.text
        end
        if #texts == 0 then
            Game.speak(L["Nothing caught yet this session."])
        else
            Game.speak(table.concat(texts, " "))
        end
    elseif MESSAGES[word] then
        if ON[argument] then
            ns.setMessages(true)
        elseif OFF[argument] then
            ns.setMessages(false)
        else
            ns.setMessages(not ns.messagesOn())
        end
        Game.speak(ns.messagesOn() and L["Fishing messages are on."] or L["Fishing messages are off."])
    elseif HELP[word] then
        Game.speak(L["Fishing: /wv fishing opens the screen, /wv fishing start opens the fishing window and equips the gear, /wv fishing close closes it, /wv fishing read says what is on it, /wv fishing gold says the gold per hour, /wv fishing messages on or off."])
    else
        Screen.toggle()
    end
end

module:registerCommand({
    name = "fishing",
    description = L["Forever Fishing: screen, start, close, read, gold, messages."],
    func = function(args)
        ns.handleCommand(args)
    end,
})

-- Forever Fishing builds its window a moment after login: the hooks are tried a few seconds after entering the world.
module.HOOK_AFTER = 3

module:registerEvent("event", "PLAYER_ENTERING_WORLD")

function module:onEvent()
    if ns.hooksAsked then
        return
    end
    ns.hooksAsked = true
    C_Timer.After(self.HOOK_AFTER, Game.guarded(function()
        ns.retryHooks(1)
    end))
end
