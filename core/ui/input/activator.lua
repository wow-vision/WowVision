-- The input activator: resolves a request of keymap name plus action spec,
-- acquires pooled secure frames, applies the action, and returns a release
-- handle. This is the input API the graph framework uses; the old framework's
-- Binding/ActivationSet path coexists beside it untouched.
--
-- During coexistence the keymap store is the existing named bindings
-- (WowVision.input:getBinding) -- they already carry the user's rebindable
-- inputs, the default emulated key, and persistence. When the old framework
-- is deleted, those collapse into plain keymap records and this file's lookup
-- is the only consumer left.
--
-- Combat: override bindings cannot change during combat lockdown. Callers own
-- the timing (the graph host defers binding swaps until combat ends), matching
-- how UIHost already sequences the old navigator around PLAYER_REGEN events.

local Handle = WowVision.Class("InputActivationHandle")

function Handle:initialize(inputManager, action, spec)
    self.inputManager = inputManager
    self.action = action
    self.spec = spec
    self.frames = {}
    self.active = false
end

function Handle:_engage(inputs, emulatedKey)
    for _, input in ipairs(inputs) do
        local frame = self.inputManager:acquireFrame()
        self.action.configure(frame, self.spec, emulatedKey)
        SetOverrideBindingClick(frame, true, input, frame:GetName(), emulatedKey)
        tinsert(self.frames, frame)
    end
    self.active = #self.frames > 0
end

function Handle:release()
    if not self.active then
        return
    end
    for _, frame in ipairs(self.frames) do
        self.action.clear(frame, self.spec)
        self.inputManager:releaseFrame(frame)
    end
    self.frames = {}
    self.active = false
end

local Activator = WowVision.Class("InputActivator")

function Activator:initialize(inputManager, actions)
    self.inputManager = inputManager
    self.actions = actions
end

-- Activate one spec: { binding = keymapKey, type = actionType, emulatedKey?,
-- ...action fields }. Always returns a handle; it is inactive (handle.active
-- false) when the keymap has no inputs bound or a conflicting addon is loaded.
-- Unknown keymap or action names are errors -- they are authoring bugs, not
-- runtime conditions.
function Activator:activate(spec)
    local keymap = self.inputManager:getBinding(spec.binding)
    if keymap == nil then
        error("Unknown keymap: " .. tostring(spec.binding))
    end
    local action = self.actions:get(spec.type)
    if action == nil then
        error("Unknown input action type: " .. tostring(spec.type))
    end

    local handle = Handle:new(self.inputManager, action, spec)

    local loaded = WowVision.loadedAddons
    if loaded ~= nil and keymap.conflictingAddons ~= nil then
        for _, addon in ipairs(keymap.conflictingAddons) do
            if loaded[addon] or loaded[addon:lower()] then
                return handle
            end
        end
    end

    handle:_engage(keymap.inputs, spec.emulatedKey or keymap.emulatedKey)
    return handle
end

WowVision.inputActivator = Activator:new(WowVision.input, WowVision.inputActions)
