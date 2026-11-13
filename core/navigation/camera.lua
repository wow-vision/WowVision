-- Camera helpers shared by turn to waypoint and the pitch lock, and the
-- one-time camera settings both need.
--
-- Addons cannot turn the character (SetFacing and the turn functions are
-- protected), but the camera turns freely, and a MouselookStart/Stop pulse
-- copies the camera's yaw AND pitch onto the character. The pulse takes
-- effect one frame later.
local camera = {}

-- The saved view slot WowVision resets and snaps to: ResetView puts it at
-- the game's default, behind the character and nearly level. This
-- overwrites whatever a player saved in slot 5 (Save View 5 binding), the
-- slot least likely to be in use.
camera.VIEW_SLOT = 5

-- Set once per character on the first login with WowVision:
-- - "Always adjust camera": with the other following styles the camera
--   keeps an offset after a pulse, and turns went to random places
--   (measured on WoW Forever).
-- - Instant view switching: the snap to the view slot must be complete
--   in the same frame, or the sweep starts from a camera still blending.
camera.SETTINGS = {
    { name = "cameraSmoothStyle", value = "2" },
    { name = "cameraViewBlendStyle", value = "2" },
}

-- state.cameraStyleSet records that this character was handled, so a
-- player who changes the style back keeps it. Returns true when a setting
-- was changed.
function camera.applyOnce(state, getCVar, setCVar)
    if state.cameraStyleSet then
        return false
    end
    if getCVar == nil or setCVar == nil then
        return false
    end
    local changed = false
    for _, setting in ipairs(camera.SETTINGS) do
        local okRead, value = pcall(getCVar, setting.name)
        if not okRead then
            return false
        end
        if tostring(value) ~= setting.value then
            if not pcall(setCVar, setting.name, setting.value) then
                -- Refused: try again next login.
                return false
            end
            changed = true
        end
    end
    state.cameraStyleSet = true
    return changed
end

-- Put the camera straight behind the character, nearly level.
function camera.align()
    pcall(ResetView, camera.VIEW_SLOT)
    pcall(SetView, camera.VIEW_SLOT)
end

-- Switch to first person: view 1 is always first person and cannot be
-- saved over (warcraft.wiki.gg, API_SetView); with instant view switching
-- (SETTINGS above) it is there in the next frame. camera.align() goes back.
function camera.firstPerson()
    pcall(SetView, 1)
end

-- Turn the character to where the camera looks (the mouselook pulse).
function camera.transfer()
    MouselookStart()
    MouselookStop()
end

-- The gamepad (WoW: Forever's gamepad interface). Free look, the gamepad's
-- mouse look, is on all the time there, and the swept camera then reaches
-- the character only while the camera stick is pushed (pad logs
-- 2026-10-23). For the length of a turn free look is off; then the sweep
-- and the pulse work as without a gamepad.
local freeLookOff = false

local function gamepadOn()
    local gamePad = C_GamePad
    if gamePad == nil or type(gamePad.IsEnabled) ~= "function" then
        return false
    end
    local ok, enabled = pcall(gamePad.IsEnabled)
    return ok and enabled == true
end

-- True when free look went off for this turn.
function camera.beginGamepadTurn()
    if freeLookOff or not gamepadOn() or SetGamePadFreeLook == nil or IsGamePadFreelookEnabled == nil then
        return false
    end
    local ok, on = pcall(IsGamePadFreelookEnabled)
    if ok and on and pcall(SetGamePadFreeLook, false) then
        freeLookOff = true
    end
    return freeLookOff
end

function camera.endGamepadTurn()
    if freeLookOff then
        freeLookOff = false
        pcall(SetGamePadFreeLook, true)
    end
end

WowVision.navigationCamera = camera
