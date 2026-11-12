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
local readings = {}

local function fieldOfView()
    local ok, value = pcall(GetCVar, "cameraFov")
    local fov = ok and tonumber(value) or nil
    if fov == nil or fov < 30 or fov > 150 then
        return FOV_DEFAULT
    end
    return fov
end

-- What the unit's plate says now: "none", "secret", "behind", or "seen"
-- plus its offset from the screen centre (-1 to 1).
local function readPlate(unit)
    if C_NamePlate == nil or C_NamePlate.GetNamePlateForUnit == nil then
        return "none"
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if not ok or plate == nil then
        return "none"
    end
    local token = plate.unitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    local manager = C_NamePlateManager
    if token ~= nil and manager ~= nil and manager.IsNamePlateUnitBehindCamera ~= nil then
        local okBehind, behind = pcall(manager.IsNamePlateUnitBehindCamera, token)
        if okBehind and not secrets.isSecret(behind) and behind == true then
            return "behind"
        end
    end
    local okCenter, x = pcall(plate.GetCenter, plate)
    if not okCenter or x == nil then
        return "none"
    end
    if secrets.isSecret(x) then
        return "secret"
    end
    local width = WorldFrame:GetWidth() * WorldFrame:GetEffectiveScale()
    local offset = unitAim.offset(x * plate:GetEffectiveScale(), width)
    if offset == nil then
        return "none"
    end
    return "seen", offset
end

local function note(run, line)
    tinsert(run.lines, line)
end

local function finish(run, message)
    if running ~= run then
        return
    end
    running = nil
    waitFrame:SetScript("OnUpdate", nil)
    note(run, message or "facing")
    tinsert(readings, run.unit .. ": " .. table.concat(run.lines, ", "))
    while #readings > 20 do
        tremove(readings, 1)
    end
    if message == nil then
        module:fireAlert("turnToUnit", { action = "facing" })
    elseif message ~= "" then
        WowVision:notify(message)
    end
end

local step, turnThen

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
        if run.searches >= SEARCH_TURNS then
            return finish(run, L["No nameplate"])
        end
        run.searches = run.searches + 1
        return turnThen(run, SEARCH_TURN)
    elseif kind == "secret" then
        return finish(run, L["Nameplate position is hidden here"])
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

-- Turn by degrees, then read the plate again.
turnThen = function(run, turn)
    note(run, string.format("turn %.1f", turn))
    local started = module:turnByAngle(turn, "unit ", function(how)
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
    end)
    if started == "facing" then
        return finish(run)
    elseif not started then
        return finish(run, "")
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
    }
    running = run
    -- Read the plate with the camera straight behind the character.
    camera.align()
    afterFrames(run, READ_FRAMES, function()
        step(run)
    end)
    return true
end

-- Copyable diagnostics: one line per press, also printed to chat.
module:registerCommand({
    name = "unitturnlog",
    description = "Show the last turns to a unit",
    func = function()
        local lines = { string.format("%d presses, field of view %d", #readings, fieldOfView()) }
        for _, line in ipairs(readings) do
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
