-- What a zone costs: the memory its index takes once unpacked (entering the zone) and the time the unpack and a
-- lookup take, per zone of a client. LuaJIT with its JIT off (`luajit -joff`) is closer to the game's Lua.
--
--   luajit [-joff] tools/bumps/cost.lua <client> [locale]      (from the repo root)

local client, locale = arg[1], arg[2] or "enUS"
assert(client, "usage: luajit tools/bumps/cost.lua <client> [locale]")
local bumpLogic = dofile("tools/bumps/load.lua")(client)

local function full()
    collectgarbage()
    collectgarbage()
    return collectgarbage("count")
end

for _, zone in ipairs(bumpLogic.zones) do
    local before = full()
    local t0 = os.clock()
    local ix = bumpLogic.unpack(zone, locale)
    local unpackMs = (os.clock() - t0) * 1000
    local mb = (full() - before) / 1024
    -- a lookup beside every fifth object, pushing east
    local n = 0
    t0 = os.clock()
    for i = 1, #ix.ox, 5 do
        n = n + 1
        bumpLogic.objectAhead(zone, ix.ox[i] - 1, ix.oy[i], 1, 0, bumpLogic.REACH, 0)
    end
    local lookupMs = (os.clock() - t0) * 1000 / math.max(1, n)
    print(string.format("%s: %d objects, %d rooms; index %.1f MB, unpack %.0f ms, lookup %.3f ms",
        zone.key, #ix.ox, #ix.rooms, mb, unpackMs, lookupMs))
    bumpLogic.pack(zone)
end
