local module = WowVision.base.ui
local L = module.L
local graph = WowVision.graph
local gameDefaults = WowVision.gameDefaults

-- "Apply Recommended Game Settings" in the User Interface menu: sets the
-- rules of gameDefaults.lua, then reloads the interface. The reload makes a
-- fresh interface, so nothing the changes touched stays tainted; the report
-- waits in WowVisionDump and is spoken (and printed to chat) after it.

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
    }
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
