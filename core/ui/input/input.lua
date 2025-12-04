local InputManager = WowVision.Class("InputManager")

function InputManager:initialize(name)
    self.name = name
    self.frameCount = 0
    self.frames = {}
    self.bindingTypes = WowVision.Registry:new()
    self.bindingRefs = {}
    self.framePool = CreateObjectPool(function(pool)
        self.frameCount = self.frameCount + 1
        local frame = CreateFrame("Button", self.name .. self.frameCount, UIParent, "SecureActionButtonTemplate")
        frame:RegisterForClicks("AnyDown")
        return frame
    end, function(_, frame)
        ClearOverrideBindings(frame)
        frame.binding = nil
        frame:SetAttribute("type", nil)
    end)
end

function InputManager:acquireFrame()
    local frame = self.framePool:Acquire()
    tinsert(self.frames, frame)
    return frame
end

function InputManager:releaseFrame(frame)
    for i, v in ipairs(self.frames) do
        if v == frame then
            table.remove(self.frames, i)
            break
        end
    end
    return self.framePool:Release(frame)
end

function InputManager:createBindingSet()
    local set = self.BindingSet:new()
    set.inputManager = self
    return set
end

function InputManager:createActivationSet()
    local set = self.ActivationSet:new()
    set.inputManager = self
    return set
end

function InputManager:createBindingType(key)
    local class = WowVision.Class(key .. "InputBinding", self.Binding):include(WowVision.InfoClass)
    self.bindingTypes:register(key, class)
    return class
end

function InputManager:createBinding(info, temporary)
    local class = self.bindingTypes:get(info.type)
    if not class then
        error("No binding type " .. info.type .. " found.")
    end
    local instance = class:new(info)
    instance.inputManager = self
    if temporary then
        return instance
    end
    self.bindings:add(instance)
    if instance.key then
        self.bindingRefs[instance.key] = instance
    end
    return instance
end

function InputManager:getBinding(key)
    return self.bindingRefs[key]
end

WowVision.input = InputManager:new("WowVisionInputManager")
