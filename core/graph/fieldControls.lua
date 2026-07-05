local graph = WowVision.graph
local settings = graph.settings
local nodes = graph.nodes
local ControlId = graph.ControlId
local L = WowVision:getLocale()

-- Graph controls for the remaining field types, mirroring each type's old
-- element generator. Registered into settings' field-control dispatch, so
-- they appear anywhere fields render: module settings, component editors,
-- object parameters.

local function getterOf(owner, field)
    return function()
        return field:get(owner)
    end
end

local function setterOf(owner, field)
    return function(value)
        field:set(owner, value)
    end
end

local function valueTextOf(owner, field)
    return function()
        return field:getValueString(owner, field:get(owner))
    end
end

-- Time: a Number wearing duration formatting. Arrows adjust in seconds;
-- typed entry takes raw seconds; readouts speak the formatted duration.
settings.registerFieldControl("Time", function(field, owner)
    return nodes.number({
        label = field:getLabel(),
        get = getterOf(owner, field),
        set = setterOf(owner, field),
        valueText = valueTextOf(owner, field),
    })
end)

-- VoicePack: a choice over the registered voice packs.
settings.registerFieldControl("VoicePack", function(field, owner)
    return nodes.choice({
        label = field:getLabel(),
        get = getterOf(owner, field),
        set = setterOf(owner, field),
        choices = function()
            local result = {}
            local voicePacks = WowVision.audio.packs:get("Voice")
            for _, pack in ipairs(voicePacks.packs.items) do
                tinsert(result, { label = pack:getLabel(), value = pack.key })
            end
            return result
        end,
        valueText = valueTextOf(owner, field),
    })
end)

-- Spell: typed entry resolving a name or id (the field's validate does the
-- lookup), plus the recent-spell history as quick picks.
settings.registerFieldControl("Spell", function(field, owner)
    local valueText = valueTextOf(owner, field)
    return nodes.button({
        label = field:getLabel(),
        value = valueText,
        onActivate = function()
            settings.pushScreen("spell:" .. field.key, function(builder)
                builder:pushContext(field:getLabel() or field.key)
                builder:addItem(
                    ControlId.structural("entry"),
                    nodes.button({
                        label = L["Spell Name"],
                        onActivate = function()
                            WowVision.graphHost:openTextEntry({
                                label = field:getLabel(),
                                text = "",
                                onCommit = function(text)
                                    local resolved = field:validate(text)
                                    if resolved ~= nil then
                                        field:set(owner, resolved)
                                        WowVision:speak(valueText() or "")
                                        local host = WowVision.graphHost
                                        host:pop(host:focusedStack())
                                    else
                                        WowVision:speak(L["Not Found"])
                                    end
                                end,
                            })
                        end,
                    })
                )
                local history = WowVision.spellHistory
                if history ~= nil then
                    local sorted = {}
                    for spellID, entry in pairs(history.spells) do
                        tinsert(sorted, { spellID = spellID, name = entry.name })
                    end
                    table.sort(sorted, function(a, b)
                        return a.name < b.name
                    end)
                    for _, spell in ipairs(sorted) do
                        local spellID = spell.spellID
                        builder:addItem(
                            ControlId.structural("spell:" .. spellID),
                            nodes.button({
                                label = spell.name .. " (" .. spellID .. ")",
                                onActivate = function()
                                    field:set(owner, spellID)
                                    local host = WowVision.graphHost
                                    host:pop(host:focusedStack())
                                end,
                            })
                        )
                    end
                end
                builder:popContext()
            end)
        end,
    })
end)

-- Alert: its parameters are an InfoFrame; open them as a child screen.
settings.registerFieldControl("Alert", function(field, owner)
    return nodes.button({
        label = field:getLabel(),
        onActivate = function()
            local alert = field:getAlert(owner)
            settings.pushScreen("alert:" .. field.key, function(builder)
                settings.renderInto(builder, alert.parameters)
            end)
        end,
    })
end)

-- Template: pick a registered template, or Custom for a typed format string
-- (empty reverts to the default).
settings.registerFieldControl("Template", function(field, owner)
    local valueText = valueTextOf(owner, field)
    return nodes.button({
        label = field:getLabel(),
        value = valueText,
        onActivate = function()
            settings.pushScreen("template:" .. field.key, function(builder)
                builder:pushContext(field:getLabel() or field.key)
                local templates = field:getAvailableTemplates(owner)
                if templates ~= nil then
                    for _, template in ipairs(templates.items) do
                        local templateKey = template.key
                        builder:addItem(
                            ControlId.structural("template:" .. templateKey),
                            nodes.button({
                                label = template.name,
                                onActivate = function()
                                    field:set(owner, { key = templateKey })
                                    local host = WowVision.graphHost
                                    host:pop(host:focusedStack())
                                end,
                            })
                        )
                    end
                end
                builder:addItem(
                    ControlId.structural("custom"),
                    nodes.button({
                        label = L["Custom"],
                        onActivate = function()
                            local current = field:get(owner)
                            WowVision.graphHost:openTextEntry({
                                label = L["Format"],
                                text = current ~= nil and current.format or "",
                                onCommit = function(text)
                                    if text ~= nil and text ~= "" then
                                        field:set(owner, { format = text })
                                    else
                                        field:set(owner, nil)
                                    end
                                    WowVision:speak(valueText() or "")
                                    local host = WowVision.graphHost
                                    host:pop(host:focusedStack())
                                end,
                            })
                        end,
                    })
                )
                builder:popContext()
            end)
        end,
    })
end)

-- Object: an editor with a type choice and the type's parameter fields
-- inline, writing through the field's params proxy.
local function objectTypeChoices()
    local result = { { label = L["None"] } }
    for _, objectType in ipairs(WowVision.objects.types.items) do
        tinsert(result, { label = objectType.label or objectType.key, value = objectType.key })
    end
    return result
end

settings.registerFieldControl("Object", function(field, owner)
    local valueText = valueTextOf(owner, field)
    return nodes.button({
        label = field:getLabel(),
        value = valueText,
        onActivate = function()
            settings.pushScreen("object:" .. field.key, function(builder)
                builder:pushContext(field:getLabel() or field.key)
                builder:addItem(
                    ControlId.structural("type"),
                    nodes.choice({
                        label = L["Type"],
                        get = function()
                            local value = field:get(owner)
                            return value ~= nil and value.type or nil
                        end,
                        set = function(typeKey)
                            field:setType(owner, typeKey)
                        end,
                        choices = objectTypeChoices,
                        valueText = valueText,
                    })
                )
                local value = field:get(owner)
                local objectType = value ~= nil and value.type ~= nil and WowVision.objects.types:get(value.type)
                    or nil
                if objectType ~= nil and objectType.parameters ~= nil and #objectType.parameters.fields > 0 then
                    local proxy = field:createParamsProxy(owner)
                    builder:pushContext(L["Parameters"])
                    for _, paramField in ipairs(objectType.parameters.fields) do
                        if paramField.showInUI then
                            builder:addItem(
                                ControlId.structural("param:" .. paramField.key),
                                settings.controlFor(paramField, proxy)
                            )
                        end
                    end
                    builder:popContext()
                end
                builder:popContext()
            end)
        end,
    })
end)

-- TrackingConfig: type choice plus a parameters screen that edits a copy and
-- validates on Save, like the old editor.
local function buildParamsFromConfig(config)
    local params = {}
    if config.units ~= nil and config.units[1] ~= nil then
        params.unit = config.units[1]
    end
    if config.params ~= nil then
        for k, v in pairs(config.params) do
            params[k] = v
        end
    end
    return params
end

local function pushTrackingParams(field, owner, objectType)
    -- Edited as a copy; nothing applies until Save validates.
    local editCopy = WowVision.info.deepCopy(field:get(owner) or { type = nil })
    editCopy.params = editCopy.params or {}

    settings.pushScreen("trackingParams:" .. field.key, function(builder)
        builder:pushContext(L["Parameters"])
        for _, paramField in ipairs(objectType.parameters.fields) do
            if paramField.key == "unit" then
                builder:addItem(
                    ControlId.structural("unit"),
                    nodes.textInput({
                        label = L["Unit"],
                        get = function()
                            return editCopy.unit or (editCopy.units ~= nil and editCopy.units[1]) or "player"
                        end,
                        set = function(value)
                            editCopy.unit = value
                            editCopy.units = { value }
                        end,
                    })
                )
            elseif paramField.showInUI then
                builder:addItem(
                    ControlId.structural("param:" .. paramField.key),
                    settings.controlFor(paramField, editCopy.params)
                )
            end
        end
        builder:addItem(
            ControlId.structural("save"),
            nodes.button({
                label = L["Save"],
                onActivate = function()
                    if editCopy.unit ~= nil then
                        editCopy.units = { editCopy.unit }
                    end
                    local params = buildParamsFromConfig(editCopy)
                    local valid, unique = objectType:validParams(params)
                    if not valid then
                        WowVision:speak(L["Invalid parameters"])
                        return
                    end
                    if field.requireUnique and not unique then
                        WowVision:speak(L["Parameters must identify a single object"])
                        return
                    end
                    field:set(owner, editCopy)
                    local host = WowVision.graphHost
                    host:pop(host:focusedStack())
                end,
            })
        )
        builder:popContext()
    end)
end

settings.registerFieldControl("TrackingConfig", function(field, owner)
    local valueText = valueTextOf(owner, field)
    return nodes.button({
        label = field:getLabel(),
        value = valueText,
        onActivate = function()
            settings.pushScreen("tracking:" .. field.key, function(builder)
                builder:pushContext(field:getLabel() or field.key)
                builder:addItem(
                    ControlId.structural("type"),
                    nodes.choice({
                        label = L["Type"],
                        get = function()
                            local value = field:get(owner)
                            return value ~= nil and value.type or nil
                        end,
                        set = function(typeKey)
                            field:setType(owner, typeKey)
                        end,
                        choices = objectTypeChoices,
                        valueText = valueText,
                    })
                )
                local value = field:get(owner)
                local objectType = value ~= nil and value.type ~= nil and WowVision.objects.types:get(value.type)
                    or nil
                if objectType ~= nil and objectType.parameters ~= nil and #objectType.parameters.fields > 0 then
                    builder:addItem(
                        ControlId.structural("params"),
                        nodes.button({
                            label = L["Parameters"],
                            onActivate = function()
                                pushTrackingParams(field, owner, objectType)
                            end,
                        })
                    )
                end
                builder:popContext()
            end)
        end,
    })
end)

-- DataBrowse: pick a path from a data directory (the sound and beacon
-- pickers). Subdirectories push deeper screens; entries preview on focus and
-- select on Enter, unwinding back to the field.
local function directoryLabel(directory)
    if directory.getLabel ~= nil then
        return directory:getLabel()
    end
    return directory.label or directory.key or ""
end

local function pushBrowse(field, owner, directory, segments)
    settings.pushScreen("browse:" .. tostring(directory.key or "root"), function(builder)
        builder:pushContext(directoryLabel(directory))
        for _, subdirectory in ipairs(directory.subdirectories) do
            local captured = subdirectory
            builder:addItem(
                ControlId.structural("dir:" .. tostring(captured.key)),
                nodes.button({
                    label = directoryLabel(captured),
                    onActivate = function()
                        local deeper = {}
                        for _, segment in ipairs(segments) do
                            tinsert(deeper, segment)
                        end
                        tinsert(deeper, captured.key)
                        pushBrowse(field, owner, captured, deeper)
                    end,
                })
            )
        end
        for _, entry in ipairs(directory.entries) do
            local captured = entry
            local vtable = nodes.button({
                label = function()
                    if captured.getLabel ~= nil then
                        return captured:getLabel()
                    end
                    return tostring(captured.key)
                end,
                onActivate = function()
                    local parts = {}
                    for _, segment in ipairs(segments) do
                        tinsert(parts, segment)
                    end
                    tinsert(parts, captured.key)
                    field:set(owner, table.concat(parts, "/"))
                    -- Unwind every browse level; the revealed field button
                    -- re-announces with the new value.
                    local host = WowVision.graphHost
                    for _ = 1, #segments + 1 do
                        host:pop(host:focusedStack())
                    end
                end,
            })
            vtable.onFocus = function()
                if captured.preview ~= nil then
                    captured:preview()
                end
            end
            builder:addItem(ControlId.structural("entry:" .. tostring(captured.key)), vtable)
        end
        builder:popContext()
    end)
end

settings.registerFieldControl("DataBrowse", function(field, owner)
    return nodes.button({
        label = field:getLabel(),
        value = valueTextOf(owner, field),
        onActivate = function()
            local directory = field:getDirectory(owner)
            if directory ~= nil then
                pushBrowse(field, owner, directory, {})
            end
        end,
    })
end)

-- Array: rows of element editor plus Remove, and Add appending the element
-- default. Elements edit through the field's index proxies.
settings.registerFieldControl("Array", function(field, owner)
    return nodes.button({
        label = function()
            return (field:getLabel() or field.key) .. " (" .. field:getLength(owner) .. ")"
        end,
        onActivate = function()
            settings.pushScreen("array:" .. field.key, function(builder)
                builder:pushContext(field:getLabel() or field.key)
                local elementField = field:getElementField()
                local length = field:getLength(owner)
                for i = 1, length do
                    local index = i
                    local proxy = field:createElementProxy(owner, index)
                    builder:startRow()
                    builder:addItem(
                        ControlId.structural("item:" .. index),
                        settings.controlFor(elementField, proxy)
                    )
                    builder:addItem(
                        ControlId.structural("item:" .. index .. ":remove"),
                        nodes.button({
                            label = L["Remove"],
                            onActivate = function()
                                field:removeElement(owner, index)
                            end,
                        })
                    )
                    builder:endRow()
                end
                builder:addItem(
                    ControlId.structural("add"),
                    nodes.button({
                        label = L["Add"],
                        onActivate = function()
                            field:addElement(owner, field:getElementField():getDefault({}))
                        end,
                    })
                )
                builder:popContext()
            end)
        end,
    })
end)
