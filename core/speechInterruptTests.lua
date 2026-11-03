local testRunner = WowVision.testing.testRunner
local interrupt = WowVision.speechInterrupt

local function isolated(body)
    return function(t)
        interrupt._reset()
        local ok, err = pcall(body, t)
        interrupt._reset()
        if not ok then
            error(err, 0)
        end
    end
end

testRunner:addSuite("Speech interrupt", {
    ["a line without a stop in front is handed over unchanged"] = isolated(function(t)
        t:assertEqual(interrupt.handOver("Quest log"), "Quest log")
    end),

    ["the first line after a stop carries the mark"] = isolated(function(t)
        interrupt.noteStop()
        t:assertEqual(interrupt.handOver("Quest log"), "Quest log" .. interrupt.MARK)
    end),

    ["only the first line after a stop carries it, the next ones queue"] = isolated(function(t)
        interrupt.noteStop()
        interrupt.handOver("Navigation")
        t:assertEqual(interrupt.handOver("Search"), "Search")
    end),

    ["on the Mac client no line carries the mark"] = isolated(function(t)
        interrupt.enabled = false
        interrupt.noteStop()
        t:assertEqual(interrupt.handOver("Quest log"), "Quest log")
    end),

    ["several stops before a line still mark it once"] = isolated(function(t)
        interrupt.noteStop()
        interrupt.noteStop()
        t:assertEqual(interrupt.handOver("Bags"), "Bags" .. interrupt.MARK)
        t:assertEqual(interrupt.handOver("Bags"), "Bags")
    end),
})
