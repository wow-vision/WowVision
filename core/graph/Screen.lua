local graph = WowVision.graph

-- A graph screen: a render function plus the persistent cursor state and the
-- KeyGraph engine over it. Screens declare fresh from live game state on every
-- rebuild; a render that adds no nodes closes the screen.
--
-- config:
--   key             debug name
--   render          function(builder, screen) -- add nodes; no return needed
--   wrap            tab wraps between stops (default true)
--   captureClose    hold the close key while this stack is focused (frameless
--                   windows the game cannot close for us)
--   onRequestClose  function(stack) -- close/escape pressed on the last screen;
--                   the owner (window bridge) closes the real UI. Absent = the
--                   host just closes the stack.
local Screen = WowVision.Class("GraphScreen")
graph.Screen = Screen

function Screen:initialize(config)
    self.config = config
    self.key = config.key
    self.wrap = config.wrap ~= false
    self.state = graph.newState()
    self.keyGraph = graph.KeyGraph:new(function()
        return self:buildRender()
    end, self.state)
    -- The announce-once differ's memory and the live watch caches.
    self._lastSpokenKey = nil
    self._lastSpokenNode = nil
    self._liveKey = nil
    self._liveValues = {}
    self._alwaysValues = nil
end

function Screen:buildRender()
    local builder = graph.Builder:new(self.state.expanded)
    local ok, err = pcall(self.config.render, builder, self)
    if not ok then
        -- Report once and close the screen; erroring every rebuild tick would
        -- flood the error list and TTS.
        if not self._renderErrorReported then
            self._renderErrorReported = true
            geterrorhandler()(err)
        end
        return nil
    end
    return builder:build()
end

-- Reset the differ so the next update announces the landing in full.
function Screen:resetAnnouncement()
    self._lastSpokenKey = nil
    self._lastSpokenNode = nil
    self._liveKey = nil
end
