local L = WowVision:getLocale()
local objects = WowVision.objects
local secrets = WowVision.secrets

-- The hearthstone's tooltip: its cooldown and where it takes you.
local Hearthstone = objects:createObjectType("Hearthstone")
Hearthstone:setLabel(L["Hearthstone"])

-- All hearthstones share one cooldown, so the plain Hearthstone item
-- reports it even for a player who carries a different one.
local HEARTHSTONE = 6948

-- Seconds left on the cooldown, 0 when ready. nil when the game hands
-- the cooldown over as a secret: then the line names only the place.
local function remainingCooldown()
    local start, duration = C_Container.GetItemCooldown(HEARTHSTONE)
    if start == nil or secrets.isSecret(start) or secrets.isSecret(duration) then
        return nil
    end
    if duration == 0 then
        return 0
    end
    local remaining = start + duration - GetTime()
    if remaining < 0 then
        return 0
    end
    return remaining
end

Hearthstone:addField({
    key = "ready",
    type = "Bool",
    label = L["Ready"],
    get = function(params)
        local remaining = remainingCooldown()
        if remaining == nil then
            return nil
        end
        return remaining == 0
    end,
})

Hearthstone:addField({
    key = "remaining",
    type = "Time",
    timeType = "duration",
    label = L["Remaining"],
    get = function(params)
        local remaining = remainingCooldown()
        if remaining == nil or remaining == 0 then
            return nil
        end
        return remaining
    end,
})

Hearthstone:addField({
    key = "location",
    type = "String",
    label = L["Bind Location"],
    get = function(params)
        return GetBindLocation()
    end,
})

function Hearthstone:getFocusString(params)
    local ready = self:get(params, "ready")
    if ready == nil then
        return self:renderTemplate("[Hearthstone]: {location}", params)
    end
    if ready then
        return self:renderTemplate("[Hearthstone]: [ready], {location}", params)
    end
    return self:renderTemplate("[Hearthstone]: {remaining}, {location}", params)
end
