local L = WowVision:getLocale()

-- StateRule is a base class for state-machine rules.
-- Not registered directly — subclasses register themselves.
local StateRule = WowVision.monitors.ruleRegistry:createType({ key = "State" })

function StateRule:initialize(config)
    self._currentState = nil
    WowVision.monitors.Rule.initialize(self, config)
end

-- Override in subclasses
function StateRule:getStates()
    return {}
end

function StateRule:getStateAlert(stateKey)
    local field = self.class:getField(stateKey)
    if field and field.getAlert then
        return field:getAlert(self)
    end
    return self[stateKey]
end

function StateRule:getFallbackChain(stateKey)
    local states = self:getStates()
    local stateMap = {}
    for _, state in ipairs(states) do
        stateMap[state.key] = state
    end

    local chain = {}
    local current = stateKey
    while current do
        tinsert(chain, current)
        local state = stateMap[current]
        current = state and state.fallback or nil
    end
    return chain
end

function StateRule:resolveOutputStates(stateKey)
    local chain = self:getFallbackChain(stateKey)
    local resolved = {}

    for _, chainState in ipairs(chain) do
        local alert = self:getStateAlert(chainState)
        if alert and alert.outputs then
            for _, output in ipairs(alert.outputs) do
                if output.enabled and not resolved[output.key] then
                    resolved[output.key] = chainState
                end
            end
        end
    end

    return resolved
end

-- Check resolved output states and fire any that changed
-- Called every frame, not just on state transitions
function StateRule:updateResolved(stateKey)
    local newResolved = self:resolveOutputStates(stateKey)
    local previousResolved = self._resolvedStates

    -- First-ever resolve: establish state silently without firing
    if previousResolved == nil then
        self._resolvedStates = newResolved
        return
    end

    local message = { text = stateKey, state = stateKey, rule = self }

    for outputKey, resolvedState in pairs(newResolved) do
        if previousResolved[outputKey] ~= resolvedState then
            local alert = self:getStateAlert(resolvedState)
            if alert then
                for _, output in ipairs(alert.outputs) do
                    if output.key == outputKey and output.enabled then
                        output:fire(message)
                    end
                end
            end
        end
    end

    self._resolvedStates = newResolved
end

function StateRule:transitionTo(stateKey, message)
    self._currentState = stateKey
    self:updateResolved(stateKey)
end

function StateRule:getCurrentState()
    return self._currentState
end

function StateRule:reset()
    self._currentState = nil
    self._resolvedStates = {}
end

WowVision.monitors.StateRule = StateRule
