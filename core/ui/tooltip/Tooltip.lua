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
    self.comparisonCache = nil
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
    self.comparisonCache = nil
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

-- The link of the item a tooltip frame shows, for the comparison; nil for
-- none or a secret one. Classic tooltips answer GetItem; Retail and WoW:
-- Forever dropped it for TooltipUtil.GetDisplayedItem (their GameTooltip
-- data mixin).
local function shownItemLink(frame)
    local ok, _, link
    if frame.GetItem ~= nil then
        ok, _, link = pcall(frame.GetItem, frame)
    elseif TooltipUtil ~= nil and TooltipUtil.GetDisplayedItem ~= nil and frame.IsTooltipType ~= nil then
        ok, _, link = pcall(TooltipUtil.GetDisplayedItem, frame)
    end
    if not ok or link == nil or WowVision.isSecret(link) then
        return nil
    end
    return link
end

-- The lines as read: { left, right } pairs from the frame, plus the item
-- quality and item level when the tooltip shows an item (see
-- WowVision.items.augmentTooltipLines), then Pawn's upgrade summary and
-- WowVision's own comparison (see WowVision.items.augmentComparisonLines),
-- then the equipped items the game compares it with (see addComparison)
-- unless withComparison is false.
function Tooltip:collectLines(withComparison)
    local frame = self.activeFrame
    if not frame then
        return {}
    end
    local lines = self:frameLines(frame)
    -- Only the shown item: a comparison box is not compared in turn.
    local link = WowVision.items ~= nil and WowVision.items.augmentComparisonLines ~= nil and shownItemLink(frame)
        or nil
    if link ~= nil then
        local augmented, augmentErr = pcall(WowVision.items.augmentComparisonLines, lines, link)
        if not augmented then
            geterrorhandler()(augmentErr)
        end
    end
    if withComparison ~= false then
        local compared, err = pcall(self.addComparison, self, frame, lines)
        if not compared then
            geterrorhandler()(err)
        end
    end
    return lines
end

-- The equipped items the game compares the shown item with (the shopping
-- tooltips sighted players get on Shift), each as a block after the item's
-- own lines: the header, the equipped item, the stat changes. The version
-- folders fill comparison.fill; every block line is marked compare, so
-- reading the whole tooltip at once stays with the item itself. The
-- blocks are built once per shown item (walking the lines reads them again
-- and again) and dropped when the tooltip is set again.
function Tooltip:addComparison(frame, lines)
    local comparison = WowVision.tooltips.comparison
    if comparison.fill == nil or not comparison.isEnabled() then
        return
    end
    local link = shownItemLink(frame)
    if link == nil then
        return
    end
    local cache = self.comparisonCache
    if cache == nil or cache.link ~= link then
        cache = { link = link, blocks = {} }
        for _, block in ipairs(comparison.fill(frame, link) or {}) do
            tinsert(cache.blocks, { header = block.header, lines = self:frameLines(block.frame) })
            block.frame:Hide()
        end
        self.comparisonCache = cache
    end
    for _, block in ipairs(cache.blocks) do
        comparison.append(lines, block.header, block.lines)
    end
end

function Tooltip:frameLines(frame)
    local lines = {}
    for index = 1, frame:NumLines() do
        local left, right = self.reader:getLine(frame, index)
        tinsert(lines, { left, right })
    end
    local spokeMoney, err = pcall(self.speakMoney, self, frame, lines)
    if not spokeMoney then
        geterrorhandler()(err)
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

local function coinText(copper)
    return C_CurrencyInfo.GetCoinText(copper)
end

-- A money frame's prefix or suffix. A secret one cannot be compared with an
-- empty text, but it can still be joined to the spoken line.
local function hasText(text)
    if WowVision.isSecret(text) then
        return true
    end
    return text ~= nil and text ~= ""
end

-- Money lines spoken with their coins (gold, silver, copper) instead of
-- bare numbers. Two shapes:
-- - coins written into the line text, coin textures that speech drops, or
--   a bare copper number after the sell price label;
-- - a money frame (SetTooltipMoney) laid over an empty line: the line has
--   no text, the frame holds the prefix ("Sell Price:") and the amount.
function Tooltip:speakMoney(frame, lines)
    local isSecret = WowVision.isSecret
    for index, line in ipairs(lines) do
        local left, right = line[1], line[2]
        if not isSecret(left) and not isSecret(right) then
            local text = self.reader:formatLine(left, right)
            local spoken = WowVision.utils.moneyLineText(text, SELL_PRICE, coinText)
            if spoken ~= nil then
                lines[index] = { spoken, nil }
            end
        end
    end
    local name = frame:GetName()
    for i = 1, frame.shownMoneyFrames or 0 do
        local moneyFrame = _G[name .. "MoneyFrame" .. i]
        if moneyFrame ~= nil and moneyFrame:IsShown() and moneyFrame.staticMoney ~= nil
            and not isSecret(moneyFrame.staticMoney) then
            local _, anchor = moneyFrame:GetPoint(1)
            for index = 1, #lines do
                if anchor ~= nil and anchor == _G[name .. "TextLeft" .. index] then
                    local prefix = _G[moneyFrame:GetName() .. "PrefixText"]
                    local suffix = _G[moneyFrame:GetName() .. "SuffixText"]
                    local spoken = coinText(moneyFrame.staticMoney)
                    local prefixText = prefix ~= nil and prefix:GetText() or nil
                    if hasText(prefixText) then
                        spoken = prefixText .. " " .. spoken
                    end
                    local suffixText = suffix ~= nil and suffix:GetText() or nil
                    if hasText(suffixText) then
                        spoken = spoken .. " " .. suffixText
                    end
                    lines[index] = { spoken, nil }
                end
            end
        end
    end
end

function Tooltip:getText(lineNumber)
    if not self.activeFrame then
        return ""
    end
    -- The whole tooltip at once leaves the comparison out, so it is not built.
    local lines = self:readLines(lineNumber ~= nil)
    local result = {}
    if lineNumber == nil then
        for _, line in ipairs(lines) do
            if not line.compare then
                tinsert(result, self.reader:formatLine(line[1], line[2]))
            end
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
function Tooltip:readLines(withComparison)
    self:prepareRead()
    local lines = self:collectLines(withComparison)
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

-- Move to the start of the next or previous block (the item, then each
-- equipped item it is compared with and its stat changes) and speak that
-- line. The item's block
-- starts at its first non-blank line. At either end the current block's
-- start is read again.
function Tooltip:moveBlock(direction)
    if not self.activeFrame then
        return
    end
    local lines = self:readLines()
    local starts = {}
    for index, line in ipairs(lines) do
        if line.blockStart or (#starts == 0 and not self:isBlank(line)) then
            tinsert(starts, index)
        end
    end
    if #starts == 0 then
        return
    end

    -- The block the current line is in; before any line, none.
    local current = 0
    for i, start in ipairs(starts) do
        if self.currentLine ~= nil and start <= self.currentLine then
            current = i
        end
    end
    local target = math.max(1, math.min(#starts, current + direction))
    self.currentLine = starts[target]

    local line = lines[self.currentLine]
    local text = self.reader:formatLine(line[1], line[2])
    if WowVision.secrets.hasText(text) then
        WowVision:speak(text)
    end
end

function Tooltip:nextBlock()
    self:moveBlock(1)
end

function Tooltip:previousBlock()
    self:moveBlock(-1)
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

-- Comparison with equipped items. fill(frame, link) returns a list of
-- { frame, header } blocks, filled by the game; nil where a game version
-- has none. isEnabled is the tooltip/compare module's switch.
local comparison = {
    fill = nil,
    isEnabled = function()
        return true
    end,
}

-- The two boxes the version folders fill: our own frames, so the game's
-- ShoppingTooltip1 and 2 stay untouched.
local compareFrames = nil
function comparison.frames()
    if compareFrames == nil then
        compareFrames = {
            CreateFrame("GameTooltip", "WowVisionCompareTooltip1", nil, "ShoppingTooltipTemplate"),
            CreateFrame("GameTooltip", "WowVisionCompareTooltip2", nil, "ShoppingTooltipTemplate"),
        }
    end
    return compareFrames
end

-- The game's heading over the stat changes in a comparison box ("If you
-- replace this item, the following stat changes will occur:"): a block of
-- its own for nextBlock/previousBlock.
local function isStatChangeHeading(text)
    return text ~= nil
        and not WowVision.secrets.isSecret(text)
        and (text == ITEM_DELTA_DESCRIPTION or text == ITEM_DELTA_MULTIPLE_COMPARISON_DESCRIPTION)
end

-- One block after the tooltip lines: the header unless the game's own
-- first line already says it, then the block lines, all marked compare.
-- The block's first line, and the stat change heading, are marked
-- blockStart for nextBlock/previousBlock.
function comparison.append(lines, header, blockLines)
    local first = #lines + 1
    local firstText = blockLines[1] ~= nil and blockLines[1][1] or nil
    -- A secret first line cannot be compared: the header goes in.
    if header ~= nil and (firstText == nil or WowVision.secrets.isSecret(firstText) or firstText ~= header) then
        tinsert(lines, { header, nil, compare = true })
    end
    for _, line in ipairs(blockLines) do
        line.compare = true
        if isStatChangeHeading(line[1]) then
            line.blockStart = true
        end
        tinsert(lines, line)
    end
    if lines[first] ~= nil then
        lines[first].blockStart = true
    end
end

local tooltips = {
    Tooltip = Tooltip,
    types = WowVision.Registry:new(),
    comparison = comparison,
}

function tooltips:createType(key)
    local class = WowVision.Class(key .. "TooltipType", self.TooltipType)
    self.types:register(key, class)
    return class
end

WowVision.Tooltip = Tooltip
WowVision.tooltips = tooltips
