local L = WowVision:getLocale()
local objects = WowVision.objects

local GameClock = objects:createObjectType("GameClock")
GameClock:setLabel(L["Clock"])

-- The minimap clock's own text: realm or local time and 12 or 24 hours,
-- whichever the player picked in the game's clock settings.
GameClock:addField({
    key = "time",
    type = "String",
    label = L["Time"],
    get = function(params)
        return GameTime_GetTime(true)
    end,
})

GameClock:registerTemplate({
    key = "default",
    name = "Default",
    format = "[Time]: {time}",
})
