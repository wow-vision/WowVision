# Monitors System Implementation Plan

## Context

WowVision's Buffers system gives users passive, on-demand access to game state. The Monitors system fills the reactive gap: it automatically fires outputs (sounds, TTS) when game state changes in ways the user cares about. This is critical for combat awareness — tracking DoTs, health thresholds, resource levels — without requiring the player to manually check buffers.

The architecture is: **Monitor** (what to watch) → **Rule** (what conditions matter) → **Output** (what to do when conditions change). Rule types are constrained by the monitor type, keeping behavior sensible.

## File Structure

```
core/monitors/
  Monitor.lua          -- Monitor base class (InfoClass) + component registry
  Rule.lua             -- Rule base class (InfoClass) + rule component registry
  module.lua           -- Module setup, update loop, keybindings, menu
  modules.xml          -- Load order
  rules/
    StateRule.lua       -- State machine rule base class (not registered directly)
    modules.xml
  types/
    AuraMonitor.lua     -- Aura monitor + AuraStateRule (extends StateRule)
    modules.xml
```

## Implementation Phases

### Phase 1: Foundation Classes

#### 1a. Monitor Base Class + Registry (`core/monitors/Monitor.lua`)

Uses ComponentRegistry (same pattern as `buffers/Buffer.lua:120-146`). Monitor is the base class; concrete types (AuraMonitor, HealthMonitor, PowerMonitor) extend it via ComponentRegistry, which gives each its own InfoClass automatically.

```lua
local Monitor = WowVision.Class("Monitor"):include(WowVision.InfoClass)

Monitor.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true },
    { key = "label", type = "String", persist = true },
    { key = "rules", type = "ComponentArray", persist = true,
      factory = function(config)
          return WowVision.monitors.ruleRegistry:createTemporaryComponent(config)
      end,
      getTypeKey = function(instance)
          return instance.ruleType
      end,
      availableTypes = function()
          -- Each monitor type overrides this to filter by allowed rule types
          return {}
      end,
    },
})

local registry = WowVision.components.createRegistry({
    path = "monitors/monitor",
    type = "class",
    baseClass = Monitor,
    classNameSuffix = "Monitor",
})

WowVision.monitors = {
    Monitor = Monitor,
    registry = registry,
}

function WowVision.monitors:createType(key)
    return registry:createType({ key = key })
end

function WowVision.monitors:create(typeKey, params)
    params = params or {}
    params.type = typeKey
    return registry:createTemporaryComponent(params)
end
```

Each concrete type (e.g., AuraMonitor) adds its own fields (e.g., `unit`) directly on its InfoClass. Parameters like `unit` and `powerType` are just fields — no separate parameter system needed.

**Tracker lifecycle** (mirrors `TrackedBuffer:restartTracking/cleanupTracker`):
- `restartTracking()` — creates ObjectTracker, subscribes to events
- `cleanupTracker()` — unsubscribes, clears tracker
- `onSetInfo()` → calls `restartTracking()`
- On initialize, subscribes to `valueChange` on all fields returned by `getTrackingFields()`. When any of these change, calls `restartTracking()`. This is how parameter changes (e.g., switching unit from "target" to "player") trigger a new tracker.

**Methods on Monitor (overridden per type as needed):**
- `createTracker()` — creates ObjectTracker for this monitor's config; override per type
- `getTrackingFields()` — returns `{}` by default; override per type to list field keys that affect tracking (e.g., AuraMonitor returns `{ "unit" }`, PowerMonitor returns `{ "unit", "powerType" }`)
- `update()` — called every frame. The Monitor is the **single driver of state evaluation**. It iterates all objects in the tracker, computes state per object (monitor-type-specific logic), then passes results to matching rules. Rules don't query objects themselves — the Monitor does all the work and tells rules what their current state is. This avoids redundant lookups when multiple rules match the same object, and avoids relying on WoW events firing correctly.
- `computeObjectState(object)` — override per type. Given a tracked object, returns its current state (e.g., for auras: "applied", "pandemic", "expiring"). The Monitor calls this for each object, then matches results against rules.
- `updateRules()` — called by `update()`. For each rule, finds objects matching the rule's conditions, calls `rule:setObjectState(object, state)` with the computed state. Also detects removals — if a rule's `objectStates` contains objects no longer in the tracker, calls `rule:removeObject(object)` so the rule can fire its "missing" output.
- `getSettingsGenerator()` — delegates to `info:getGenerator(self)` (InfoClass handles it)
- `getLabel()` — returns label or auto-generated name

**Tracked objects:**
- The ObjectTracker maintains the live set of objects via add/remove events
- `trackedObjects = {}` — maps Object → true, updated by tracker event subscriptions
- The per-frame `update()` iterates this set — it does not rely on events for state evaluation

#### 1b. Rule Base Class + Component Registry (`core/monitors/Rule.lua`)

Same ComponentRegistry pattern. The rule registry is **global** — all rule types (both general-purpose and monitor-specific) are registered here.

```lua
local Rule = WowVision.Class("Rule"):include(WowVision.InfoClass)

Rule.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true },
    { key = "label", type = "String", persist = true },
})

local registry = WowVision.components.createRegistry({
    path = "monitors/rule",
    type = "class",
    baseClass = Rule,
    classNameSuffix = "Rule",
})

WowVision.monitors.Rule = Rule
WowVision.monitors.ruleRegistry = registry
```

Rules are primarily **configuration and state tracking** — they define what to match and what outputs to fire. The Monitor drives evaluation and tells rules their current state; rules don't query objects themselves.

**Alert storage:**
Rules own their alerts, following the same pattern as Module. Each rule stores alerts in `self.alerts[stateKey]`, with DB nested under the rule's own DB entry at `self.db.alerts`. Rules implement `getDefaultDBRecursive()` and `setDB(db)` to handle alert persistence, mirroring `Module:getDefaultDBRecursive()` and `Module:setDB()`.

```lua
-- DB structure for a rule instance:
{
    type = "AuraState",
    enabled = true,
    auraName = "Moonfire",
    alerts = {
        applied = { enabled = true, outputs = { sound = { enabled = true, path = "..." } } },
        pandemic = { enabled = true, outputs = { tts = { enabled = true } } },
        missing = { enabled = true, outputs = { sound = { enabled = true, path = "..." } } },
    },
}
```

**Methods:**
- `matches(object)` — returns true if this rule cares about the given object (e.g., aura name matches). Override per type.
- `addAlert(info)` — creates an Alert for a state, stores in `self.alerts[key]`. Same API as `Module:addAlert`.
- `fireAlert(stateKey, message)` — fires the alert for the given state key.
- `getDefaultDBRecursive()` — returns default DB including `alerts` section with all alert defaults.
- `setDB(db)` — restores rule state and propagates to alerts via `alert:setDB(db.alerts[key])`.
- `getSettingsGenerator()` — delegates to `info:getGenerator(self)` (InfoClass handles it). Alert settings appear as buttons opening each alert's parameters (via `addRef` pattern).

**Rule types in the global registry:**

The rule registry holds all rule types. Currently these are monitor-specific subclasses that extend a base rule class and add condition-specific fields. General-purpose rules can be added later.

- `AuraStateRule` — extends StateRule base with aura-specific fields (auraName, spellId, pandemicThreshold). Registered by AuraMonitor.

Each monitor type declares its `availableTypes` as the subset of global rule registry keys that apply to it. For example:
- AuraMonitor: `{ "AuraState" }`

### Phase 3: Rule Types

#### 3a. General-purpose rules (in `core/monitors/rules/`)

These are registered in the global rule registry and work with any monitor that lists them in `availableTypes`.

**StateRule** (`core/monitors/rules/StateRule.lua`)

Base class for state-machine rules. Tracks per-object state, compares against previous, fires per-state outputs on transition. **Not registered directly** in the rule registry — monitor-specific subclasses extend it and register themselves.

**Alerts:**
Each state maps to an Alert (using the existing alert system). The rule creates one Alert per state during initialization, and the user configures outputs (sound, TTS, voice) through the standard alert settings UI. No custom output storage needed.

```lua
self.alerts = {
    applied = Alert,
    pandemic = Alert,
    expiring = Alert,
    missing = Alert,
}
```

**State fallback chain:**
States have a dependency order. For aura states: `expiring → pandemic → applied` (missing is independent). Fallback is resolved **per output key** — each output type (sound, tts, voice) independently walks the chain to find the nearest state that has that output configured.

**Runtime state (not persisted):**
- `objectStates = {}` — table mapping object → resolved state info. Each entry tracks the resolved state per output key, not just the raw state:
  ```lua
  objectStates[object] = {
      state = "pandemic",                          -- raw state from Monitor
      resolved = { sound = "applied", tts = "pandemic" }  -- per output key
  }
  ```
- An output only fires when its resolved state changes (e.g., raw state goes from "applied" to "pandemic", but sound resolves to "applied" both times → sound doesn't fire, only TTS fires if pandemic has a TTS output).

**Methods (in addition to Rule base):**
- `setObjectState(object, stateKey)` — resolves the fallback chain per output key, compares to previous resolved states, fires only the outputs whose resolved state changed
- `removeObject(object)` — called when a previously matched object is no longer tracked. Fires "missing" alert outputs if applicable, removes from `objectStates`.
- `clearObjectStates()` — resets all tracked states (e.g., on tracker restart)
- `resolveOutputStates(stateKey)` — walks the fallback chain for each output key, returns the resolved table
- `getStates()` — returns the list of states and their fallback order (override per subclass)
- `getFallbackChain()` — returns the dependency order for state resolution (override per subclass)

The Monitor calls `setObjectState` for each matched object during its update loop. For objects that were previously in `objectStates` but no longer match (or are no longer in the tracker), the Monitor calls `removeObject`.

#### 3b. Monitor-specific rules (registered by monitor type files)

These extend base rule classes and add condition-specific fields.

**AuraStateRule** (registered by `core/monitors/types/AuraMonitor.lua`)

Extends StateRule. States: applied, pandemic, expiring, missing.

```lua
local AuraStateRule = WowVision.monitors.ruleRegistry:createType({ key = "AuraState", parent = "State" })
```

**Additional InfoClass fields:**
- `auraName` (String, persist=true) — aura to match
- `spellId` (Number, persist=true, optional) — for precision matching
- `pandemicThreshold` (Number, persist=true, default=30) — % of duration remaining
- `expiringThreshold` (Number, persist=true, default=5) — seconds remaining

**Alerts** (one per state, created during initialization):
- `applied` — fires when aura is active with comfortable duration
- `pandemic` — fires when aura is within pandemic window
- `expiring` — fires when aura is about to expire
- `missing` — fires when no matching aura is found on the unit

Users configure outputs (sound, TTS, voice) on each alert through the standard alert settings UI.

**Fallback chain:** `expiring → pandemic → applied` (missing is independent)

**`matches(object)`** — returns true if `object:get("name")` matches `self.auraName` or `object:get("spellId")` matches `self.spellId`. Prefers `isFromPlayerOrPlayerPet` matches.

The AuraMonitor's `computeObjectState(object)` determines the raw state:
- `duration == 0` (infinite) → "applied"
- `remaining <= expiringThreshold` → "expiring"
- `remaining/duration * 100 <= pandemicThreshold` → "pandemic"
- Otherwise → "applied"

The Monitor calls `rule:setObjectState(object, state)` for each matched object. The rule resolves fallback per output key and fires only the outputs whose resolved state changed. For objects that were previously tracked by the rule but are no longer in the tracker, the Monitor calls `rule:removeObject(object)`.

### Phase 4: Concrete Monitor Types

Each is a `createType` call that extends Monitor, adds type-specific InfoClass fields, and overrides `createTracker()`.

#### 4a. AuraMonitor (`core/monitors/types/AuraMonitor.lua`)

```lua
local AuraMonitor = WowVision.monitors:createType("Aura")
AuraMonitor.info:addFields({
    { key = "unit", type = "String", default = "target", persist = true, label = L["Unit"] },
})
-- Override createTracker to track Aura type on self.unit
-- Override computeObjectState to determine applied/pandemic/expiring from aura data
-- getTrackingFields returns { "unit" }
-- Allowed rule types: { "AuraState" }
-- Also registers AuraStateRule in the global rule registry
```

Health and Power monitors can be added later once their rule types are designed.

### Phase 5: Module + Integration (`core/monitors/module.lua`)

**Module setup:**
- `WowVision.base:createModule("monitors")`
- Stores monitor instances in `module.data.monitors` (ComponentArray pattern)
- Persistence via module DB → `data.monitors` array

**Update loop** (every frame):
- Iterates enabled monitors, calls `monitor:update()` on each
- Each Monitor's `update()` iterates its tracked objects, computes state via `computeObjectState()`, and passes results to matching rules via `rule:setObjectState(object, state)` / `rule:removeObject(object)`
- No throttling needed — object system already updates every frame without performance issues, and monitors are just evaluating cached state

**Keybindings:**
- Toggle all monitors (unbound by default)
- Status check — speak current state of all enabled monitors (unbound by default)

**Settings UI:**
- Monitor list via ComponentArray in /wv menu
- Each monitor opens settings panel with: label, enabled, parameters, rules list
- Each rule opens settings with: type-specific fields + per-state output config
- Output config per state: type choice (None/Sound/TTS/Voice) + type-specific settings

### Phase 6: XML + TOC Integration

**`core/monitors/modules.xml`** — load order: Monitor → Rule → rules/ → types/ → module

**`core/modules.xml`** — add `<Include file="monitors/modules.xml" />` after buffers

**Locale** — add monitor-related strings to `locale/enUS/`

## Critical Files to Reference

| Purpose | File | Why |
|---|---|---|
| Tracker lifecycle pattern | `core/buffers/types/TrackedBuffer.lua` | restartTracking/cleanupTracker/event subscription |
| Buffer base + registry | `core/buffers/Buffer.lua:120-146` | Exact pattern for Monitor base + registry setup |
| ClassRegistryType | `core/components/ClassRegistryType.lua` | How createType auto-includes InfoClass |
| ComponentArray field | `core/info/types/ComponentArray.lua` | Handles rules array: factory, persistence, UI |
| Alert/Output classes | `core/alerts/alerts.lua` | Output firing pattern reference |
| Aura ObjectType | `core/objects/types/unit/Aura.lua` | Aura fields, events, tracker integration |
| Module base class | `core/module/Module.lua` | Module lifecycle, settings, update loop |

## Per-State Output via Alerts

Each state on a StateRule maps to an Alert instance (using the existing alert system). Rules create their alerts during initialization based on `getStates()`, and store them in `self.alerts[stateKey]`. Alerts are persisted under `rule.db.alerts[stateKey]`, following the same pattern as `Module.alerts`. The user configures outputs (sound, TTS, voice) on each alert through the standard `/wv` settings UI — no custom output storage or UI needed.

Fallback resolution happens per output key independently. The rule tracks the resolved state per output key per object, and only fires an alert's specific output when the resolved state for that output key changes.

## Verification

1. Create an AuraMonitor tracking "target" with an AuraStateRule for a known buff
2. Configure "applied" alert with a sound, "missing" alert with a different sound
3. Apply the buff to a target dummy → hear "applied" sound
4. Wait for expiring threshold → no sound fires (expiring falls back to "applied" for sound, already played)
5. Let it fall off → hear "missing" sound
6. Configure "pandemic" alert with a TTS output → re-apply buff → enter pandemic → hear TTS, no sound (sound still resolved to "applied")
7. Verify persistence: reload UI, confirm monitors and alert configs restored from DB
8. Verify settings UI: open /wv → Monitors → add/edit/remove monitors, rules, and alert outputs
