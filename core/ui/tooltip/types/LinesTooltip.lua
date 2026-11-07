local LinesTooltipType = WowVision.tooltips:createType("Lines")

-- A tooltip WowVision writes itself, one line per string, read with the
-- tooltip keys like any other. An optional game link adds the lines of the
-- game's own tooltip for it that are not there yet (the link's text, read
-- off the frame first, since filling a link clears the frame).
--
-- data: { type = "Lines", lines = list | function -> list, link = string? }
-- Filled again before every read, so progress is current.
function LinesTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
    self.data = nil
end

local function linkLines(frame, link)
    local lines = {}
    frame:ClearLines()
    frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    if not pcall(frame.SetHyperlink, frame, link) then
        return lines
    end
    local name = frame:GetName()
    for index = 1, frame:NumLines() do
        local region = name ~= nil and _G[name .. "TextLeft" .. index] or nil
        local text = region ~= nil and region:GetText() or nil
        if type(text) == "string" and text ~= "" and not WowVision.isSecret(text) then
            tinsert(lines, text)
        end
    end
    return lines
end

function LinesTooltipType:fill()
    local data = self.data
    local frame = self.tooltip.frame
    local lines = data.lines
    if type(lines) == "function" then
        local ok, result = pcall(lines)
        if not ok then
            geterrorhandler()(result)
            result = nil
        end
        lines = result
    end
    lines = lines or {}
    local extra = data.link ~= nil and linkLines(frame, data.link) or {}
    local said = {}
    frame:ClearLines()
    frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    for _, line in ipairs(lines) do
        tinsert(said, LinesTooltipType.normalize(line))
        frame:AddLine(line, 1, 1, 1, true)
    end
    -- A link line already said (the title; "- Kobold Vermin slain: 3/10"
    -- next to our "Kobold Vermin slain: 3/10") is left out.
    for _, line in ipairs(extra) do
        local norm = LinesTooltipType.normalize(line)
        local known = norm == ""
        for _, existing in ipairs(said) do
            if known or existing:find(norm, 1, true) ~= nil then
                known = true
                break
            end
        end
        if not known then
            tinsert(said, norm)
            frame:AddLine(line, 1, 1, 1, true)
        end
    end
end

-- Lower case, leading dashes and spaces gone, inner spaces collapsed.
function LinesTooltipType.normalize(text)
    text = tostring(text):lower():gsub("^[%s%-%*]+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return text
end

function LinesTooltipType:activate(widget, data)
    self.data = data
    self:fill()
    self.tooltip.activeFrame = self.tooltip.frame
end

function LinesTooltipType:deactivate()
    self.data = nil
end

function LinesTooltipType:beforeRead()
    if self.data ~= nil then
        self:fill()
    end
end

WowVision.LinesTooltipType = LinesTooltipType
