local MountTooltipType = WowVision.tooltips:createType("Mount")

function MountTooltipType:activate(widget, data)
    if data.spellID == nil then
        return
    end
    self.tooltip.frame:SetSpellByID(data.spellID)
    self.tooltip.activeFrame = self.tooltip.frame
end