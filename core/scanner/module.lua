local module = WowVision.base:createModule("scanner")
local L = module.L
module:setLabel(L["Scanner"])
local settings = module:hasSettings()

-- The scanner: a tree of things and where they are, for looking around
-- without a screen. Providers register categories; each provider builds
-- its subtree from live data when the scanner OPENS (never per tick -- a
-- flying player cannot afford a hitch, so the tree is a snapshot and the
-- Refresh stop rebuilds it on demand). Only distance and direction are
-- live, computed per focused node from the player's current position.
--
-- A provider: { key, label, order?, optional?, build = function(ctx) -> nodes }
-- An optional provider's category is left out while it has no nodes.
-- ctx: { radius, maxEntries } from the settings, plus whatever the
-- provider needs from the game.
--
-- A node (plain data, built once per open):
--   key        string, unique among siblings, stable across refreshes
--              (an id, never a position in the list)
--   label      string
--   detail     string | function -> extra spoken part after the label
--   x, y       world position (Enter sets a beacon there and closes)
--   children   list of nodes, or function() -> list (built when expanded)
--   expanded   true to start expanded on first sight
--   onActivate function -> replaces the beacon action
--   onArrive   function, run when the beacon Enter set arrives
--   toggle     { get, set }: a checkbox instead; Enter flips it
--   details    list of strings, or function -> list: Backspace opens them
--              as a read-only child screen

settings:add({
    key = "radius",
    type = "Number",
    label = L["Scan Radius"],
    default = 500,
    min = 50,
    max = 5000,
})
settings:add({
    key = "maxEntries",
    type = "Number",
    label = L["Entries Per Category"],
    default = 25,
    min = 5,
    max = 200,
})

module.providers = {}

function module:registerProvider(provider)
    if provider == nil or provider.key == nil or provider.build == nil then
        error("scanner provider requires key and build")
    end
    for i, existing in ipairs(self.providers) do
        if existing.key == provider.key then
            self.providers[i] = provider
            return provider
        end
    end
    tinsert(self.providers, provider)
    table.sort(self.providers, function(a, b)
        local ao, bo = a.order or 100, b.order or 100
        if ao ~= bo then
            return ao < bo
        end
        return tostring(a.key) < tostring(b.key)
    end)
    return provider
end

function module:context()
    return { radius = self.settings.radius, maxEntries = self.settings.maxEntries }
end

-- One category node per provider. A provider that errors reads as an
-- error line under its category rather than killing the tree.
function module:buildTree()
    local ctx = self:context()
    local tree = {}
    for _, provider in ipairs(self.providers) do
        local ok, children = pcall(provider.build, ctx)
        if not ok then
            geterrorhandler()(children)
            children = { { key = "error", label = L["Error"] .. " " .. tostring(children) } }
        end
        if not (provider.optional and (children == nil or #children == 0)) then
            tinsert(tree, {
                key = provider.key,
                label = provider.label,
                children = children or {},
                expanded = provider.expanded ~= false,
            })
        end
    end
    return tree
end
