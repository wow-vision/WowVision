local graph = WowVision.graph

-- Double arrow presses (Host.lua): the same arrow twice within WINDOW skips the empty slots of a bag or action bar
-- and lands on the next filled one (KeyGraph:moveSkippingEmpty). A double press is the SAME key twice -- Up then
-- Down quickly are two steps -- and only while focus is still where the first press left it on the same screen, so
-- a list rebuilding between the presses (an item arriving, a bag closing) gives a plain step. Every press after the
-- first that keeps the rhythm counts again, so tapping quickly hops from item to item. Pure Lua: the headless suite
-- tests it.
local doublePress = {}
graph.doublePress = doublePress

doublePress.WINDOW = 0.25 -- seconds between the two presses (Sku's tested value)

-- The screen of the last press is held weakly: a closed screen is not kept alive until the next arrow press.
function doublePress.newState()
    return { key = nil, at = nil, screen = setmetatable({}, { __mode = "v" }), focus = nil }
end

-- A press of key at time now, on screen with focus (a ControlId key) before the move. True when it doubles the
-- previous press. A press older than the previous one (dispatched late, after a speech stop delay) never doubles.
function doublePress.press(state, key, now, screen, focus)
    local elapsed = state.at ~= nil and now - state.at or nil
    local double = state.key == key
        and elapsed ~= nil
        and elapsed >= 0
        and elapsed < doublePress.WINDOW
        and state.screen[1] == screen
        and state.focus == focus
    state.key = key
    state.at = now
    state.screen[1] = screen
    state.focus = nil
    return double
end

-- Where the press left focus; the next press doubles it only from there.
function doublePress.settle(state, focus)
    state.focus = focus
end

-- Any other input ends the rhythm.
function doublePress.reset(state)
    state.key = nil
    state.at = nil
end
