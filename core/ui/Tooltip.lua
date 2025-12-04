local Tooltip = WowVision.Class("Tooltip")

function Tooltip:initialize(name)
    self.name = name
    self.frame = CreateFrame("GameTooltip", name .. "Tooltip", nil, "GameTooltipTemplate")
    self.frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    self.types = WowVision.Registry:new()
    self:reset()
    self.types:register("game", function(tip, widget, data)
        tip.activeFrame = GameTooltip
    end)
    self.types:register("unit", function(tip, widget, data)
        tip.frame:SetUnit(data.unit)
    end)
end

function Tooltip:set(widget, data)
    self:reset()
    self.activeFrame = self.frame
    if type(data) == "string" then
        self.tooltip = { text = data }
        self.frame:SetText(data)
        return
    end
    local tType = self.types:get(data.type)
    if not tType then
        error("Unknown tooltip type " .. data.type)
    end
    tType(self, widget, data)
    self.widget = widget
    self.tooltip = data
end

function Tooltip:reset()
    self.index = 0
    self.frame:ClearLines()
    self.activeFrame = nil
    self.widget = nil
    self.tooltip = nil
end

function Tooltip:getLine(index)
    if not self.activeFrame or index < 1 or index > self.activeFrame:NumLines() then
        return nil, nil
    end
    local left = _G[self.activeFrame:GetName() .. "TextLeft" .. index]
    local right = _G[self.activeFrame:GetName() .. "TextRight" .. index]
    if not left and not right then
        return nil, nil
    end
    return left:GetText(), right:GetText()
end

function Tooltip:getText(line)
    if self.tooltip.mode == "immediate" then
        if self.widget.frame and self.widget.frame:HasScript("OnEnter") then
            ExecuteFrameScript(self.widget.frame, "OnEnter")
        end
    end
    local lines = {}
    if line == nil then
        for l = 1, self.activeFrame:NumLines() do
            local left, right = self:getLine(l)
            tinsert(lines, { left, right })
        end
    else
        local left, right = self:getLine(line)
        tinsert(lines, { left, right })
    end
    local final = {}
    for _, line in ipairs(lines) do
        local left, right = line[1], line[2]
        local result = ""
        if left and left ~= "" then
            result = result .. left
        end
        if right and right ~= "" then
            if result ~= "" then
                result = result .. " "
            end
            result = result .. right
        end
        tinsert(final, result)
    end
    if self.tooltip.mode == "immediate" then
        if self.widget.frame and self.widget.frame:HasScript("OnLeave") then
            ExecuteFrameScript(self.widget.frame, "OnLeave")
        end
    end

    return table.concat(final, "\n")
end

function Tooltip:speak(line)
    if not self.tooltip then
        return
    end
    local text = self:getText(line)
    if text and text ~= "" then
        WowVision:speak(text)
    end
end

WowVision.Tooltip = Tooltip
