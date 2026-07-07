local graph = WowVision.graph
local kinds = graph.kinds
local L = WowVision:getLocale()

-- The control-type registry: each entry is a plain value owning its settings
-- key, the speak order of its announcement kinds, and the parts common to
-- every control of the type (the localized role word). A node factory sets the
-- type and gets the role word, the ordering, and the user's per-type
-- announcement settings for free.
--
-- type = { key, order = array of kinds, common = function -> parts or nil }
local controlTypes = {}
graph.controlTypes = controlTypes
graph.controlTypeList = {}

graph.standardOrder = {
    kinds.label,
    kinds.role,
    kinds.value,
    kinds.selected,
    kinds.enabled,
    kinds.position,
}

function graph.registerControlType(key, roleWord)
    local common = nil
    if roleWord ~= nil then
        local parts = { { text = roleWord, kind = kinds.role } }
        common = function()
            return parts
        end
    end
    local controlType = { key = key, order = graph.standardOrder, common = common }
    controlTypes[key] = controlType
    tinsert(graph.controlTypeList, controlType)
    return controlType
end

graph.registerControlType("button", L["Button"])
graph.registerControlType("toggle", L["Checkbox"])
graph.registerControlType("radio", L["Radio"])
graph.registerControlType("dropdown", L["Dropdown"])
graph.registerControlType("number", L["Number"])
graph.registerControlType("editBox", L["EditBox"])
-- An expandable group header: no role word -- the announcer appends the
-- expanded/collapsed state word instead.
graph.registerControlType("group", nil)
-- A read-only text line: no role word; typed so its parts stay configurable.
graph.registerControlType("text", nil)
