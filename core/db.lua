local dbManager = {}
local DB_VERSION = 1

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

function migrateDB(db)
    --a more robust solution to this will be added later
    local buffers = db.submodules.buffers
    buffers.data = nil
    db._version = DB_VERSION
end

function dbManager:beginReconcile(default, db)
    if next(db) then
        if db._version == nil or db._version < DB_VERSION then
            migrateDB(db)
        end
    end
    return dbManager:reconcile(default, db)
end

WowVision.dbManager = dbManager
