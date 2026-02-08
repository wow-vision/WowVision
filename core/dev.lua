local devTools = {}

function devTools.tpairs(t)
    local tbl = {}
    for k, _ in pairs(t) do
        tinsert(tbl, k)
    end
    print(table.concat(tbl, "\n"))
end

function devTools.printRegions(element, regionType)
    local regions = { element:GetRegions() }
    local tbl = {}
    for i, v in ipairs(regions) do
        local objType = v:GetObjectType()
        if (regionType ~= nil and objType == regionType) or regionType == nil then
            local result
            if objType == "Texture" then
                result = "texture " .. tostring(v:GetTexture())
            elseif objType == "FontString" then
                result = "FontString " .. tostring(v:GetText())
            end
            if result then
                local name = v:GetName()
                if name then
                    result = result .. " name " .. name
                end
                tinsert(tbl, result)
            end
        end
    end
    print(table.concat(tbl, "\n"))
end

local function tString(obj, depth)
    local depth = depth or 2
    if depth < 1 then
        return ""
    end
    local builder = {}
    for k, v in pairs(obj) do
        if type(v) == "table" then
            tinsert(builder, k .. " = " .. tString(v, depth - 1))
        else
            tinsert(builder, k .. " = " .. tostring(v))
        end
    end
    return "table begin\n" .. table.concat(builder, "\n") .. "\ntable end"
end

function devTools.tprint(obj, depth)
    print(tString(obj, depth))
end

local info = WowVision.info.InfoManager:new()
info:addFields({
    { type = "String", key = "name", label = "name", default = "Bob" },
    { type = "Number", key = "age", label = "age", default = 25 },
    {
        type = "Choice",
        key = "class",
        label = "Class",
        choices = {
            { label = "Warrior", value = 1 },
            { label = "Mage", value = 2 },
        },
    },
})

function devTools.testInfo(obj)
    local root = info:getGenerator(obj)
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
end

-- Array field test with people (name, age, class)
local arrayInfo = WowVision.info.InfoManager:new()
arrayInfo:addFields({
    {
        type = "Array",
        key = "people",
        label = "People",
        elementField = {
            type = "Category",
            label = "Person",
            fields = {
                { type = "String", key = "name", label = "Name", default = "New Person" },
                { type = "Number", key = "age", label = "Age", default = 25, minimum = 0, maximum = 150 },
                {
                    type = "Choice",
                    key = "class",
                    label = "Class",
                    choices = {
                        { label = "Warrior", value = "warrior" },
                        { label = "Mage", value = "mage" },
                        { label = "Rogue", value = "rogue" },
                        { label = "Priest", value = "priest" },
                    },
                },
            },
        },
    },
})

function devTools.testArrayInfo(obj)
    obj = obj
        or {
            people = {
                { name = "Alice", age = 30, class = "mage" },
                { name = "Bob", age = 25, class = "warrior" },
            },
        }
    local root = arrayInfo:getGenerator(obj)
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
    return obj
end

-- Object field test
local objectInfo = WowVision.info.InfoManager:new()
objectInfo:addFields({
    {
        type = "Object",
        key = "trackedObject",
        label = "Tracked Object",
    },
})

function devTools.testObjectInfo(obj)
    obj = obj or {
        trackedObject = { type = "Health", params = { unit = "player" } },
    }
    local root = objectInfo:getGenerator(obj)
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
    return obj
end

-- TrackingConfig field test
local trackingConfigInfo = WowVision.info.InfoManager:new()
trackingConfigInfo:addFields({
    {
        type = "TrackingConfig",
        key = "source",
        label = "Tracking Source",
    },
})

function devTools.testTrackingConfigInfo(obj)
    obj = obj or {
        source = { type = "Health", units = { "player" } },
    }
    local root = trackingConfigInfo:getGenerator(obj)
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
    return obj
end

-- Tracking generator test
function devTools.testTrackingGenerator(typeKey, config)
    typeKey = typeKey or "Health"
    local objectType = WowVision.objects.types:get(typeKey)
    if not objectType then
        print("Unknown object type: " .. typeKey)
        return
    end

    local gen, trackingConfig = objectType:getTrackingGenerator(config)
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = gen,
        hookEscape = true,
    })
    return trackingConfig
end

-- Lazily register virtual elements for tracking config UI
local trackingConfigElementsRegistered = false
local function ensureTrackingConfigElements()
    if trackingConfigElementsRegistered then
        return
    end
    trackingConfigElementsRegistered = true

    local gen = WowVision.ui.generator
    local L = WowVision:getLocale()

    gen:Element("TrackingConfig/editor", function(props)
        local config = props.config
        local children = {}

        -- Type selector button
        local typeLabel = config.type and (WowVision.objects.types:get(config.type).label or config.type) or L["None"]
        tinsert(children, {
            "Button",
            key = "type",
            label = L["Type"] .. ": " .. typeLabel,
            events = {
                click = function(event, button)
                    button.context:addGenerated({
                        "TrackingConfig/typeSelector",
                        config = config,
                    })
                end,
            },
        })

        -- Show tracking parameters if type is selected
        if config.type then
            local objectType = WowVision.objects.types:get(config.type)
            if objectType then
                local trackingGen, _ = objectType:getTrackingGenerator(config)
                trackingGen.key = "tracking"
                tinsert(children, trackingGen)
            end
        end

        return {
            "List",
            label = "Tracking Config",
            children = children,
        }
    end)

    gen:Element("TrackingConfig/typeSelector", function(props)
        local config = props.config
        local children = {}

        -- "None" option
        tinsert(children, {
            "Button",
            key = "none",
            label = L["None"],
            events = {
                click = function(event, button)
                    config.type = nil
                    button.context:pop()
                end,
            },
        })

        -- Add all registered object types
        for _, objectType in ipairs(WowVision.objects.types.items) do
            tinsert(children, {
                "Button",
                key = objectType.key,
                label = objectType.label or objectType.key,
                events = {
                    click = function(event, button)
                        -- Reset config when type changes
                        local newType = objectType.key
                        for k in pairs(config) do
                            config[k] = nil
                        end
                        config.type = newType
                        button.context:pop()
                    end,
                },
            })
        end

        return {
            "List",
            label = L["Select Type"],
            children = children,
        }
    end)
end

-- Test with unified type selector and parameters panel
function devTools.testTrackingGeneratorWithSelector(config)
    ensureTrackingConfigElements()

    config = config or {}

    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = {
            "TrackingConfig/editor",
            config = config,
        },
        hookEscape = true,
    })

    return config
end

-- Buffer management test
function devTools.testBufferGroup(group)
    group = group or WowVision.buffers.BufferGroup:new({
        label = "Test Group",
    })

    -- Add some sample buffers if empty
    if #group.items == 0 then
        group:add(WowVision.buffers:create("Static", {
            label = "General Info",
            objects = {
                { type = "Health", params = { unit = "player" } },
                { type = "PlayerMoney" },
            },
        }))
        group:add(WowVision.buffers:create("Tracked", {
            label = "Player Powers",
            source = { type = "Power", units = { "player" } },
        }))
    end

    local gen = group:getSettingsGenerator()
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = gen,
        hookEscape = true,
    })

    return group
end

-- Test individual buffer settings
function devTools.testBufferSettings(buffer)
    buffer = buffer
        or WowVision.buffers:create("Static", {
            label = "Test Buffer",
            objects = {
                { type = "Health", params = { unit = "player" } },
            },
        })

    local gen = buffer:getSettingsGenerator()
    WowVision.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = gen,
        hookEscape = true,
    })

    return buffer
end

function WowVision:globalizeDevTools()
    for k, v in pairs(devTools) do
        _G[k] = v
    end
end
