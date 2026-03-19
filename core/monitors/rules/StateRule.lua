local L = WowVision:getLocale()

-- StateRule is a base class for state-machine rules.
-- It is NOT registered in the rule registry directly — subclasses register themselves.
-- We register it so subclasses can use parent = "State" in createType.
local StateRule = WowVision.monitors.ruleRegistry:createType({ key = "State" })

function StateRule:initialize(config)
    self.objectStates = {}
    WowVision.monitors.Rule.initialize(self, config)
end

-- Override in subclasses to return list of state keys and their fallback order
-- Returns: { { key = "applied" }, { key = "pandemic", fallback = "applied" }, ... }
function StateRule:getStates()
    return {}
end

-- Get the alert for a state key (alerts are InfoClass fields on the rule)
function StateRule:getStateAlert(stateKey)
    return self[stateKey]
end

-- Get the fallback chain for a state key
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

-- Resolve which state's alert to use for each output key
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

function StateRule:setObjectState(object, stateKey)
    local previous = self.objectStates[object]

    -- Early out if raw state hasn't changed — resolved states will be identical
    if previous and previous.state == stateKey then
        return
    end

    local previousResolved = previous and previous.resolved or {}
    local newResolved = self:resolveOutputStates(stateKey)

    local message = {
        text = stateKey,
        state = stateKey,
        object = object,
        rule = self,
    }

    -- Fire outputs where the resolved state changed
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

    self.objectStates[object] = {
        state = stateKey,
        resolved = newResolved,
    }
end

function StateRule:removeObject(object)
    local previous = self.objectStates[object]
    if not previous then
        return
    end

    local message = {
        text = "missing",
        state = "missing",
        object = object,
        rule = self,
    }

    -- Fire missing alert if we have one
    local missingAlert = self:getStateAlert("missing")
    if missingAlert then
        missingAlert:fire(message)
    end

    self.objectStates[object] = nil
end

function StateRule:clearObjectStates()
    self.objectStates = {}
end

WowVision.monitors.StateRule = StateRule
