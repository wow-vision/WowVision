local GameTooltipType = WowVision.tooltips:createType("Game")

function GameTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
    self.mode = nil
    self.widget = nil
end

function GameTooltipType:activate(widget, data)
    self.tooltip.activeFrame = GameTooltip
    self.mode = data.mode
    self.widget = widget
end

function GameTooltipType:deactivate()
    self.mode = nil
    self.widget = nil
end

function GameTooltipType:onFocus()
    if self.mode == "static" then
        self:executeOnEnter()
    end
end

function GameTooltipType:onUnfocus()
    if self.mode == "static" then
        self:executeOnLeave()
    end
end

function GameTooltipType:beforeRead()
    if self.mode == "immediate" then
        self:executeOnEnter()
    end
end

function GameTooltipType:afterRead()
    if self.mode == "immediate" then
        self:executeOnLeave()
    end
end

function GameTooltipType:executeOnEnter()
    if self.widget and self.widget.frame and self.widget.frame:HasScript("OnEnter") then
        ExecuteFrameScript(self.widget.frame, "OnEnter")
    end
end

function GameTooltipType:executeOnLeave()
    if self.widget and self.widget.frame and self.widget.frame:HasScript("OnLeave") then
        ExecuteFrameScript(self.widget.frame, "OnLeave")
    end
end

WowVision.GameTooltipType = GameTooltipType
