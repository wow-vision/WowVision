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
