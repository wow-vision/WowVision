local devTools = {}

function devTools.tpairs(t)
    local tbl = {}
    for k, _ in pairs(t) do
        tinsert(tbl, k)
    end
    print(table.concat(tbl, "\n"))
end

function devTools.printRegions(element)
    local regions = { element:GetRegions() }
    local tbl = {}
    for i, v in ipairs(regions) do
        local objType = v:GetObjectType()
        if objType == "Texture" then
            tinsert(tbl, "texture " .. tostring(v:GetTexture()))
        elseif objType == "FontString" then
            tinsert(tbl, "FontString " .. tostring(v:GetText()))
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

function WowVision:globalizeDevTools()
    for k, v in pairs(devTools) do
        _G[k] = v
    end
end
