local TextTooltipType = WowVision.tooltips:createType("Text")

function TextTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
end

function TextTooltipType:activate(widget, data)
    self.tooltip.frame:SetText(data.text)
    self.tooltip.activeFrame = self.tooltip.frame
end

WowVision.TextTooltipType = TextTooltipType
