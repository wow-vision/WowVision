local module = WowVision.base.navigation.maps
local L = module.L
local unitAim = WowVision.unitAim
local camera = WowVision.navigationCamera
local secrets = WowVision.secrets

-- Turn the character to face a unit: the target, or the focus (an escort
-- NPC on focus keeps the target free for the fight).
--
-- The game gives coordinates for group members only, and none in
-- instances, so for an NPC the unit's NAMEPLATE is the way: it stands on
-- screen above the unit, where every sighted player sees it. The plate is
-- fetched for the unit token itself (C_NamePlate.GetNamePlateForUnit), so
-- no unit comparison is needed; UnitIsUnit and raid marker numbers come
-- back secret on WoW: Forever in instances. unitAim.lua turns the plate's
-- place on screen into a turn; each turn is a turn to waypoint sweep
-- (turnTo.lua), so it lands frame-exact and needs neither the player's
-- position nor facing. Two or three turns per press: see unitAim.lua.
-- The sweeps move only the camera; the character turns once, at the end,
-- and only when the unit was found.
--
-- WoW: Forever refuses to measure nameplates ("Can't measure restricted
-- regions", tested 2026-11-12) but says whether one is behind the camera:
-- there the edge sweep finds the bearing instead (unitAim.edgeBearing).
--
-- A unit with coordinates (a group member outdoors) is turned to by them,
-- like a waypoint.

-- At most this many aiming turns per press.
local MAX_TURNS = 4
-- With offscreen nameplates off (the game's default) a unit off screen has
-- no plate: look around in quarter turns first. A screen shows about a
-- quarter circle, so three of them cover the rest.
local SEARCH_TURN = 90
local SEARCH_TURNS = 3
-- A press still running after this long (it should take well under a
-- second) is taken as stuck and a new press starts over.
local STUCK = 5
-- After the last turn, still this far off is reported as a miss.
local MISSED = 10
-- Frames to wait after the camera moved, before its plates are read: the
-- plates follow the camera a frame later.
local READ_FRAMES = 2
-- The edge sweep (where plates cannot be measured): degrees per second
-- (6 degrees a frame at 60 fps).
local EDGE_SPEED = 360
-- The camera is pulled in to this many yards for it, staying behind the
-- character (third person: first person turned out wrong in game). A unit
-- nearer than that never goes behind the camera. A fast zoom, then wait
-- until it is there and has held still ZOOM_STILL frames, at most
-- ZOOM_FRAMES: a zoom still running moves the two changes unevenly.
local ZOOM_TO = 2
local ZOOM_SPEED = 50
local ZOOM_STILL = 2
local ZOOM_FRAMES = 60
-- With the camera behind the character the in-front stretch is at least
-- half a circle, wider the nearer the unit. Outside these the changes were
-- not clean: no turn then.
local WIDTH_MIN = 170
local WIDTH_MAX = 330
-- Assumed horizontal field of view when the game does not say; the gain
-- takes up the error (unitAim.lua).
local FOV_DEFAULT = 90

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
-- The log of presses (and trials), kept in WowVisionDump.turnToUnit so it
-- is in the SavedVariables after a /reload or logout: no copying from chat.
local KEEP_READINGS = 40

local function readings()
    WowVisionDump = WowVisionDump or {}
    if type(WowVisionDump.turnToUnit) ~= "table" then
        WowVisionDump.turnToUnit = {}
    end
    return WowVisionDump.turnToUnit
end

local function addReading(text)
    local list = readings()
    tinsert(list, date("%Y-%m-%d %H:%M:%S") .. " " .. text)
    while #list > KEEP_READINGS do
        tremove(list, 1)
    end
end

local function fieldOfView()
    local ok, value = pcall(GetCVar, "cameraFov")
    local fov = ok and tonumber(value) or nil
    if fov == nil or fov < 30 or fov > 150 then
        return FOV_DEFAULT
    end
    return fov
end

-- The unit's plate: asked for by the unit token, else found among the
-- plates by UnitIsUnit (fine outdoors; secret in instances, then skipped).
local function findPlate(unit)
    if C_NamePlate == nil or C_NamePlate.GetNamePlateForUnit == nil then
        return nil
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and plate ~= nil then
        return plate
    end
    local okList, plates = pcall(C_NamePlate.GetNamePlates)
    if not okList or type(plates) ~= "table" then
        return nil
    end
    for _, candidate in ipairs(plates) do
        local token = candidate.unitToken or (candidate.UnitFrame and candidate.UnitFrame.unit)
        if token ~= nil then
            local okSame, same = pcall(UnitIsUnit, token, unit)
            if okSame and not secrets.isSecret(same) and same == true then
                return candidate
            end
        end
    end
    return nil
end

-- What the unit's plate says now: "none", "hidden" (the game keeps its
-- place on screen from addons) plus why, "behind", or "seen" plus its
-- offset from the screen centre (-1 to 1).
local function readPlate(unit)
    local plate = findPlate(unit)
    if plate == nil then
        return "none"
    end
    -- Measuring first: where the game refuses it, the edge sweep takes
    -- over from the camera as it is (behind the character).
    local okCenter, x = pcall(plate.GetCenter, plate)
    if not okCenter then
        return "hidden", "measuring refused"
    elseif x == nil then
        return "hidden", "no center"
    elseif secrets.isSecret(x) then
        return "hidden", "secret center"
    end
    local token = plate.unitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    local manager = C_NamePlateManager
    if token ~= nil and manager ~= nil and manager.IsNamePlateUnitBehindCamera ~= nil then
        local okBehind, behind = pcall(manager.IsNamePlateUnitBehindCamera, token)
        if okBehind and not secrets.isSecret(behind) and behind == true then
            return "behind"
        end
    end
    local width = WorldFrame:GetWidth() * WorldFrame:GetEffectiveScale()
    local offset = unitAim.offset(x * plate:GetEffectiveScale(), width)
    if offset == nil then
        return "hidden", "no screen width"
    end
    return "seen", offset
end

local function shown(value)
    if secrets.isSecret(value) then
        return "secret"
    end
    return tostring(value)
end

-- For the log when no plate is found: the nameplate settings, the unit, and
-- every plate there is.
local function describe(unit)
    local parts = {}
    for _, name in ipairs({
        "nameplateShowAll",
        "nameplateShowFriendlyNpcs",
        "nameplateShowFriendlyPlayers",
        "nameplateShowEnemies",
        "nameplateShowOffscreen",
        "nameplateMaxDistance",
    }) do
        local ok, value = pcall(GetCVar, name)
        tinsert(parts, name .. " " .. (ok and shown(value) or "error"))
    end
    local okReaction, reaction = pcall(UnitReaction, "player", unit)
    tinsert(parts, "reaction " .. (okReaction and shown(reaction) or "error"))
    local okVisible, visible = pcall(UnitIsVisible, unit)
    tinsert(parts, "visible " .. (okVisible and shown(visible) or "error"))
    if C_NamePlate == nil then
        tinsert(parts, "no C_NamePlate")
        return table.concat(parts, "; ")
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    tinsert(parts, "by token " .. (ok and (plate == nil and "nil" or "plate") or ("error " .. tostring(plate))))
    local okForbidden, forbidden = pcall(C_NamePlate.GetNamePlateForUnit, unit, true)
    tinsert(
        parts,
        "with forbidden " .. (okForbidden and (forbidden == nil and "nil" or "plate") or ("error " .. tostring(forbidden)))
    )
    local okList, plates = pcall(C_NamePlate.GetNamePlates)
    if not okList or type(plates) ~= "table" then
        tinsert(parts, "plate list error")
        return table.concat(parts, "; ")
    end
    tinsert(parts, #plates .. " plates")
    for _, candidate in ipairs(plates) do
        local token = candidate.unitToken or (candidate.UnitFrame and candidate.UnitFrame.unit)
        local okSame, same = pcall(UnitIsUnit, tostring(token), unit)
        tinsert(parts, tostring(token) .. " same " .. (okSame and shown(same) or "error"))
    end
    return table.concat(parts, "; ")
end

local function facingDegrees()
    local ok, facing = pcall(GetPlayerFacing)
    if ok and type(facing) == "number" and not secrets.isSecret(facing) then
        return math.deg(facing)
    end
    return nil
end

local function note(run, line)
    tinsert(run.lines, line)
end

local function cameraZoom()
    local ok, zoom = pcall(GetCameraZoom)
    if ok and type(zoom) == "number" and not secrets.isSecret(zoom) then
        return zoom
    end
    return nil
end

-- Move the camera to distance yards (in or out).
local function zoomTo(distance)
    local zoom = cameraZoom()
    if zoom == nil then
        return
    end
    if distance > zoom then
        CameraZoomOut(distance - zoom)
    elseif distance < zoom then
        CameraZoomIn(zoom - distance)
    end
end

-- The press's line for /wv unitturnlog, with how far the character turned.
local function record(run, message)
    local facing = facingDegrees()
    if run.facing ~= nil and facing ~= nil then
        -- positive = turned right, as the bearing
        local turned = (run.facing - facing + 180) % 360 - 180
        note(run, string.format("turned %.1f to facing %.1f", turned, facing))
    end
    note(run, message or "facing")
    addReading(run.unit .. ": " .. table.concat(run.lines, ", "))
end

-- The pulse lands a frame later; the log and the zoom wait this long.
local LAND_DELAY = 0.1

-- message nil: facing the unit; the character turns to the camera if a
-- sweep moved it. "" ends quietly. Otherwise the message is said. Either
-- way without a find, the camera goes back behind the character, which
-- has not moved.
local function finish(run, message)
    if running ~= run then
        return
    end
    running = nil
    waitFrame:SetScript("OnUpdate", nil)
    if run.zoomSpeed ~= nil then
        pcall(SetCVar, "cameraZoomSpeed", run.zoomSpeed)
        run.zoomSpeed = nil
    end
    if message == nil then
        if run.swept then
            module:faceCamera()
            C_Timer.After(LAND_DELAY, function()
                record(run)
                -- The player's own camera distance back, after the sweep's.
                if run.zoomFrom ~= nil then
                    zoomTo(run.zoomFrom)
                end
            end)
        else
            record(run)
        end
        module:fireAlert("turnToUnit", { action = "facing" })
        return
    end
    record(run, message)
    if run.swept then
        camera.align()
    end
    if message ~= "" then
        WowVision:notify(message)
    end
end

local step, turnThen, edgeSweep

-- Run fn once frames real frames have passed.
local function afterFrames(run, frames, fn)
    local last = GetTime()
    local seen = 0
    waitFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now <= last then
            return
        end
        last = now
        seen = seen + 1
        if seen >= frames then
            waitFrame:SetScript("OnUpdate", nil)
            if running == run then
                fn()
            end
        end
    end)
end

step = function(run)
    local kind, offset = readPlate(run.unit)
    if kind == "none" then
        note(run, "no plate")
        if run.aim.turns > 0 then
            return finish(run, L["Lost the nameplate"])
        end
        if run.searches == 0 then
            note(run, describe(run.unit))
        end
        if run.searches >= SEARCH_TURNS then
            return finish(run, L["No nameplate"])
        end
        run.searches = run.searches + 1
        return turnThen(run, SEARCH_TURN)
    elseif kind == "hidden" then
        note(run, offset)
        return edgeSweep(run)
    end
    local angle = nil
    if kind == "seen" then
        angle = unitAim.cameraAngle(offset, run.fov)
        note(run, string.format("offset %.3f angle %.1f gain %.2f", offset, angle, run.aim.gain))
        if math.abs(angle) <= unitAim.AIMED and math.abs(offset) < unitAim.EDGE then
            return finish(run)
        end
    else
        note(run, "behind")
    end
    if run.aim.turns >= MAX_TURNS then
        if angle ~= nil and math.abs(angle) <= MISSED then
            return finish(run)
        end
        return finish(run, L["Could not turn to it"])
    end
    return turnThen(run, unitAim.nextTurn(run.aim, kind, angle, offset))
end

-- Sweep the camera by degrees (the character stays), then read the plate
-- again. Only a found unit turns the character (finish).
turnThen = function(run, turn)
    note(run, string.format("turn %.1f", turn))
    local started = module:turnByAngle(turn, {
        label = "unit ",
        cameraOnly = true,
        onDone = function(how)
            if running ~= run then
                return
            end
            if how ~= "landed" then
                -- The player turned, or the watchdog stopped it: end quietly.
                return finish(run, "")
            end
            afterFrames(run, READ_FRAMES, function()
                step(run)
            end)
        end,
    })
    if started == "facing" then
        return finish(run)
    elseif not started then
        return finish(run, "")
    end
    run.swept = true
end

-- The edge sweep (unitAim.edgeBearing has the rule), for where the plate
-- cannot be measured: true when the unit is in front of the camera with a
-- plate, false when not, nil when the game will not say.
local function inFront(unit)
    local plate = findPlate(unit)
    if plate == nil then
        return false
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

-- One motion, as a turn to waypoint turn ends: the camera sweeps right
-- from straight behind the character, finds the two changes, sweeps on to
-- the bearing and stops there, and the stop hands the camera to the
-- character in the same frame. Snapping the camera back after the
-- measuring and turning from there went wrong in game (asked 87, turned
-- -33; the camera follow style swings the camera back in any pause).
-- The sweep goes once round to find the changes, and at most once more to
-- reach the bearing.
local EDGE_FIND = 400
local EDGE_TOTAL = 800
-- Faster: stop as soon as the bearing is known and turn the short way at
-- full speed from there, one frame later. Off: in game it landed at random
-- (2026-11-12). A camera sweep started later than its key press first
-- jumps by the distance it would have covered meanwhile (warcraft.wiki.gg,
-- API_MoveViewLeftStart), and turnTo.lua's own measurements rule out a
-- sweep right after a stop. The one motion above works.
local FAST_APPROACH = false

edgeSweep = function(run)
    note(run, "edge sweep")
    camera.align()
    local okSpeed, speed = pcall(GetCVar, "cameraZoomSpeed")
    run.zoomSpeed = okSpeed and speed or nil
    pcall(SetCVar, "cameraZoomSpeed", ZOOM_SPEED)
    local zoomFrom = cameraZoom()
    run.zoomFrom = zoomFrom
    if zoomFrom ~= nil and zoomFrom > ZOOM_TO then
        CameraZoomIn(zoomFrom - ZOOM_TO)
    elseif zoomFrom ~= nil then
        CameraZoomOut(ZOOM_TO - zoomFrom)
    end
    run.swept = true
    local frames, lastZoom, stillFrames = 0, zoomFrom, 0

    local function sweep()
        note(run, string.format("zoom %.1f to %s in %d frames", zoomFrom or -1, tostring(lastZoom), frames))
        local last = inFront(run.unit)
        if last == nil then
            return finish(run, L["Nameplate position is hidden here"])
        end
        local changes = {}
        local previous = 0
        local frame = 0
        local target = nil
        local failure = nil
        local started = module:turnByAngle(EDGE_TOTAL, {
            label = "unit ",
            keepCamera = true,
            fixedSpeed = EDGE_SPEED,
            onFrame = function(moved)
                frame = frame + 1
                local step = moved - previous
                if target ~= nil then
                    previous = moved
                    -- Stop on the frame nearest the bearing.
                    if target - moved <= step / 2 then
                        run.stoppedAt = moved
                        return true
                    end
                    return false
                end
                local now = inFront(run.unit)
                if now ~= nil and now ~= last then
                    -- A change while the camera has not moved yet is the
                    -- game catching up, not an edge.
                    if moved > previous then
                        changes[#changes + 1] = { at = (previous + moved) / 2, front = now, frame = frame }
                    end
                    last = now
                end
                previous = moved
                if #changes >= 2 then
                    local bearing, width = unitAim.edgeBearing(changes[1], changes[2], nil)
                    run.bearing, run.width = bearing, width
                    if width < WIDTH_MIN or width > WIDTH_MAX then
                        failure = "width"
                        return "quiet"
                    end
                    target = bearing % 360
                    while target < moved do
                        target = target + 360
                    end
                    run.target = target
                    if FAST_APPROACH then
                        -- Stop here; the approach turns the short way.
                        run.stoppedAt = moved
                        run.approach = (bearing - moved + 180) % 360 - 180
                        return "quiet"
                    end
                    if target - moved <= step / 2 then
                        run.stoppedAt = moved
                        return true
                    end
                elseif moved >= EDGE_FIND then
                    failure = "changes"
                    return "quiet"
                end
                return false
            end,
            onDone = function(how)
                if running ~= run then
                    return
                end
                if how ~= "landed" then
                    return finish(run, "")
                end
                if #changes >= 1 then
                    note(run, string.format("change %.1f %s frame %d", changes[1].at, changes[1].front and "in" or "out", changes[1].frame))
                end
                if #changes >= 2 then
                    note(run, string.format("change %.1f %s frame %d", changes[2].at, changes[2].front and "in" or "out", changes[2].frame))
                end
                if run.bearing ~= nil then
                    note(run, string.format("width %.1f, bearing %.1f", run.width, run.bearing))
                    if run.facing ~= nil then
                        note(run, string.format("facing %.1f, unit in the world %.1f", run.facing, (run.facing - run.bearing) % 360))
                    end
                end
                if failure ~= nil then
                    note(run, failure == "width" and "width off" or (#changes .. " changes in " .. frame .. " frames"))
                    return finish(run, L["Could not turn to it"])
                end
                local function done()
                    -- The character has turned; the camera's distance comes back.
                    run.swept = false
                    if run.zoomFrom ~= nil then
                        zoomTo(run.zoomFrom)
                    end
                    finish(run)
                end
                if run.approach == nil then
                    note(run, string.format("stopped at %.1f for %.1f", run.stoppedAt or -1, run.target or -1))
                    return done()
                end
                -- The approach: at once, from where the camera stands, the
                -- short way at full speed; its stop hands the camera over.
                note(run, string.format("stopped at %.1f, approach %.1f", run.stoppedAt, run.approach))
                local approached = module:turnByAngle(run.approach, {
                    label = "unit ",
                    keepCamera = true,
                    onDone = function(approachHow)
                        if running ~= run then
                            return
                        end
                        if approachHow ~= "landed" then
                            return finish(run, "")
                        end
                        done()
                    end,
                })
                if approached == "facing" then
                    -- Already pointing at it: only the hand-over.
                    module:faceCamera()
                    return C_Timer.After(LAND_DELAY, function()
                        if running == run then
                            done()
                        end
                    end)
                elseif not approached then
                    return finish(run, "")
                end
            end,
        })
        if not started then
            return finish(run, "")
        end
    end

    -- Wait for the zoom to land: near its distance and holding still.
    local function wait()
        afterFrames(run, 1, function()
            frames = frames + 1
            local zoom = cameraZoom()
            if zoom ~= nil and lastZoom ~= nil and math.abs(zoom - lastZoom) < 0.01 then
                stillFrames = stillFrames + 1
            else
                stillFrames = 0
            end
            lastZoom = zoom
            local near = zoom ~= nil and math.abs(zoom - ZOOM_TO) <= 0.3
            if (near and stillFrames >= ZOOM_STILL) or frames >= ZOOM_FRAMES then
                return sweep()
            end
            wait()
        end)
    end
    wait()
end

-- Turn to face unit ("target" or "focus").
function module:turnToUnit(unit)
    if running ~= nil then
        if GetTime() - running.started < STUCK then
            return false
        end
        finish(running, "")
    end
    if not UnitExists(unit) then
        WowVision:notify(unit == "focus" and L["No focus"] or L["No target"])
        return false
    end
    -- Coordinates where the game gives them: a group member outdoors.
    local px, py, _, playerInstance = UnitPosition("player")
    local x, y, _, instance = UnitPosition(unit)
    if
        px ~= nil
        and x ~= nil
        and not secrets.isSecret(x)
        and not secrets.isSecret(y)
        and instance == playerInstance
        and (x ~= px or y ~= py)
    then
        return self:turnToPoint(x, y)
    end
    local run = {
        unit = unit,
        aim = unitAim.newAim(),
        fov = fieldOfView(),
        lines = {},
        searches = 0,
        started = GetTime(),
        -- For the log: the facing at the press (degrees, as GetPlayerFacing;
        -- nil where the game hides it).
        facing = facingDegrees(),
    }
    running = run
    -- Read the plate with the camera straight behind the character.
    camera.align()
    afterFrames(run, READ_FRAMES, function()
        step(run)
    end)
    return true
end

-- Trial (/wv sweeptest, outdoors): does a camera sweep started late (from a
-- timer, not a key press) land wrong, and does the workaround on
-- warcraft.wiki.gg (API_MoveViewLeftStart: speed 0 first, the real start a
-- frame later) help? It only calls the turn engine (turnTo.lua stays as
-- it is), from a timer, the way turn to unit does: a normal turn of 90, and
-- a camera-only sweep of 90 followed at once by a turn of 45 back (the
-- short-way approach), each without and with the workaround, twice.
-- Each line: asked against turned (positive = right). Results go to
-- WowVisionDump.turnToUnit. (An own copy of the sweep turned 0 every time;
-- FlipCameraYaw from an addon does not move the camera.)
local function prime(fn)
    MoveViewLeftStart(0)
    MoveViewRightStart(0)
    C_Timer.After(0, fn)
end

local function trialRun(kind, primed, after)
    local before = facingDegrees()
    if before == nil then
        addReading("sweep test: no facing here (instance?)")
        return
    end
    local asked = kind == "single" and 90 or 45
    local function landed(how)
        C_Timer.After(0.3, function()
            local now = facingDegrees()
            local turned = now and ((before - now + 180) % 360 - 180) or nil
            local line = string.format(
                "sweep test %s %s: asked %d, turned %s (%s)",
                kind,
                primed and "with workaround" or "without",
                asked,
                turned and string.format("%.1f", turned) or "unknown",
                tostring(how)
            )
            print("WowVision " .. line)
            addReading(line)
            after()
        end)
    end
    local function go(fn)
        if primed then
            prime(fn)
        else
            fn()
        end
    end
    C_Timer.After(0.5, function()
        if kind == "single" then
            go(function()
                if not module:turnByAngle(90, { label = "trial ", onDone = landed }) then
                    landed("not started")
                end
            end)
            return
        end
        camera.align()
        go(function()
            local started = module:turnByAngle(90, {
                label = "trial ",
                cameraOnly = true,
                onDone = function()
                    -- at once, from where the camera stands: back 45
                    go(function()
                        if not module:turnByAngle(-45, { label = "trial ", keepCamera = true, onDone = landed }) then
                            landed("second not started")
                        end
                    end)
                end,
            })
            if not started then
                landed("not started")
            end
        end)
    end)
end

module:registerCommand({
    name = "sweeptest",
    description = "Trial: late turns through the turn engine, with and without the speed 0 workaround, logged",
    func = function()
        local plan = {
            { "single", false },
            { "single", true },
            { "back", false },
            { "back", true },
            { "single", false },
            { "single", true },
            { "back", false },
            { "back", true },
        }
        local index = 0
        local function nextTrial()
            index = index + 1
            local trial = plan[index]
            if trial == nil then
                WowVision:speak("sweep test done")
                return
            end
            trialRun(trial[1], trial[2], function()
                C_Timer.After(0.3, nextTrial)
            end)
        end
        nextTrial()
    end,
})

-- Copyable diagnostics: one line per press, also printed to chat.
module:registerCommand({
    name = "unitturnlog",
    description = "Show the last turns to a unit",
    func = function()
        local lines = { string.format("%d presses, field of view %d", #readings(), fieldOfView()) }
        for _, line in ipairs(readings()) do
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
