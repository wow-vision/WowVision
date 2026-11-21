-- The repeat delay of the environmental state alerts (indoors/outdoors, flying,
-- swimming, diving), pure and headless-tested. At a border (a shore, a doorway,
-- a ledge) the game flips these states many times a second, and each flip used
-- to queue a line: half a minute of "swimming" after a few seconds at a shore.
--
-- One tracker per state. A change is spoken at once when the tracker said
-- nothing within the delay. A change inside the delay waits; once the delay is
-- over, the state as it is THEN counts, and only if it differs from what was
-- said last. So a flickering border says at most one line per delay, and the
-- last line heard always matches the state now. A state without a line of its
-- own (out of the water) is taken over silently, also only after the delay,
-- and does not start a new delay: walking back into the water later is spoken
-- at once.

local stateRepeat = {}
WowVision.stateRepeat = stateRepeat

-- value: the state at the start, taken as already known (nothing is said for it).
function stateRepeat.new(value)
    return { said = value, saidAt = nil }
end

-- value: the state now. speaks: whether that state has a line. delay: seconds,
-- 0 or nil for none. Returns true when the line for value is due now.
function stateRepeat.update(tracker, value, now, delay, speaks)
    if value == tracker.said then
        return false
    end
    if tracker.saidAt ~= nil and delay ~= nil and delay > 0 and now - tracker.saidAt < delay then
        return false
    end
    tracker.said = value
    if not speaks then
        return false
    end
    tracker.saidAt = now
    return true
end
