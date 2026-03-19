local SpellHistory = WowVision.Class("SpellHistory")

function SpellHistory:initialize()
    self.spells = {} -- spellID → { name, sources = { aura = true, ... } }
    self.db = nil
end

function SpellHistory:setDB(db)
    self.db = db
    -- Restore from DB
    for spellID, entry in pairs(db) do
        local id = tonumber(spellID)
        if id then
            self.spells[id] = entry
        end
    end
end

function SpellHistory:add(spellID, name, sourceType)
    if not spellID or not name then
        return
    end

    local existing = self.spells[spellID]
    if existing then
        -- Update name if it changed
        if existing.name ~= name then
            existing.name = name
            if self.db then
                self.db[tostring(spellID)].name = name
            end
        end
        -- Add source type if new
        if sourceType and not existing.sources[sourceType] then
            existing.sources[sourceType] = true
            if self.db then
                self.db[tostring(spellID)].sources[sourceType] = true
            end
        end
        return
    end

    local sources = {}
    if sourceType then
        sources[sourceType] = true
    end

    local entry = { name = name, sources = sources }
    self.spells[spellID] = entry

    if self.db then
        self.db[tostring(spellID)] = entry
    end
end

function SpellHistory:get(spellID)
    return self.spells[spellID]
end

function SpellHistory:getByName(name)
    if not name then
        return nil
    end
    local lower = strlower(name)
    local results = {}
    for spellID, entry in pairs(self.spells) do
        if strlower(entry.name) == lower then
            tinsert(results, { spellID = spellID, name = entry.name, sources = entry.sources })
        end
    end
    return results
end

function SpellHistory:search(query)
    if not query or query == "" then
        return {}
    end
    local lower = strlower(query)
    local results = {}
    for spellID, entry in pairs(self.spells) do
        if strlower(entry.name):find(lower, 1, true) then
            tinsert(results, { spellID = spellID, name = entry.name, sources = entry.sources })
        end
    end
    table.sort(results, function(a, b)
        return a.name < b.name
    end)
    return results
end

function SpellHistory:hasSource(spellID, sourceType)
    local entry = self.spells[spellID]
    if not entry then
        return false
    end
    return entry.sources[sourceType] == true
end

WowVision.spellHistory = SpellHistory:new()
