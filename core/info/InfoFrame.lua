local L = WowVision:getLocale()

local InfoFrame = WowVision.Class("InfoFrame")
WowVision.info.InfoFrame = InfoFrame

-- FieldProxy: wraps a Field + InfoFrame to provide Parameter-compatible API
local FieldProxy = WowVision.Class("FieldProxy")
InfoFrame.FieldProxy = FieldProxy

function FieldProxy:initialize(frame, field)
    self.frame = frame
    self.field = field
    self.events = {
        valueChange = WowVision.Event:new("valueChange"),
    }
    -- Re-emit field changes with Parameter-compatible signature: (proxy, value)
    local proxy = self
    field.events.valueChange:subscribe(nil, function(event, obj, key, value)
        proxy.events.valueChange:emit(proxy, value)
    end)
end

function FieldProxy:getValue()
    return self.field:get(self.frame)
end

function FieldProxy:setValue(value)
    self.field:set(self.frame, value)
end

-- Choice compatibility: dynamically add a choice option
function FieldProxy:addChoice(choice)
    local choices = self.field.choices
    if type(choices) == "table" then
        tinsert(choices, choice)
    end
end

-- Bool compatibility
function FieldProxy:toggle()
    local value = self:getValue()
    self:setValue(not value)
    return self:getValue()
end

-- InfoFrame

function InfoFrame:initialize(config)
    self.key = config.key
    self.label = config.label
    self.info = WowVision.info.InfoManager:new()
    self.children = {}
    self.proxies = {}
    if config.fields then
        self:addFields(config.fields)
    end
end

-- Add a field, defaulting persist to true (settings should persist)
function InfoFrame:addField(config)
    if config.persist == nil then
        config.persist = true
    end
    return self.info:addField(config)
end

function InfoFrame:addFields(fields)
    for _, field in ipairs(fields) do
        self:addField(field)
    end
end

function InfoFrame:getField(key)
    return self.info:getField(key)
end

-- Parameter-compatible add: returns FieldProxy for regular fields, child InfoFrame for Category
function InfoFrame:add(config)
    if config.type == "Category" then
        local child = InfoFrame:new({ key = config.key, label = config.label })
        self:addChild(child)
        return child
    end
    local field = self:addField(config)
    local proxy = FieldProxy:new(self, field)
    self.proxies[config.key] = proxy
    return proxy
end

-- Parameter-compatible get: returns FieldProxy by key
function InfoFrame:get(key)
    return self.proxies[key]
end

-- Add a nested InfoFrame as a child
function InfoFrame:addChild(childFrame)
    tinsert(self.children, childFrame)
    return childFrame
end

-- Add a reference to another InfoFrame or ParameterCategory (UI only, no db involvement)
function InfoFrame:addRef(key, target)
    tinsert(self.children, { key = key, label = target.label, ref = true, target = target })
end

-- Database connection

function InfoFrame:getDefaultDB()
    local result = self.info:getDefaultDB(self)
    for _, child in ipairs(self.children) do
        if not child.ref then
            result[child.key] = child:getDefaultDB()
        end
    end
    return result
end

function InfoFrame:setDB(db)
    self.info:setDB(self, db)
    for _, child in ipairs(self.children) do
        if not child.ref then
            child:setDB(db[child.key])
        end
    end
end

-- UI Generation

local function childButton_Click(event, button)
    local target = button.userdata
    button.context:addGenerated(target:getGenerator())
end

function InfoFrame:getGenerator()
    local children = {}

    -- Field generators
    for _, field in ipairs(self.info.fields) do
        if field.showInUI then
            tinsert(children, field:getGenerator(self))
        end
    end

    -- Child InfoFrame / ref buttons
    for _, child in ipairs(self.children) do
        local target = child.ref and child.target or child
        tinsert(children, {
            "Button",
            label = target.label,
            userdata = target,
            events = {
                click = childButton_Click,
            },
        })
    end

    return { "List", label = self.label, children = children }
end
