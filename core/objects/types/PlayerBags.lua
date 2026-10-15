local L = WowVision:getLocale()
local objects = WowVision.objects

local PlayerBags = objects:createObjectType("PlayerBags")
PlayerBags:setLabel(L["Bags"])

-- Free slots in plain bags only: quivers, ammo pouches, soul and
-- profession bags take one kind of item, so their space is left out.
-- That is the count Blizzard's backpack button shows.
PlayerBags:addField({
    key = "free",
    type = "Number",
    label = L["Free Slots"],
    get = function(params)
        local free = 0
        for bag = 0, NUM_BAG_SLOTS do
            local slots, family = C_Container.GetContainerNumFreeSlots(bag)
            if family == 0 then
                free = free + slots
            end
        end
        return free
    end,
})

PlayerBags:registerTemplate({
    key = "default",
    name = "Default",
    format = "[Free Bag Slots]: {free}",
})
