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
-- one. Aura changes on the same target are checked once per frame at most:
-- UNIT_AURA sets the frame's update script and the check clears it.
local state = false
local frame = CreateFrame("Frame")

local function announce(controlledNow)
    if module:getEnabled() then
        alert:fire({ controlled = controlledNow })
    end
end

local function checkAuras(self)
    self:SetScript("OnUpdate", nil)
    local now = controlled("target")
    if now ~= state then
        state = now
        announce(now)
    end
end

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        self:SetScript("OnUpdate", nil)
        local was = state
        state = controlled("target")
        if state then
            announce(true)
        elseif was then
            announce(false)
        end
    else
        self:SetScript("OnUpdate", checkAuras)
    end
end)
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterUnitEvent("UNIT_AURA", "target")

module.crowdControl = { controlled = controlled }
