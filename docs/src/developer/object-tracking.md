# Object Tracking

## Overview

The object tracking system represents game state as typed objects with declarative field schemas. ObjectTypes define what data is available, Objects are instances, and ObjectTrackers subscribe to changes.

## Files

- `core/objects/objects.lua` — Object class + Objects registry
- `core/objects/ObjectTracker.lua` — Tracker with event-based subscriptions
- `core/objects/types/type.lua` — ObjectType, GlobalType, UnitType base classes
- `core/objects/types/unit/` — Unit-based types (Health, Power, Aura, PVP)
- `core/objects/types/Cooldown.lua` — Cooldown tracking (GlobalType)
- `core/objects/types/PlayerMoney.lua`, `PlayerXP.lua` — Simple types

## Type Hierarchy

```
ObjectType          — Base: fields, params, templates. Minimal tracking (single static object).
├── GlobalType      — Type-wide tracker/object lifecycle for non-unit types.
│   └── Cooldown    — Spell cooldown tracking with event-driven updates.
└── UnitType        — Unit-based tracking with GUID change detection.
    ├── Health      — Unit health
    ├── Power       — Unit power (mana/rage/energy/etc.)
    ├── Aura        — Buffs and debuffs
    └── PVP         — PVP status
```

## Object Class

```lua
local obj = WowVision.objects:create("Health", { unit = "player" })
obj.type     -- Reference to ObjectType
obj.params   -- Identifying params (e.g., {unit = "player"})
obj:get(field)        -- Get field value
obj:exists()          -- Check existence
obj:getLabel()        -- Display label
obj:getFocusString()  -- Formatted display string
obj:serialize()       -- { type = key, params = {...} }
```

## ObjectTracker

Subscribes to objects matching criteria, emits events on changes:

```lua
local tracker = WowVision.objects:track({
    type = "Aura",
    units = { "target" },
    params = {},
})
tracker.events.add:subscribe(self, handler)
tracker.events.modify:subscribe(self, handler)
tracker.events.remove:subscribe(self, handler)
tracker.events.unitsChanged:subscribe(self, handler)
```

### Param Filtering

`ObjectTracker:verify(obj)` checks `trackingInfo.params` against `obj.params` using exact equality. Only params specified in `trackingInfo.params` are checked — missing keys are ignored (pass-through).

### Dynamic Filtering via modify

`ObjectTracker:modify(obj)` re-verifies the object:
- Verify passes + not tracked → add (emit `add` event)
- Verify fails + tracked → remove (emit `remove` event)

This enables dynamic filtering when object params change at runtime (e.g., Cooldown's `onCooldown` param flips when a spell becomes ready).

## GlobalType

Type-wide tracker/object lifecycle for non-unit types. Objects belong to the type itself rather than to a unit.

```lua
local MyType = WowVision.objects:createGlobalType("MyType")
```

**Methods:**
- `addObject(key, data)` / `removeObject(key)` / `modifyObject(key, newData)` — Object lifecycle, notifies all trackers
- `addTracker(tracker)` / `removeTracker(tracker)` — Tracker subscriptions
- `track(info)` / `untrack(tracker)` — Create/destroy trackers

**Subclass hooks:**
- `getObjectParams(key, data)` — Return params for new objects
- `getObjectKey(params)` — Extract key from params (for cache lookup)
- `getCache(params)` — Default implementation uses `getObjectKey`

### Cooldown (GlobalType subclass)

Tracks spell cooldowns. Auto-discovers spells from player casts:

1. `UNIT_SPELLCAST_SENT` → queue pending spell
2. `SPELL_UPDATE_COOLDOWN` → if pending spell has real cooldown (not GCD), promote to tracked object
3. `refreshAll()` runs each frame — detects state changes, updates `onCooldown` param, calls `modifyObject`

The `onCooldown` dynamic param enables trackers to filter to only active cooldowns.

## UnitType

Unit-based tracking with GUID change detection and per-unit object management:

```lua
local Health = WowVision.objects:createUnitType("Health")
```

Each tracked unit has a `unitTable`:
```lua
{
    id = "player",
    guid = "0x12345...",
    frame = frame,         -- For WoW event listening
    trackers = {},         -- Active ObjectTrackers
    objects = {}           -- { key -> { object, data } }
}
```

**GUID detection:** `onUpdate()` polls `UnitGUID()` each frame. On change, `changeUnit()` removes all old objects, updates GUID, calls `onUnitChange()` to load new data, emits `unitsChanged`.

**Event sequence during target change:**
1. Old objects removed → `tracker.events.remove`
2. GUID updated
3. `onUnitChange` → `fullUpdate` adds new objects → `tracker.events.add`
4. `unitsChanged` emitted

### Field Caching

Fields can define `getCached(cache)` for fast reads from `unit.objects[key].data`, with `get(params)` as fallback hitting the WoW API live.

## Data Flow

```
WoW event fires (e.g., UNIT_HEALTH)
  → ObjectType:onEvent() on unit's frame
  → modifyObject(unit, key, newData) → tracker:modify(object) for each tracker
  → ObjectTracker:modify() → verify → events.add/modify/remove:emit()
  → Monitor/Buffer subscriber handles the event
```

## Creating a New Object Type

1. Choose base: `createObjectType` (static), `createGlobalType` (dynamic lifecycle), `createUnitType` (unit-based)
2. Add parameters and fields
3. Implement `getCache(params)` for cached field access
4. For GlobalType: implement `getObjectParams`, `getObjectKey`, object lifecycle
5. For UnitType: implement `onUnitAdd`, `onUnitChange`, event handling
6. Register a default template for display
