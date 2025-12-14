local Template = {}

-- Render a template string with variable and locale substitutions
-- Template syntax:
--   {field}  - Replaced with context[field]
--   [key]    - Replaced with locale[key]
--
-- Example: "[XP]: {percent}% ({current} [of] {maximum})"
function Template.render(template, context, locale)
    -- Replace locale keys [key] with locale["key"]
    local result = string.gsub(template, "%[([^%]]+)%]", function(key)
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

    return result
end

WowVision.Template = Template
