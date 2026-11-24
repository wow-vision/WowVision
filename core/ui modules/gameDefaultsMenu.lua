local module = WowVision.base.ui
local L = module.L
local graph = WowVision.graph
local gameDefaults = WowVision.gameDefaults

-- "Apply Recommended Game Settings" in the User Interface menu: sets the
-- rules of gameDefaults.lua, then reloads the interface. The reload makes a
-- fresh interface, so nothing the changes touched stays tainted; the report
-- waits in WowVisionDump and is spoken (and printed to chat) after it.
--
-- Also here: the message at login while the game's interact action has no key
-- (gameDefaults.checkInteractKey), and the setting that switches it off.

module:hasSettings():add({
    type = "Bool",
    key = "interactKeyWarning",
    label = L["Say at Login When Interact With Target Has No Key"],
    default = true,
})

local function actionBarToggles()
    if GetActionBarToggles == nil or SetActionBarToggles == nil then
        return nil
    end
    -- a hidden bar reads as nil, so count the values instead of walking them
    local function collect(...)
        local list = {}
        for i = 1, select("#", ...) do
            list[i] = select(i, ...) and true or false
        end
        return list
    end
    return collect(GetActionBarToggles())
end

local function succeeded(ok)
    if not ok then
        error("refused")
    end
end

local function audioAssist()
    local caa = C_CombatAudioAlert
    if caa == nil or caa.SetFormatSetting == nil or caa.SetSpecSetting == nil then
        return nil
    end
    if Enum.CombatAudioAlertUnit == nil or Enum.CombatAudioAlertSpecSetting == nil then
        return nil
    end
    return {
        getFormat = function(unit, alertType)
            return caa.GetFormatSetting(Enum.CombatAudioAlertUnit[unit], Enum.CombatAudioAlertType[alertType])
        end,
        setFormat = function(unit, alertType, value)
            succeeded(caa.SetFormatSetting(Enum.CombatAudioAlertUnit[unit], Enum.CombatAudioAlertType[alertType], value))
        end,
        getSpec = function(setting)
            return caa.GetSpecSetting(Enum.CombatAudioAlertSpecSetting[setting])
        end,
        setSpec = function(setting, value)
            succeeded(caa.SetSpecSetting(Enum.CombatAudioAlertSpecSetting[setting], value))
        end,
    }
end

-- The game's key bindings. Setting a key is refused in combat, which
-- gameDefaults.apply never does; a set key is saved to the binding set the
-- player uses (account or character), as the game's own key bindings page does.
local function bindings()
    local save = SaveBindings or AttemptToSaveBindings
    if GetBindingKey == nil or GetBindingAction == nil or SetBinding == nil then
        return nil
    end
    if save == nil or GetCurrentBindingSet == nil then
        return nil
    end
    return {
        keyOf = function(action)
            return (GetBindingKey(action))
        end,
        actionOf = function(key)
            local action = GetBindingAction(key)
            if action == nil or action == "" then
                return nil
            end
            return action
        end,
        nameOf = function(action)
            local name = GetBindingName ~= nil and GetBindingName(action) or nil
            if type(name) ~= "string" or name == "" then
                return action
            end
            return name
        end,
        bind = function(key, action)
            succeeded(SetBinding(key, action))
            save(GetCurrentBindingSet())
        end,
    }
end

local function gameApi()
    return {
        inCombat = InCombatLockdown,
        getCVar = C_CVar ~= nil and C_CVar.GetCVar or GetCVar,
        setCVar = C_CVar ~= nil and C_CVar.SetCVar or SetCVar,
        actionBarToggles = actionBarToggles,
        setActionBarToggles = function(list)
            SetActionBarToggles(unpack(list))
        end,
        audioAssist = audioAssist(),
        bindings = bindings(),
    }
end

function gameDefaults.runInteractKeyCheck()
    local api = bindings()
    if api == nil then
        return
    end
    local scriptsAllowed = nil
    if WowVision.scriptsCheck ~= nil then
        scriptsAllowed = WowVision.scriptsCheck.allowed()
    end
    gameDefaults.checkInteractKey({
        keyOf = api.keyOf,
        enabled = module.settings.interactKeyWarning,
        scriptsAllowed = scriptsAllowed,
        actionName = api.nameOf(gameDefaults.INTERACT.action),
        L = L,
        say = function(text)
            WowVision:notify(text)
        end,
    })
end

local function announce(lines)
    WowVision:notify(table.concat(lines, ". "))
    for _, line in ipairs(lines) do
        print(line)
    end
end

function gameDefaults.run()
    local report = gameDefaults.apply(gameApi(), L)
    if report.refused then
        WowVision:notify(L["Not in combat: try again after the fight"])
        return
    end
    local lines = gameDefaults.reportLines(report, L)
    if #report.changed == 0 then
        announce(lines)
        return
    end
    WowVisionDump = WowVisionDump or {}
    WowVisionDump.gameDefaultsReport = lines
    ReloadUI()
end

local previousMenuItems = module.getGraphMenuItems
function module:getGraphMenuItems(builder)
    if previousMenuItems ~= nil then
        previousMenuItems(self, builder)
    end
    builder:addItem(
        graph.ControlId.structural("gameDefaults"),
        graph.nodes.button({
            label = L["Apply Recommended Game Settings"],
            onActivate = function()
                gameDefaults.run()
            end,
        })
    )
end

local previousFullEnable = module.onFullEnable
function module:onFullEnable()
    previousFullEnable(self)
    -- this runs at login, before the world is entered
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        C_Timer.After(gameDefaults.interactCheck.DELAY, gameDefaults.runInteractKeyCheck)
    end)
    local lines = WowVisionDump ~= nil and WowVisionDump.gameDefaultsReport or nil
    if type(lines) ~= "table" then
        return
    end
    WowVisionDump.gameDefaultsReport = nil
    -- after the login lines, so the report is not cut off
    C_Timer.After(3, function()
        announce(lines)
    end)
end
