local TooltipType = WowVision.Class("TooltipType")

function TooltipType:initialize(tooltip)
    self.tooltip = tooltip
end

function TooltipType:activate(widget, data)
    -- Override in subclasses to set up the tooltip for this type
    -- Should set self.tooltip.activeFrame
end

function TooltipType:deactivate()
    -- Override in subclasses for cleanup
end

function TooltipType:onFocus()
    -- Override in subclasses for focus behavior (e.g., static mode OnEnter)
end

function TooltipType:onUnfocus()
    -- Override in subclasses for unfocus behavior (e.g., static mode OnLeave)
end

function TooltipType:beforeRead()
    -- Override in subclasses for pre-read behavior (e.g., immediate mode OnEnter)
end

function TooltipType:afterRead()
    -- Override in subclasses for post-read behavior (e.g., immediate mode OnLeave)
end

WowVision.TooltipType = TooltipType
WowVision.tooltips.TooltipType = TooltipType
