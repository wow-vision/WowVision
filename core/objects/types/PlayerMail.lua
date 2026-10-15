local L = WowVision:getLocale()
local objects = WowVision.objects

-- What the minimap mail icon and its tooltip show: unread mail waiting,
-- and the names of up to three of its senders when the game knows them.
local PlayerMail = objects:createObjectType("PlayerMail")
PlayerMail:setLabel(L["Mail"])

PlayerMail:addField({
    key = "unread",
    type = "Bool",
    label = L["Unread"],
    get = function(params)
        return HasNewMail() == true
    end,
})

PlayerMail:addField({
    key = "senders",
    type = "String",
    label = L["Senders"],
    get = function(params)
        local senders = { GetLatestThreeSenders() }
        if #senders == 0 then
            return nil
        end
        return table.concat(senders, ", ")
    end,
})

function PlayerMail:getFocusString(params)
    if not self:get(params, "unread") then
        return self:renderTemplate("[Mail]: [none]", params)
    end
    if self:get(params, "senders") == nil then
        return self:renderTemplate("[New mail]", params)
    end
    return self:renderTemplate("[Mail from] {senders}", params)
end
