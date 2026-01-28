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
            { key = "warrior", label = "Warrior", value = 1 },
            { key = "mage", label = "Mage", value = 2 },
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
                        { key = "warrior", label = "Warrior", value = "warrior" },
                        { key = "mage", label = "Mage", value = "mage" },
                        { key = "rogue", label = "Rogue", value = "rogue" },
                        { key = "priest", label = "Priest", value = "priest" },
                    },
                },
            },
        },
    },
})

function devTools.testArrayInfo(obj)
    obj = obj or {
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

function WowVision:globalizeDevTools()
    for k, v in pairs(devTools) do
        _G[k] = v
    end
end
