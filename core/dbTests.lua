local testRunner = WowVision.testing.testRunner
local dbManager = WowVision.dbManager

testRunner:addSuite("DB migrations", {
    ["an unversioned store without submodules migrates without error"] = function(t)
        local db = { someKey = 1 }
        local ok, err = pcall(dbManager.beginReconcile, dbManager, {}, db)
        t:assertTrue(ok, err)
        t:assertEqual(db._version, 2)
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
})
