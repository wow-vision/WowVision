local testRunner = WowVision.testing.testRunner
local dbManager = WowVision.dbManager

testRunner:addSuite("DB migrations", {
    ["an unversioned store without submodules migrates without error"] = function(t)
        local db = { someKey = 1 }
        local ok, err = pcall(dbManager.beginReconcile, dbManager, {}, db)
        t:assertTrue(ok, err)
        t:assertEqual(db._version, 3)
        t:assertType(db.bindings, "table")
    end,

    ["migration 1 still drops buffer data"] = function(t)
        local db = { submodules = { buffers = { data = { 1, 2 } } } }
        dbManager:beginReconcile({}, db)
        t:assertNil(db.submodules.buffers.data)
    end,

    ["migration 2 still lifts nested bindings"] = function(t)
        local db = {
            _version = 1,
            submodules = { chat = { bindings = { next = "ALT-N" } } },
        }
        dbManager:beginReconcile({}, db)
        t:assertEqual(db.bindings.next, "ALT-N")
        t:assertNil(db.submodules.chat.bindings)
    end,

    ["migration 3 adds the new General buffer lines before PvP"] = function(t)
        local general = {
            type = "Static",
            label = "General",
            items = {
                { type = "Health", object = { type = "Health", units = { "player" } } },
                { type = "PlayerXP", object = { type = "PlayerXP" } },
                { type = "PlayerMoney", object = { type = "PlayerMoney" } },
                { type = "PlayerMail", object = { type = "PlayerMail" } },
                { type = "PVP", object = { type = "PVP", units = { "player" } } },
            },
        }
        local db = {
            _version = 2,
            submodules = { buffers = { data = { items = { { type = "Group", items = { general } } } } } },
        }
        dbManager:beginReconcile({}, db)
        local order = {}
        for _, item in ipairs(general.items) do
            tinsert(order, item.object.type)
        end
        t:assertEqual(
            table.concat(order, " "),
            "Health PlayerXP PlayerMoney PlayerMail PlayerBags PlayerDurability Hearthstone GameClock PVP"
        )
    end,

    ["migration 3 leaves other buffers alone"] = function(t)
        local auras = { type = "Static", items = { { type = "Health", object = { type = "Health" } } } }
        local db = {
            _version = 2,
            submodules = { buffers = { data = { items = { { type = "Group", items = { auras } } } } } },
        }
        dbManager:beginReconcile({}, db)
        t:assertEqual(#auras.items, 1)
    end,

    ["the account store gets the new lines too"] = function(t)
        local general = {
            type = "Static",
            items = {
                { type = "PlayerXP", object = { type = "PlayerXP" } },
                { type = "PlayerMoney", object = { type = "PlayerMoney" } },
            },
        }
        local db = {
            _version = 1,
            submodules = { buffers = { data = { items = { { type = "Group", items = { general } } } } } },
        }
        dbManager:beginReconcileGlobal({}, db)
        t:assertEqual(#general.items, 7)
        t:assertEqual(general.items[7].object.type, "GameClock")
        t:assertEqual(db._version, 2)
    end,
})
