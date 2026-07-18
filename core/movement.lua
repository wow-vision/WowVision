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
    },
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
        or flags.autorun
        or flags.following
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
hooksecurefunc("FollowUnit", flagSetter("following", true))
-- Any manual movement command ends follow.
hooksecurefunc("MoveForwardStart", flagSetter("following", false))
hooksecurefunc("MoveBackwardStart", flagSetter("following", false))
hooksecurefunc("StartAutoRun", flagSetter("following", false))
