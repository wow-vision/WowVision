local ActivatedBinding = WowVision.Class("ActivatedBinding")

function ActivatedBinding:initialize(binding, info)
    self.frames = {} --one frame per input
    self.binding = binding
    self.info = info
    self.activated = false
end

function ActivatedBinding:activate()
    if self.activated then
        return
    end
    local binding = self.binding
    for _, input in ipairs(binding.inputs) do
        local frame = WowVision.input:acquireFrame()
        frame.binding = self.binding
        if self.binding.onActivate then
            self.binding:onActivate(frame, self.info)
        end
        SetOverrideBindingClick(frame, true, input, frame:GetName(), self.info.emulatedKey)
        tinsert(self.frames, frame)
    end
    self.activated = true
end

function ActivatedBinding:deactivate()
    if not self.activated then
        return
    end
    for _, frame in ipairs(self.frames) do
        if self.binding.onDeactivate then
            self.binding:onDeactivate(frame, self.info)
        end
        WowVision.input:releaseFrame(frame)
    end
    self.frames = {}
    self.activated = false
end

function ActivatedBinding:reactivate()
    self:deactivate()
    self:activate()
end

local Binding = WowVision.Class("Binding"):include(WowVision.InfoClass)
WowVision.input.Binding = Binding
Binding.info:addFields({
    { key = "key", required = true },
    { key = "type", required = true },
    { key = "vital", default = false },
    { key = "dorment", default = false },
    {
        key = "inputs",
        default = function()
            return {}
        end,
        set = function(obj, key, value)
            if type(obj.setInputs) == "function" then
                obj:setInputs(value)
            else
                obj[key] = value
            end
        end,
    },
    { key = "label" },
    { key = "emulatedKey" },
    {
        key = "conflictingAddons",
        default = function()
            return {}
        end,
    },
    { key = "category" },
})

function Binding:initialize(info)
    self.inputs = { _type = "array" }
    self.activated = {}
    self:setInfo(info, true)
end

function Binding:getLabel()
    return self.label
end

function Binding:getDefaultDB()
    local result = { inputs = { _type = "array" } }
    for i, input in ipairs(self.inputs) do
        tinsert(result.inputs, input)
    end
    return result
end

function Binding:setDB(db)
    self.db = db
    -- Copy inputs from db to our own table (self.inputs is source of truth)
    self.inputs = { _type = "array" }
    for _, input in ipairs(db.inputs) do
        tinsert(self.inputs, input)
    end
end

function Binding:addInput(input)
    -- Check if input conflicts with other bindings (or this one)
    if self:doesInputConflict(input) then
        error("Conflicting input: " .. input .. ".")
    end


    -- Add to our source of truth
    tinsert(self.inputs, input)

    -- Sync to DB if it exists
    if self.db and self.db.inputs ~= self.inputs then
        tinsert(self.db.inputs, input)
    end
end

function Binding:removeInput(input)
    for i, bindingInput in ipairs(self.inputs) do
        if input == bindingInput then
            -- Remove from our source of truth
            table.remove(self.inputs, i)

            -- Sync to DB if it exists
            self:setDBInputs()
            return
        end
    end
end

function Binding:setDBInputs()
    if self.db then
        self.db.inputs = self.inputs
    end
end

function Binding:setInputs(inputs)
    self.inputs = { _type = "array" }
    if self.db then
        -- Clear existing entries without replacing the table
        self.db.inputs = { _type = "array" }
    end
    for _, input in ipairs(inputs) do
        self:addInput(input) -- This will sync to db.inputs via addInput
    end
end

function Binding:doesInputConflict(input)
    if not self.inputManager then
        return nil
    end
    for _, binding in ipairs(self.inputManager.bindings.orderedBindings) do
        for _, bindingInput in ipairs(binding.inputs) do
            if input == bindingInput then
                return binding
            end
        end
    end
    return nil
end

function Binding:activate(info)
    local newInfo = {}
    self.info:set(newInfo, self)
    if info then
        self.info:set(newInfo, info)
    end
    if newInfo.dorment then
        return nil
    end
    local loaded = WowVision.loadedAddons
    for _, addon in ipairs(newInfo.conflictingAddons) do
        if loaded and (loaded[addon] or loaded[addon:lower()]) then
            return nil
        end
    end
    local activated = ActivatedBinding:new(self, newInfo)
    activated.inputManager = self.inputManager
    activated:activate() --Change later to fix frame bug
    tinsert(self.activated, activated)
    return activated
end

function Binding:deactivate(instance)
    instance:deactivate()
    for i, v in ipairs(self.activated) do
        if v == instance then
            table.remove(self.activated, i)
            break
        end
    end
end

function Binding:deactivateAll()
    for i = #self.activated, 1, -1 do
        local instance = self.activated[i]
        instance:deactivate()
    end
    self.activated = {}
end

function Binding:reactivateAll()
    for _, activated in ipairs(self.activated) do
        activated:reactivate()
    end
end

local BindingSet = WowVision.Class("BindingSet")
WowVision.input.BindingSet = BindingSet

function BindingSet:initialize()
    self.bindingSet = {}
    self.orderedBindings = {}
end

function BindingSet:createBinding(info)
    local binding = self.inputManager:createBinding(info)
    self:add(binding)
    return binding
end

function BindingSet:createBindings(bindings)
    local result = {}
    for _, info in ipairs(bindings) do
        tinsert(result, self:createBinding(info))
    end
    return result
end

function BindingSet:add(binding)
    if self.bindingSet[binding] then
        return false
    end
    self.bindingSet[binding] = true
    tinsert(self.orderedBindings, binding)
    return true
end

function BindingSet:activateAll(info)
    for _, binding in ipairs(self.orderedBindings) do
        binding:activate(info)
    end
end

function BindingSet:deactivateAll()
    for _, binding in ipairs(self.orderedBindings) do
        binding:deactivateAll()
    end
end

function BindingSet:reactivateAll()
    for _, binding in ipairs(self.orderedBindings) do
        binding:reactivateAll()
    end
end

function BindingSet:getDefaultDB()
    local result = {}
    for _, binding in ipairs(self.orderedBindings) do
        if binding.key ~= nil then
            result[binding.key] = binding:getDefaultDB()
        end
    end
    return result
end

function BindingSet:setDB(db)
    self.db = db
    for _, binding in ipairs(self.orderedBindings) do
        if binding.key then
            local info = db[binding.key]
            if info then
                binding:setDB(info)
            end
        end
    end
end

WowVision.input.bindings = BindingSet:new()

local ActivationSet = WowVision.Class("ActivationSet")
WowVision.input.ActivationSet = ActivationSet

function ActivationSet:initialize()
    self.activations = {}
    self.activated = {}
end

function ActivationSet:add(info)
    info.activated = {}
    if info.enabled == nil then
        info.enabled = true
    end
    tinsert(self.activations, info)
    return info
end

function ActivationSet:activate(activation, info)
    if not activation.enabled then
        return
    end
    local binding = activation.binding
    if not binding then
        error("ActivationSet binding has no binding attribute.")
    end
    if type(binding) == "string" then
        binding = self.inputManager.bindingRefs[binding]
        if not binding then
            error("No binding matching " .. info.binding .. ".")
        end
        activation.binding = binding --Cache
    end
    local newInfo = {}
    for k, v in pairs(activation) do
        newInfo[k] = v
    end
    for k, v in pairs(info) do
        newInfo[k] = v
    end
    local activated = binding:activate(newInfo)
    tinsert(activation.activated, activated)
end

function ActivationSet:deactivate(info)
    for _, activated in ipairs(info.activated) do
        info.binding:deactivate(activated)
    end
    info.activated = {}
end

function ActivationSet:activateAll(info)
    for _, activation in ipairs(self.activations) do
        self:activate(activation, info)
    end
end

function ActivationSet:deactivateAll()
    for _, info in ipairs(self.activations) do
        self:deactivate(info)
    end
end
