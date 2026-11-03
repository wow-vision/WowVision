-- Whether a unit is crowd controlled, by anyone: the game's CROWD_CONTROL
-- aura filter (stuns, fears, polymorph and the like). A tooltip of our own
-- filled with the first harmful aura under that filter has lines exactly
-- when there is one. Under Retail's restriction the aura list is closed to
-- the index read, but this fill is allowed and its line count is plain; the
-- count is right in the same frame (measured on the target with /wv cctest,
-- 2026-11-02; nameplate units are not measured yet). Clients without the
-- filter (TBC Anniversary) get nil: unknown.
--
-- Used by the Target Crowd Control alert and by the enemy count's Announce
-- Crowd Control.
local crowdControl = {}
WowVision.crowdControl = crowdControl

crowdControl.FILTER = "HARMFUL|CROWD_CONTROL"

local known
function crowdControl.filterKnown()
    if known == nil then
        known = false
        if AuraUtil ~= nil and type(AuraUtil.AuraFilters) == "table" then
            for _, token in pairs(AuraUtil.AuraFilters) do
                if token == "CROWD_CONTROL" then
                    known = true
                end
            end
        end
    end
    return known
end

local tooltip

-- Fills the tooltip with the unit's first crowd control aura; true when the
-- game allowed it.
local function fill(unit)
    if not crowdControl.filterKnown() or CreateFrame == nil or not UnitExists(unit) then
        return false
    end
    if tooltip == nil then
        tooltip = CreateFrame("GameTooltip", "WowVisionCrowdControlTooltip", UIParent, "GameTooltipTemplate")
    end
    tooltip:ClearLines()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    return pcall(tooltip.SetUnitAura, tooltip, unit, 1, crowdControl.FILTER)
end

-- true or false, nil when it cannot be told (no filter, refused fill).
function crowdControl.controlled(unit)
    if not fill(unit) then
        return nil
    end
    return tooltip:NumLines() > 0
end

-- The name of the unit's first crowd control aura, the tooltip's first line
-- (secret under restriction: store, join and speak it, never compare it).
-- nil when there is none or it cannot be read.
function crowdControl.name(unit)
    if not fill(unit) or tooltip:NumLines() == 0 then
        return nil
    end
    local line = _G["WowVisionCrowdControlTooltipTextLeft1"]
    if line == nil then
        return nil
    end
    local ok, text = pcall(line.GetText, line)
    return ok and text or nil
end
