local testRunner = WowVision.testing.testRunner

-- Module.runAllUpdates over a small tree: the middle module throws.
local function run()
    local root = WowVision.Module:new("updateTestRoot")
    local ran = {}
    for _, key in ipairs({ "first", "broken", "last" }) do
        local module = root:createModule(key)
        module:hasUpdate(function(self)
            if self.key == "broken" then
                error("broken update")
            end
            tinsert(ran, self.key)
        end)
    end
    local reported = {}
    local savedBase, savedHandler = WowVision.base, geterrorhandler
    WowVision.base = root
    geterrorhandler = function()
        return function(message)
            tinsert(reported, tostring(message))
            return message
        end
    end
    local ok, err = pcall(function()
        WowVision.Module.rebuildAllUpdateHandlers()
        WowVision.Module.runAllUpdates()
    end)
    WowVision.base, geterrorhandler = savedBase, savedHandler
    WowVision.Module.rebuildAllUpdateHandlers()
    return ok, err, ran, reported
end

testRunner:addSuite("Module updates", {
    ["a module whose update throws does not stop the others"] = function(t)
        local ok, err, ran = run()
        t:assertTrue(ok, tostring(err))
        t:assertEqual(table.concat(ran, ","), "first,last")
    end,

    ["the error reaches the game's error handler"] = function(t)
        local _, _, _, reported = run()
        t:assertEqual(#reported, 1)
        t:assertTrue(reported[1]:find("broken update", 1, true) ~= nil, reported[1])
    end,
})
