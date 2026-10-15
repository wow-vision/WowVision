local testRunner = WowVision.testing.testRunner
local objects = WowVision.objects
local L = WowVision:getLocale()

-- Swaps the named game globals for stand-ins during one test and puts the
-- real ones back afterwards, also when the test fails.
local function withGame(stubs, fn)
    return function(t)
        local saved = {}
        for name, value in pairs(stubs) do
            saved[name] = _G[name]
            _G[name] = value
        end
        local ok, err = pcall(fn, t)
        for name in pairs(stubs) do
            _G[name] = saved[name]
        end
        if not ok then
            error(err, 0)
        end
    end
end

local function line(typeKey)
    return objects:create(typeKey, {}):getFocusString()
end

local function durabilities(list)
    return function(slot)
        local entry = list[slot]
        if entry == nil then
            return nil
        end
        return entry[1], entry[2]
    end
end

local equipSlots = { INVSLOT_FIRST_EQUIPPED = 1, INVSLOT_LAST_EQUIPPED = 19 }

local function merge(a, b)
    local result = {}
    for k, v in pairs(a) do
        result[k] = v
    end
    for k, v in pairs(b) do
        result[k] = v
    end
    return result
end

local xpLine = L["XP"] .. ": 50% (12500 " .. L["of"] .. " 25000 " .. L["to level"] .. " 31)"

local xpGame = {
    UnitXP = function()
        return 12500
    end,
    UnitXPMax = function()
        return 25000
    end,
    UnitLevel = function()
        return 30
    end,
    GetMaxPlayerLevel = function()
        return 60
    end,
    IsXPUserDisabled = function()
        return false
    end,
}

testRunner:addSuite("GeneralBufferLines", {
    ["bags count only plain bags"] = withGame({
        NUM_BAG_SLOTS = 4,
        C_Container = {
            GetContainerNumFreeSlots = function(bag)
                -- bag 3 is a quiver (family 1): its free slots stay out
                local free = { [0] = 4, [1] = 0, [2] = 6, [3] = 20, [4] = 0 }
                return free[bag], bag == 3 and 1 or 0
            end,
        },
    }, function(t)
        t:assertEqual(line("PlayerBags"), L["Free Bag Slots"] .. ": 10")
    end),

    ["mail: none, senders, and unread without names"] = function(t)
        local unread, senders = false, {}
        local run = withGame({
            HasNewMail = function()
                return unread
            end,
            GetLatestThreeSenders = function()
                return unpack(senders)
            end,
        }, function(t)
            t:assertEqual(line("PlayerMail"), L["Mail"] .. ": " .. L["none"])
            unread, senders = true, { "Thrall", "Jaina" }
            t:assertEqual(line("PlayerMail"), L["Mail from"] .. " Thrall, Jaina")
            senders = {}
            t:assertEqual(line("PlayerMail"), L["New mail"])
        end)
        run(t)
    end,

    ["durability names the most worn item and the broken ones"] = function(t)
        local list = {}
        local run = withGame(
            merge(equipSlots, { GetInventoryItemDurability = durabilities(list) }),
            function(t)
                t:assertEqual(line("PlayerDurability"), L["Durability"] .. ": " .. L["no items"])
                list[1] = { 60, 60 }
                list[5] = { 100, 100 }
                t:assertEqual(line("PlayerDurability"), L["Durability"] .. ": 100%")
                list[7] = { 59, 60 }
                t:assertEqual(line("PlayerDurability"), L["Durability"] .. ": " .. L["lowest item"] .. " 98%")
                list[16] = { 0, 90 }
                list[17] = { 0, 50 }
                t:assertEqual(line("PlayerDurability"), L["Durability"] .. ": " .. L["lowest item"] .. " 0%, 2 " .. L["broken"])
            end
        )
        run(t)
    end,

    ["hearthstone: ready, cooling down, and secret"] = function(t)
        local start, duration = 0, 0
        local run = withGame({
            C_Container = {
                GetItemCooldown = function(itemID)
                    t:assertEqual(itemID, 6948)
                    return start, duration, 1
                end,
            },
            GetTime = function()
                return 1000
            end,
            GetBindLocation = function()
                return "Goldshire"
            end,
            issecretvalue = function(value)
                return type(value) == "table"
            end,
        }, function(t)
            t:assertEqual(line("Hearthstone"), L["Hearthstone"] .. ": " .. L["ready"] .. ", Goldshire")
            start, duration = 400, 1800
            t:assertEqual(line("Hearthstone"), L["Hearthstone"] .. ": 20 " .. L["minutes"] .. ", Goldshire")
            start = {}
            t:assertEqual(line("Hearthstone"), L["Hearthstone"] .. ": Goldshire")
        end)
        run(t)
    end,

    ["clock reads the game's own clock text"] = withGame({
        GameTime_GetTime = function(showAMPM)
            return showAMPM and "8:05 PM" or "8:05"
        end,
    }, function(t)
        t:assertEqual(line("GameClock"), L["Time"] .. ": 8:05 PM")
    end),

    ["xp names rested only when there is some"] = function(t)
        local rested = nil
        local run = withGame(
            merge(xpGame, {
                GetXPExhaustion = function()
                    return rested
                end,
            }),
            function(t)
                t:assertEqual(line("PlayerXP"), xpLine)
                rested = 3000
                t:assertEqual(line("PlayerXP"), xpLine .. ", " .. L["rested"] .. " 3000")
            end
        )
        run(t)
    end,

    ["xp leaves rested out when XP gain is off"] = withGame(
        merge(xpGame, {
            GetXPExhaustion = function()
                return 3000
            end,
            IsXPUserDisabled = function()
                return true
            end,
        }),
        function(t)
            t:assertEqual(line("PlayerXP"), xpLine)
        end
    ),
})
