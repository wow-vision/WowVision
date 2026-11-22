local testRunner = WowVision.testing.testRunner
local crowdControl = WowVision.crowdControl

-- A watch over a state the test sets, recording what it announces.
local function newWatch(interval)
    local world = { controlled = false, reads = 0, said = {} }
    world.watch = crowdControl.newWatch(function()
        world.reads = world.reads + 1
        return world.controlled
    end, function(now)
        tinsert(world.said, now and "on" or "off")
    end, interval)
    return world
end

local function said(world)
    return table.concat(world.said, " ")
end

testRunner:addSuite("CrowdControlWatch", {
    ["a change is found by the timer alone, without any aura event"] = function(t)
        local world = newWatch(0.2)
        world.watch.update(0.25)
        t:assertEqual(said(world), "", "free and unchanged: nothing to say")
        world.controlled = true
        world.watch.update(0.1)
        t:assertEqual(said(world), "", "not due yet")
        world.watch.update(0.1)
        t:assertEqual(said(world), "on")
        world.watch.update(0.2)
        t:assertEqual(said(world), "on", "still controlled: said once")
        world.controlled = false
        world.watch.update(0.2)
        t:assertEqual(said(world), "on off")
    end,

    ["between two reads nothing is read"] = function(t)
        local world = newWatch(0.2)
        for _ = 1, 10 do
            world.watch.update(0.016)
        end
        t:assertEqual(world.reads, 0, "0.16 s: before the first read")
        for _ = 1, 10 do
            world.watch.update(0.016)
        end
        t:assertEqual(world.reads, 1)
    end,

    ["the aura event brings the read forward to the next update"] = function(t)
        local world = newWatch(0.2)
        world.controlled = true
        world.watch.auraChanged()
        t:assertEqual(said(world), "", "not inside the event")
        world.watch.update(0.01)
        t:assertEqual(said(world), "on")
        world.watch.update(0.01)
        t:assertEqual(world.reads, 1, "the hint is used up")
    end,

    ["a new unit is read at once: controlled is said, free only after a controlled one"] = function(t)
        local world = newWatch(0.2)
        world.watch.unitChanged()
        t:assertEqual(said(world), "", "a free target after none")
        world.controlled = true
        world.watch.unitChanged()
        t:assertEqual(said(world), "on")
        world.watch.unitChanged()
        t:assertEqual(said(world), "on on", "another controlled target is said again")
        world.controlled = false
        world.watch.unitChanged()
        t:assertEqual(said(world), "on on off")
    end,

    ["a read that cannot tell counts as free"] = function(t)
        local world = newWatch(0.2)
        world.controlled = nil
        world.watch.update(0.2)
        world.watch.unitChanged()
        t:assertEqual(said(world), "")
    end,
})
