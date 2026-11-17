local testRunner = WowVision.testing.testRunner

-- The Game tooltip type runs the frame's OnEnter, then the node's afterEnter
-- step on the tooltip frame (the quest log's party progress call).
local function newType(data)
    local tooltip = { activeFrame = nil }
    local gameType = WowVision.GameTooltipType:new(tooltip)
    local frame = {
        _scripts = {},
        HasScript = function()
            return true
        end,
    }
    gameType:activate({ frame = frame }, data)
    return gameType, frame, tooltip
end

testRunner:addSuite("GameTooltipType", {
    ["afterEnter runs after the frame's OnEnter, on the tooltip frame"] = function(t)
        local seen = {}
        local tooltipFrame = { name = "fake tooltip" }
        local gameType, frame, tooltip = nil, nil, nil
        gameType, frame, tooltip = newType({
            mode = "immediate",
            frame = tooltipFrame,
            afterEnter = function(tooltipFrame, owner)
                tinsert(seen, { tooltipFrame = tooltipFrame, owner = owner, scripts = #frame._scripts })
            end,
        })
        gameType:beforeRead()
        t:assertEqual(frame._scripts[1], "OnEnter")
        t:assertEqual(#seen, 1)
        t:assertEqual(seen[1].scripts, 1, "OnEnter ran first")
        t:assertEqual(seen[1].tooltipFrame, tooltipFrame)
        t:assertEqual(tooltip.activeFrame, tooltipFrame)
        t:assertEqual(seen[1].owner, frame)
    end,

    ["a failing afterEnter is reported and the read goes on"] = function(t)
        local savedHandler = geterrorhandler
        local reported = nil
        geterrorhandler = function()
            return function(err)
                reported = err
            end
        end
        local ok = pcall(function()
            local gameType = newType({
                mode = "immediate",
                afterEnter = function()
                    error("boom")
                end,
            })
            gameType:beforeRead()
        end)
        geterrorhandler = savedHandler
        t:assertTrue(ok, "the error does not escape")
        t:assertTrue(reported ~= nil and tostring(reported):find("boom", 1, true) ~= nil)
    end,

    ["afterEnter is skipped when nothing filled the tooltip"] = function(t)
        local ran = false
        local gameType, frame = newType({
            mode = "immediate",
            frame = {},
            afterEnter = function()
                ran = true
            end,
        })
        frame.HasScript = function()
            return false
        end
        gameType:beforeRead()
        t:assertEqual(ran, false)
    end,

    ["afterEnter also follows populate"] = function(t)
        local order = {}
        local tooltipFrame = {
            SetOwner = function() end,
        }
        local gameType, frame = newType({
            mode = "immediate",
            frame = tooltipFrame,
            populate = function()
                tinsert(order, "populate")
            end,
            afterEnter = function()
                tinsert(order, "afterEnter")
            end,
        })
        gameType:beforeRead()
        t:assertEqual(#frame._scripts, 0, "populate replaces OnEnter")
        t:assertEqual(order[1], "populate")
        t:assertEqual(order[2], "afterEnter")
    end,

    ["deactivate drops the afterEnter step"] = function(t)
        local gameType = newType({ mode = "immediate", afterEnter = function() end })
        gameType:deactivate()
        t:assertEqual(gameType.afterEnter, nil)
    end,
})
