-- When the count of the waypoints left is spoken after a waypoint is
-- reached ("3 remaining", maps/module.lua), pure and headless-tested. The
-- player picks a mode in Navigation's settings (Announce Remaining
-- Waypoints): every waypoint, only the last stretch of the route (once the
-- threshold is reached, every waypoint from there to the end), every round
-- ten counted from the end, or never.

local remainingAnnounce = {}
WowVision.remainingAnnounce = remainingAnnounce

-- The modes in dropdown order; navigation/module.lua gives them labels.
remainingAnnounce.modes = {
    "always",
    "last10",
    "last5",
    "last1",
    "lastTenPercent",
    "every10",
    "never",
}

remainingAnnounce.DEFAULT = "always"

-- The last stretch of a route of total waypoints in percent mode: a tenth,
-- rounded up, so even a short route says its last one (55 waypoints: from 6
-- on, 5 waypoints: the last one). Whole numbers only, 30 / 10 is exactly 3.
function remainingAnnounce.tenPercent(total)
    if total == nil or total < 1 then
        return 0
    end
    return math.floor((total + 9) / 10)
end

-- Whether "remaining" is spoken: remaining counts the waypoints still ahead,
-- the one the beacon now leads to included (1 at the waypoint before the
-- last), total the route's waypoints. An unknown mode speaks, like always.
function remainingAnnounce.shouldAnnounce(mode, remaining, total)
    if remaining == nil or remaining < 1 then
        return false
    end
    if mode == "never" then
        return false
    elseif mode == "last10" then
        return remaining <= 10
    elseif mode == "last5" then
        return remaining <= 5
    elseif mode == "last1" then
        return remaining <= 1
    elseif mode == "lastTenPercent" then
        return remaining <= remainingAnnounce.tenPercent(total)
    elseif mode == "every10" then
        -- counted from the end: 50, 40, ... 10, and the last one
        return remaining % 10 == 0 or remaining == 1
    end
    return true
end
