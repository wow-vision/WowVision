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

autoMove.events.valueChange:subscribe(nil, function(event, setting, value)
    SetCVar("autoInteract", value)
end)
