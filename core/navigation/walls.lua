local module = WowVision.base.navigation:createModule("walls")
local L = module.L
module:setLabel(L["Wall Detection"])

-- Wall detection (Sku's stuck system, whose graded sounds we ship with
-- permission): when the player is COMMANDING translation but their position
-- barely changes, they are against something. The shortfall between actual
-- and expected movement grades into five severities, each an independently
-- configurable sound output; a cadence counter turns continuous pushing
-- into rhythmic clunks. Toggle the whole thing via the alert's enable.

local stuckMath = WowVision.stuckMath

local CHECK_INTERVAL = 0.15

local severityLabels = {
    L["Blocked"],
    L["Mostly Blocked"],
    L["Impeded"],
    L["Slowed"],
    L["Slightly Slowed"],
}

local alert = module:addAlert({ key = "stuck", label = L["Wall Detection"] })
for severity = 1, 5 do
    alert:addOutput({
        type = "Sound",
        key = "stuck" .. severity,
        action = "stuck" .. severity,
        label = severityLabels[severity],
        path = "Sound/WowVision/alerts/stuck" .. severity .. ".mp3",
    })
end

local settings = module:hasSettings()
settings:addRef("stuck", alert.parameters)

local cadence = stuckMath.newCadence(3)
local lastCheck = 0
local lastX, lastY = nil, nil
local wasTranslating = false

module:hasUpdate(function(self)
    local now = GetTime()
    if now - lastCheck < CHECK_INTERVAL then
        return
    end
    local dt = now - lastCheck
    lastCheck = now

    if UnitOnTaxi("player") then
        lastX, lastY = nil, nil
        wasTranslating = false
        cadence:sample(nil)
        return
    end

    local px, py = UnitPosition("player")
    local translating = WowVision.movement:isTranslating()

    -- Only judge intervals where translation was commanded end to end and
    -- both position samples exist.
    if translating and wasTranslating and px ~= nil and lastX ~= nil then
        local dx, dy = px - lastX, py - lastY
        local actual = math.sqrt(dx * dx + dy * dy)
        local severity = stuckMath.severity(actual, GetUnitSpeed("player"), dt)
        local sound = cadence:sample(severity)
        if sound ~= nil then
            self:fireAlert("stuck", { action = "stuck" .. sound })
        end
    else
        cadence:sample(nil)
    end

    lastX, lastY = px, py
    wasTranslating = translating
end)
