local module = WowVision.base.targeting
local L = module.L

-- Target of Target (unbound by default): your target's own target becomes your target, the
-- game's /assist without its auto attack. Targeting is protected, so it is a
-- secure macro: the /run line speaks why nothing happens BEFORE the switch
-- (afterwards the old target is gone), and the conditional /target leaves the
-- target alone when there is no target of target. A target that changes is
-- spoken by the Hard Target alert as usual, yourself included.
function module:checkTargetOfTarget()
    -- a secret answer cannot be tested: nothing is said, the macro still runs
    local hasTarget = UnitExists("target")
    if WowVision.isSecret(hasTarget) then
        return
    end
    if not hasTarget then
        WowVision:speak(L["No target"])
        return
    end
    local hasTargetOfTarget = UnitExists("targettarget")
    if not WowVision.isSecret(hasTargetOfTarget) and not hasTargetOfTarget then
        WowVision:speak(L["Your target has no target"])
    end
end

module:registerBinding({
    type = "Script",
    key = "targetOfTarget",
    label = L["Target of Target"],
    inputs = {},
    script = "/run WowVision.base.targeting:checkTargetOfTarget()\n/target [@targettarget,exists] targettarget",
})
