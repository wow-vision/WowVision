-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/TransitActivation.lua at
-- 5b8b5f2), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Purely local continuation to a raw-checked AreaTrigger activation area.
-- This does not confirm a server-side action, a target zone or a world edge.
local Activation = {}
WowVisionNavigationTransitActivation = Activation

function Activation:IsActivationTarget(target, nav)
    if not nav or nav.packageLayoutVersion ~= 3 or (not WowVisionNavigationTargetCatalog
        or not WowVisionNavigationTargetCatalog:CertifiedInteraction(nav,target or {})) then return false end
    local captureFeature = (nav.approach_schema == 1
        and type(nav.approachFingerprint) == "string" and #nav.approachFingerprint == 64)
        or (nav.localCaptureSchema == 1 and type(nav.localCaptureFingerprint) == "string"
            and #nav.localCaptureFingerprint == 64)
    return type(target) == "table" and type(nav) == "table" and captureFeature
        and target.type == "transit_facility"
        and target.facilityRole == "entrance"
        and target.activationMode == "walk_into_trigger"
        and target.interactionMode == nil
        and target.waitpointProofId == nil
        and type(target.activationPreX) == "number"
        and type(target.activationPreY) == "number"
        and type(target.x) == "number" and type(target.y) == "number"
        and type(target.activationCaptureRadius) == "number"
        and target.activationCaptureRadius > 0
        and target.activationCaptureRadius <= 1.5
        and target.reachable and type(target.nodeId) == "number"
end

function Activation:PrepointReached(target, x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    local dx, dy = x - target.activationPreX, y - target.activationPreY
    return dx * dx + dy * dy <= 1.5 * 1.5
end

function Activation:CaptureReached(target, x, y, observation)
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    local dx, dy = x - target.x, y - target.y
    local r = target.activationCaptureRadius
    if target.actionSemanticStatus == "unresolved" then
        if type(observation) == "table" then
            if observation.nativeMapId ~= nil and observation.nativeMapId ~= target.nativeMapId then return false end
            -- The current outdoor client's UnitPosition Z is unverified. Only an
            -- explicitly verified future observation may establish live height.
            if observation.zVerified == true then
                if type(observation.z) ~= "number" or type(target.z) ~= "number"
                    or math.abs(observation.z-target.z) > 0.5 then return false end
                return dx * dx + dy * dy <= r * r, "height_verified"
            end
        end
        return dx * dx + dy * dy <= r * r, "xy_only"
    end
    return dx * dx + dy * dy <= r * r
end
