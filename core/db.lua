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
