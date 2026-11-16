-- Recommended game settings for a blind player, applied in one go from the
-- User Interface menu (gameDefaultsMenu.lua). Kept free of frames so the
-- rules run in the headless tests.
--
-- Everything goes through the game's own settings: console variables, the
-- action bar toggles and Blizzard's Audio Assist. Nothing WowVision-only.
-- Key bindings, camera, soft targeting and sound volumes stay as they are.
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
