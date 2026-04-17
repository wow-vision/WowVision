local utils = {}
WowVision.errors = { utils = utils }

function utils.templateLiteral(template)
    if not template then return "" end
    local stripped = template:gsub("%%[%-%+%d%.%$]*[sdfioxXcug]", "")
    stripped = stripped:gsub("%s+", "")
    return stripped
end

function utils.prettifyTemplate(template)
    if not template then return template end
    return (template:gsub("%%[%-%+%d%.%$]*[sdfioxXcug]", "…"))
end

function utils.normalizeMessage(template, message)
    if template and utils.templateLiteral(template) ~= "" then
        return utils.prettifyTemplate(template)
    end
    return message
end

function utils.makeKey(messageType, message)
    return tostring(messageType) .. ":" .. tostring(message)
end
