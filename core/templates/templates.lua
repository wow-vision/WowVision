-- Placeholders for escaped characters
local ESCAPE_LEFT_BRACE = "\001"
local ESCAPE_RIGHT_BRACE = "\002"
local ESCAPE_LEFT_BRACKET = "\003"
local ESCAPE_RIGHT_BRACKET = "\004"

local templates = {
    registry = WowVision.Registry:new(),
}

-- Render a template string with variable and locale substitutions
-- Template syntax:
--   {field}  - Replaced with context[field]
--   [key]    - Replaced with locale[key]
--   {{       - Literal {
--   }}       - Literal }
--   [[       - Literal [
--   ]]       - Literal ]
--
-- Example: "[XP]: {percent}% ({current} [of] {maximum})"
function templates.render(template, context, locale)
    -- Replace escape sequences with placeholders
    local result = template
    result = string.gsub(result, "{{", ESCAPE_LEFT_BRACE)
    result = string.gsub(result, "}}", ESCAPE_RIGHT_BRACE)
    result = string.gsub(result, "%[%[", ESCAPE_LEFT_BRACKET)
    result = string.gsub(result, "%]%]", ESCAPE_RIGHT_BRACKET)

    -- Replace locale keys [key] with locale["key"]
    result = string.gsub(result, "%[([^%]]+)%]", function(key)
        local value = locale[key]
        if value == nil then
            return "[" .. key .. "]"
        end
        return value
    end)

    -- Replace context fields {field} with context values
    result = string.gsub(result, "{([^}]+)}", function(field)
        local value = context[field]
        if value == nil then
            return "{" .. field .. "}"
        end
        return tostring(value)
    end)

    -- Replace placeholders with literal characters
    result = string.gsub(result, ESCAPE_LEFT_BRACE, "{")
    result = string.gsub(result, ESCAPE_RIGHT_BRACE, "}")
    result = string.gsub(result, ESCAPE_LEFT_BRACKET, "[")
    result = string.gsub(result, ESCAPE_RIGHT_BRACKET, "]")

    return result
end

WowVision.templates = templates
