local testRunner = WowVision.testing.testRunner
local dbManager = WowVision.dbManager

local function keys(...)
    return { next = { inputs = { _type = "array", ... }, padInputs = { _type = "array" } } }
end

local function bufferStore(groups)
    groups._type = "array"
    return { submodules = { buffers = { data = { items = groups } } } }
end

local function generalBuffer()
    return {
        type = "Static",
        label = "General",
        items = { { type = "Health", object = { type = "Health" } }, { type = "PVP", object = { type = "PVP" } } },
    }
end

testRunner:addSuite("Binding stores", {
    ["the first character fills the account from its own keys"] = function(t)
        local charDB = { bindings = keys("ALT-N") }
        local globalDB = {}
        local store = dbManager:resolveBindings(keys("F1"), charDB, globalDB)
        t:assertEqual(store, globalDB.bindings)
        t:assertEqual(store.next.inputs[1], "ALT-N")
        t:assertTrue(globalDB._bindingsSeeded)
        t:assertTrue(store ~= charDB.bindings)
    end,

    ["a later character uses the account's keys"] = function(t)
        local globalDB = {}
        dbManager:resolveBindings(keys("F1"), { bindings = keys("ALT-N") }, globalDB)
        local store = dbManager:resolveBindings(keys("F1"), { bindings = keys("CTRL-X") }, globalDB)
        t:assertEqual(store.next.inputs[1], "ALT-N")
    end,

    ["a character with no keys yet starts from the defaults"] = function(t)
        local charDB = {}
        local store = dbManager:resolveBindings(keys("F1"), charDB, {})
        t:assertEqual(store.next.inputs[1], "F1")
    end,

    ["the first character's buffer groups move to the empty account"] = function(t)
        local charDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        local globalDB = bufferStore({})
        t:assertTrue(dbManager:moveBuffersToAccount(charDB, globalDB))
        local account = globalDB.submodules.buffers.data.items
        t:assertEqual(#account, 1)
        t:assertEqual(account[1].label, "General")
        t:assertEqual(#charDB.submodules.buffers.data.items, 0)
    end,

    ["a default group adds nothing to the account's group of that name"] = function(t)
        local charDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        local globalDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        dbManager:moveBuffersToAccount(charDB, globalDB)
        local account = globalDB.submodules.buffers.data.items
        t:assertEqual(#account, 1)
        t:assertEqual(#account[1].items, 1)
        t:assertEqual(#charDB.submodules.buffers.data.items, 0)
    end,

    ["a group's own buffers join the account's group, the shared one stays single"] = function(t)
        local charDB = bufferStore({
            { type = "Group", label = "General", items = { generalBuffer(), { type = "Aura", label = "Target Buffs" } } },
            { type = "Group", label = "Combat", items = { { type = "Aura", label = "Target Debuffs" } } },
        })
        local globalDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        dbManager:moveBuffersToAccount(charDB, globalDB)
        local account = globalDB.submodules.buffers.data.items
        t:assertEqual(#account, 2)
        t:assertEqual(#account[1].items, 2)
        t:assertEqual(account[1].items[2].label, "Target Buffs")
        t:assertEqual(account[2].label, "Combat")
    end,

    ["a changed buffer of the same name is kept beside the account's"] = function(t)
        local changed = generalBuffer()
        changed.items[2] = { type = "PlayerXP", object = { type = "PlayerXP" } }
        local charDB = bufferStore({ { type = "Group", label = "General", items = { changed } } })
        local globalDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        dbManager:moveBuffersToAccount(charDB, globalDB)
        t:assertEqual(#globalDB.submodules.buffers.data.items[1].items, 2)
    end,

    ["buffer groups move once, a group scoped back stays on its character"] = function(t)
        local charDB = bufferStore({ { type = "Group", label = "General", items = { generalBuffer() } } })
        local globalDB = bufferStore({})
        dbManager:moveBuffersToAccount(charDB, globalDB)
        local items = charDB.submodules.buffers.data.items
        tinsert(items, { type = "Group", label = "Mine", items = { _type = "array" } })
        t:assertEqual(dbManager:moveBuffersToAccount(charDB, globalDB), false)
        t:assertEqual(#items, 1)
        t:assertEqual(#globalDB.submodules.buffers.data.items, 1)
    end,

    ["buffer groups wait for a store with the buffers module"] = function(t)
        local charDB = {}
        t:assertEqual(dbManager:moveBuffersToAccount(charDB, {}), false)
        t:assertNil(charDB._buffersOnAccount)
    end,

    ["a binding added later reaches a seeded account"] = function(t)
        local globalDB = {}
        dbManager:resolveBindings(keys("F1"), {}, globalDB)
        local defaults = keys("F1")
        defaults.added = { inputs = { _type = "array", "F2" }, padInputs = { _type = "array" } }
        local store = dbManager:resolveBindings(defaults, {}, globalDB)
        t:assertEqual(store.added.inputs[1], "F2")
        t:assertEqual(store.next.inputs[1], "F1")
    end,

    ["removing every key stays removed"] = function(t)
        local globalDB = {}
        local store = dbManager:resolveBindings(keys("F1"), {}, globalDB)
        table.remove(store.next.inputs, 1)
        store = dbManager:resolveBindings(keys("F1"), {}, globalDB)
        t:assertNil(store.next.inputs[1])
    end,

    ["switching to the character forks the current keys"] = function(t)
        local charDB, globalDB = { bindings = keys("OLD") }, { _bindingsSeeded = true, bindings = keys("F1") }
        local store = dbManager:setBindingScope(charDB, globalDB, "char")
        t:assertEqual(store, charDB.bindings)
        t:assertEqual(store.next.inputs[1], "F1")
        store.next.inputs[1] = "F5"
        t:assertEqual(globalDB.bindings.next.inputs[1], "F1")
    end,

    ["the character's choice survives the next login"] = function(t)
        local charDB, globalDB = { bindings = keys("OLD") }, { _bindingsSeeded = true, bindings = keys("F1") }
        dbManager:setBindingScope(charDB, globalDB, "char")
        charDB.bindings.next.inputs[1] = "F5"
        local store = dbManager:resolveBindings(keys("F9"), charDB, globalDB)
        t:assertEqual(store.next.inputs[1], "F5")
    end,

    ["choosing the character twice keeps its changes"] = function(t)
        local charDB, globalDB = { bindings = keys("OLD") }, { _bindingsSeeded = true, bindings = keys("F1") }
        dbManager:setBindingScope(charDB, globalDB, "char")
        charDB.bindings.next.inputs[1] = "F5"
        local store = dbManager:setBindingScope(charDB, globalDB, "char")
        t:assertEqual(store.next.inputs[1], "F5")
    end,

    ["switching back joins the account's keys"] = function(t)
        local charDB, globalDB = { bindings = keys("OLD") }, { _bindingsSeeded = true, bindings = keys("F1") }
        dbManager:setBindingScope(charDB, globalDB, "char")
        local store = dbManager:setBindingScope(charDB, globalDB, "global")
        t:assertEqual(store, globalDB.bindings)
        t:assertNil(charDB.bindingScope)
    end,
})

testRunner:addSuite("DB migrations", {
    ["an unversioned store without submodules migrates without error"] = function(t)
        local db = { someKey = 1 }
        local ok, err = pcall(dbManager.beginReconcile, dbManager, {}, db)
        t:assertTrue(ok, err)
        t:assertEqual(db._version, 8)
        t:assertType(db.bindings, "table")
    end,

    ["WowNav routes saved off take the new default in both stores"] = function(t)
        local function saved()
            return { submodules = { navigation = { submodules = { wownav = { settings = { enabled = false, comfort = 40 } } } } } }
        end
        local default = { submodules = { navigation = { submodules = { wownav = { settings = { enabled = true, comfort = 60 } } } } } }
        local char = saved()
        char._version = 6
        dbManager:beginReconcile(default, char)
        local global = saved()
        global._version = 4
        dbManager:beginReconcileGlobal(default, global)
        for _, db in ipairs({ char, global }) do
            local settings = db.submodules.navigation.submodules.wownav.settings
            t:assertEqual(settings.enabled, true)
            t:assertEqual(settings.comfort, 40)
        end
    end,

    ["WowNav routes turned off after the migration stay off"] = function(t)
        local db = {
            _version = 7,
            submodules = { navigation = { submodules = { wownav = { settings = { enabled = false } } } } },
        }
        local default = { submodules = { navigation = { submodules = { wownav = { settings = { enabled = true } } } } } }
        dbManager:beginReconcile(default, db)
        t:assertEqual(db.submodules.navigation.submodules.wownav.settings.enabled, false)
    end,

    ["the old arrival distances take the new defaults in both stores"] = function(t)
        local function saved()
            return { submodules = { navigation = { submodules = {
                maps = { settings = { arrivalShort = 1, arrivalMedium = 3, arrivalLong = 5, arrivalRange = 3 } },
                wownav = { settings = { arrivalMin = 2, comfort = 40 } },
            } } } }
        end
        local default = { submodules = { navigation = { submodules = {
            maps = { settings = { arrivalShort = 0.3, arrivalMedium = 1, arrivalLong = 3, arrivalRange = 2 } },
            wownav = { settings = { comfort = 60 } },
        } } } }
        local char = saved()
        char._version = 7
        dbManager:beginReconcile(default, char)
        local global = saved()
        global._version = 5
        dbManager:beginReconcileGlobal(default, global)
        for _, db in ipairs({ char, global }) do
            local navigation = db.submodules.navigation.submodules
            t:assertEqual(navigation.maps.settings.arrivalShort, 0.3)
            t:assertEqual(navigation.maps.settings.arrivalMedium, 1)
            t:assertEqual(navigation.maps.settings.arrivalLong, 3)
            t:assertEqual(navigation.maps.settings.arrivalRange, 3, "the active one stays")
            t:assertNil(navigation.wownav.settings.arrivalMin)
            t:assertEqual(navigation.wownav.settings.comfort, 40)
        end
    end,

    ["tuned arrival distances are kept"] = function(t)
        local db = {
            _version = 7,
            submodules = { navigation = { submodules = {
                maps = { settings = { arrivalShort = 1, arrivalMedium = 3, arrivalLong = 8 } },
            } } },
        }
        local default = { submodules = { navigation = { submodules = {
            maps = { settings = { arrivalShort = 0.3, arrivalMedium = 1, arrivalLong = 3 } },
        } } } }
        dbManager:beginReconcile(default, db)
        local settings = db.submodules.navigation.submodules.maps.settings
        t:assertEqual(settings.arrivalShort, 1)
        t:assertEqual(settings.arrivalMedium, 3)
        t:assertEqual(settings.arrivalLong, 8)
    end,

    ["a Range module switched off stays off through its alert"] = function(t)
        local db = { _version = 5, submodules = { range = { enabled = false, alerts = { rangeChange = { enabled = true } } } } }
        dbManager:beginReconcile({}, db)
        local range = db.submodules.range
        t:assertEqual(range.enabled, true)
        t:assertEqual(range.alerts.rangeChange.enabled, false)
        t:assertEqual(range.alertScopes.rangeChange, "char")
    end,

    ["a Range module left on is not touched"] = function(t)
        local db = { _version = 5, submodules = { range = { enabled = true, alerts = { rangeChange = { enabled = true } } } } }
        dbManager:beginReconcile({}, db)
        local range = db.submodules.range
        t:assertEqual(range.alerts.rangeChange.enabled, true)
        t:assertNil(range.alertScopes)
    end,

    ["soft target arcs and ranges move onto their alerts"] = function(t)
        local function saved()
            return {
                submodules = {
                    targeting = {
                        settings = { softEnemyArc = "game", softEnemyRange = 0, softFriendArc = 0, softFriendRange = 25, kept = 1 },
                    },
                },
            }
        end
        local function alertDefaults()
            return { enabled = false, arc = 2, range = 60 }
        end
        local defaults = {
            submodules = {
                targeting = {
                    settings = {},
                    alerts = { softEnemy = alertDefaults(), softFriend = alertDefaults(), softInteract = alertDefaults() },
                },
            },
        }
        for _, begin in ipairs({ dbManager.beginReconcile, dbManager.beginReconcileGlobal }) do
            local db = saved()
            db._version = begin == dbManager.beginReconcileGlobal and 2 or 3
            begin(dbManager, defaults, db)
            local targeting = db.submodules.targeting
            t:assertEqual(targeting.alerts.softEnemy.arc, 2)
            t:assertEqual(targeting.alerts.softEnemy.range, 60)
            t:assertEqual(targeting.alerts.softFriend.arc, 0)
            t:assertEqual(targeting.alerts.softFriend.range, 25)
            t:assertEqual(targeting.alerts.softInteract.enabled, false)
            t:assertNil(targeting.settings.softFriendArc)
            t:assertNil(targeting.settings.softFriendRange)
            t:assertEqual(targeting.settings.kept, 1)
        end
    end,

    ["the old soft target defaults give way, chosen values stay"] = function(t)
        local function saved()
            return {
                _version = 3,
                submodules = {
                    targeting = {
                        settings = { softEnemyArc = "game", softEnemyRange = 0, softFriendArc = 0, softFriendRange = 25 },
                    },
                },
            }
        end
        local defaults = {
            submodules = {
                targeting = { settings = { softEnemyArc = 2, softEnemyRange = 60, softFriendArc = 2, softFriendRange = 60 } },
            },
        }
        for _, begin in ipairs({ dbManager.beginReconcile, dbManager.beginReconcileGlobal }) do
            local db = saved()
            db._version = begin == dbManager.beginReconcileGlobal and 2 or 3
            begin(dbManager, {}, db)
            -- Both migrations ran: what stayed is on the alert now
            local alerts = db.submodules.targeting.alerts
            t:assertNil(alerts.softEnemy.arc)
            t:assertNil(alerts.softEnemy.range)
            t:assertEqual(alerts.softFriend.arc, 0)
            t:assertEqual(alerts.softFriend.range, 25)
        end
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
        t:assertEqual(db._version, 6)
    end,
})
