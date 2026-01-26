local Registry = WowVision.Class("Registry")

function Registry:initialize(info)
    self.items = {}
    self.itemKeys = {}
    if info then
        if info.allowReplace then
            self.allowReplace = info.allowReplace
        else
            info.allowReplace = false
        end
        self.default = info.default
    else
        self.allowReplace = false
    end
end

function Registry:register(key, item)
    -- Keyless registration: only one parameter, or key is nil
    if item == nil or key == nil then
        local itemToRegister = item or key
        if itemToRegister then
            tinsert(self.items, itemToRegister)
            tinsert(self.itemKeys, nil)
        end
        return
    end

    -- Keyed registration: both key and item are non-nil
    if self.items[key] then
        if self.allowReplace == false then
            error("Cannot replace registered item as an item with key " .. key .. " already exists.")
        end
        for i, v in ipairs(self.itemKeys) do
            if key == v then
                table.remove(self.items, i)
                table.remove(self.itemKeys, i)
                break
            end
        end
    end
    self.items[key] = item
    tinsert(self.items, item)
    tinsert(self.itemKeys, key)
end

function Registry:get(key, default)
    local item = self.items[key]
    if item ~= nil then
        return item
    end
    if default ~= nil then
        return default
    end
    return self.default
end

WowVision.Registry = Registry
