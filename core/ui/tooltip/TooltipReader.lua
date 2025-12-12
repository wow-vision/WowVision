local TooltipReader = WowVision.Class("TooltipReader")

function TooltipReader:initialize() end

function TooltipReader:getLine(frame, index)
    if not frame or index < 1 or index > frame:NumLines() then
        return nil, nil
    end
    local left = _G[frame:GetName() .. "TextLeft" .. index]
    local right = _G[frame:GetName() .. "TextRight" .. index]
    if not left and not right then
        return nil, nil
    end
    return left:GetText(), right:GetText()
end

function TooltipReader:formatLine(left, right)
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
    return result
end

function TooltipReader:getText(frame, lineNumber)
    if not frame then
        return ""
    end
    local lines = {}
    if lineNumber == nil then
        for l = 1, frame:NumLines() do
            local left, right = self:getLine(frame, l)
            tinsert(lines, self:formatLine(left, right))
        end
    else
        local left, right = self:getLine(frame, lineNumber)
        tinsert(lines, self:formatLine(left, right))
    end
    return table.concat(lines, "\n")
end

WowVision.TooltipReader = TooltipReader
