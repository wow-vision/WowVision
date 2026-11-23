-- Loads core/navigation/bumpLogic.lua and one client's bump data (mapdata/bumps/<client>/) outside the game, for the
-- other tools of this folder. Run them from the repo root:
--   local bumps = dofile("tools/bumps/load.lua")("tbc")
-- returns WowVision.bumpLogic with bumpLogic.zones holding that client's zones (registered, not unpacked).

return function(client)
    WowVision = WowVision or {}
    dofile("core/navigation/bumpLogic.lua")
    local bumpLogic = WowVision.bumpLogic
    local base = "mapdata/bumps/" .. client .. "/"
    local xml = io.open(base .. "data.xml", "r")
    assert(xml, "no bump data for " .. tostring(client) .. " (" .. base .. "data.xml)")
    local text = xml:read("*a")
    xml:close()
    for name in text:gmatch('<Script file="([^"]+)"') do
        dofile(base .. name)
    end
    return bumpLogic
end
