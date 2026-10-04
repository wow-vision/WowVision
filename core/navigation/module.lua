local module = WowVision.base:createModule("navigation")
local L = module.L
module:setLabel(L["Navigation"])
local settings = module:hasSettings()

--Note that the autoInteract CVar is equivalent to the Click to Move mouse setting in the UI
--This is here for two reasons:
-- 1. To ensure that this behavior is enabled by default as it could be a pain point for new players if not
-- 2. In case of client differences that might change this or make it harder to find (IE Classic Era?)
local autoMove = settings:add({
    key = "autoMove",
    type = "Bool",
    label = L["Auto-move to Interact Target"],
    default = true,
})

autoMove.events.valueChange:subscribe(nil, function(event, obj, key, value)
    SetCVar("autoInteract", value)
end)

-- The camera settings turn to waypoint and the pitch lock need, set once
-- per character (see camera.lua).
settings:add({
    type = "Bool",
    key = "cameraStyleSet",
    default = false,
    global = false,
    showInUI = false,
})

function module:onFullEnable()
    local getCVar = C_CVar ~= nil and C_CVar.GetCVar or GetCVar
    local setCVar = C_CVar ~= nil and C_CVar.SetCVar or SetCVar
    if WowVision.navigationCamera.applyOnce(self.settings, getCVar, setCVar) then
        print(L["WowVision set the camera to always follow behind your character, which turning to waypoints needs. You can change the camera following style in the game options under Controls."])
    end
end
