-- Graph UI framework core. Ported from the WrathAccess/Tanglebeep key-graph
-- design, itself descended from Factorio Access. See
-- docs/src/developer/ui-rewrite-plan.md for the overall design.
WowVision.graph = WowVision.graph or {}

-- Two-tier node identity, so focus can be followed across rebuilds even when
-- the world shifts. `reference` (optional) is the game/domain object the node
-- was derived from (a Blizzard frame, a data object), matched by identity.
-- `key` (required) is the value-equatable structural identity: a string or
-- number, or a table compared by identity. Two ids are equal when their keys
-- are equal; the reference tier is applied explicitly during focus
-- reconciliation. Renders store nodes keyed by `key`.
local ControlId = {}
ControlId.__index = ControlId
ControlId.__eq = function(a, b)
    return a.key == b.key
end

function ControlId.structural(key)
    if key == nil then
        error("ControlId requires a structural key")
    end
    return setmetatable({ key = key }, ControlId)
end

function ControlId.referenced(reference, key)
    local id = ControlId.structural(key)
    id.reference = reference
    return id
end

-- The object doubles as the structural key (equality collapses to identity).
-- For wrapping a raw frame or object with no better key.
function ControlId.forObject(reference)
    if reference == nil then
        error("ControlId.forObject requires an object")
    end
    return ControlId.referenced(reference, reference)
end

function ControlId:referenceMatches(obj)
    return self.reference ~= nil and rawequal(self.reference, obj)
end

WowVision.graph.ControlId = ControlId
