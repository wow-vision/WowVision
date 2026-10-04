local testRunner = WowVision.testing.testRunner
local camera = WowVision.navigationCamera

-- A console variable store standing in for the game's.
local function cvars(values, refuse)
    local store = { writes = 0 }
    for name, value in pairs(values) do
        store[name] = value
    end
    local function get(name)
        return store[name]
    end
    local function set(name, value)
        if refuse then
            error("refused")
        end
        store[name] = value
        store.writes = store.writes + 1
    end
    return store, get, set
end

testRunner:addSuite("CameraSetup", {
    ["the first login sets the following style and instant views"] = function(t)
        local state = { cameraStyleSet = false }
        local store, get, set = cvars({ cameraSmoothStyle = "4", cameraViewBlendStyle = "1" })
        t:assertTrue(camera.applyOnce(state, get, set))
        t:assertEqual(store.cameraSmoothStyle, "2")
        t:assertEqual(store.cameraViewBlendStyle, "2")
        t:assertTrue(state.cameraStyleSet)
    end,

    ["settings already right are left alone and marked done"] = function(t)
        local state = { cameraStyleSet = false }
        local store, get, set = cvars({ cameraSmoothStyle = "2", cameraViewBlendStyle = "2" })
        t:assertFalse(camera.applyOnce(state, get, set))
        t:assertEqual(store.writes, 0)
        t:assertTrue(state.cameraStyleSet)
    end,

    ["a style the player chose later is kept"] = function(t)
        local state = { cameraStyleSet = true }
        local store, get, set = cvars({ cameraSmoothStyle = "0", cameraViewBlendStyle = "1" })
        t:assertFalse(camera.applyOnce(state, get, set))
        t:assertEqual(store.cameraSmoothStyle, "0")
        t:assertEqual(store.writes, 0)
    end,

    ["a refused write is tried again next login"] = function(t)
        local state = { cameraStyleSet = false }
        local store, get, set = cvars({ cameraSmoothStyle = "1", cameraViewBlendStyle = "2" }, true)
        t:assertFalse(camera.applyOnce(state, get, set))
        t:assertEqual(store.cameraSmoothStyle, "1")
        t:assertFalse(state.cameraStyleSet)
    end,
})
