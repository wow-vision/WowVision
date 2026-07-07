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

local migrations = {
    {
        version = 1,
        migrate = function(db)
            db.submodules.buffers.data = nil
        end,
    },
    {
        version = 2,
        migrate = function(db)
            if db.bindings == nil then
                db.bindings = {}
            end
            migrateBindings(db.submodules, db.bindings)
        end,
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
local globalMigrations = {}

local GLOBAL_DB_VERSION = 1

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

WowVision.dbManager = dbManager
