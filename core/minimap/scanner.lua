local module = WowVision.base.minimap
local scanner = WowVision.base.scanner
local L = module.L

-- The scanner's Gathering category: nodes the minimap scanner placed this
-- session, one subcategory per tracking spell ("Find Herbs", "Find
-- Minerals", named by the game), plus names it could not sort when the
-- gathering sort is switched off. Hidden while there is nothing. The
-- Points of Interest category below holds the town markers.
-- Quest givers and other NPCs feed the Quests and NPCs categories instead
-- (see module.lua).

-- One category's entries around the player, nearest first, capped.
local function entryNodes(category, ctx)
    local px, py, _, continent = UnitPosition("player")
    local out = {}
    if px == nil then
        return out
    end
    for _, near in ipairs(module.store:around(px, py, continent, ctx.radius, category)) do
        local entry = near.entry
        tinsert(out, {
            key = "seen:" .. entry.id,
            label = entry.name,
            detail = entry.indoors and (L["seen"] .. ", " .. L["indoors"]) or L["seen"],
            x = entry.wx,
            y = entry.wy,
        })
        if #out >= ctx.maxEntries then
            break
        end
    end
    return out
end

scanner:registerProvider({
    key = "gathering",
    label = L["Gathering"],
    order = 30,
    optional = true,
    build = function(ctx)
        local out, seen = {}, {}
        for _, entry in ipairs(module.store.entries) do
            local category = entry.category
            if not seen[category] and (category == "unsorted" or category:sub(1, 6) == "spell:") then
                seen[category] = true
                if #entryNodes(category, ctx) > 0 then
                    tinsert(out, {
                        key = category,
                        label = module:categoryLabel(category),
                        children = function()
                            return entryNodes(category, ctx)
                        end,
                    })
                end
            end
        end
        return out
    end,
})

-- Points of interest: the towns and landmarks whose arrows the last scan
-- saw on the minimap (tracking type POI), such as Goldshire and Stormwind.
-- Names only, like a glance at the map: the arrows give no position (see
-- module.places).
scanner:registerProvider({
    key = "poi",
    label = L["Points of Interest"],
    order = 25,
    optional = true,
    build = function()
        local out = {}
        for _, name in ipairs(module.places) do
            tinsert(out, { key = "poi:" .. name, label = name })
        end
        return out
    end,
})
