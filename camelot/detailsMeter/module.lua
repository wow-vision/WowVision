-- The damage meter's module: optional (OptionalDeps in WowVision_Camelot.toc), only with Details installed. Shift+F6
-- opens the screen, Alt+Ctrl+D says your line, Alt+Ctrl+M and Alt+Ctrl+C step through the figures and the fights, /wv
-- meter does the rest.
local loaded = WowVision.loadedAddons
if loaded == nil or not (loaded["Details"] or loaded["details"]) then
    return
end

local ns = WowVision.detailsMeter
local L = ns.L
local Text = ns.Text
local Game = ns.Game
local Data = ns.Data
local Screen = ns.Screen

local module = WowVision.base.windows:createModule("detailsMeter")
module:setLabel(L["Details damage meter"])
ns.module = module
local settings = module:hasSettings()
settings:add({ type = "Bool", key = "follow", label = L["Follow the Details window"], default = Game.DEFAULTS.follow })
ns.settings = module.settings

local function readSpeak(attribute)
    local selection = Data.selection(attribute)
    local view, reason = Data.read(selection)
    if view == nil then
        Game.speak(Data.reasonText(reason))
    end
    return view
end

-- "You: 1240 damage per second, second of 5. The best: Bob, 1500 damage per second."
function ns.sayMine(attribute)
    local view = readSpeak(attribute)
    if view ~= nil then
        Game.speak(Data.quickSentence(view))
    end
end

-- The essentials, in order: which fight and figures with your line and rank, the best, the group.
function ns.sayOverview()
    local selection = Data.selection()
    local view, reason = Data.read(selection)
    if view == nil then
        Game.speak(Data.reasonText(reason))
        return
    end
    local parts = { Data.overview(selection, view, reason) }
    local best = Data.bestLine(view)
    if best then
        parts[#parts + 1] = best .. "."
    end
    parts[#parts + 1] = Data.groupLine(selection, view)
    Game.speak(Text.join(parts, " "))
end

-- One step through the fights (what = "segment") or the measures ("attribute"), and what is shown now, said.
function ns.cycle(what, step)
    if Data.cycle(what, step) == nil then
        Game.speak(Data.reasonText("missing"))
        return
    end
    Game.speak(Data.readout())
end

-- The first of the list.
ns.TOP = 3
function ns.sayTop(count, attribute)
    local view = readSpeak(attribute)
    if view ~= nil then
        Game.speak(Data.topSentence(view, count or ns.TOP))
    end
end

-- Which fight, which figures, and whether Details is followed.
function ns.sayStatus()
    local selection = Data.selection()
    local attribute = Data.attribute(selection.attribute)
    if attribute == nil then
        Game.speak(Data.reasonText("missing"))
        return
    end
    local following = Game.getSetting("follow") ~= false
    local parts = { Data.segmentLabel(selection.segment), Data.attributeName(attribute) }
    if selection.followed then
        parts[#parts + 1] = L["following Details"]
    elseif following then
        parts[#parts + 1] = Game.hasDetails() and L["Details has no window open"] or L["Details is not installed"]
    else
        parts[#parts + 1] = L["not following Details"]
    end
    Game.speak(Text.join(parts, ", ") .. ".")
end

-- ------------------------------------------------------------------- keys

-- Shift+F6: the screen. Alt+Ctrl+D: D for damage; Alt+Ctrl+M the measure, Alt+Ctrl+C the fight.
ns.bindings = {
    {
        type = "Function",
        key = "details/open",
        label = "Open the Details damage meter",
        inputs = { "SHIFT-F6" },
        interruptSpeech = true,
        func = function()
            Screen.toggle()
        end,
    },
    {
        type = "Function",
        key = "details/say",
        label = "Say my line in the Details damage meter",
        inputs = { "ALT-CTRL-D" },
        interruptSpeech = true,
        func = function()
            ns.sayMine()
        end,
    },
    -- Alt+Ctrl+M and Alt+Ctrl+C: M for the measure, C for the fight (combat). Nothing else is a key: the steps back, the
    -- choice of a fight or of all fights together, following Details and the reset are options in the screen
    -- (Shift+F6), where each says what Enter does; the reset in particular is only there, behind its question.
    {
        type = "Function",
        key = "details/measure-next",
        label = "Next measure of the damage meter",
        inputs = { "ALT-CTRL-M" },
        interruptSpeech = true,
        func = function()
            ns.cycle("attribute", 1)
        end,
    },
    {
        type = "Function",
        key = "details/fight-next",
        label = "Next fight of the damage meter",
        inputs = { "ALT-CTRL-C" },
        interruptSpeech = true,
        func = function()
            ns.cycle("segment", 1)
        end,
    },
}

for _, info in ipairs(ns.bindings) do
    local copy = {}
    for key, value in pairs(info) do
        copy[key] = value
    end
    copy.label = L[info.label]
    copy.func = Game.guarded(info.func)
    module:registerBinding(copy)
end

local ATTRIBUTE_WORDS = {
    DamageDone = { "damage", "damagedone", "degats", "schaden" },
    Dps = { "dps" },
    HealingDone = { "healing", "heal", "heals", "soins", "heilung" },
    Hps = { "hps" },
    Absorbs = { "absorbs", "absorb", "absorptions", "absorption", "absorbiert" },
    Interrupts = { "interrupts", "interrupt", "interruptions", "interruption", "unterbrechungen", "unterbrechung" },
    Dispels = { "dispels", "dispel", "dissipations", "dissipation", "bannungen", "bannung" },
    DamageTaken = { "taken", "damagetaken", "subis", "recus", "erlitten" },
    AvoidableDamageTaken = { "avoidable", "evitables", "vermeidbar" },
    Deaths = { "deaths", "death", "morts", "mort", "tode", "tod" },
    EnemyDamageTaken = { "enemies", "enemy", "ennemis", "gegner", "feinde" },
}

-- The key of the kind of figure a word (or the whole name the game gives it) means, nil when it means none.
local function attributeFor(text)
    local folded = Text.fold(text)
    if folded == "" then
        return nil
    end
    for _, attribute in ipairs(Data.attributes()) do
        for _, word in ipairs(ATTRIBUTE_WORDS[attribute.key] or {}) do
            if word == folded then
                return attribute.key
            end
        end
        if Text.fold(Data.attributeName(attribute)) == folded then
            return attribute.key
        end
    end
    return nil
end

local HELP = { help = true, aide = true, hilfe = true }
local STATUS = { status = true, etat = true, zustand = true }
local SAY = { say = true, dire = true, sagen = true }
local TOP = { top = true, classement = true, rangliste = true }
local SEGMENT = { segment = true, fight = true, combat = true, kampf = true }
local MEASURE = { measure = true, attribute = true, mesure = true, attribut = true, messwert = true }
local FOLLOW = { follow = true, suivre = true, folgen = true }
local RESUME = { summary = true, resume = true, uebersicht = true, ubersicht = true }
local RESET = { reset = true, reinitialiser = true, reinit = true, zuruecksetzen = true, zurucksetzen = true }
local PREVIOUS = { previous = true, precedent = true, vorheriger = true, last = true, dernier = true, letzter = true }
local YES = { on = true, yes = true, oui = true, ja = true, an = true, ["1"] = true }
local NO = { off = true, no = true, non = true, nein = true, aus = true, ["0"] = true }
local CURRENT = { current = true, actuel = true, aktuell = true }
local OVERALL = { overall = true, global = true, total = true, gesamt = true, all = true, tout = true, alle = true }

-- The names of the choices, said one after the other.
local function sayChoices(choices)
    local parts = {}
    for _, choice in ipairs(choices) do
        parts[#parts + 1] = choice.label
    end
    Game.speak(Text.join(parts, ". "))
end

local function segmentCommand(rest)
    local word = Text.fold(rest)
    if word == "" then
        sayChoices(Data.segmentChoices())
        return
    end
    local value
    if CURRENT[word] then
        value = "current"
    elseif OVERALL[word] then
        value = "overall"
    elseif PREVIOUS[word] then
        -- the fight that ended last of those the game keeps: the first after "current" and "overall" in the list
        local choices = Data.segmentChoices()
        value = choices[3] and choices[3].value
        if value == nil then
            Game.speak(L["There is no kept fight yet."])
            return
        end
    else
        local number = tonumber(word)
        if number ~= nil then
            for _, choice in ipairs(Data.segmentChoices()) do
                if choice.value == "id:" .. math.floor(number) then
                    value = choice.value
                end
            end
        end
    end
    if value == nil then
        Game.speak(L["Say current, overall, previous, or the number of a fight (/wv meter segment alone lists them)."])
        return
    end
    Data.choose("segment", value)
    ns.sayStatus()
end

local function measureCommand(rest)
    if Text.fold(rest) == "" then
        sayChoices(Data.attributeChoices())
        return
    end
    local key = attributeFor(rest)
    if key == nil then
        Game.speak(L["That kind of figure is not known (/wv meter measure alone lists them)."])
        return
    end
    Data.choose("attribute", key)
    ns.sayStatus()
end

local function followCommand(rest)
    local word = Text.fold(rest)
    local wanted
    if YES[word] then
        wanted = true
    elseif NO[word] then
        wanted = false
    else
        wanted = Game.getSetting("follow") == false
    end
    Game.setSetting("follow", wanted)
    Data.clearCache()
    Game.speak(wanted and L["Details is followed."] or L["Details is no longer followed."])
end

-- How long a reset asked for by the command stays waiting for its "yes", in seconds.
ns.RESET_WAIT = 30
ns.pendingReset = nil

-- /wv meter reset asks (and says what would go), /wv meter reset yes erases if it was asked a moment ago, no cancels.
local function resetCommand(rest)
    local word = Text.fold(rest)
    if YES[word] then
        local asked = ns.pendingReset
        ns.pendingReset = nil
        local now = Game.now()
        if asked == nil or now < asked or now - asked > ns.RESET_WAIT then
            Game.speak(L["Nothing to confirm: say /wv meter reset first."])
            return
        end
        Data.reset(Game.speak)
    elseif NO[word] then
        ns.pendingReset = nil
        Game.speak(L["Nothing was erased."])
    else
        if Game.inCombat() then
            Game.speak(L["Erasing is not possible during a fight. Try again after it."])
            return
        end
        ns.pendingReset = Game.now()
        Game.speak(Data.resetQuestion() .. " " .. L["To confirm, say /wv meter reset yes within 30 seconds."])
    end
end

function ns.handleCommand(message)
    local word, rest = Text.fold(message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    word, rest = word or "", rest or ""
    if word == "" then
        Screen.toggle()
    elseif HELP[word] then
        Game.speak(
            L["Damage meter: /wv meter opens the screen, /wv meter say says your line and the best, /wv meter summary says the essentials, /wv meter dps (or hps, healing, interrupts...) says it for that figure, /wv meter top says the first three, /wv meter status says what is shown, /wv meter segment (current, overall, previous or a number) and /wv meter measure choose the fight and the figures, /wv meter follow on or off follows Details' window, /wv meter reset erases the data after asking."]
        )
    elseif STATUS[word] then
        ns.sayStatus()
    elseif SAY[word] then
        if rest ~= "" then
            local key = attributeFor(rest)
            if key == nil then
                Game.speak(L["That kind of figure is not known (/wv meter measure alone lists them)."])
                return
            end
            ns.sayMine(key)
        else
            ns.sayMine()
        end
    elseif TOP[word] then
        local count = tonumber(rest)
        if count ~= nil then
            count = math.max(1, math.min(10, math.floor(count)))
        end
        ns.sayTop(count)
    elseif SEGMENT[word] then
        segmentCommand(rest)
    elseif MEASURE[word] then
        measureCommand(rest)
    elseif FOLLOW[word] then
        followCommand(rest)
    elseif RESUME[word] then
        ns.sayOverview()
    elseif RESET[word] then
        resetCommand(rest)
    elseif attributeFor(word) ~= nil then
        ns.sayMine(attributeFor(word))
    else
        Screen.toggle()
    end
end

module:registerCommand({
    name = "meter",
    description = L["Damage meter: screen, say, summary, top, status, segment, measure, follow, reset."],
    func = function(args)
        ns.handleCommand(args)
    end,
})

-- The module's screen also holds the meter's own buttons.
function module:getGraphMenuItems(builder)
    ns.renderMenu(builder)
end

