local info = WowVision.info
local L = WowVision:getLocale()

local AlertField, parent = info:CreateFieldClass("Alert")

function AlertField:setup(config)
    parent.setup(self, config)
    self.alertConfig = config.alert or {}
    self.outputs = config.outputs or {}
end

function AlertField:getInfo()
    local result = parent.getInfo(self)
    result.alert = self.alertConfig
    result.outputs = self.outputs
    return result
end

-- Create an Alert instance for the given object if it doesn't exist yet
function AlertField:getAlert(obj)
    local alert = obj[self.key]
    if not alert or not alert.class then
        -- Create the alert
        local alertInfo = {
            key = self.alertConfig.key or self.key,
            label = self.alertConfig.label or self:getLabel(),
        }
        alert = WowVision.alerts.Alert:new(alertInfo)
        -- Add configured outputs
        for _, outputConfig in ipairs(self.outputs) do
            alert:addOutput(outputConfig)
        end
        obj[self.key] = alert
    end
    -- Lazy link to DB when available
    if obj.db and obj.db[self.key] and not alert.db then
        alert:setDB(obj.db[self.key])
    end
    return alert
end

function AlertField:get(obj)
    return self:getAlert(obj)
end

function AlertField:getData(obj)
    local alert = self:getAlert(obj)
    if alert.db then
        return alert.db
    end
    return alert:getDefaultDBRecursive()
end

function AlertField:getDefaultDB(obj)
    local alert = self:getAlert(obj)
    return alert:getDefaultDBRecursive()
end

function AlertField:setDB(obj, db)
    local alertDB = db[self.key]
    if not alertDB then
        return
    end
    local alert = self:getAlert(obj)
    alert:setDB(alertDB)
end

function AlertField:set(obj, value)
    if not value or type(value) ~= "table" then
        return
    end
    local alert = self:getAlert(obj)
    alert:setDB(value)
end

function AlertField:getGenerator(obj)
    local alert = self:getAlert(obj)
    return {
        "Button",
        label = self:getLabel() or self.key,
        events = {
            click = function(event, button)
                button.context:addGenerated(alert.parameters:getGenerator())
            end,
        },
    }
end
