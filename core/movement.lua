-- Movement INTENT tracking: hooks on the movement API functions maintain a
-- flags table of what the player is commanding, regardless of which keys
-- those actions are bound to. Consumers: wall detection (commanded movement
-- vs actual displacement), and any future feature that needs to know the
-- player is trying to move (fall detection, off-route checks).
--
-- Same approach as Sku's SkuCoreMovement: hooksecurefunc fires alongside the
-- game's own handling and never taints it.

local movement = {
    flags = {
        moveForward = false,
        moveBackward = false,
        strafeLeft = false,
        strafeRight = false,
        turnLeft = false,
        turnRight = false,
        ascend = false,
        descend = false,
        autorun = false,
        following = false,
        pitchUp = false,
        pitchDown = false,
        moveAndSteer = false,
    },
    -- GetTime() of the last translation command (a movement key going down,
    -- autorun). The game reports PLAYER_STARTED_MOVING before the key's Start
    -- function runs, in the same frame, so a start with no flag set can still
    -- be the player's own: compare against this.
    lastCommandAt = 0,
    -- The game's own turning state (PLAYER_STARTED_TURNING and
    -- PLAYER_STOPPED_TURNING): the ground truth behind the turn flags, as
    -- IsPlayerMoving is behind the movement flags.
    turning = false,
    -- Whether your auto-attack is on (PLAYER_ENTER_COMBAT and
    -- PLAYER_LEAVE_COMBAT, which despite their names follow the attack, not
    -- the fight).
    attacking = false,
}
WowVision.movement = movement

-- Whether the player is commanding any translation (movement that should
-- change position -- turning alone does not).
function movement:isTranslating()
    local flags = self.flags
    return flags.moveForward
        or flags.moveBackward
        or flags.strafeLeft
        or flags.strafeRight
        or flags.moveAndSteer
        or flags.autorun
        or flags.following
end

-- Whether the player is moving by any means: a commanded movement, or the
-- game moving them with no key held (autorun, the interact key walking to
-- its target, click to move). The game's moving state is the ground truth:
-- it stays on while the player pushes against something (and while stunned
-- with a key held), turning has a state of its own (PLAYER_STARTED_TURNING),
-- and it stays off when a flag above went stale (a key release that never
-- reached its Stop function). Falls without a key are left out: a fall
-- straight down has no sideways movement to judge.
function movement:isMoving()
    return IsPlayerMoving() and (self:isTranslating() or not IsFalling())
end

-- Whether the game is chasing the enemy you fight: you are in combat, your
-- auto-attack is on and you command no translation. Attacking with the
-- interact key (click to move) keeps the game walking you after the enemy
-- for the whole fight, with small steps while you stand in reach: the
-- game's moving state stays on though you hardly move. The walk up to the
-- enemy, before the fight begins, is no chase: an obstacle on the way
-- still counts.
function movement:isChasing()
    return self.attacking and not self:isTranslating() and UnitAffectingCombat("player") == true
end

local function flagSetter(key, value)
    return function()
        movement.flags[key] = value
    end
end

hooksecurefunc("MoveForwardStart", flagSetter("moveForward", true))
hooksecurefunc("MoveForwardStop", flagSetter("moveForward", false))
hooksecurefunc("MoveBackwardStart", flagSetter("moveBackward", true))
hooksecurefunc("MoveBackwardStop", flagSetter("moveBackward", false))
hooksecurefunc("StrafeLeftStart", flagSetter("strafeLeft", true))
hooksecurefunc("StrafeLeftStop", flagSetter("strafeLeft", false))
hooksecurefunc("StrafeRightStart", flagSetter("strafeRight", true))
hooksecurefunc("StrafeRightStop", flagSetter("strafeRight", false))
hooksecurefunc("TurnLeftStart", flagSetter("turnLeft", true))
hooksecurefunc("TurnLeftStop", flagSetter("turnLeft", false))
hooksecurefunc("TurnRightStart", flagSetter("turnRight", true))
hooksecurefunc("TurnRightStop", flagSetter("turnRight", false))
hooksecurefunc("JumpOrAscendStart", flagSetter("ascend", true))
hooksecurefunc("AscendStop", flagSetter("ascend", false))
hooksecurefunc("SitStandOrDescendStart", flagSetter("descend", true))
hooksecurefunc("DescendStop", flagSetter("descend", false))
hooksecurefunc("StartAutoRun", flagSetter("autorun", true))
hooksecurefunc("StopAutoRun", flagSetter("autorun", false))
hooksecurefunc("ToggleAutoRun", function()
    movement.flags.autorun = not movement.flags.autorun
end)
local function noteCommand()
    movement.lastCommandAt = GetTime()
end
for _, name in ipairs({
    "MoveForwardStart",
    "MoveBackwardStart",
    "StrafeLeftStart",
    "StrafeRightStart",
    "StartAutoRun",
    "ToggleAutoRun",
}) do
    hooksecurefunc(name, noteCommand)
end
hooksecurefunc("FollowUnit", flagSetter("following", true))

-- Pitch and move-and-steer are held commands too (the key takeover guard in
-- core/ui/input/heldKeys.lua asks for them); their functions are not on
-- every client.
local function hookIfPresent(name, func)
    if type(_G[name]) == "function" then
        hooksecurefunc(name, func)
    end
end
hookIfPresent("PitchUpStart", flagSetter("pitchUp", true))
hookIfPresent("PitchUpStop", flagSetter("pitchUp", false))
hookIfPresent("PitchDownStart", flagSetter("pitchDown", true))
hookIfPresent("PitchDownStop", flagSetter("pitchDown", false))
hookIfPresent("MoveAndSteerStart", flagSetter("moveAndSteer", true))
hookIfPresent("MoveAndSteerStop", flagSetter("moveAndSteer", false))
-- Any manual movement command ends follow.
hooksecurefunc("MoveForwardStart", flagSetter("following", false))
hooksecurefunc("MoveBackwardStart", flagSetter("following", false))
hooksecurefunc("StartAutoRun", flagSetter("following", false))

-- The game ends some movement without calling the hooked functions: a
-- movement key cancels autorun without StopAutoRun, so the flag would stay
-- on and the next ToggleAutoRun would invert it; follow ends on its own when
-- the leader gets out of range. Stopping is the ground truth for autorun
-- (pushing against a wall does not count as stopping), AUTOFOLLOW_END for
-- follow.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_STOPPED_MOVING")
frame:RegisterEvent("AUTOFOLLOW_END")
frame:RegisterEvent("PLAYER_STARTED_TURNING")
frame:RegisterEvent("PLAYER_STOPPED_TURNING")
frame:RegisterEvent("PLAYER_ENTER_COMBAT")
frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_STOPPED_MOVING" then
        movement.flags.autorun = false
    elseif event == "AUTOFOLLOW_END" then
        movement.flags.following = false
    elseif event == "PLAYER_STARTED_TURNING" then
        movement.turning = true
    elseif event == "PLAYER_STOPPED_TURNING" then
        movement.turning = false
    elseif event == "PLAYER_ENTER_COMBAT" then
        movement.attacking = true
    elseif event == "PLAYER_LEAVE_COMBAT" then
        movement.attacking = false
    end
end)
