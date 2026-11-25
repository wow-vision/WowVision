-- RestedXP's settings are an AceConfig options table: groups holding toggles, sliders, lists, inputs and buttons,
-- each with get/set/func/name/hidden/disabled that are values, functions or names of a handler's methods, some of
-- them inherited from the group above. AceConfigDialog turns that into a window nobody can read without seeing it.
-- This turns the same table into plain entries with the same rules (they are AceConfigDialog's own), so that the
-- screens can show them as WowVision controls. Nothing here touches the game.
local ns = WowVision.restedXP
local Text = ns.Text

local Options = {}
ns.Options = Options

-- ---- AceConfigDialog's rules, as they are in AceConfigDialog-3.0

-- members taken from the nearest group above when the option has none
local inherited = { set = true, get = true, func = true, confirm = true, validate = true, disabled = true, hidden = true }
-- members for which a string is the value itself rather than a method name
local stringIsLiteral = {
    name = true,
    desc = true,
    icon = true,
    usage = true,
    width = true,
    image = true,
    fontSize = true,
    tooltipHyperlink = true,
}
-- members that are never a function or a method
local allIsLiteral = { type = true, descStyle = true, imageWidth = true, imageHeight = true }

local function pickFirstSet(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
end

-- An option of a group, looking at its plugins first.
local function subOption(group, key)
    if type(group.plugins) == "table" then
        for _, plugin in pairs(group.plugins) do
            if plugin[key] then
                return plugin[key]
            end
        end
    end
    if type(group.args) == "table" then
        return group.args[key]
    end
end

local function copyPath(path, key)
    local result = {}
    for i, value in ipairs(path) do
        result[i] = value
    end
    if key ~= nil then
        result[#result + 1] = key
    end
    return result
end

-- The options table of the application, looked up the way AceConfigDialog does.
function Options.context(root, appName)
    return { root = root, appName = appName }
end

-- The info table every get/set/func receives: where the option is, its handler, its argument.
local function infoFor(ctx, option, path)
    local handler = ctx.root.handler
    local group = ctx.root
    local info = {
        options = ctx.root,
        appName = ctx.appName,
        [0] = ctx.appName,
        arg = option.arg,
        option = option,
        type = option.type,
        uiType = "dialog",
        uiName = "WowVision",
    }
    for i, key in ipairs(path) do
        group = subOption(group, key)
        if group == nil then
            break
        end
        info[i] = key
        handler = group.handler or handler
    end
    info.handler = handler
    return info
end

-- The value of a member that may be a function, a method name or a plain value (AceConfigDialog's
-- GetOptionsMemberValue). Calls it with the info table then the extra arguments; up to four results.
local function member(ctx, name, option, path, ...)
    local value
    if inherited[name] then
        local group = ctx.root
        if group[name] ~= nil then
            value = group[name]
        end
        for _, key in ipairs(path) do
            group = subOption(group, key)
            if group == nil then
                break
            end
            if group[name] ~= nil then
                value = group[name]
            end
        end
    else
        value = option[name]
    end
    if allIsLiteral[name] then
        return value
    end
    if type(value) == "function" or (not stringIsLiteral[name] and type(value) == "string") then
        local info = infoFor(ctx, option, path)
        if type(value) == "function" then
            return value(info, ...)
        end
        local handler = info.handler
        if handler ~= nil and handler[value] ~= nil then
            return handler[value](handler, info, ...)
        end
        error(string.format("Method %s doesn't exist in handler for type %s", value, name))
    end
    return value
end

-- Like member, but a failing option function gives nil instead of an error: the screens read these every tick.
local function safe(ctx, name, option, path, ...)
    local ok, a, b, c, d = pcall(member, ctx, name, option, path, ...)
    if ok then
        return a, b, c, d
    end
    return nil
end

local function isHidden(ctx, option, path)
    local hidden = pickFirstSet(option.dialogHidden, option.guiHidden)
    if hidden == nil then
        hidden = safe(ctx, "hidden", option, path)
    end
    return hidden and true or false
end

local function isDisabled(ctx, option, path)
    local disabled = pickFirstSet(option.dialogDisabled, option.guiDisabled)
    if disabled == nil then
        disabled = safe(ctx, "disabled", option, path)
    end
    return disabled and true or false
end

-- ---- sorting, as AceConfigDialog's BuildSortedOptionsTable

local function sortedKeys(ctx, group, path)
    local merged, keys, orders, names = {}, {}, {}, {}
    local function add(key, option)
        if merged[key] == nil then
            merged[key] = option
            keys[#keys + 1] = key
            local childPath = copyPath(path, key)
            orders[key] = safe(ctx, "order", option, childPath) or 100
            names[key] = safe(ctx, "name", option, childPath)
        end
    end
    if type(group.plugins) == "table" then
        for _, plugin in pairs(group.plugins) do
            for key, option in pairs(plugin) do
                add(key, option)
            end
        end
    end
    if type(group.args) == "table" then
        for key, option in pairs(group.args) do
            add(key, option)
        end
    end
    local function before(a, b)
        local orderA, orderB = orders[a] or 100, orders[b] or 100
        if orderA == orderB then
            local nameA = type(names[a]) == "string" and names[a] or ""
            local nameB = type(names[b]) == "string" and names[b] or ""
            nameA, nameB = nameA:upper(), nameB:upper()
            if nameA == nameB then
                return tostring(a) < tostring(b)
            end
            return nameA < nameB
        end
        if orderA < 0 then
            if orderB >= 0 then
                return false
            end
        elseif orderB < 0 then
            return true
        end
        return orderA < orderB
    end
    table.sort(keys, before)
    return keys, merged
end

-- ---- entries

local function numberOr(value, default)
    return tonumber(value) or default
end

-- The values of a list: { value, label } in the order the list shows them (its sorting, else by label).
local function choicesOf(ctx, option, path)
    local values = safe(ctx, "values", option, path)
    if type(values) ~= "table" then
        return {}
    end
    local order = option.sorting
    if type(order) == "function" then
        local ok, result = pcall(order, infoFor(ctx, option, path))
        order = ok and result or nil
    end
    local list = {}
    if type(order) == "table" then
        for _, key in ipairs(order) do
            if values[key] ~= nil then
                list[#list + 1] = { value = key, label = Text.plain(values[key]) or tostring(key) }
            end
        end
        return list
    end
    for key, label in pairs(values) do
        list[#list + 1] = { value = key, label = Text.plain(label) or tostring(key) }
    end
    local numeric = true
    for _, choice in ipairs(list) do
        if type(choice.value) ~= "number" then
            numeric = false
        end
    end
    table.sort(list, function(a, b)
        if numeric then
            return a.value < b.value
        end
        local labelA, labelB = a.label:lower(), b.label:lower()
        if labelA == labelB then
            return tostring(a.value) < tostring(b.value)
        end
        return labelA < labelB
    end)
    return list
end

-- One option as the screens use it. entry.type is the option's type; the functions read the option as it is now.
function Options.entry(ctx, option, path)
    local entry = { key = path[#path], option = option, path = path, type = option.type }

    function entry.label()
        local name = safe(ctx, "name", option, path)
        return Text.plain(name) or tostring(entry.key)
    end

    function entry.description()
        return Text.plain((safe(ctx, "desc", option, path)))
    end

    function entry.disabled()
        return isDisabled(ctx, option, path)
    end

    function entry.get(...)
        return safe(ctx, "get", option, path, ...)
    end

    function entry.choices()
        return choicesOf(ctx, option, path)
    end

    -- A slider's limits: min, max, step, bigStep, isPercent.
    function entry.range()
        local min = option.min or (not option.softMin and 0 or nil)
        local max = option.max or (not option.softMax and 100 or nil)
        if min == nil then
            min = option.softMin
        end
        if max == nil then
            max = option.softMax
        end
        return numberOr(min, nil), numberOr(max, nil), numberOr(option.step, nil), numberOr(option.bigStep, nil), option.isPercent == true
    end

    -- Whether the value is allowed (a pattern, a validate function or method). true, or false and why.
    function entry.check(...)
        local value = ...
        if option.type == "input" and type(option.pattern) == "string" and type(value) == "string" then
            if not value:match(option.pattern) then
                return false, entry.label() .. ": " .. (option.usage or ("Expected " .. option.pattern))
            end
        end
        if option.type == "execute" then
            return true
        end
        local ok, result = pcall(member, ctx, "validate", option, path, ...)
        if not ok then
            return false, entry.label()
        end
        if result == nil or result == true then
            return true
        end
        if type(result) == "string" then
            return false, result
        end
        return false, entry.label() .. ": " .. (option.usage or "Invalid Value")
    end

    -- nil when no confirmation is asked, else the text to ask with.
    function entry.confirmText(...)
        local ok, confirm = pcall(member, ctx, "confirm", option, path, ...)
        if not ok then
            return nil
        end
        local text = option.confirmText
        if type(confirm) == "string" then
            return confirm
        end
        if confirm == true then
            if text ~= nil then
                return Text.plain(text)
            end
            local name = entry.label()
            local desc = entry.description()
            if desc ~= nil then
                return name .. " - " .. desc
            end
            return name
        end
        return nil
    end

    -- Sets the value (or runs the button). Returns true, or false and the error.
    function entry.commit(...)
        local name = option.type == "execute" and "func" or "set"
        local ok, err = pcall(member, ctx, name, option, path, ...)
        if not ok then
            return false, err
        end
        return true
    end

    function entry.isGroup()
        return option.type == "group"
    end

    return entry
end

-- The group at a path, nil when the path no longer exists.
function Options.groupAt(ctx, path)
    local group = ctx.root
    for _, key in ipairs(path) do
        group = subOption(group, key)
        if group == nil then
            return nil
        end
    end
    return group
end

-- The visible options of the group at path, in the order AceConfigDialog lists them.
function Options.entries(ctx, path)
    local group = Options.groupAt(ctx, path)
    if group == nil or group.type ~= "group" then
        return {}
    end
    local keys, merged = sortedKeys(ctx, group, path)
    local result = {}
    for _, key in ipairs(keys) do
        local option = merged[key]
        local childPath = copyPath(path, key)
        if not isHidden(ctx, option, childPath) then
            result[#result + 1] = Options.entry(ctx, option, childPath)
        end
    end
    return result
end

-- RestedXP's options table (registered with AceConfig under the addon's title), nil without AceConfig or before the
-- settings exist.
function Options.find(appName)
    local stub = rawget(_G, "LibStub")
    if stub == nil or appName == nil then
        return nil
    end
    local ok, registry = pcall(stub, "AceConfigRegistry-3.0", true)
    if not ok or registry == nil or registry.GetOptionsTable == nil then
        return nil
    end
    local ok2, root = pcall(registry.GetOptionsTable, registry, appName, "dialog", "WowVision")
    if not ok2 or type(root) ~= "table" or root.type ~= "group" then
        return nil
    end
    return Options.context(root, appName)
end
