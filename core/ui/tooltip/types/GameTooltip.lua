local GameTooltipType = WowVision.tooltips:createType("Game")

function GameTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
    self.mode = nil
    self.widget = nil
end

function GameTooltipType:activate(widget, data)
    -- Some panels render into their own tooltip frame (SettingsPanel uses
    -- SettingsTooltip); data.frame points the reader there.
    self.tooltip.activeFrame = data.frame or GameTooltip
    self.mode = data.mode
    -- populate(tooltipFrame, frame): fill the tooltip directly instead of
    -- running the frame's OnEnter (which would run as the addon and taint
    -- whatever it writes; see nodes.proxyButton).
    self.populate = data.populate
    -- afterEnter(tooltipFrame, frame): a step after the tooltip is filled
    -- (by populate, else the frame's OnEnter); skipped when neither ran. The
    -- quest log uses it to put the player's progress back in a group.
    self.afterEnter = data.afterEnter
    self.widget = widget
end

function GameTooltipType:deactivate()
    self.mode = nil
    self.populate = nil
    self.afterEnter = nil
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

-- A config step (populate, afterEnter) under pcall: a failing step is
-- reported and the read goes on.
local function runStep(step, ...)
    local ok, err = pcall(step, ...)
    if not ok then
        geterrorhandler()(err)
    end
end

function GameTooltipType:executeOnEnter()
    local frame = self.widget and self.widget.frame or nil
    if frame == nil then
        return
    end
    local tooltip = self.tooltip.activeFrame
    if self.populate ~= nil then
        tooltip:SetOwner(frame, "ANCHOR_NONE")
        runStep(self.populate, tooltip, frame)
    elseif frame:HasScript("OnEnter") then
        ExecuteFrameScript(frame, "OnEnter")
    else
        return
    end
    if self.afterEnter ~= nil then
        runStep(self.afterEnter, tooltip, frame)
    end
end

function GameTooltipType:executeOnLeave()
    local frame = self.widget and self.widget.frame or nil
    if frame == nil then
        return
    end
    if self.populate ~= nil then
        self.tooltip.activeFrame:Hide()
        return
    end
    if frame:HasScript("OnLeave") then
        ExecuteFrameScript(frame, "OnLeave")
    end
end

WowVision.GameTooltipType = GameTooltipType
