local module = WowVision.base.navigation.maps
local L = module.L
local unitAim = WowVision.unitAim
local camera = WowVision.navigationCamera
local secrets = WowVision.secrets

-- Turn the character to face a unit: the target, or the focus (an escort
-- NPC on focus keeps the target free for the fight). A sighted player sees
-- where the unit stands; the game gives addons no position for an NPC, but
-- it does answer whether the unit's nameplate is behind the camera.
--
-- Facts this rests on (WoW: Forever, in game 2026-11-12):
-- - C_NamePlate.GetNamePlateForUnit(unit) gives the unit's plate without
--   any unit comparison (UnitIsUnit is secret in instances). Addons may not
--   measure the plate ("Can't measure restricted regions"), but
--   C_NamePlateManager.IsNamePlateUnitBehindCamera answers every frame.
-- - In first person the unit changes between in front of the camera and
--   behind it exactly 90 degrees either side of its bearing, at any
--   distance (unitAim.lua).
-- - Camera sweeps started outside a key press must be primed
--   (turnByAngle's lateStart, turnTo.lua).
--
-- A press: snap the camera behind the character and into first person;
-- sweep the camera alone to the right until the plate's answer changes
-- (at most half a turn); that change gives the bearing. Within the turn
-- tolerance nothing more happens. Else the camera turns the short way to
-- the bearing and its stop hands it to the character, as a turn to
-- waypoint ends. Then the camera goes back behind the character.

-- The measuring sweep: degrees per second (6 a frame at 60 fps, so the
-- bearing is good to about 3 degrees), and how far: the change comes within
-- half a turn, a little more allows for the primed start.
local SWEEP_SPEED = 360
local SWEEP_LIMIT = 200
-- Frames for the switch to first person to land and the plates to follow.
local VIEW_FRAMES = 3
-- In first person the camera is at the character's eyes.
local FIRST_PERSON_ZOOM = 0.5
-- As turn to waypoint: this close counts as facing it already.
local FACING_TOLERANCE = 3
-- A press still running after this long (a Lua error in a callback) is
-- given up, and a new press starts over.
local STUCK = 5
local KEEP_READINGS = 40

local alert = module:addAlert({ key = "turnToUnit", label = L["Turn to Unit"] })
alert:addOutput({
    type = "Sound",
    key = "facing",
    action = "facing",
    label = L["Facing Unit"],
    path = "Sound/WowVision/alerts/clack.mp3",
})

local waitFrame = CreateFrame("Frame")
local running = nil

-- The press log, kept in WowVisionDump.turnToUnit so it is in the
-- SavedVariables after a /reload: one line per press.
local function readings()
    WowVisionDump = WowVisionDump or {}
    if type(WowVisionDump.turnToUnit) ~= "table" then
        WowVisionDump.turnToUnit = {}
    end
    return WowVisionDump.turnToUnit
end

local function note(run, line)
    tinsert(run.lines, line)
end

-- The facing in degrees (nil where the game hides it: instances).
local function facingDegrees()
    local ok, facing = pcall(GetPlayerFacing)
    if ok and type(facing) == "number" and not secrets.isSecret(facing) then
        return math.deg(facing)
    end
    return nil
end

local function cameraZoom()
    local ok, zoom = pcall(GetCameraZoom)
    if ok and type(zoom) == "number" and not secrets.isSecret(zoom) then
        return zoom
    end
    return nil
end

local function findPlate(unit)
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then
        return plate
    end
    return nil
end

-- Whether the press's unit is in front of the camera now: true, false,
-- "lost" (its plate is gone or belongs to another unit now: target changed,
-- unit died or out of range), or nil (the game will not say).
local function inFront(run)
    local plate = findPlate(run.unit)
    if plate == nil or plate ~= run.plate then
        return "lost"
    end
    local token = plate.unitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    local manager = C_NamePlateManager
    if token == nil or manager == nil or manager.IsNamePlateUnitBehindCamera == nil then
        return nil
    end
    local ok, behind = pcall(manager.IsNamePlateUnitBehindCamera, token)
    if not ok or secrets.isSecret(behind) then
        return nil
    end
    return behind == false
end

-- The sweeps set the camera's turn speed (cameraYawMoveSpeed). Whether the
-- game lets an addon write it in combat is not known; a refused write would
-- break the sweep, so each press writes the value it has first.
local function cameraSpeedWritable()
    local okRead, value = pcall(GetCVar, "cameraYawMoveSpeed")
    if not okRead or value == nil then
        return false
    end
    local ok, result = pcall(SetCVar, "cameraYawMoveSpeed", value)
    return ok and result ~= false
end

-- Run fn after frames real frames, unless the press ended meanwhile.
local function afterFrames(run, frames, fn)
    local last = GetTime()
    local seen = 0
    waitFrame:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if now <= last then
            return
        end
        last = now
        seen = seen + 1
        if seen >= frames then
            self:SetScript("OnUpdate", nil)
            if running == run then
                fn()
            end
        end
    end)
end

-- End the press. message nil: facing the unit (the alert); "": quietly;
-- else it is said. The camera goes back behind the character in any case.
local function finish(run, message)
    if running ~= run then
        return
    end
    running = nil
    waitFrame:SetScript("OnUpdate", nil)
    camera.align()
    if run.freeLookOff then
        camera.endGamepadTurn()
    end
    local facing = facingDegrees()
    if run.facing ~= nil and facing ~= nil then
        -- positive = turned right, as the bearing
        note(run, string.format("turned %.1f", unitAim.wrap(run.facing - facing)))
    end
    note(run, message or "facing")
    local list = readings()
    tinsert(list, date("%Y-%m-%d %H:%M:%S") .. " " .. run.unit .. ": " .. table.concat(run.lines, ", "))
    while #list > KEEP_READINGS do
        tremove(list, 1)
    end
    if message == nil then
        module:fireAlert("turnToUnit", { action = "facing" })
    elseif message ~= "" then
        WowVision:notify(message)
    end
end

-- The short way from where the measuring sweep stopped to the bearing; the
-- turn's stop hands the camera to the character.
local function approach(run, angle)
    note(run, string.format("approach %.1f", angle))
    local started = module:turnByAngle(angle, {
        label = "unit ",
        keepCamera = true,
        lateStart = true,
        onDone = function(how)
            if how == "landed" then
                finish(run)
            else
                finish(run, "")
            end
        end,
    })
    if started ~= true then
        -- (the change lies 90 degrees off the bearing: never "facing")
        finish(run, "")
    end
end

-- Sweep the camera alone to the right until the unit changes between in
-- front and behind; that change gives the bearing.
local function measure(run)
    local zoom = cameraZoom()
    if zoom ~= nil and zoom > FIRST_PERSON_ZOOM then
        -- The view switch was refused: no first person, no 90 degrees.
        note(run, string.format("not in first person, zoom %.1f", zoom))
        return finish(run, L["Turning is not available here"])
    end
    local last = inFront(run)
    if last == "lost" then
        return finish(run, L["Lost the nameplate"])
    elseif last == nil then
        return finish(run, L["Nameplate position is hidden here"])
    end
    local previous = 0
    local change = nil
    local lost = false
    local started = module:turnByAngle(SWEEP_LIMIT, {
        label = "unit ",
        cameraOnly = true,
        lateStart = true,
        fixedSpeed = SWEEP_SPEED,
        onFrame = function(moved)
            local now = inFront(run)
            if now == "lost" then
                lost = true
                return true
            end
            if now ~= nil and now ~= last then
                change = { at = (previous + moved) / 2, cameIn = now, moved = moved }
                return true
            end
            previous = moved
            return false
        end,
        onDone = function(how)
            if running ~= run then
                return
            end
            if how ~= "landed" then
                return finish(run, "")
            elseif lost then
                return finish(run, L["Lost the nameplate"])
            elseif change == nil then
                note(run, "no change")
                return finish(run, L["Could not turn to it"])
            end
            local bearing = unitAim.firstPersonBearing(change.at, change.cameIn)
            note(run, string.format("change %.1f %s, bearing %.1f", change.at, change.cameIn and "in" or "out", bearing))
            if math.abs(bearing) <= FACING_TOLERANCE then
                note(run, "already facing")
                return finish(run)
            end
            approach(run, unitAim.wrap(bearing - change.moved))
        end,
    })
    if started ~= true then
        finish(run, "")
    end
end

-- Turn to face unit ("target" or "focus").
function module:turnToUnit(unit)
    if running ~= nil then
        if GetTime() - running.started < STUCK then
            return false
        end
        finish(running, "")
    end
    if self:isTurning() then
        -- a turn to waypoint still runs
        return false
    end
    if not UnitExists(unit) then
        WowVision:notify(unit == "focus" and L["No focus"] or L["No target"])
        return false
    end
    local plate = findPlate(unit)
    if plate == nil then
        -- Instances hide friendly nameplates from addons (forbidden frames).
        local reaction = UnitReaction("player", unit)
        if IsInInstance() and reaction ~= nil and not secrets.isSecret(reaction) and reaction >= 5 then
            WowVision:notify(L["Friendly nameplates are hidden here"])
        else
            WowVision:notify(L["No nameplate"])
        end
        return false
    end
    if not cameraSpeedWritable() then
        WowVision:notify(L["Turning is not available here"])
        return false
    end
    local run = {
        unit = unit,
        plate = plate,
        started = GetTime(),
        facing = facingDegrees(),
        lines = {},
    }
    running = run
    note(run, (InCombatLockdown() and "in combat" or "no combat") .. ", " .. (IsInInstance() and "instance" or "world"))
    if run.facing ~= nil then
        note(run, string.format("facing %.1f", run.facing))
    end
    camera.align()
    camera.firstPerson()
    run.freeLookOff = camera.beginGamepadTurn()
    afterFrames(run, VIEW_FRAMES, function()
        measure(run)
    end)
    return true
end

-- Copyable diagnostics: the press log, also printed to chat.
module:registerCommand({
    name = "unitturnlog",
    description = "Show the last turns to a unit",
    func = function()
        local list = readings()
        local lines = { string.format("%d presses", #list) }
        for _, line in ipairs(list) do
            tinsert(lines, line)
        end
        for _, line in ipairs(lines) do
            print(line)
        end
        WowVision.testing.showResults(table.concat(lines, string.char(10)))
        WowVision:speak(lines[1])
    end,
})

module:registerBinding({
    type = "Script",
    key = "maps/turnToTarget",
    label = L["Turn to Target"],
    inputs = { "CTRL-I" },
    script = "/run WowVision.base.navigation.maps:turnToUnit('target')",
})

module:registerBinding({
    type = "Script",
    key = "maps/turnToFocus",
    label = L["Turn to Focus"],
    inputs = { "CTRL-U" },
    script = "/run WowVision.base.navigation.maps:turnToUnit('focus')",
})
