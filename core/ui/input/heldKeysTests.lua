local testRunner = WowVision.testing.testRunner
local heldKeys = WowVision.heldKeys

local function modernEnv(downKeys)
    return {
        isKeyDown = function(key)
            return downKeys[key] == true
        end,
        bindingAction = function()
            return nil
        end,
        flags = {},
    }
end

local function classicEnv(actions, flags)
    return {
        isKeyDown = nil,
        bindingAction = function(key)
            return actions[key]
        end,
        flags = flags,
    }
end

testRunner:addSuite("HeldKeys", {
    ["baseKey strips modifiers and keeps the minus key"] = function(t)
        t:assertEqual(heldKeys.baseKey("LEFT"), "LEFT")
        t:assertEqual(heldKeys.baseKey("CTRL-SHIFT-TAB"), "TAB")
        t:assertEqual(heldKeys.baseKey("SHIFT-F10"), "F10")
        t:assertEqual(heldKeys.baseKey("-"), "-")
        t:assertEqual(heldKeys.baseKey("CTRL--"), "-")
        t:assertEqual(heldKeys.baseKey("\\"), "\\")
    end,

    ["modern client: the key state decides, modifiers ignored"] = function(t)
        local env = modernEnv({ LEFT = true, TAB = true })
        t:assertTrue(heldKeys.isHeld("LEFT", env))
        t:assertTrue(heldKeys.isHeld("CTRL-TAB", env))
        t:assertFalse(heldKeys.isHeld("RIGHT", env))
        t:assertFalse(heldKeys.isHeld("ENTER", env))
    end,

    ["modern client: a refused query falls back to the movement flags"] = function(t)
        local env = {
            isKeyDown = function()
                error("secret")
            end,
            bindingAction = function(key)
                return key == "LEFT" and "TURNLEFT" or nil
            end,
            flags = { turnLeft = true },
        }
        t:assertTrue(heldKeys.isHeld("LEFT", env))
        t:assertFalse(heldKeys.isHeld("UP", env))
    end,

    ["classic client: a key bound to a held command reads from its flag"] = function(t)
        local actions = { LEFT = "TURNLEFT", UP = "MOVEFORWARD", TAB = "TARGETNEARESTENEMY", SPACE = "JUMP" }
        local env = classicEnv(actions, { turnLeft = true, moveForward = false, ascend = true })
        t:assertTrue(heldKeys.isHeld("LEFT", env))
        t:assertFalse(heldKeys.isHeld("UP", env))
        t:assertTrue(heldKeys.isHeld("SPACE", env))
        -- Not a held command: never counts as held.
        t:assertFalse(heldKeys.isHeld("TAB", env))
        t:assertFalse(heldKeys.isHeld("CTRL-TAB", env))
        -- Unbound key.
        t:assertFalse(heldKeys.isHeld("ENTER", env))
    end,

    ["both signals count: a movement flag reads held even when the key state says up"] = function(t)
        local env = {
            isKeyDown = function()
                return false
            end,
            bindingAction = function(key)
                return key == "DOWN" and "MOVEBACKWARD" or nil
            end,
            flags = { moveBackward = true },
        }
        t:assertTrue(heldKeys.isHeld("DOWN", env))
        t:assertFalse(heldKeys.isHeld("UP", env))
    end,

    ["pitch and steer commands are held commands"] = function(t)
        local actions = { INSERT = "PITCHUP", DELETE = "PITCHDOWN", NUMPAD0 = "MOVEANDSTEER" }
        local env = classicEnv(actions, { pitchUp = true, pitchDown = false, moveAndSteer = true })
        t:assertTrue(heldKeys.isHeld("INSERT", env))
        t:assertFalse(heldKeys.isHeld("DELETE", env))
        t:assertTrue(heldKeys.isHeld("NUMPAD0", env))
    end,

    ["describe names the keys down and the commands they hold"] = function(t)
        local env = {
            isKeyDown = function(key)
                return key == "DOWN"
            end,
            bindingAction = function(key)
                return ({ DOWN = "MOVEBACKWARD", UP = "MOVEFORWARD", TAB = "TARGETNEARESTENEMY" })[key]
            end,
            flags = { moveBackward = true, moveForward = false },
        }
        t:assertEqual(
            heldKeys.describe({ "UP", "DOWN", "TAB", "CTRL-TAB" }, env),
            "key state available. UP MOVEFORWARD off. DOWN down, MOVEBACKWARD on"
        )
        t:assertEqual(heldKeys.describe({ "ENTER" }, env), "key state available")
        t:assertEqual(heldKeys.describe({ "UP" }, classicEnv({ UP = "MOVEFORWARD" }, { moveForward = true })),
            "key state unavailable. UP MOVEFORWARD on")
    end,

    ["a stale movement flag is not held once the game says the player is not moving"] = function(t)
        local env = classicEnv({ DOWN = "MOVEBACKWARD", LEFT = "TURNLEFT" }, { moveBackward = true, turnLeft = true })
        env.isMoving = function()
            return false
        end
        env.isTurning = function()
            return false
        end
        t:assertFalse(heldKeys.isHeld("DOWN", env))
        t:assertFalse(heldKeys.isHeld("LEFT", env))
        env.isMoving = function()
            return true
        end
        env.isTurning = function()
            return true
        end
        t:assertTrue(heldKeys.isHeld("DOWN", env))
        t:assertTrue(heldKeys.isHeld("LEFT", env))
        t:assertEqual(
            heldKeys.describe({ "DOWN" }, classicEnv({ DOWN = "MOVEBACKWARD" }, { moveBackward = true })),
            "key state unavailable. DOWN MOVEBACKWARD on"
        )
        env.isMoving = function()
            return false
        end
        t:assertEqual(
            heldKeys.describe({ "DOWN" }, env),
            "key state unavailable. DOWN MOVEBACKWARD on but stale, the game says not moving"
        )
    end,

    ["flags without a game state behind them stand alone"] = function(t)
        local env = classicEnv({ SPACE = "JUMP" }, { ascend = true })
        env.isMoving = function()
            return false
        end
        t:assertTrue(heldKeys.isHeld("SPACE", env))
    end,

    ["classic client: autorun and follow are not held keys"] = function(t)
        local env = classicEnv({ UP = "MOVEFORWARD" }, { autorun = true, following = true })
        t:assertFalse(heldKeys.isHeld("UP", env))
    end,

    ["nothing to ask: nothing is held"] = function(t)
        t:assertFalse(heldKeys.isHeld("LEFT", {}))
        t:assertFalse(heldKeys.isHeld(nil, modernEnv({})))
    end,

    ["anyHeld over a list"] = function(t)
        local env = modernEnv({ DOWN = true })
        t:assertTrue(heldKeys.anyHeld({ "UP", "DOWN", "LEFT" }, env))
        t:assertFalse(heldKeys.anyHeld({ "UP", "LEFT" }, env))
        t:assertFalse(heldKeys.anyHeld({}, env))
    end,

    ["runsCommand: the key is down and its game command runs"] = function(t)
        local env = {
            isKeyDown = function(key)
                return key == "UP" or key == "DOWN"
            end,
            bindingAction = function(key)
                return ({ UP = "MOVEFORWARD", DOWN = "MOVEBACKWARD", LEFT = "TURNLEFT" })[key]
            end,
            flags = { moveForward = true, turnLeft = true },
            isMoving = function()
                return true
            end,
        }
        t:assertTrue(heldKeys.runsCommand("UP", env))
        -- down, but pressed on a binding of WowVision's own: its game command does not run
        t:assertFalse(heldKeys.runsCommand("DOWN", env))
        -- the command runs from another key (A): this key is up
        t:assertFalse(heldKeys.runsCommand("LEFT", env))
        t:assertFalse(heldKeys.runsCommand("ENTER", env))
        t:assertEqual(heldKeys.commandKey({ "DOWN", "LEFT", "UP" }, env), "UP")
        t:assertNil(heldKeys.commandKey({ "DOWN", "LEFT" }, env))
    end,

    ["runsCommand: a stale flag does not count"] = function(t)
        local env = {
            isKeyDown = function()
                return true
            end,
            bindingAction = function()
                return "MOVEFORWARD"
            end,
            flags = { moveForward = true },
            isMoving = function()
                return false
            end,
        }
        t:assertFalse(heldKeys.runsCommand("UP", env))
    end,

    ["runsCommand: no answer without the key state"] = function(t)
        local env = classicEnv({ UP = "MOVEFORWARD" }, { moveForward = true })
        t:assertFalse(heldKeys.runsCommand("UP", env))
        local refused = classicEnv({ UP = "MOVEFORWARD" }, { moveForward = true })
        refused.isKeyDown = function()
            error("secret")
        end
        t:assertFalse(heldKeys.runsCommand("UP", refused))
        t:assertFalse(heldKeys.runsCommand(nil, modernEnv({})))
    end,
})
