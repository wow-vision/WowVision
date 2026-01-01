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

function WowVision:globalizeDevTools()
    for k, v in pairs(devTools) do
        _G[k] = v
    end
end
