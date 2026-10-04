local module = WowVision.base.navigation:createModule("pitchLock")
local L = module.L
module:setLabel(L["Pitch Lock"])

-- Pitch lock while swimming and flying (Sku's fix, rebuilt):
--
-- The mouselook pulse that ends every turn to waypoint copies the camera's
-- pitch onto the character too, and the camera always looks slightly
-- down, so in water and in the air every turn tipped the nose down: a slow
-- dive no keyboard input can undo. The console command pitchlimit caps how
-- far the character can pitch while moving; 0 keeps it level.
--
-- Measured in Sku on TBC:
-- - The lock must be HELD while swimming or flying; switching it on only
--   around each pulse failed.
-- - It works in combat (a console command, not a protected setting).
-- - It cannot be read back, so every login blindly restores the default.
-- - It caps but does not level: a tilt already there stays. Re-levelling
--   means a camera snap to a known nearly-level view plus one pulse, at
--   least half a second after a turn's own pulse (the turn's yaw lands a
--   frame late; an early second pulse undoes the turn).
-- - Interact-to-move steers the character down THROUGH the lock; that
--   approach ends when the NPC's window opens.
-- - It caps the view pitch as well, so it is held only in water and in the
--   air, never on land or on a taxi.
--
-- Space and X keep working under the lock, so a keyboard player loses no
-- vertical movement. Disabling this module releases the lock.

local CHECK_INTERVAL = 0.25
local LIMIT_LOCKED = "pitchlimit 0"
local LIMIT_DEFAULT = "pitchlimit 88"
local AFTER_TURN_DELAY = 0.5
local LEVEL_DEBOUNCE = 0.75
-- Re-levelling waits this long after a turn started (its own pulse and
-- the delayed re-level are still in flight).
local TURN_QUIET = 1.2

local pitchLock = {
    locked = false,
    -- Retail turns this off: skyriding steers by pitch.
    lockWhileFlying = true,
}
WowVision.pitchLock = pitchLock

local camera = WowVision.navigationCamera
local lastTurn = 0
local lastLevel = 0
local turnSeq = 0

local function inWaterOrAir()
    if UnitOnTaxi("player") then
        return false
    end
    return IsSwimming() or (pitchLock.lockWhileFlying and IsFlying()) or false
end

local function setLimit(command)
    pcall(ConsoleExec, command)
end

local function lock()
    setLimit(LIMIT_LOCKED)
    pitchLock.locked = true
end

local function unlock()
    setLimit(LIMIT_DEFAULT)
    pitchLock.locked = false
end

local function canLevel()
    return pitchLock.locked and inWaterOrAir()
end

local function level()
    lastLevel = GetTime()
    camera.align()
    camera.transfer()
end

-- Turn to waypoint calls these.
function pitchLock.noteTurn()
    lastTurn = GetTime()
    turnSeq = turnSeq + 1
end

-- After a turn's pulse: re-level once it has landed, unless a newer turn
-- started meanwhile.
function pitchLock.afterTurn()
    if not canLevel() then
        return
    end
    local seq = turnSeq
    C_Timer.After(AFTER_TURN_DELAY, function()
        if seq == turnSeq and canLevel() then
            level()
        end
    end)
end

-- A press of the turn key while already facing the waypoint re-levels,
-- so the key itself is the way out of a tilt.
function pitchLock.alreadyFacing()
    local now = GetTime()
    if canLevel() and now - lastTurn > 1 and now - lastLevel > LEVEL_DEBOUNCE then
        level()
    end
end

local function levelQuietly()
    local now = GetTime()
    if canLevel() and now - lastLevel >= LEVEL_DEBOUNCE and now - lastTurn >= TURN_QUIET then
        level()
    end
end

-- Ascend and descend: "I pressed Space to stop sinking, now hold me
-- level". Hooked on the engine functions, so any key bound to them counts.
hooksecurefunc("JumpOrAscendStart", levelQuietly)
hooksecurefunc("AscendStop", levelQuietly)
hooksecurefunc("SitStandOrDescendStart", levelQuietly)
hooksecurefunc("DescendStop", levelQuietly)

module:registerEvent("event", "PLAYER_ENTERING_WORLD")
-- The windows that end an interact-to-move approach.
module:registerEvent("event", "GOSSIP_SHOW")
module:registerEvent("event", "QUEST_GREETING")
module:registerEvent("event", "QUEST_DETAIL")
module:registerEvent("event", "QUEST_PROGRESS")
module:registerEvent("event", "MERCHANT_SHOW")

function module:onEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- A lock left over from a reload; a zone change while locked keeps it.
        if not pitchLock.locked then
            unlock()
        end
        return
    end
    levelQuietly()
end

local nextCheck = 0
module:hasUpdate(function(self)
    local now = GetTime()
    if now < nextCheck then
        return
    end
    nextCheck = now + CHECK_INTERVAL
    local wanted = inWaterOrAir()
    if wanted and not pitchLock.locked then
        lock()
    elseif not wanted and pitchLock.locked then
        unlock()
    end
end)

function module:onDisable()
    if pitchLock.locked then
        unlock()
    end
end
