local module = WowVision.base.navigation:createModule("walls")
local L = module.L
module:setLabel(L["Wall Detection"])

-- Wall detection (Sku's stuck system, whose graded sounds we ship with
-- permission): when the player is moving (a commanded movement, or the game
-- walking them: autorun, the interact key) but their position barely
-- changes, they are against something. The shortfall between actual
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
local wasMoving = false
-- The last check's severity, for judging how a game walk ended.
local lastSeverity = nil

-- Stunned, rooted and the like: standing still is no wall then. The game
-- shows it on screen (the loss of control alert).
local function lostControl()
    return C_LossOfControl.GetActiveLossOfControlDataCount() > 0
end

-- A walk the game makes with no key held (the interact key, click to move)
-- ends on its own when the way is blocked, mostly before three checks could
-- grade it. A walk that ended short of its goal plays the blocked sound
-- once. The game reports a stop and a start in the same instant as such a
-- walk begins, so a stop counts only once it held for STOP_SETTLE.
local STOP_SETTLE = 0.2
local gameWalkStart = nil
-- When the game said the walk stopped, and the last check's severity then
-- (checks after the stop see a standing player).
local stoppedAt, stoppedSeverity = nil, nil

module:registerEvent("event", "PLAYER_STARTED_MOVING")
module:registerEvent("event", "PLAYER_STOPPED_MOVING")

function module:onEvent(event)
    if event == "PLAYER_STARTED_MOVING" then
        if stoppedAt == nil then
            gameWalkStart = not WowVision.movement:isTranslating() and GetTime() or nil
        end
        stoppedAt = nil
    elseif event == "PLAYER_STOPPED_MOVING" and gameWalkStart ~= nil then
        stoppedAt, stoppedSeverity = GetTime(), lastSeverity
    end
end

local function checkGameWalkEnd(self, now)
    local movement = WowVision.movement
    -- A movement key during the walk made it the player's own (the start
    -- comes before the key's Start function, so a quick tap shows only in
    -- lastCommandAt).
    if movement:isTranslating() or movement.lastCommandAt >= gameWalkStart then
        gameWalkStart, stoppedAt = nil, nil
        return
    end
    if stoppedAt == nil or now - stoppedAt < STOP_SETTLE then
        return
    end
    gameWalkStart, stoppedAt = nil, nil
    if not lostControl() and stuckMath.walkEndedShort(stoppedSeverity) then
        self:fireAlert("stuck", { action = "stuck1" })
    end
end

module:hasUpdate(function(self)
    local now = GetTime()
    if now - lastCheck < CHECK_INTERVAL then
        return
    end
    local dt = now - lastCheck
    lastCheck = now

    if UnitOnTaxi("player") then
        lastX, lastY = nil, nil
        wasMoving = false
        lastSeverity = nil
        cadence:sample(nil)
        return
    end

    if gameWalkStart ~= nil then
        checkGameWalkEnd(self, now)
    end

    local px, py = UnitPosition("player")
    local moving = WowVision.movement:isMoving()

    if lostControl() then
        lastSeverity = nil
        cadence:sample(nil)
    -- Only judge intervals where the player was moving end to end and both
    -- position samples exist.
    elseif moving and wasMoving and px ~= nil and lastX ~= nil then
        local dx, dy = px - lastX, py - lastY
        local actual = math.sqrt(dx * dx + dy * dy)
        local speed, _, _, swimSpeed = GetUnitSpeed("player")
        -- In water the first return stays the run speed, which would read
        -- every stroke as a shortfall.
        if IsSwimming() then
            speed = swimSpeed
        end
        local severity
        if WowVision.isSecret(speed) then
            -- Speed is a secret value in combat on the modern engine, and the
            -- grading compares it. The position stays plain, so a standstill
            -- is still judged.
            severity = stuckMath.standstill(actual, dt)
        else
            severity = stuckMath.severity(actual, speed, dt)
        end
        lastSeverity = severity
        local sound = cadence:sample(severity)
        if sound ~= nil then
            self:fireAlert("stuck", { action = "stuck" .. sound })
        end
    else
        lastSeverity = nil
        cadence:sample(nil)
    end

    lastX, lastY = px, py
    wasMoving = moving
end)
