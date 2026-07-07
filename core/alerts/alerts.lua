local L = WowVision:getLocale()
local Alert = WowVision.Class("Alert")
Alert:addFields({
    { key = "key", required = true, once = true },
    { key = "label" },
    -- Plain managed field: accessor methods below MUST NOT be wired as the
    -- field's get/set -- they read/write self.enabled, which would re-enter
    -- the field and recurse.
    { key = "enabled", default = true },
})

function Alert:initialize(info)
    self.outputs = {}
    self.parameters = WowVision.info.InfoFrame:new({
        key = info.key,
        label = info.label,
    })
    local enabledParam = self.parameters:add({
        key = "enabled",
        type = "Bool",
        label = L["Enabled"],
        default = function()
            return self.defaultEnabled
        end,
    })
    enabledParam.events.valueChange:subscribe(self, function(self, event, source, value)
        self:setEnabled(value)
    end)
    self:applyFields(info)
    -- The config-time enabled value feeds the settings parameter's default.
    self.defaultEnabled = self.enabled
end

function Alert:getEnabled()
    return self.enabled
end

function Alert:setEnabled(enabled)
    self.enabled = enabled
    if self.db then
        self.db.enabled = enabled
    end
end

function Alert:addOutput(info)
    local outputClass = WowVision.alerts.outputTypes:get(info.type)
    if outputClass == nil then
        error("Output type " .. info.type .. " does not exist.")
    end
    local output = outputClass:new(info)
    tinsert(self.outputs, output)
    self.parameters:addRef(info.key, output.parameters)
    return output
end

function Alert:fire(message)
    if not self.enabled then
        return
    end
    local action = message and message.action
    for i = 1, #self.outputs do
        local output = self.outputs[i]
        if output.enabled and output:respondsTo(action) then
            output:fire(message)
        end
    end
end

function Alert:update()
    if not self.enabled then
        return
    end
    for i = 1, #self.outputs do
        self.outputs[i]:update()
    end
end

function Alert:getDefaultDBRecursive()
    local db = self.parameters:getDefaultDB()
    db.outputs = {}
    for i = 1, #self.outputs do
        local output = self.outputs[i]
        db.outputs[output.key] = output:getDefaultDB()
    end
    return db
end

function Alert:setDB(db)
    self.db = db
    self.parameters:setDB(db)
    for i = 1, #self.outputs do
        local output = self.outputs[i]
        local outputDB = db.outputs[output.key]
        if not outputDB then
            error("No output db for " .. output.key)
        end
        output:setDB(outputDB)
    end
end

local Output = WowVision.Class("AlertOutput")
Output:addFields({
    { key = "key", required = true, once = true },
    { key = "label" },
    { key = "tag" },
    -- Optional action this output responds to. When set, the output only fires
    -- if the fire message's `action` matches; when nil, it fires on every fire
    -- (legacy multi-output alerts). Lets one alert host several distinct cues.
    { key = "action" },
    { key = "shouldFire" },
    -- Plain managed field; see the Alert note above.
    { key = "enabled", default = true },
})

function Output:initialize(info)
    self.parameters = WowVision.info.InfoFrame:new({
        key = info.key,
        label = info.label,
    })
    local enabledParam = self.parameters:add({
        type = "Bool",
        key = "enabled",
        label = L["Enabled"],
        default = function()
            return self.defaultEnabled
        end,
    })
    enabledParam.events.valueChange:subscribe(self, function(self, event, source, value)
        self:setEnabled(value)
    end)
    self:applyFields(info)
    self.defaultEnabled = self.enabled
end

function Output:addParameter(info)
    return self.parameters:add(info)
end

function Output:respondsTo(action)
    if self.action == nil then
        return true
    end
    return self.action == action
end

function Output:getEnabled()
    return self.enabled
end

function Output:setEnabled(enabled)
    self.enabled = enabled
    if self.db then
        self.db.enabled = enabled
    end
end

function Output:fire(message)
    if self.shouldFire and not self:shouldFire(message) then
        return
    end
    self:onFire(message)
end

function Output:getDefaultDB()
    return self.parameters:getDefaultDB()
end

function Output:setDB(db)
    self.db = db
    self.parameters:setDB(db)
end

local Alerts = WowVision.Class("Alerts")
WowVision.alerts = Alerts
Alerts.outputTypes = WowVision.Registry:new()
Alerts.Alert = Alert
Alerts.Output = Output

function Alerts:initialize()
    self.outputTypes = WowVision.Registry:new()
end

function Alerts:createOutput(name)
    local class = WowVision.Class(name .. "AlertOutput", Output)
    self.outputTypes:register(name, class)
    return class
end
