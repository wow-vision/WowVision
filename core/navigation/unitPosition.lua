-- Where the game puts a unit now, in the same world frame as the player: x, y, or nil when the game does not say
-- (a loading screen, an instance the API cannot place, a secret value), when a coordinate is no finite number, or
-- when the unit is on another map than the player (its coordinates would be in that map's frame, so distance and
-- direction from here would be nonsense). Shared by the scanner's group members and the route to the target.
-- api: the game reads (tests pass fakes).
local function usable(value)
    return type(value) == "number"
        and not (WowVision.isSecret ~= nil and WowVision.isSecret(value))
        and value == value
        and math.abs(value) < math.huge
end

function WowVision.unitPosition(unit, api)
    api = api or _G
    local read = api.UnitPosition
    if read == nil then
        return nil
    end
    local ok, x, y, _, map = pcall(read, unit)
    if not ok or not usable(x) or not usable(y) then
        return nil
    end
    if map ~= nil and unit ~= "player" then
        local okPlayer, px, _, _, playerMap = pcall(read, "player")
        if okPlayer and px ~= nil and playerMap ~= nil then
            local okCompare, differs = pcall(function()
                return map ~= playerMap
            end)
            if not okCompare or differs then
                return nil
            end
        end
    end
    return x, y
end
