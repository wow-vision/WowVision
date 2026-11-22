local module = WowVision.base.targeting
local alert = module.targetCrowdControl

-- Whether the current target is crowd controlled, by anyone: the shared
-- tooltip read (core/crowdControl.lua). Clients without the CROWD_CONTROL
-- filter (TBC Anniversary) get no alert.
local crowdControl = WowVision.crowdControl

if alert == nil or not crowdControl.filterKnown() or CreateFrame == nil then
    return
end

local function controlled(unit)
    return crowdControl.controlled(unit) == true
end

-- The state of the current target. On a target change the new target is
-- checked at once, in the event: its auras are in place there (measured with
-- /wv cctest watch, 2026-11-02: right from frame 0, and the game sends no
-- UNIT_AURA for a new target). The sound always tells the current target's
-- state: on when it is controlled, off when it is free after a controlled
-- one. Aura changes on the same target are found by reading it every
-- POLL seconds: UNIT_AURA is not sent everywhere (not in some instanced
-- content), so the event only brings the next read forward to the next
-- frame. One tooltip fill per read, and none without a target.
local POLL = 0.2

local watch = crowdControl.newWatch(function()
    return controlled("target")
end, function(controlledNow)
    if module:getEnabled() then
        alert:fire({ controlled = controlledNow })
    end
end, POLL)

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        watch.unitChanged()
    else
        watch.auraChanged()
    end
end)
frame:SetScript("OnUpdate", function(self, elapsed)
    watch.update(elapsed)
end)
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterUnitEvent("UNIT_AURA", "target")

module.crowdControl = { controlled = controlled }
