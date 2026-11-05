local dbManager = {}

function dbManager:reconcileArray(default, db)
    local db = db
    if db == nil then
        db = {}
        for _, v in ipairs(default) do
            tinsert(db, dbManager:reconcile(v, nil))
        end
    elseif type(db) ~= "table" then
        return db
    end
    return db
end

function dbManager:reconcileRequiredDict(default, db)
    local db = db
    if db == nil then
        db = {}
    elseif type(db) ~= "table" then
        return db
    end
    for key, defaultValue in pairs(default) do
        local dbValue = db[key]
        db[key] = dbManager:reconcile(defaultValue, dbValue)
    end
    return db
end

function dbManager:reconcile(default, db)
    if type(default) == "table" then
        if default._type == "array" then
            return dbManager:reconcileArray(default, db)
        else
            return dbManager:reconcileRequiredDict(default, db)
        end
    end
    if db == nil then
        return default
    end
    return db
end

local function migrateBindings(submodules, target)
    for key, moduleDB in pairs(submodules) do
        if moduleDB.bindings then
            for bindingKey, bindingData in pairs(moduleDB.bindings) do
                target[bindingKey] = bindingData
            end
            moduleDB.bindings = nil
        end
        if moduleDB.submodules then
            migrateBindings(moduleDB.submodules, target)
        end
    end
end

-- Lines the General buffer gained after characters already had one. The
-- General buffer is the first Static buffer holding the default XP and
-- Money lines (players may rename or reorder it). Each new line it lacks
-- goes in before PvP, which ends the default list, or at the end. Runs
-- once per store, so a line removed later stays removed.
local newGeneralLines = { "PlayerBags", "PlayerDurability", "PlayerMail", "Hearthstone", "GameClock" }

local function findGeneralBuffer(groups)
    for _, group in ipairs(groups) do
        for _, buffer in ipairs(group.items or {}) do
            if buffer.type == "Static" and buffer.items ~= nil then
                local types = {}
                for _, item in ipairs(buffer.items) do
                    if item.object ~= nil and item.object.type ~= nil then
                        types[item.object.type] = true
                    end
                end
                if types.PlayerXP and types.PlayerMoney then
                    return buffer, types
                end
            end
        end
    end
    return nil
end

local function addGeneralBufferLines(db)
    local buffers = db.submodules and db.submodules.buffers
    local groups = buffers and buffers.data and buffers.data.items
    if groups == nil then
        return
    end
    local buffer, present = findGeneralBuffer(groups)
    if buffer == nil then
        return
    end
    local position = #buffer.items + 1
    for i, item in ipairs(buffer.items) do
        if item.object ~= nil and item.object.type == "PVP" then
            position = i
            break
        end
    end
    for _, objectType in ipairs(newGeneralLines) do
        if not present[objectType] then
            tinsert(buffer.items, position, { type = objectType, object = { type = objectType } })
            position = position + 1
        end
    end
end

-- Soft targeting arcs and ranges used to default to the game's own values.
-- Those saved defaults go, so the reconcile that follows fills in the new
-- widest and longest ones. The account store holds them too.
local function dropOldSoftTargetDefaults(db)
    local targeting = db.submodules and db.submodules.targeting
    local settings = targeting and targeting.settings
    if settings == nil then
        return
    end
    for _, key in ipairs({ "softEnemy", "softFriend", "softInteract" }) do
        if settings[key .. "Arc"] == "game" then
            settings[key .. "Arc"] = nil
        end
        if settings[key .. "Range"] == 0 then
            settings[key .. "Range"] = nil
        end
    end
end

-- The arcs and ranges moved from the module's settings onto its soft target
-- alerts. Anything left of them goes along; the reconcile that follows fills
-- in the rest.
local function moveSoftTargetSettings(db)
    local targeting = db.submodules and db.submodules.targeting
    local settings = targeting and targeting.settings
    if settings == nil then
        return
    end
    if targeting.alerts == nil then
        targeting.alerts = {}
    end
    for _, key in ipairs({ "softEnemy", "softFriend", "softInteract" }) do
        local alert = targeting.alerts[key]
        if alert == nil then
            alert = {}
            targeting.alerts[key] = alert
        end
        if settings[key .. "Arc"] ~= nil then
            alert.arc = settings[key .. "Arc"]
            settings[key .. "Arc"] = nil
        end
        if settings[key .. "Range"] ~= nil then
            alert.range = settings[key .. "Range"]
            settings[key .. "Range"] = nil
        end
    end
end

-- The Range module lost its menu entry, and with it the Enabled switch: only
-- its alert is left to switch. A character who had turned the module off keeps
-- it off that way, on this character alone, as the module's switch was.
local function moveRangeSwitchToAlert(db)
    local range = db.submodules and db.submodules.range
    if range == nil or range.enabled ~= false then
        return
    end
    range.enabled = true
    if range.alerts == nil then
        range.alerts = {}
    end
    if range.alerts.rangeChange == nil then
        range.alerts.rangeChange = {}
    end
    range.alerts.rangeChange.enabled = false
    if range.alertScopes == nil then
        range.alertScopes = {}
    end
    range.alertScopes.rangeChange = "char"
end

-- WowNav routes went from off to on by default. The old default is saved like
-- any other value, so it goes, and the reconcile that follows fills in the new
-- one. The account store holds it too.
local function dropOldWowNavDefault(db)
    local navigation = db.submodules and db.submodules.navigation
    local wownav = navigation and navigation.submodules and navigation.submodules.wownav
    local settings = wownav and wownav.settings
    if settings ~= nil and settings.enabled == false then
        settings.enabled = nil
    end
end

-- The three arrival distances went from 1, 3 and 5 yards to 0.3, 1 and 3,
-- and WowNav's own minimum arrival distance went (the active one of the
-- three is WowNav's minimum now). Saved defaults go when all three are still
-- the old ones, so the reconcile that follows fills in the new; a player who
-- tuned any of them keeps theirs. The account store holds them too.
local oldArrivalDefaults = { arrivalShort = 1, arrivalMedium = 3, arrivalLong = 5 }

local function dropOldArrivalDefaults(db)
    local navigation = db.submodules and db.submodules.navigation
    local submodules = navigation and navigation.submodules
    local maps = submodules and submodules.maps
    local settings = maps and maps.settings
    if settings ~= nil then
        local untouched = true
        for key, value in pairs(oldArrivalDefaults) do
            if settings[key] ~= nil and settings[key] ~= value then
                untouched = false
            end
        end
        if untouched then
            for key in pairs(oldArrivalDefaults) do
                settings[key] = nil
            end
        end
    end
    local wownav = submodules and submodules.wownav
    if wownav ~= nil and wownav.settings ~= nil then
        wownav.settings.arrivalMin = nil
    end
end

local migrations = {
    {
        version = 1,
        migrate = function(db)
            local buffers = db.submodules and db.submodules.buffers
            if buffers ~= nil then
                buffers.data = nil
            end
        end,
    },
    {
        version = 2,
        migrate = function(db)
            if db.bindings == nil then
                db.bindings = {}
            end
            if db.submodules ~= nil then
                migrateBindings(db.submodules, db.bindings)
            end
        end,
    },
    {
        version = 3,
        migrate = addGeneralBufferLines,
    },
    {
        version = 4,
        migrate = dropOldSoftTargetDefaults,
    },
    {
        version = 5,
        migrate = moveSoftTargetSettings,
    },
    {
        version = 6,
        migrate = moveRangeSwitchToAlert,
    },
    {
        version = 7,
        migrate = dropOldWowNavDefault,
    },
    {
        version = 8,
        migrate = dropOldArrivalDefaults,
    },
}

local DB_VERSION = migrations[#migrations].version

local function migrateDB(db)
    local dbVersion = db._version or 0
    for _, migration in ipairs(migrations) do
        if dbVersion < migration.version then
            migration.migrate(db)
        end
    end
    db._version = DB_VERSION
end

function dbManager:beginReconcile(default, db)
    if next(db) then
        if (db._version or 0) < DB_VERSION then
            migrateDB(db)
        end
    else
        db._version = DB_VERSION
    end
    return dbManager:reconcile(default, db)
end

-- The account-wide store: its own migration list and version stamp,
-- reconciled the same way.
local globalMigrations = {
    {
        version = 2,
        migrate = addGeneralBufferLines,
    },
    {
        version = 3,
        migrate = dropOldSoftTargetDefaults,
    },
    {
        version = 4,
        migrate = moveSoftTargetSettings,
    },
    {
        version = 5,
        migrate = dropOldWowNavDefault,
    },
    {
        version = 6,
        migrate = dropOldArrivalDefaults,
    },
}

local GLOBAL_DB_VERSION = globalMigrations[#globalMigrations].version

function dbManager:beginReconcileGlobal(default, db)
    local dbVersion = db._version or 0
    if next(db) then
        for _, migration in ipairs(globalMigrations) do
            if dbVersion < migration.version then
                migration.migrate(db)
            end
        end
    end
    db._version = GLOBAL_DB_VERSION
    return dbManager:reconcile(default, db)
end

local function sameConfig(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if not sameConfig(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

-- Buffer groups are account-wide unless a character chooses otherwise. Each
-- character does this once, so a group moved back with Scope stays there. A
-- group joins the account's group of the same name, which takes only the
-- buffers it lacks: a default General adds nothing, and nothing is lost. Any
-- other group moves as it is. True when this character was moved.
function dbManager:moveBuffersToAccount(charDB, globalDB)
    if charDB._buffersOnAccount then
        return false
    end
    local charNode = charDB.submodules and charDB.submodules.buffers
    local globalNode = globalDB.submodules and globalDB.submodules.buffers
    if charNode == nil or globalNode == nil then
        return false
    end
    local charData = charNode.data or {}
    globalNode.data = globalNode.data or {}
    if globalNode.data.items == nil then
        globalNode.data.items = { _type = "array" }
    end
    local accountGroups = globalNode.data.items
    for _, group in ipairs(charData.items or {}) do
        local joined = nil
        for _, accountGroup in ipairs(accountGroups) do
            if group.label ~= nil and accountGroup.label == group.label then
                joined = accountGroup
                break
            end
        end
        if joined == nil then
            tinsert(accountGroups, group)
        else
            if joined.items == nil then
                joined.items = { _type = "array" }
            end
            for _, buffer in ipairs(group.items or {}) do
                local present = false
                for _, accountBuffer in ipairs(joined.items) do
                    if sameConfig(buffer, accountBuffer) then
                        present = true
                        break
                    end
                end
                if not present then
                    tinsert(joined.items, buffer)
                end
            end
        end
    end
    charData.items = { _type = "array" }
    charNode.data = charData
    charDB._buffersOnAccount = true
    return true
end

-- Key bindings live at the top of each store, outside the module tree, and
-- are account-wide unless this character chose otherwise. Bindings joined the
-- account store later than settings, so they carry their own seeding stamp:
-- the first character to get here fills the account from its own keys. A
-- character's own copy stays behind either way. Returns the store to bind.
function dbManager:resolveBindings(defaults, charDB, globalDB)
    charDB.bindings = dbManager:reconcile(defaults, charDB.bindings or {})
    if globalDB._bindingsSeeded then
        globalDB.bindings = dbManager:reconcile(defaults, globalDB.bindings or {})
    else
        globalDB.bindings = WowVision.classes.deepCopy(charDB.bindings)
        globalDB._bindingsSeeded = true
    end
    if charDB.bindingScope == "char" then
        return charDB.bindings
    end
    return globalDB.bindings
end

-- Same directions as classes.setFieldScope: to global JOINS the account's
-- keys, to character FORKS the current ones. Returns the store to bind.
function dbManager:setBindingScope(charDB, globalDB, scope)
    if scope == "char" then
        if charDB.bindingScope ~= "char" then
            charDB.bindings = WowVision.classes.deepCopy(globalDB.bindings)
            charDB.bindingScope = "char"
        end
        return charDB.bindings
    end
    charDB.bindingScope = nil
    return globalDB.bindings
end

WowVision.dbManager = dbManager
