local templates = {
    registry = WowVision.Registry:new(),
}

-- Template syntax:
--   {field}  - Replaced with context[field]
--   [key]    - Replaced with locale[key] (resolved at parse time)
--   {{       - Literal {
--   }}       - Literal }
--   [[       - Literal [
--   ]]       - Literal ]
--
-- Example: "[XP]: {percent}% ({current} [of] {maximum})"

-- Parse a template string into an AST (array of nodes) and a set of required field keys.
-- Locale values are resolved at parse time into literal nodes.
-- Node types:
--   { type = "literal", value = "some text" }
--   { type = "field", key = "fieldName" }
function templates.parse(template, locale)
    local nodes = {}
    local fields = {}
    local pos = 1
    local len = #template
    local literal = ""

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
            literal = literal .. string.sub(template, pos)
            break
        end

        -- Accumulate literal text before the special char
        if nextSpecial > pos then
            literal = literal .. string.sub(template, pos, nextSpecial - 1)
        end

        local char = string.sub(template, nextSpecial, nextSpecial)
        local nextChar = string.sub(template, nextSpecial + 1, nextSpecial + 1)

        if char == "{" then
            if nextChar == "{" then
                -- Escaped {{ -> literal {
                literal = literal .. "{"
                pos = nextSpecial + 2
            else
                -- Find closing }
                local closePos = string.find(template, "}", nextSpecial + 1, true)
                if closePos then
                    -- Flush accumulated literal before field node
                    if #literal > 0 then
                        tinsert(nodes, { type = "literal", value = literal })
                        literal = ""
                    end
                    local fieldKey = string.sub(template, nextSpecial + 1, closePos - 1)
                    tinsert(nodes, { type = "field", key = fieldKey })
                    fields[fieldKey] = true
                    pos = closePos + 1
                else
                    -- No closing brace, treat as literal
                    literal = literal .. "{"
                    pos = nextSpecial + 1
                end
            end
        elseif char == "}" then
            if nextChar == "}" then
                -- Escaped }} -> literal }
                literal = literal .. "}"
                pos = nextSpecial + 2
            else
                -- Standalone }, just output it
                literal = literal .. "}"
                pos = nextSpecial + 1
            end
        elseif char == "[" then
            if nextChar == "[" then
                -- Escaped [[ -> literal [
                literal = literal .. "["
                pos = nextSpecial + 2
            else
                -- Find closing ]
                local closePos = string.find(template, "]", nextSpecial + 1, true)
                if closePos then
                    -- Resolve locale at parse time into literal
                    local key = string.sub(template, nextSpecial + 1, closePos - 1)
                    local value = locale and locale[key]
                    if value ~= nil then
                        literal = literal .. value
                    else
                        literal = literal .. "[" .. key .. "]"
                    end
                    pos = closePos + 1
                else
                    -- No closing bracket, treat as literal
                    literal = literal .. "["
                    pos = nextSpecial + 1
                end
            end
        elseif char == "]" then
            if nextChar == "]" then
                -- Escaped ]] -> literal ]
                literal = literal .. "]"
                pos = nextSpecial + 2
            else
                -- Standalone ], just output it
                literal = literal .. "]"
                pos = nextSpecial + 1
            end
        end
    end

    -- Flush remaining literal
    if #literal > 0 then
        tinsert(nodes, { type = "literal", value = literal })
    end

    return nodes, fields
end

-- Render from pre-parsed AST nodes.
-- Uses concatenation (not table.concat) to support WoW's "secret values"
-- which cannot be used with most Lua operations but can be concatenated.
function templates.renderNodes(nodes, context)
    local result = ""
    for i = 1, #nodes do
        local node = nodes[i]
        if node.type == "literal" then
            result = result .. node.value
        elseif node.type == "field" then
            local value = context[node.key]
            if value ~= nil then
                result = result .. value
            end
        end
    end
    return result
end

-- Convenience: parse and render in one call (for one-off usage)
function templates.render(template, context, locale)
    local nodes = templates.parse(template, locale)
    return templates.renderNodes(nodes, context)
end

WowVision.templates = templates
