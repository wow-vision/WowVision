-- Everything this addon asks of the game, of Details and of WowVision, in one table, so the tests can replace it.
--
-- The numbers are not read from Details' own objects: on WoW: Forever Details shows what the game's own damage meter
-- (C_DamageMeter) delivers, so this addon asks that meter, the same one Details asks, for the same sessions. Details
-- is only asked what its first open window shows (the fight and the kind of figure), so the screen can start where
-- that window is. Nothing of Details is changed or run: the calls are reads, each one guarded.
local ns = WowVision.detailsMeter
local Text = ns.Text

local Game = {}
ns.Game = Game

-- The name of the WowVision window this addon opens.
Game.WINDOW = "detailsMeter"

-- An error here must never break a key, and must not repeat on every press either: each distinct message once.
local reported = {}
function Game.report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("Details meter: " .. err)
end

function Game.guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            Game.report(err)
        end
    end
end

-- The text may be a hidden (secret) one: it is only handed over to the speech, never looked at.
function Game.speak(text)
    if not text then
        return
    end
    local wowVision = rawget(_G, "WowVision")
    if wowVision ~= nil and wowVision.speak ~= nil then
        wowVision:speak(text)
    else
        pcall(print, text)
    end
end

-- -------------------------------------------------------------- the settings

Game.DEFAULTS = {
    follow = true, -- start where Details' first open window is (the fight, the kind of figure)
    segment = "current", -- the fight when Details is not followed: current | overall | id:N
    attribute = "DamageDone", -- the kind of figure when Details is not followed
}

-- Follow Details' window is a module setting; the fight and the figures last chosen are kept in the character's
-- module data.
local memory = {}
local function store()
    if ns.module ~= nil and ns.module.data ~= nil then
        return ns.module.data
    end
    return ns.saved or memory
end

function Game.getSetting(key)
    local value
    if key == "follow" and ns.settings ~= nil then
        value = ns.settings.follow
    else
        value = store()[key]
    end
    if value == nil then
        return Game.DEFAULTS[key]
    end
    return value
end

function Game.setSetting(key, value)
    if key == "follow" and ns.settings ~= nil then
        ns.settings.follow = value
        return
    end
    store()[key] = value
end

-- ------------------------------------------------------------------ the game

function Game.now()
    if GetTime ~= nil then
        return GetTime()
    end
    return 0
end

-- A yes or no from a game function that may hide its answer or refuse the call: true or false when it can be read, nil
-- otherwise. A hidden value is never compared.
local function plainBool(fn, ...)
    if fn == nil then
        return nil
    end
    local ok, value = pcall(fn, ...)
    if not ok or Text.isSecret(value) then
        return nil
    end
    return value and true or false
end

function Game.inCombat()
    return plainBool(InCombatLockdown) == true
end

-- The game's own damage meter, the one Details reads.
local function meter()
    local found = rawget(_G, "C_DamageMeter")
    if type(found) == "table" then
        return found
    end
    return nil
end

-- true, or false and why: "missing" (this game has no damage meter), "disabled" (it is turned off).
function Game.available()
    local found = meter()
    if found == nil or type(found.GetCombatSessionFromType) ~= "function" then
        return false, "missing"
    end
    if type(found.IsDamageMeterAvailable) == "function" then
        local ok, available = pcall(found.IsDamageMeterAvailable)
        if ok and not Text.isSecret(available) and available == false then
            return false, "disabled"
        end
    end
    return true
end

-- The kinds of session the game knows (Enum.DamageMeterSessionType), by the names this addon uses.
local function sessionType(kind)
    local enum = rawget(_G, "Enum")
    local types = type(enum) == "table" and enum.DamageMeterSessionType or nil
    if kind == "overall" then
        return type(types) == "table" and types.Overall or 0
    end
    return type(types) == "table" and types.Current or 1
end
Game.sessionType = sessionType

-- The value of a kind of figure (Enum.DamageMeterType.DamageDone...), nil when this game has none of that name.
function Game.meterType(name)
    local enum = rawget(_G, "Enum")
    local types = type(enum) == "table" and enum.DamageMeterType or nil
    if type(types) == "table" then
        return types[name]
    end
    return nil
end

-- The fights the game keeps, oldest first: { sessionID, name, durationSeconds }.
function Game.sessions()
    local found = meter()
    if found == nil or type(found.GetAvailableCombatSessions) ~= "function" then
        return {}
    end
    local ok, list = pcall(found.GetAvailableCombatSessions)
    if ok and type(list) == "table" then
        return list
    end
    return {}
end

-- One fight as one kind of figure: { durationSeconds, maxAmount, totalAmount, combatSources = { ... } }, nil when the
-- game gives nothing. segment: { kind = "current" | "overall" | "id", id = N }.
function Game.session(segment, meterType)
    local found = meter()
    if found == nil then
        return nil
    end
    local ok, result
    if segment.kind == "id" then
        if type(found.GetCombatSessionFromID) ~= "function" then
            return nil
        end
        ok, result = pcall(found.GetCombatSessionFromID, segment.id, meterType)
    else
        ok, result = pcall(found.GetCombatSessionFromType, sessionType(segment.kind), meterType)
    end
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local function sourceCall(segment, meterType, guid, creatureId)
    local found = meter()
    if found == nil then
        return nil
    end
    local fn, first
    if segment.kind == "id" then
        fn, first = found.GetCombatSessionSourceFromID, segment.id
    else
        fn, first = found.GetCombatSessionSourceFromType, sessionType(segment.kind)
    end
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, first, meterType, guid, creatureId)
    if ok and type(result) == "table" then
        return result, false
    end
    return nil, not ok
end

-- What one source did in a fight, spell by spell: { maxAmount, totalAmount, combatSpells = { ... } }. A player is
-- asked for by the GUID, a creature by its creature id; the id is left out (asked again) when the game refuses the pair.
function Game.sourceSpells(segment, meterType, guid, creatureId)
    local result, refused = sourceCall(segment, meterType, guid, creatureId)
    if result == nil and refused and creatureId then
        result = sourceCall(segment, meterType, guid, nil)
    end
    return result
end

-- The name of a spell, nil when the game has none. It may be a hidden one.
function Game.spellName(spellId)
    if not spellId then
        return nil
    end
    local spell = rawget(_G, "C_Spell")
    if type(spell) == "table" and type(spell.GetSpellInfo) == "function" then
        local ok, info = pcall(spell.GetSpellInfo, spellId)
        if ok and type(info) == "table" and info.name then
            return info.name
        end
    end
    return nil
end

-- Runs something in a moment (at once when the game has no timer).
function Game.after(seconds, fn)
    local timer = rawget(_G, "C_Timer")
    if type(timer) == "table" and type(timer.After) == "function" then
        timer.After(seconds, fn)
    else
        fn()
    end
end

-- Erases every fight the damage meter keeps, the way Details' own reset button does: Details' ResetSegmentData (it
-- empties its own memory and resets the game's meter), or the game's ResetAllCombatSessions when Details is not
-- there. Never during a fight. true, or false and why: "combat", "missing", "failed".
function Game.resetAll()
    if Game.inCombat() then
        return false, "combat"
    end
    local details = rawget(_G, "Details") or rawget(_G, "_detalhes")
    if type(details) == "table" and type(details.ResetSegmentData) == "function" then
        if pcall(details.ResetSegmentData, details) then
            return true
        end
        return false, "failed"
    end
    local found = meter()
    if found ~= nil and type(found.ResetAllCombatSessions) == "function" then
        if pcall(found.ResetAllCombatSessions) then
            return true
        end
        return false, "failed"
    end
    return false, "missing"
end

-- A hidden text between a prefix and a suffix; nothing at all (not even the prefix) when the text is empty. nil when
-- the game has no such function.
function Game.wrapString(text, prefix, suffix)
    local utils = rawget(_G, "C_StringUtil")
    if type(utils) ~= "table" or type(utils.WrapString) ~= "function" then
        return nil
    end
    local ok, wrapped = pcall(utils.WrapString, text, prefix, suffix)
    if ok and wrapped then
        return wrapped
    end
    return nil
end

-- The name of a class in the game's language ("MAGE" is "Mage"), nil when it is not known or hidden.
function Game.className(class)
    if not class or Text.isSecret(class) or type(class) ~= "string" then
        return nil
    end
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    if type(names) == "table" then
        return names[class]
    end
    return nil
end

-- A text the game provides in its own language (a global string), nil when there is none.
function Game.globalString(name)
    local value = rawget(_G, name)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

-- ------------------------------------------------------------------ Details

local function open(instance)
    if type(instance.IsEnabled) == "function" then
        local ok, enabled = pcall(instance.IsEnabled, instance)
        return ok and enabled and true or false
    end
    return instance.ativa == true
end

-- What the first open window of Details shows: { id, segment = { kind, id } or nil, attributeValue = N or nil }. The
-- segment is nil when the window shows the fights Details keeps itself (source_type 0), which the game's meter does
-- not know. nil when Details is not there or has no window open.
local function describe(instance)
    local result = { id = instance.meu_id }
    local sourceType = instance.source_type
    if sourceType ~= 0 and type(instance.GetSegmentType) == "function" then
        local kind = instance:GetSegmentType()
        if kind == sessionType("overall") then
            result.segment = { kind = "overall" }
        elseif kind == sessionType("current") then
            result.segment = { kind = "current" }
        elseif type(kind) == "number" and type(instance.GetNewSegmentId) == "function" then
            local id = instance:GetNewSegmentId()
            if type(id) == "number" and id > 0 then
                result.segment = { kind = "id", id = id }
            end
        end
    end
    if type(instance.GetAttributeType) == "function" then
        local value = instance:GetAttributeType()
        if type(value) == "number" then
            result.attributeValue = value
        end
    end
    return result
end

local function firstWindow()
    local details = rawget(_G, "Details") or rawget(_G, "_detalhes")
    if type(details) ~= "table" or type(details.GetNumInstances) ~= "function" or type(details.GetInstance) ~= "function" then
        return nil
    end
    for index = 1, details:GetNumInstances() or 0 do
        local instance = details:GetInstance(index)
        if type(instance) == "table" and open(instance) then
            return describe(instance)
        end
    end
    return nil
end

function Game.detailsWindow()
    local ok, result = pcall(firstWindow)
    if ok then
        return result
    end
    return nil
end

-- Whether Details is there at all.
function Game.hasDetails()
    return type(rawget(_G, "Details") or rawget(_G, "_detalhes")) == "table"
end

-- ----------------------------------------------------------------- the window

local function host()
    local wowVision = rawget(_G, "WowVision")
    return wowVision ~= nil and wowVision.UIHost or nil
end

function Game.isOpen()
    local current = host()
    local manager = current ~= nil and current.windowManager or nil
    if manager == nil then
        return false
    end
    for _, instance in ipairs(manager.openWindows) do
        if instance.name == Game.WINDOW then
            return true
        end
    end
    return false
end

-- Opens the frameless graph window. screen is the graphScreen config (render, onRequestClose...).
function Game.open(screen)
    local current = host()
    if current == nil then
        return false
    end
    current:openTemporaryWindow({ name = Game.WINDOW, graphScreen = screen })
    return true
end

function Game.close()
    local current = host()
    if current ~= nil then
        current:closeWindow(Game.WINDOW)
    end
end
