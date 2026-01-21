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
--
-- Note: This implementation uses manual parsing and string concatenation
-- instead of gsub to support WoW's "secret values" which cannot be used
-- with most Lua operations but can be concatenated.
function templates.render(template, context, locale)
    local result = ""
    local pos = 1
    local len = #template

    while pos <= len do
        -- Find next special character
        local nextBrace = string.find(template, "{", pos, true)
        local nextBracket = string.find(template, "[", pos, true)
        local nextCloseBrace = string.find(template, "}", pos, true)
        local nextCloseBracket = string.find(template, "]", pos, true)

        -- Find the earliest special character
        local nextSpecial = nil
        local specials = { nextBrace, nextBracket, nextCloseBrace, nextCloseBracket }
        for _, v in ipairs(specials) do
            if v and (not nextSpecial or v < nextSpecial) then
                nextSpecial = v
            end
        end

        if not nextSpecial then
            -- No more special chars, append rest of string
            result = result .. string.sub(template, pos)
            break
        end

        -- Append literal text before the special char
        if nextSpecial > pos then
            result = result .. string.sub(template, pos, nextSpecial - 1)
        end

        local char = string.sub(template, nextSpecial, nextSpecial)
        local nextChar = string.sub(template, nextSpecial + 1, nextSpecial + 1)

        if char == "{" then
            if nextChar == "{" then
                -- Escaped {{ -> literal {
                result = result .. "{"
                pos = nextSpecial + 2
            else
                -- Find closing }
                local closePos = string.find(template, "}", nextSpecial + 1, true)
                if closePos then
                    local field = string.sub(template, nextSpecial + 1, closePos - 1)
                    local value = context[field]
                    if value ~= nil then
                        result = result .. value
                    else
                        result = result .. "{" .. field .. "}"
                    end
                    pos = closePos + 1
                else
                    -- No closing brace, treat as literal
                    result = result .. "{"
                    pos = nextSpecial + 1
                end
            end
        elseif char == "}" then
            if nextChar == "}" then
                -- Escaped }} -> literal }
                result = result .. "}"
                pos = nextSpecial + 2
            else
                -- Standalone }, just output it
                result = result .. "}"
                pos = nextSpecial + 1
            end
        elseif char == "[" then
            if nextChar == "[" then
                -- Escaped [[ -> literal [
                result = result .. "["
                pos = nextSpecial + 2
            else
                -- Find closing ]
                local closePos = string.find(template, "]", nextSpecial + 1, true)
                if closePos then
                    local key = string.sub(template, nextSpecial + 1, closePos - 1)
                    local value = locale[key]
                    if value ~= nil then
                        result = result .. value
                    else
                        result = result .. "[" .. key .. "]"
                    end
                    pos = closePos + 1
                else
                    -- No closing bracket, treat as literal
                    result = result .. "["
                    pos = nextSpecial + 1
                end
            end
        elseif char == "]" then
            if nextChar == "]" then
                -- Escaped ]] -> literal ]
                result = result .. "]"
                pos = nextSpecial + 2
            else
                -- Standalone ], just output it
                result = result .. "]"
                pos = nextSpecial + 1
            end
        end
    end

    return result
end

WowVision.templates = templates
