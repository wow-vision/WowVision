-- Recommended game settings for a blind player, applied in one go from the
-- User Interface menu (gameDefaultsMenu.lua). Kept free of frames so the
-- rules run in the headless tests.
--
-- Everything goes through the game's own settings: console variables, the
-- action bar toggles, Blizzard's Audio Assist and one key, the interact key.
-- Nothing WowVision-only. Every other key binding, the camera, soft targeting
-- and sound volumes stay as they are.
local gameDefaults = {}
WowVision.gameDefaults = gameDefaults

gameDefaults.CVARS = {
    { name = "autoLootDefault", value = "1", label = "Auto Loot" },
    -- An enemy behind you or beside you gets its nameplate at once, so the
    -- combat module's enemy count hears it without waiting for the camera.
    { name = "nameplateShowOffscreen", value = "1", label = "Offscreen Nameplates" },
    -- Friendly NPCs get a nameplate, so turn to target and turn to focus
    -- find an escort or other friendly NPC (navigation/maps/turnToUnit.lua).
    { name = "nameplateShowFriendlyNpcs", value = "1", label = "Friendly NPC Nameplates" },
}

-- Audio Assist (Blizzard_CombatAudioAlerts): on, your health, target health
-- and your resource every 20 percent, "targeted" without the attacker's
-- name; combat start and end, target name and your debuffs off. Percent
-- values count in tens (2 = every 20 percent).
gameDefaults.AUDIO_ASSIST_CVARS = {
    { name = "CAAEnabled", value = "1", label = "Audio Assist" },
    { name = "CAASayCombatStart", value = "0", label = "Audio Assist Combat Start" },
    { name = "CAASayCombatEnd", value = "0", label = "Audio Assist Combat End" },
    { name = "CAASayTargetName", value = "0", label = "Audio Assist Target Name" },
    { name = "CAASayYourDebuffs", value = "0", label = "Audio Assist Your Debuffs" },
    { name = "CAAPlayerHealthPercent", value = "2", label = "Audio Assist Your Health" },
    { name = "CAATargetHealthPercent", value = "2", label = "Audio Assist Target Health" },
}

-- The health style: the fifth entry of the game's style list, the number
-- alone (CAA_SAY_HEALTH_FORMAT_NUM_ONLY, value 4), for you and your target.
gameDefaults.HEALTH_FORMAT = 4

-- Per specialization: these are set for the current one.
gameDefaults.AUDIO_ASSIST_SPEC = {
    { setting = "Resource1Percent", value = 2, label = "Audio Assist Resource" },
    -- 0 off, 1 aggro, 2 targeted without the name, 3 targeted with the name
    { setting = "SayIfTargeted", value = 2, label = "Audio Assist You Are Targeted" },
}

-- The interact key: the game's key binding Interact With Target (action
-- INTERACTTARGET; the game's options list it under that name on the Controls
-- page and under Targeting in the key bindings, on every game version), the
-- one key that talks to a character, loots a corpse and opens a mailbox. Players reported
-- (2026-11) that it has no key by default, and without one none of that works
-- from the keyboard. G is WowVision's recommendation.
--
-- G is given to it when G is free, or holds Target Last Hostile, the action
-- the game's own default keys are known to put on G (not checked on every
-- game version). A G the player gave to anything else is left alone and
-- named in the report. Interact With Mouseover counts as an interact key too:
-- with nothing under the mouse it does the same interaction.
gameDefaults.INTERACT = {
    action = "INTERACTTARGET",
    alsoCounts = { "INTERACTMOUSEOVER" },
    key = "G",
    replaces = "TARGETLASTHOSTILE",
}

-- Whether the player has an interact key: true or false, nil when the game
-- cannot be asked. keyOf(action) gives the action's first key or nil.
function gameDefaults.hasInteractKey(keyOf)
    if type(keyOf) ~= "function" then
        return nil
    end
    local interact = gameDefaults.INTERACT
    local function has(action)
        local ok, key = pcall(keyOf, action)
        if not ok then
            return nil
        end
        return key ~= nil and key ~= ""
    end
    local main = has(interact.action)
    if main ~= false then
        return main
    end
    for _, action in ipairs(interact.alsoCounts) do
        if has(action) == true then
            return true
        end
    end
    return false
end

local function sameValue(a, b)
    if a == b then
        return true
    end
    local numberA, numberB = tonumber(a), tonumber(b)
    return numberA ~= nil and numberA == numberB
end

-- api, the game calls this needs:
--   inCombat()
--   getCVar(name), setCVar(name, value)           setCVar errors when refused
--   actionBarToggles() -> list or nil, setActionBarToggles(list)
--   bindings                                      nil where keys cannot be set:
--     keyOf(action) -> key or nil, actionOf(key) -> action or nil,
--     nameOf(action) -> the game's name for it,
--     bind(key, action)                           errors when refused; saves
--   audioAssist                                   nil where the game has none:
--     getFormat(unit, alertType), setFormat(unit, alertType, value)
--     getSpec(setting), setSpec(setting, value)   setting by name
-- L, the locale table.
--
-- Returns a report: { refused = true } in combat, else
-- { changed = { lines }, unchanged = { names }, failed = { names } }.
function gameDefaults.apply(api, L)
    if api.inCombat() then
        return { refused = true }
    end
    local report = { changed = {}, unchanged = {}, failed = {} }

    local function setCVars(list)
        for _, cvar in ipairs(list) do
            local ok, current = pcall(api.getCVar, cvar.name)
            if not ok or current == nil then
                tinsert(report.failed, L[cvar.label])
            elseif sameValue(current, cvar.value) then
                tinsert(report.unchanged, L[cvar.label])
            elseif pcall(api.setCVar, cvar.name, cvar.value) and sameValue(api.getCVar(cvar.name), cvar.value) then
                tinsert(report.changed, L[cvar.label])
            else
                tinsert(report.failed, L[cvar.label])
            end
        end
    end

    setCVars(gameDefaults.CVARS)

    local toggles = api.actionBarToggles()
    if toggles ~= nil then
        local all = {}
        local missing = false
        for i, shown in ipairs(toggles) do
            all[i] = true
            if not shown then
                missing = true
            end
        end
        if not missing then
            tinsert(report.unchanged, L["All Action Bars"])
        elseif pcall(api.setActionBarToggles, all) then
            tinsert(report.changed, L["All Action Bars"])
        else
            tinsert(report.failed, L["All Action Bars"])
        end
    end

    local bindings = api.bindings
    if bindings ~= nil then
        local interact = gameDefaults.INTERACT
        -- named as the game's options name it, in the game's language
        local label = bindings.nameOf(interact.action)
        local has = gameDefaults.hasInteractKey(bindings.keyOf)
        local okHolder, holder = pcall(bindings.actionOf, interact.key)
        if has == true then
            tinsert(report.unchanged, label)
        elseif has == nil or not okHolder then
            tinsert(report.failed, label)
        elseif holder ~= nil and holder ~= interact.replaces then
            -- the player's own choice for that key: say what holds it, change nothing
            tinsert(
                report.failed,
                string.format(L["%s (%s is used by %s)"], label, interact.key, bindings.nameOf(holder))
            )
        elseif
            pcall(bindings.bind, interact.key, interact.action)
            and gameDefaults.hasInteractKey(bindings.keyOf) == true
        then
            if holder ~= nil then
                tinsert(
                    report.changed,
                    string.format(L["%s set to %s, in place of %s"], label, interact.key, bindings.nameOf(holder))
                )
            else
                tinsert(report.changed, string.format(L["%s set to %s"], label, interact.key))
            end
        else
            tinsert(report.failed, label)
        end
    end

    local audio = api.audioAssist
    if audio ~= nil then
        setCVars(gameDefaults.AUDIO_ASSIST_CVARS)
        for _, unit in ipairs({ "Player", "Target" }) do
            local label = unit == "Player" and L["Audio Assist Your Health Style"]
                or L["Audio Assist Target Health Style"]
            local ok, current = pcall(audio.getFormat, unit, "Health")
            if ok and current == gameDefaults.HEALTH_FORMAT then
                tinsert(report.unchanged, label)
            elseif pcall(audio.setFormat, unit, "Health", gameDefaults.HEALTH_FORMAT) then
                tinsert(report.changed, label)
            else
                tinsert(report.failed, label)
            end
        end
        for _, spec in ipairs(gameDefaults.AUDIO_ASSIST_SPEC) do
            local ok, current = pcall(audio.getSpec, spec.setting)
            if ok and current == spec.value then
                tinsert(report.unchanged, L[spec.label])
            elseif pcall(audio.setSpec, spec.setting, spec.value) then
                tinsert(report.changed, L[spec.label])
            else
                tinsert(report.failed, L[spec.label])
            end
        end
    end

    return report
end

-- Said at login while there is no interact key, once per session, some
-- seconds after the world is entered and after the custom scripts message
-- (core/scriptsCheck.lua) would have been said. A new player does not know the
-- key exists, or that it has to be bound, so the message says what to press.
gameDefaults.interactCheck = { said = false, DELAY = 8 }

-- actionName is the game's own name of the action, in the game's language.
function gameDefaults.interactKeyMessage(L, actionName)
    return string.format(
        L["The game's action %s has no key, so you cannot talk to characters or loot from the keyboard. To set it to G: press Shift+F1, open %s, and choose %s. Or give it a key of your own in the game's key bindings."],
        actionName or L["Interact With Target"],
        L["UI"],
        L["Apply Recommended Game Settings"]
    )
end

-- options: keyOf (as in api.bindings), enabled (the setting; false is off),
-- scriptsAllowed (false while the game runs no custom scripts: WowVision's
-- keys are dead then, Shift+F1 with them, and that message comes first),
-- actionName, L, say(text). True when it spoke.
function gameDefaults.checkInteractKey(options)
    local check = gameDefaults.interactCheck
    if check.said or options.enabled == false or options.scriptsAllowed == false then
        return false
    end
    if gameDefaults.hasInteractKey(options.keyOf) ~= false then
        return false
    end
    check.said = true
    options.say(gameDefaults.interactKeyMessage(options.L, options.actionName))
    return true
end

-- The report as one line per part, for speech and chat.
function gameDefaults.reportLines(report, L)
    local lines = {}
    if #report.changed == 0 then
        tinsert(lines, L["Game settings: nothing to change"])
    else
        tinsert(lines, L["Game settings changed:"])
        for _, line in ipairs(report.changed) do
            tinsert(lines, line)
        end
    end
    if #report.unchanged > 0 then
        tinsert(lines, L["Already set:"] .. " " .. table.concat(report.unchanged, ", "))
    end
    if #report.failed > 0 then
        tinsert(lines, L["Could not set:"] .. " " .. table.concat(report.failed, ", "))
    end
    return lines
end
