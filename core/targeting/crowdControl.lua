local module = WowVision.base.targeting
local alert = module.targetCrowdControl

-- Whether the current target is crowd controlled, by anyone: the game's
-- CROWD_CONTROL aura filter (stuns, fears, polymorph and the like). A
-- tooltip of our own filled with the first harmful aura under that filter
-- has lines exactly when there is one. Under Retail's restriction the aura
-- list is closed to the index read, but this fill is allowed and its line
-- count is plain; the count is right in the same frame (measured with
-- /wv cctest, 2026-11-02). Clients without the filter (TBC Anniversary)
-- get no alert.
local FILTER = "HARMFUL|CROWD_CONTROL"

local function filterKnown()
    if AuraUtil == nil or type(AuraUtil.AuraFilters) ~= "table" then
        return false
    end
    for _, token in pairs(AuraUtil.AuraFilters) do
        if token == "CROWD_CONTROL" then
            return true
        end
    end
    return false
end

if alert == nil or not filterKnown() or CreateFrame == nil then
    return
end

local tooltip = CreateFrame("GameTooltip", "WowVisionCrowdControlTooltip", UIParent, "GameTooltipTemplate")

local function controlled(unit)
    if not UnitExists(unit) then
        return false
    end
    tooltip:ClearLines()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    if not pcall(tooltip.SetUnitAura, tooltip, unit, 1, FILTER) then
        return false
    end
    return tooltip:NumLines() > 0
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
