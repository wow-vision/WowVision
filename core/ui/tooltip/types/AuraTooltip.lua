local AuraTooltipType = WowVision.tooltips:createType("Aura")

-- One buff or debuff of a unit, by its position: the game's own tooltip for
-- it (name, description, time left), filled into our private tooltip frame
-- with SetUnitAura. Under Retail's secrets (combat, instances) the aura list
-- is closed to addons, but this fill is allowed: the line count is plain,
-- the text secret but speakable (measured 2026-10-24; see AuraBuffer.lua).
-- Filled again before every read, so the time left is current while the
-- player reads line by line.
function AuraTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
    self.unit = nil
    self.index = nil
    self.filter = nil
end

function AuraTooltipType:fill()
    local frame = self.tooltip.frame
    frame:ClearLines()
    frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(frame.SetUnitAura, frame, self.unit, self.index, self.filter)
    return ok and frame:NumLines() > 0
end

-- data: { type = "Aura", unit, index, filter }
function AuraTooltipType:activate(widget, data)
    self.unit, self.index, self.filter = data.unit, data.index, data.filter
    if self.unit == nil or self.index == nil then
        return
    end
    self:fill()
    self.tooltip.activeFrame = self.tooltip.frame
end

function AuraTooltipType:deactivate()
    self.unit, self.index, self.filter = nil, nil, nil
end

function AuraTooltipType:beforeRead()
    if self.unit ~= nil and self.index ~= nil then
        self:fill()
    end
end

WowVision.AuraTooltipType = AuraTooltipType
