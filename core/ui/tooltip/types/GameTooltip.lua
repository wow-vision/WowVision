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
    -- afterEnter(tooltipFrame, frame): a step of the game's own run after the
    -- frame's OnEnter (e.g. the quest log's party progress call made again
    -- with the player in it).
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

function GameTooltipType:executeOnEnter()
    local frame = self.widget and self.widget.frame or nil
    if frame == nil then
        return
    end
    if self.populate ~= nil then
        local tooltip = self.tooltip.activeFrame or GameTooltip
        tooltip:SetOwner(frame, "ANCHOR_NONE")
        local ok, err = pcall(self.populate, tooltip, frame)
        if not ok then
            geterrorhandler()(err)
        end
        return
    end
    if frame:HasScript("OnEnter") then
        ExecuteFrameScript(frame, "OnEnter")
    end
    if self.afterEnter ~= nil then
        local ok, err = pcall(self.afterEnter, self.tooltip.activeFrame or GameTooltip, frame)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

function GameTooltipType:executeOnLeave()
    local frame = self.widget and self.widget.frame or nil
    if frame == nil then
        return
    end
    if self.populate ~= nil then
        local tooltip = self.tooltip.activeFrame or GameTooltip
        tooltip:Hide()
        return
    end
    if frame:HasScript("OnLeave") then
        ExecuteFrameScript(frame, "OnLeave")
    end
end

WowVision.GameTooltipType = GameTooltipType
