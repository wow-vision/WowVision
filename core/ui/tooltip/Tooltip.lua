local Tooltip = WowVision.Class("Tooltip")

function Tooltip:initialize(name)
    self.name = name
    self.frame = CreateFrame("GameTooltip", name .. "Tooltip", nil, "GameTooltipTemplate")
    self.frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    self.reader = WowVision.TooltipReader:new()
    self.activeType = nil
    self.activeFrame = nil
    self.widget = nil
    self.tooltipData = nil
    self.currentLine = nil
end

function Tooltip:set(widget, data)
    self:reset()

    -- Handle simple string tooltips
    if type(data) == "string" then
        data = { type = "Text", text = data }
    end

    local tooltipType = WowVision.tooltips.types:get(data.type)
    if not tooltipType then
        error("Unknown tooltip type: " .. tostring(data.type))
    end

    self.activeType = tooltipType:new(self)
    self.widget = widget
    self.tooltipData = data
    self.activeType:activate(widget, data)
end

function Tooltip:reset()
    if self.activeType then
        self.activeType:deactivate()
    end
    self.frame:ClearLines()
    self.activeType = nil
    self.activeFrame = nil
    self.widget = nil
    self.tooltipData = nil
    self.currentLine = nil
end

function Tooltip:onFocus()
    if self.activeType then
        self.activeType:onFocus()
    end
end

function Tooltip:onUnfocus()
    if self.activeType then
        self.activeType:onUnfocus()
    end
end

function Tooltip:getText(lineNumber)
    if not self.activeFrame then
        return ""
    end

    if self.activeType then
        self.activeType:beforeRead()
    end

    local text = self.reader:getText(self.activeFrame, lineNumber)

    if self.activeType then
        self.activeType:afterRead()
    end

    return text
end

function Tooltip:speak(lineNumber)
    if not self.tooltipData then
        return
    end
    local text = self:getText(lineNumber)
    if text and text ~= "" then
        WowVision:speak(text)
    end
end

function Tooltip:getNumLines()
    if not self.activeFrame then
        return 0
    end
    return self.activeFrame:NumLines()
end

function Tooltip:prepareRead()
    if self.activeType then
        self.activeType:beforeRead()
    end
end

function Tooltip:finishRead()
    if self.activeType then
        self.activeType:afterRead()
    end
end

function Tooltip:nextLine()
    if not self.activeFrame then return end
    self:prepareRead()
    local numLines = self:getNumLines()
    if numLines == 0 then
        self:finishRead()
        return
    end

    if self.currentLine == nil then
        self.currentLine = 1
    elseif self.currentLine < numLines then
        self.currentLine = self.currentLine + 1
    end

    local left, right = self.reader:getLine(self.activeFrame, self.currentLine)
    self:finishRead()
    local text = self.reader:formatLine(left, right)
    if text and text ~= "" then
        WowVision:speak(text)
    end
end

function Tooltip:previousLine()
    if not self.activeFrame then return end
    self:prepareRead()
    local numLines = self:getNumLines()
    if numLines == 0 then
        self:finishRead()
        return
    end

    if self.currentLine == nil then
        self.currentLine = numLines
    elseif self.currentLine > 1 then
        self.currentLine = self.currentLine - 1
    end

    local left, right = self.reader:getLine(self.activeFrame, self.currentLine)
    self:finishRead()
    local text = self.reader:formatLine(left, right)
    if text and text ~= "" then
        WowVision:speak(text)
    end
end

function Tooltip:speakCurrentLeft()
    if not self.activeFrame then return end
    self:prepareRead()
    local numLines = self:getNumLines()
    if numLines == 0 then
        self:finishRead()
        return
    end
    if self.currentLine == nil then
        self.currentLine = 1
    end

    local left, _ = self.reader:getLine(self.activeFrame, self.currentLine)
    self:finishRead()
    if left and left ~= "" then
        WowVision:speak(left)
    end
end

function Tooltip:speakCurrentRight()
    if not self.activeFrame then return end
    self:prepareRead()
    local numLines = self:getNumLines()
    if numLines == 0 then
        self:finishRead()
        return
    end
    if self.currentLine == nil then
        self.currentLine = 1
    end

    local _, right = self.reader:getLine(self.activeFrame, self.currentLine)
    self:finishRead()
    if right and right ~= "" then
        WowVision:speak(right)
    end
end

local tooltips = {
    Tooltip = Tooltip,
    types = WowVision.Registry:new(),
}

function tooltips:createType(key)
    local class = WowVision.Class(key .. "TooltipType", self.TooltipType)
    self.types:register(key, class)
    return class
end

WowVision.Tooltip = Tooltip
WowVision.tooltips = tooltips
