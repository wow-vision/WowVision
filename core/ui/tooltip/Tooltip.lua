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

-- The lines as read: { left, right } pairs from the frame, plus the item
-- quality and item level when the tooltip shows an item (see
-- WowVision.items.augmentTooltipLines).
function Tooltip:collectLines()
    local frame = self.activeFrame
    local lines = {}
    if not frame then
        return lines
    end
    for index = 1, frame:NumLines() do
        local left, right = self.reader:getLine(frame, index)
        tinsert(lines, { left, right })
    end
    if frame.GetItem ~= nil and WowVision.items ~= nil then
        local ok, _, link = pcall(frame.GetItem, frame)
        if ok and link ~= nil and not WowVision.isSecret(link) then
            local augmented, err = pcall(WowVision.items.augmentTooltipLines, lines, link)
            if not augmented then
                geterrorhandler()(err)
            end
        end
    end
    return lines
end

function Tooltip:getText(lineNumber)
    if not self.activeFrame then
        return ""
    end
    local lines = self:readLines()
    local result = {}
    if lineNumber == nil then
        for _, line in ipairs(lines) do
            tinsert(result, self.reader:formatLine(line[1], line[2]))
        end
    elseif lines[lineNumber] ~= nil then
        tinsert(result, self.reader:formatLine(lines[lineNumber][1], lines[lineNumber][2]))
    end
    return self.reader:joinLines(result)
end

function Tooltip:speak(lineNumber)
    if not self.tooltipData then
        return
    end
    local text = self:getText(lineNumber)
    if WowVision.secrets.hasText(text) then
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

-- Fill the tooltip (immediate mode), collect its lines, and release it.
function Tooltip:readLines()
    self:prepareRead()
    local lines = self:collectLines()
    self:finishRead()
    return lines
end

function Tooltip:isBlank(line)
    local text = self.reader:formatLine(line[1], line[2])
    if not text then
        return true
    end
    -- A secret line cannot be inspected; it is taken to say something.
    if WowVision.secrets.isSecret(text) then
        return false
    end
    -- Strip WoW escape sequences: color codes, reset, textures, atlas, hyperlinks
    local stripped =
        text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|H.-|h", "")
    return strtrim(stripped) == ""
end

function Tooltip:isLineBlank(lineNumber)
    local line = self:readLines()[lineNumber]
    return line == nil or self:isBlank(line)
end

-- Move to the next non-blank line in direction (1 or -1) and speak it.
function Tooltip:moveLine(direction)
    if not self.activeFrame then
        return
    end
    local lines = self:readLines()
    local numLines = #lines
    if numLines == 0 then
        return
    end

    local start = self.currentLine or (direction > 0 and 0 or numLines + 1)
    local target = start + direction
    while target >= 1 and target <= numLines and self:isBlank(lines[target]) do
        target = target + direction
    end
    if target >= 1 and target <= numLines then
        self.currentLine = target
    end

    local line = self.currentLine ~= nil and lines[self.currentLine] or nil
    if line == nil then
        return
    end
    local text = self.reader:formatLine(line[1], line[2])
    if WowVision.secrets.hasText(text) then
        WowVision:speak(text)
    end
end

function Tooltip:nextLine()
    self:moveLine(1)
end

function Tooltip:previousLine()
    self:moveLine(-1)
end

-- Speak one side (1 left, 2 right) of the current line.
function Tooltip:speakCurrentSide(side)
    if not self.activeFrame then
        return
    end
    local lines = self:readLines()
    if #lines == 0 then
        return
    end
    if self.currentLine == nil then
        self.currentLine = 1
    end
    local line = lines[self.currentLine]
    local text = line ~= nil and line[side] or nil
    if WowVision.secrets.hasText(text) then
        WowVision:speak(text)
    end
end

function Tooltip:speakCurrentLeft()
    self:speakCurrentSide(1)
end

function Tooltip:speakCurrentRight()
    self:speakCurrentSide(2)
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
