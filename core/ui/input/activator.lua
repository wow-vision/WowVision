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
    self.padTokens = {}
    self.active = false
end

-- One pooled frame per input, configured with the action. A keyboard input
-- binds its key to the frame; a controller input attaches the frame to the
-- pad router (core/ui/input/pad.lua), or, for a game command, the command.
function Handle:_engage(inputs, padInputs, emulatedKey)
    local all = {}
    for _, input in ipairs(inputs) do
        tinsert(all, input)
    end
    for _, input in ipairs(padInputs or {}) do
        tinsert(all, input)
    end
    for _, input in ipairs(all) do
        local frame = self.inputManager:acquireFrame()
        self.action.configure(frame, self.spec, emulatedKey)
        -- spec.postClick: insecure follow-up on the SAME keypress, run after
        -- the secure action completes (focus bookkeeping behind a secure
        -- scroll, for example). Running after, it cannot taint the action.
        if self.spec.postClick ~= nil then
            local postClick = self.spec.postClick
            frame:SetScript("PostClick", function()
                local ok, err = pcall(postClick)
                if not ok then
                    geterrorhandler()(err)
                end
            end)
        end
        -- Actions that are not a secure click of the frame bind the input
        -- themselves (a game binding command, for example).
        local pad = WowVision.pad
        if pad.isPadInput(input) then
            local token
            if self.action.bind ~= nil then
                token = pad.attachCommand(input, self.spec.command)
            else
                token = pad.attach(input, frame, emulatedKey)
            end
            if token ~= nil then
                tinsert(self.padTokens, token)
            end
        elseif self.action.bind ~= nil then
            self.action.bind(frame, self.spec, input)
        else
            SetOverrideBindingClick(frame, true, input, frame:GetName(), emulatedKey)
        end
        tinsert(self.frames, frame)
    end
    self.active = #self.frames > 0
end

function Handle:release()
    if not self.active then
        return
    end
    for _, token in ipairs(self.padTokens) do
        WowVision.pad.detach(token)
    end
    self.padTokens = {}
    for _, frame in ipairs(self.frames) do
        self.action.clear(frame, self.spec)
        frame:SetScript("PostClick", nil)
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

    handle:_engage(keymap.inputs, keymap.padInputs, spec.emulatedKey or keymap.emulatedKey)
    return handle
end

-- Activate a spec on raw key names instead of a keymap: keys that are no
-- binding the player rebinds (the letters of letter navigation, see
-- graph/Host.lua). Same handle as activate.
function Activator:activateInputs(inputs, spec)
    local action = self.actions:get(spec.type)
    if action == nil then
        error("Unknown input action type: " .. tostring(spec.type))
    end
    local handle = Handle:new(self.inputManager, action, spec)
    handle:_engage(inputs, nil, spec.emulatedKey)
    return handle
end

-- Whether one of these raw key names is physically held (see anyInputHeld).
function Activator:inputsHeld(inputs)
    local heldKeys = WowVision.heldKeys
    return heldKeys.anyHeld(inputs, heldKeys.gameEnv())
end

-- Whether a key any of these keymaps would take is physically held. An
-- override set on a held key eats its release and leaves the game's command
-- (a turn, a move) running; callers wait a tick and ask again.
function Activator:anyInputHeld(keymapKeys)
    local inputs = {}
    for _, key in ipairs(keymapKeys) do
        local keymap = self.inputManager:getBinding(key)
        if keymap ~= nil then
            for _, input in ipairs(keymap.inputs) do
                tinsert(inputs, input)
            end
            for _, input in ipairs(keymap.padInputs or {}) do
                tinsert(inputs, input)
            end
        end
    end
    local heldKeys = WowVision.heldKeys
    return heldKeys.anyHeld(inputs, heldKeys.gameEnv())
end

-- One plain line on what the held check sees for these keymaps (the key log).
function Activator:describeInputs(keymapKeys)
    local inputs = {}
    for _, key in ipairs(keymapKeys) do
        local keymap = self.inputManager:getBinding(key)
        if keymap ~= nil then
            for _, input in ipairs(keymap.inputs) do
                tinsert(inputs, input)
            end
            for _, input in ipairs(keymap.padInputs or {}) do
                tinsert(inputs, input)
            end
        end
    end
    local heldKeys = WowVision.heldKeys
    return heldKeys.describe(inputs, heldKeys.gameEnv())
end

WowVision.inputActivator = Activator:new(WowVision.input, WowVision.inputActions)
