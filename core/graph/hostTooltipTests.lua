local testRunner = WowVision.testing.testRunner
local GraphHost = WowVision.graph.GraphHost

-- GraphHost:_setTooltipFor with a recording tooltip reader: what the focused
-- node's tooltip is set to.
local function setFor(vtable)
    local savedUIHost = WowVision.UIHost
    local sets = {}
    WowVision.UIHost = {
        tooltip = {
            set = function(_, widget, data)
                tinsert(sets, { widget = widget, data = data })
            end,
            onFocus = function() end,
        },
    }
    local host = { _tooltipActive = false }
    local ok, err = pcall(GraphHost._setTooltipFor, host, { vtable = vtable })
    WowVision.UIHost = savedUIHost
    if not ok then
        error(err, 0)
    end
    return sets, host
end

testRunner:addSuite("HostTooltip", {
    ["a found frame gets the game tooltip"] = function(t)
        local frame = {}
        local sets, host = setFor({ tooltipFrame = function()
            return frame
        end })
        t:assertEqual(#sets, 1)
        t:assertEqual(sets[1].widget.frame, frame)
        t:assertEqual(sets[1].data.type, "Game")
        t:assertEqual(host._tooltipActive, true)
    end,

    ["a frame not found now gives no game tooltip, also with a Game config"] = function(t)
        local missing = function()
            return nil
        end
        local sets = setFor({ tooltipFrame = missing })
        t:assertEqual(#sets, 0)
        sets = setFor({ tooltipFrame = missing, tooltip = { type = "Game", mode = "immediate" } })
        t:assertEqual(#sets, 0, "the reader would speak the game tooltip's old lines")
    end,

    ["a tooltip of its own still works without the frame"] = function(t)
        local sets = setFor({
            tooltipFrame = function()
                return nil
            end,
            tooltip = { type = "Text", text = "Hello" },
        })
        t:assertEqual(#sets, 1)
        t:assertEqual(sets[1].data.type, "Text")
    end,
})
