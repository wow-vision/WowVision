local UnitTooltipType = WowVision.tooltips:createType("Unit")

function UnitTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
end

function UnitTooltipType:activate(widget, data)
    self.tooltip.frame:SetUnit(data.unit)
    self.tooltip.activeFrame = self.tooltip.frame
end

WowVision.UnitTooltipType = UnitTooltipType
