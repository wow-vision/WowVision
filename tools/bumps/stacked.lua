-- The worst case on stacked floors: how often the object of another floor would be named while the room is unknown.
-- For every indoor object, the player stands 1 yd off its footprint on eight sides and pushes toward it; where the
-- object's room and other rooms lie on that spot (stacked floors), the objects of all those rooms count, as they do
-- with the room unknown, and the tool counts whether the object named is one of another room. With the room known
-- (walked in through a doorway) only its own objects count, so this is the bound, not the usual case.
--
--   luajit tools/bumps/stacked.lua <client> [locale]      (client: era, tbc or forever; from the repo root)

local client, locale = arg[1], arg[2] or "enUS"
assert(client, "usage: luajit tools/bumps/stacked.lua <client> [locale]")
local bumpLogic = dofile("tools/bumps/load.lua")(client)

for _, zone in ipairs(bumpLogic.zones) do
    local ix = bumpLogic.unpack(zone, locale)
    local pushes, stacked, wrong = 0, 0, 0
    local examples = {}
    for i = 1, #ix.ox do
        if ix.oroom[i] ~= 0 then
            local radius = math.sqrt(ix.ohl[i] ^ 2 + ix.ohw[i] ^ 2)
            for k = 0, 7 do
                local a = k * math.pi / 4
                local x, y = ix.ox[i] + math.cos(a) * (radius + 1), ix.oy[i] + math.sin(a) * (radius + 1)
                local qx, qy, d = bumpLogic.objectPoint(ix, i, x, y)
                if d > 0.05 and d <= bumpLogic.REACH then
                    local cands = bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_MARGIN, true)
                    local set, own = {}, false
                    for _, id in ipairs(cands) do
                        set[id] = true
                        own = own or id == ix.oroom[i]
                    end
                    -- only where the player can stand in the object's room (its floor is here)
                    if own then
                        pushes = pushes + 1
                        if #cands > 1 then
                            stacked = stacked + 1
                            local vx, vy = (qx - x) / d, (qy - y) / d
                            local f = bumpLogic.objectAhead(zone, x, y, vx, vy, bumpLogic.REACH, set)
                            if f and ix.oroom[f] ~= ix.oroom[i] then
                                wrong = wrong + 1
                                local key = ix.oname[f] .. " for " .. ix.oname[i]
                                examples[key] = (examples[key] or 0) + 1
                            end
                        end
                    end
                end
            end
        end
    end
    local top = {}
    for key, n in pairs(examples) do
        top[#top + 1] = { key, n }
    end
    table.sort(top, function(a, b)
        return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1])
    end)
    print(string.format("%s: %d pushes, %d on stacked floors (%.0f%%), another floor's object named %d (%.1f%% of all)",
        zone.key, pushes, stacked, 100 * stacked / math.max(1, pushes), wrong, 100 * wrong / math.max(1, pushes)))
    for k = 1, math.min(3, #top) do
        print(string.format("  %s: %d", top[k][1], top[k][2]))
    end
    bumpLogic.pack(zone)
end
