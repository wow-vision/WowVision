-- Turn-to-waypoint math, kept free of game calls so it runs in the
-- headless tests. turnTo.lua drives the camera with it; the engine facts
-- the numbers rest on are written down there.
local turnMath = {}

turnMath.SPEED_MIN = 60
-- cameraYawMoveSpeed does nothing above 360; the MoveView argument
-- multiplies it, so speeds above 360 are CVar 360 times a factor up to 4.
turnMath.CVAR_MAX = 360
turnMath.SPEED_MAX = 1440
-- A last step smaller than this share of a frame is not trimmed: the
-- sweep stops one frame early instead.
turnMath.TRIM_MIN = 0.05

-- Seconds per frame at the given frame rate, clamped to sane rates.
function turnMath.frameTime(fps)
    if fps == nil or fps < 10 then
        fps = 10
    elseif fps > 240 then
        fps = 240
    end
    return 1 / fps
end

-- Speed and frame count for a turn of angle degrees: as few frames as the
-- top speed allows, then the speed that makes the angle exactly that many
-- whole frames. At a steady frame rate the last frame lands on the angle
-- without a trim; at 20 fps a full-speed frame is 72 degrees, so this is
-- what keeps low frame rates exact.
function turnMath.plan(angle, frameTime)
    local steps = math.max(1, math.ceil(angle / (turnMath.SPEED_MAX * frameTime) - 1e-9))
    local speed = math.max(turnMath.SPEED_MIN, math.min(turnMath.SPEED_MAX, angle / (steps * frameTime)))
    return speed, steps
end

-- One camera sweep, fed the real duration of every frame. The camera
-- moves once per frame by speed times that frame's duration, the frame
-- whose OnUpdate stops it does not move, and the elapsed time an OnUpdate
-- sees is the duration of the step that follows it. So each frame knows
-- its own step before it happens: let it run, trim it to the remainder,
-- or stop.
local Sweep = {}
Sweep.__index = Sweep

function turnMath.newSweep(angle, speed, steps)
    return setmetatable({
        motionTarget = angle / speed,
        committed = 0, -- seconds of motion already granted
        frames = 0,
        frameCap = steps * 2 + 3, -- emergency stop
        stopNext = false,
        trim = nil,
    }, Sweep)
end

-- Returns "move" (this frame's step runs whole), "trim" plus the share of
-- the step to keep (scale the CVar by it for this one frame), or "stop".
function Sweep:frame(delta)
    self.frames = self.frames + 1
    if self.stopNext or self.frames >= self.frameCap then
        return "stop"
    end
    local rest = self.motionTarget - self.committed
    if delta <= rest then
        self.committed = self.committed + delta
        return "move"
    end
    local fraction = rest / delta
    -- Nearly there: stop now, unless no step has run yet.
    if fraction < turnMath.TRIM_MIN and self.frames >= 2 then
        return "stop"
    end
    fraction = math.max(fraction, turnMath.TRIM_MIN)
    self.committed = self.committed + delta * fraction
    self.trim = fraction
    self.stopNext = true
    return "trim", fraction
end

local function wrap(degrees)
    while degrees > 180 do
        degrees = degrees - 360
    end
    while degrees <= -180 do
        degrees = degrees + 360
    end
    return degrees
end

-- Bearing from (px, py) to (x, y) relative to facing (radians), in
-- degrees, positive = to the right (Beacon's convention).
function turnMath.relativeBearing(px, py, facing, x, y)
    local bearing = -math.deg(math.atan2(y - py, x - px))
    return wrap(bearing + math.deg(facing))
end

-- Degrees the facing actually moved in the turn's direction (1 = right,
-- -1 = left). A right turn lowers the facing. A turn that ends just past
-- 180 would wrap to minus 179: take the full-circle value nearest the
-- target.
function turnMath.turned(startFacing, endFacing, direction, target)
    local turned = wrap(math.deg(startFacing - endFacing)) * direction
    if turned < target - 180 then
        turned = turned + 360
    end
    return turned
end

-- Direction the player is moving in (radians, same frame as facing), from
-- the movement flags, or nil when not translating. Strafing moves sideways,
-- so the direction is not simply the facing.
function turnMath.moveDirection(facing, flags)
    local forward = ((flags.moveForward or flags.autorun or flags.following) and 1 or 0)
        - (flags.moveBackward and 1 or 0)
    local side = (flags.strafeRight and 1 or 0) - (flags.strafeLeft and 1 or 0)
    if forward == 0 and side == 0 then
        return nil
    end
    return facing - math.atan2(side, forward)
end

-- Where the player will be when the turn lands: distance yards along
-- direction, never more than half the way to the target, so the aim never
-- swings behind it.
function turnMath.leadPoint(px, py, x, y, direction, distance)
    local remaining = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
    distance = math.min(distance, remaining * 0.5)
    return px + math.cos(direction) * distance, py + math.sin(direction) * distance
end

WowVision.turnMath = turnMath
