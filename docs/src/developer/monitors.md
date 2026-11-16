# Monitors

## Overview

Reactive alert system that watches game state and fires sound/TTS alerts on changes. While buffers are passive (check on demand), monitors are proactive — they fire automatically when conditions are met.

## Files

- `core/monitors/Monitor.lua` — Monitor base class
- `core/monitors/Rule.lua` — Rule base class
- `core/monitors/rules/StateRule.lua` — State machine rule base
- `core/monitors/types/AuraMonitor.lua` — Aura monitoring + AuraStateRule
- `core/monitors/types/CooldownMonitor.lua` — Cooldown monitoring + CooldownStateRule
- `core/monitors/module.lua` — Module setup and update registration
- `core/monitors/types/ResourceMonitor.lua` — Resource monitoring (all versions) + ResourceStepRule
- `core/monitors/types/resourceSteps.lua` — The Resource monitor's step rules, pure Lua (headless tests in `resourceTests.lua`)
- `core/monitors/types/resourceKey.lua` — The Speak Main Resource binding

## Architecture

```
Monitor (watches a thing)
├── Rules[] (what to watch for)
│   ├── States (conditions within a rule)
│   │   └── Alerts (what to do when state fires)
│   │       └── Outputs (TTS, Sound)
```

- Monitor — Watches objects via ObjectTracker, dispatches events to rules
- Rule — Matches objects, computes state, fires alerts
- StateRule — State machine base with fallback chains and output resolution

## Monitor Base Class

Monitors use ObjectTracker to watch game objects and distribute events to rules:

```lua
function Monitor:update()
    -- Restart tracking if dirty
    if self._trackingDirty then
        self._trackingDirty = false
        self:restartTracking()
    end
    -- Process buffered add/remove events
    for _, evt in ipairs(self.pendingEvents) do
        for _, rule in ipairs(rules) do
            if evt.type == "add" and rule:matches(evt.object) then
                rule:onObjectAdd(evt.object)
            elseif evt.type == "remove" then
                rule:onObjectRemove(evt.object)
            end
        end
    end
    -- Per-frame rule updates
    for _, rule in ipairs(rules) do
        rule:update()
    end
end
```

### Tracking Lifecycle

`_trackingDirty` triggers `restartTracking()` which:
1. Cleans up old tracker and resets all rules
2. Creates new tracker via `createTracker()` (subclass-defined)
3. Replays existing objects as "add" events
4. Subscribes to future add/remove/unitsChanged events

### Rules Change Detection

Monitor subscribes to:
- `rules` field's `valueChange` — triggers `onRulesChanged()` when rules are added/removed
- Each rule's `events.trackingDirty` — triggers `_trackingDirty = true` when rule config changes (spell, etc.)

```lua
function Monitor:onRulesChanged(rules)
    -- Unsubscribe from old rules' trackingDirty
    -- Subscribe to new rules' trackingDirty
    self._trackingDirty = true
end
```

## Rule Base Class

Rules match objects and compute state. They define which of their fields are tracking-relevant:

```lua
function Rule:initialize(config)
    self.events = { trackingDirty = WowVision.Event:new("trackingDirty") }
    self:setInfo(config)
    -- Subscribe to own tracking fields
    for _, key in ipairs(self:getTrackingFields()) do
        local field = self.class.info:getField(key)
        field.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
            if target == self then
                self.events.trackingDirty:emit(self)
            end
        end)
    end
end

function Rule:getTrackingFields() return {} end  -- Override in subclasses
```

Rules also have `setDB(db)` for proper Alert field cascade:
```lua
function Rule:setDB(db)
    self.class.info:setDB(self, db)
end
```

### Rule Interface

| Method | Purpose |
|--------|---------|
| `matches(object)` | Does this rule care about this object? |
| `onObjectAdd(object)` | Object matched, start tracking |
| `onObjectRemove(object)` | Object removed |
| `update()` | Per-frame state evaluation |
| `reset()` | Clear state (target change, tracking restart) |
| `getTrackingFields()` | Which fields trigger tracking restart |

## StateRule

State machine base for rules with multiple states and alert outputs per state:

```lua
function StateRule:getStates()
    return {
        { key = "applied" },
        { key = "pandemic", fallback = "applied" },
        { key = "expiring", fallback = "pandemic" },
    }
end
```

### State Resolution

`resolveOutputStates(stateKey)` walks the fallback chain and maps output keys to states. For example, if "expiring" doesn't have sound enabled but "pandemic" does (via fallback), the sound output resolves to "pandemic".

### Output Firing

`updateResolved(stateKey)` diffs resolved output states against previous:
- New output → fire
- Changed state for same output → fire
- Same state → skip

Initial state suppression: When `_resolvedStates` is `nil` (first-ever evaluation, e.g., login), state is established silently without firing. After `reset()`, `_resolvedStates` is `{}` (empty, not nil), so the next evaluation fires normally — this preserves `announceOnUnitChange` behavior.

### State Transitions

```lua
function StateRule:transitionTo(stateKey)
    self._currentState = stateKey
    self:updateResolved(stateKey)
end
```

## AuraMonitor

Watches buffs/debuffs on a unit via Aura ObjectTracker.

AuraStateRule tracks a spell through lifecycle states: applied → pandemic → expiring → missing.

```lua
function AuraStateRule:getTrackingFields()
    return { "spell", "playerOnly" }
end
```

The `playerOnly` check uses `UnitIsUnit(sourceUnit, "player")` to correctly filter to the current player's auras (not just any player's, which is what `isFromPlayerOrPlayerPet` means).

## CooldownMonitor

Watches spell cooldowns. Creates tracker with specific `spellIds` from rules.

CooldownStateRule tracks: ready → charging → on_cooldown. Also has event-based alerts for charge_gained/charge_lost.

```lua
function CooldownStateRule:getTrackingFields()
    return { "spell" }
end
```

## ResourceMonitor

Watches one of the player's own resources (`powerType`, a key of the Power game DB) and fires an alert per step. It reads `UnitPower`/`UnitPowerMax` in `update()` instead of an ObjectTracker. Counted resources (`resourceSteps.COUNTED`: combo points, holy power, ...) step on every count; bars step every `stepSize` percent down from 100 and fire the threshold they cross the way Blizzard's Combat Audio Alerts announce it (`resourceSteps.crossed`).

Each step is a `ResourceStepRule` in the monitor's `rules` array, with a hidden `value` and one Alert field (`Sound` + `ResourceSpeech`, an output that is only on or off; the monitor speaks with its own format, voice, rate, volume and minimum gap). The rules field is hidden: `renderGraphSettings` shows the monitor's fields and a Steps submenu with one alert button per step. The steps are built in `update()` when `builtFor` differs from `buildKey()` (resource, step size, sound series, the two defaults); a counted resource that grows gets the missing steps.

Retail and WoW: Forever hide some of the player's bar values (mana and energy measured; `C_Secrets.ShouldUnitPowerBeSecret`), so the Resource list leaves those out, a new monitor starts on a resource it can follow, and `read()` returns nothing while a value is secret. A step whose alert cannot be heard does not take a crossing (`isAudible`); switching the monitor off makes it settle in silence when it comes back on. `resourceKey.lua` speaks the shown resource on demand: a secret value is only concatenated into the text, and a bar's percent comes from `UnitPowerPercent` through a step curve.

## ComponentRegistry Integration

Both monitors and rules use ComponentRegistry:

- `WowVision.monitors.registry` — Monitor types (Aura, Cooldown)
- `WowVision.monitors.ruleRegistry` — Rule types (State → AuraState, CooldownState)

`createType` auto-includes InfoClass, so each type gets its own field definitions.

## Creating a New Monitor Type

1. Create the rule type via `ruleRegistry:createType({ key = "MyState", parent = "State" })`
2. Add rule-specific fields (spell, thresholds, Alert fields for each state)
3. Implement `getStates()`, `matches()`, `onObjectAdd/Remove()`, `update()`, `computeState()`
4. Override `getTrackingFields()` for fields that affect tracking
5. Create the monitor type via `WowVision.monitors:createType("MyMonitor")`
6. Override `createTracker()` to set up the ObjectTracker
7. Override `getTrackingFields()` if monitor-level fields affect tracking
8. Update the `rules` field's `availableTypes` to include your rule type
