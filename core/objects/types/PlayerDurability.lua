local L = WowVision:getLocale()
local objects = WowVision.objects

-- Repair state of the equipped items, from the durability every item
-- tooltip shows: the most worn item and how many are broken.
local PlayerDurability = objects:createObjectType("PlayerDurability")
PlayerDurability:setLabel(L["Durability"])

-- Calls back with (current, maximum) for every equipped item that has
-- durability at all (rings, trinkets and empty slots have none).
local function forEachDurability(callback)
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local current, maximum = GetInventoryItemDurability(slot)
        if current ~= nil and maximum ~= nil and maximum > 0 then
            callback(current, maximum)
        end
    end
end

-- Percent of the most worn item, rounded down so a nearly full item
-- never reads as 100. nil when nothing equipped has durability.
PlayerDurability:addField({
    key = "lowest",
    type = "Number",
    label = L["Lowest Item"],
    get = function(params)
        local lowest = nil
        forEachDurability(function(current, maximum)
            local percent = math.floor(current / maximum * 100)
            if lowest == nil or percent < lowest then
                lowest = percent
            end
        end)
        return lowest
    end,
})

PlayerDurability:addField({
    key = "broken",
    type = "Number",
    label = L["Broken"],
    get = function(params)
        local broken = 0
        forEachDurability(function(current, maximum)
            if current == 0 then
                broken = broken + 1
            end
        end)
        return broken
    end,
})

function PlayerDurability:getFocusString(params)
    local lowest = self:get(params, "lowest")
    if lowest == nil then
        return self:renderTemplate("[Durability]: [no items]", params)
    end
    if self:get(params, "broken") > 0 then
        return self:renderTemplate("[Durability]: [lowest item] {lowest}%, {broken} [broken]", params)
    end
    if lowest >= 100 then
        return self:renderTemplate("[Durability]: {lowest}%", params)
    end
    return self:renderTemplate("[Durability]: [lowest item] {lowest}%", params)
end
