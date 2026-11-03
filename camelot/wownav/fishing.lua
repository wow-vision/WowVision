-- The fishing spots of Broesel's WowNav core in WowVision: his FishingNavigation.lua (engine/) with what his core
-- (the arrival in OnUpdate, the passive beacon, WowVisionNavigationAlignmentTarget) does around it. A fishing spot is
-- a dyn target (kind "fishing_spot"): a standing point on the shore or on a pier, and the direction to the water.
--
-- - Choosing a fishing spot routes to its standing point like to any place.
-- - Arrived, his text says where the water lies and the cast range, and a beacon sounds from the water point (15 yd
--   out, the middle of the cast range). It never ends by being reached: nobody walks into the water. It ends when the
--   player leaves the place (the disc of the cast range around the standing point), with a new route or Shift-F12.
-- - On the place, the turn key (I) faces the water.
--
-- What WowVision adds: the arrival counts only when the player stands on the place; where the network ended farther
-- from the spot, the normal text says how far (module.lua), and no beacon starts.

local dock = WowVision.wownavDock

local fishing = {}
WowVision.wownavFishing = fishing

local function F()
    return _G.WowVisionNavigationFishingNavigation
end

-- The fishing spot a route request goes to: the full row of the dyn catalogue and the nav of its zone, or nil when
-- the request's target is no valid fishing spot.
function fishing.spot(N, contract)
    if type(contract) ~= "table" or contract.kind ~= "fishing_spot" or F() == nil then
        return nil
    end
    local nav = dock.nav(N, nil)
    local spot = nav ~= nil and F():Find(nav, contract.id) or nil
    if spot == nil then
        return nil
    end
    return spot, dock.nav(N, spot.zoneId)
end

-- The route reached a fishing spot: his Arrival (the text) when the player stands on the place; radius is the
-- arrival radius of a target position. True when it was said (the beacon to the water then follows).
function fishing.arrived(N, contract, x, y, radius)
    local spot, nav = fishing.spot(N, contract)
    if spot == nil or x == nil then
        return false
    end
    local place = math.max(radius, spot.fishingCastMax)
    if (x - spot.x) ^ 2 + (y - spot.y) ^ 2 > place * place then
        return false
    end
    return F():Arrival(spot, nav, x, y, radius)
end

-- The point the turn key faces without a route (his AlignmentTarget): the water of the fishing spot the player stands
-- on. Returns x, y, id or nil.
function fishing.alignment(N, x, y)
    local Fishing = F()
    local context = Fishing ~= nil and Fishing.reached or nil
    if context == nil or x == nil then
        return nil
    end
    local nav = dock.nav(N, context.zoneId)
    if nav == nil then
        return nil
    end
    local id, px, py = Fishing:AlignmentTarget(x, y, nav)
    if id == nil then
        return nil
    end
    return px, py, id
end

function fishing.reached()
    return F() ~= nil and F().reached ~= nil
end

function fishing.reset()
    if F() ~= nil then
        F():Reset()
    end
end

-- His direction tone after the arrival (Fishing:BeaconTarget): a beacon to the water point that is never reached;
-- it ends when the player leaves the place. nil in the headless tests (no beacon there).
function fishing.waterPath(N)
    if dock.PointPath == nil then
        return nil
    end
    return dock.PointPath:new(function(x, y)
        local Fishing = F()
        local context = Fishing.reached
        if context == nil then
            return nil
        end
        local nav = dock.nav(N, context.zoneId)
        if nav == nil then
            return nil
        end
        local id, px, py = Fishing:BeaconTarget(x, y, nav)
        if id == nil then
            return nil
        end
        return px, py, false
    end, function() end)
end
