# WowVision

WowVision is a World of Warcraft accessibility addon for visually impaired players. It provides TTS announcements, sound alerts, and audio-navigable buffers so players can access game state without a visual display.

**Alpha v0.6.0** | ~235 Lua files | Supports Vanilla, TBC, Mists, and Retail via separate TOC files.

## Quick Orientation

| Directory | Purpose |
|-----------|---------|
| `core/` | Main framework shared by all versions (~1.1M) |
| `classic/` | Modules shared by Vanilla, TBC, and Mists |
| `tbc/` | TBC-specific modules |
| `mists/` | Mists-specific modules |
| `retail/` | Retail-specific modules |
| `libs/` | Ace3, middleclass, LibSharedMedia, LibRangeCheck |
| `locale/` | Git submodule: localization strings |
| `audio/` | Git submodule: voice packs |
| `docs/` | mdBook user and developer documentation |

**Loading order**: `libs.xml` -> `[version]/setup.lua` -> `modules.xml` (core) -> `[version]/modules.xml`. Version is determined by which TOC file WoW selects, no runtime checks.

## OOP System (middleclass)

All classes use `libs/middleclass.lua`:

```lua
local MyClass = WowVision.Class("MyClass", ParentClass)
MyClass:include(SomeMixin)
function MyClass:initialize(...) end
local instance = MyClass:new(...)
```

## Core Systems

### InfoClass / InfoManager / Fields (`core/info/`)

Declarative property system. Define fields once, get validation, persistence, UI generation, and change events.

```lua
local MyClass = WowVision.Class("MyClass"):include(WowVision.InfoClass)
MyClass.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"] },
    { key = "label", type = "String", persist = true, label = L["Label"] },
})
```

**IMPORTANT: InfoClass is a mixin, and it must be `:include()`d on EVERY child class in the hierarchy.** When `InfoClass:included(class)` runs, it clones the parent's `info` (InfoManager) so the child can add its own fields without affecting the parent. If you forget to include InfoClass on a subclass, it shares the parent's InfoManager and field additions corrupt the parent.

```lua
-- CORRECT: each class includes InfoClass
local Parent = WowVision.Class("Parent"):include(WowVision.InfoClass)
Parent.info:addFields({ { key = "name", type = "String" } })

local Child = WowVision.Class("Child", Parent):include(WowVision.InfoClass)
Child.info:addFields({ { key = "age", type = "Number" } })  -- Child has name + age, Parent only has name

-- WRONG: forgetting to include InfoClass on Child
local Child = WowVision.Class("Child", Parent)
Child.info:addFields({ { key = "age", type = "Number" } })  -- CORRUPTS Parent.info!
```

**Exception:** ComponentRegistry's `createType` automatically includes InfoClass on every type class it creates (see below), so you don't need to do it manually for registry-created types.

- `InfoManager` manages a collection of Field instances for a class
- `InfoClass` mixin gives any class an `info` (InfoManager) and `setInfo(config)` method
- `Field:set(obj, value)` validates, persists to `obj.db`, and emits `valueChange`
- `Field:setDB(obj, db)` restores from database (temporarily disables `obj.db` to prevent re-persist)
- Classes needing DB cascade should define `setDB(db)` (see Buffer, Rule, Monitor for examples)
- Field types: Bool, String, Number, Choice, Array, Category, Object, TrackingConfig, ComponentArray, Alert, Template, Time, VoicePack, Spell

### ComponentRegistry (`core/components/`)

Factory pattern for creating typed, extensible class hierarchies at runtime. Used by Monitors (monitor types, rule types) and Buffers (buffer types).

```lua
-- Create a registry with a base class
local registry = WowVision.components.createRegistry({
    path = "monitors/rule",
    type = "class",            -- Uses ClassRegistryType
    baseClass = Rule,
    classNameSuffix = "Rule",
})

-- Register a new type (creates a CLASS, not an instance)
local AuraStateRule = registry:createType({ key = "AuraState", parent = "State" })
-- AuraStateRule is now a class that inherits from StateRule
-- InfoClass is AUTOMATICALLY included by createType — no need to do it manually

-- Add fields to the type class
AuraStateRule.info:addFields({ { key = "spell", type = "Spell", persist = true } })

-- Create instances of a type
local rule = registry:createTemporaryComponent({ type = "AuraState", spell = 12345 })
-- This calls AuraStateRule:new(config)
```

**Key concepts:**
- `createType(config)` creates a **class** (not an instance). It auto-includes InfoClass and clones the parent's InfoManager.
- `createTemporaryComponent(config)` creates an **instance** of a registered type class.
- `createComponent(config)` creates and registers a named instance.
- `config.parent` specifies inheritance: `createType({ key = "AuraState", parent = "State" })` makes AuraStateRule inherit from StateRule.
- The `type = "class"` registry type (ClassRegistryType) handles the class creation. Each type gets its own InfoManager via the automatic InfoClass include.

**Where it's used:**
- `WowVision.monitors.registry` — Monitor types (Aura, Cooldown)
- `WowVision.monitors.ruleRegistry` — Rule types (State, AuraState, CooldownState)
- `WowVision.buffers.registry` — Buffer types (Static, Tracked, Message)

### Events (`core/Event.lua`)

Simple pub/sub:

```lua
local event = WowVision.Event:new("myEvent")
event:subscribe(subscriber, function(self, eventName, ...) end)
event:emit(arg1, arg2, ...)
event:unsubscribe(subscriber)
```

### Registry (`core/Registry.lua`)

Key-value store used everywhere for type registries:

```lua
local reg = WowVision.Registry:new()
reg:register("key", value)
reg:get("key")
```

### Object Tracking (`core/objects/`)

Game state representation. ObjectType defines schema (fields + params), Object is an instance, ObjectTracker subscribes to changes.

**Type hierarchy:**
- `ObjectType` — base, minimal tracking (single static object)
- `GlobalType` — type-wide tracker/object lifecycle for non-unit types (Cooldown)
- `UnitType` — unit-based tracking with GUID change detection (Health, Power, Aura)

```lua
-- Creating a tracker
local tracker = WowVision.objects:track({ type = "Aura", units = { "target" } })
tracker.events.add:subscribe(self, handler)
tracker.events.remove:subscribe(self, handler)
tracker.events.modify:subscribe(self, handler)
```

**ObjectTracker:verify** checks `trackingInfo.params` against `obj.params` for filtering. `modify(obj)` re-verifies and adds or removes the object accordingly — this enables dynamic filtering (e.g., Cooldown's `onCooldown` param).

**Field caching:** Fields can define `getCached(cache)` for fast reads from cached data, with `get(params)` as fallback hitting the WoW API.

### Buffers (`core/buffers/`)

Display containers for screen reader output. Users navigate them with keyboard shortcuts.

- **StaticBuffer** — fixed list of manually-configured objects
- **TrackedBuffer** — auto-populated via ObjectTracker (e.g., all auras on target)
- **ObjectItem** — bridge between Object instances and buffer display

### Monitors (`core/monitors/`)

Reactive alert system. Watches game state and fires sound/TTS alerts on changes.

- **Monitor** — watches objects via ObjectTracker, dispatches events to rules
- **Rule** — matches objects, computes state, fires alerts. Has `events.trackingDirty` and `getTrackingFields()` for notifying parent Monitor of config changes
- **StateRule** — state machine base (applied/pandemic/expiring/missing for auras, ready/charging/on_cooldown for cooldowns)
- **AuraMonitor** / **CooldownMonitor** — concrete monitor types

Monitors subscribe to their rules' `trackingDirty` events and restart tracking when rules or their config change.

### Alerts (`core/alerts/alerts.lua`)

Configurable notification outputs attached to modules and monitor rules.

```lua
local alert = WowVision.alerts.Alert:new({ key = "myAlert", label = "My Alert" })
alert:addOutput({ type = "Sound", key = "sound", label = "Sound Alert" })
alert:addOutput({ type = "TTS", key = "tts", label = "TTS Alert" })
alert:fire({ text = "Something happened" })
```

Output types: TTS (text-to-speech), Sound (sound file), Voice (voice pack audio).

### Modules (`core/module/Module.lua`)

Hierarchical feature containers with alerts, settings, and database persistence.

```lua
local module = WowVision.base:createModule("myModule")
module:setLabel(L["My Module"])
module:addAlert({ key = "alert", label = "Alert" })
```

### UI System (`core/ui/`)

React-like virtual DOM. Generator functions produce element specs, reconciliation diffs against the real UI.

```lua
WowVision.ui:CreateElement("List", {
    label = "My List",
    children = { { "Button", label = "Click Me", events = { click = handler } } }
})
```

## Conventions

- **Classes**: `WowVision.Class("Name", Parent):include(Mixin)`
- **Registries**: key-value stores for type registries (objects, fields, elements, windows, outputs)
- **InfoClass**: use for any class needing configurable/persistable/UI-generatable properties
- **Events**: `WowVision.Event:new("name")` with subscribe/emit pattern
- **Modules**: `parent:createModule(key)` with setLabel, addAlert, etc.
- **Locale strings**: `local L = WowVision:getLocale()` then `L["String Key"]`. Locale is a git submodule.
- **dynamicValues**: functions should return key=value tables, not indexed arrays (e.g., `{ numTabs = n }` not `{ n }`)
- **Version support**: no runtime version checks. TOC file selection determines which modules load. Shared code goes in `core/`, version-specific code in its directory.
- **Database persistence**: classes in ComponentArrays need a `setDB(db)` method that cascades through `self.class.info:setDB(self, db)` (see Buffer, Rule patterns).

## Key Entry Points

| File | Role |
|------|------|
| `core/WowVision.lua` | Main addon entry, OnInitialize, OnUpdate loop |
| `core/UIHost.lua` | UI orchestrator (window context, navigator, combat) |
| `core/module/Module.lua` | Module base class |
| `core/info/Info.lua` | InfoManager + InfoClass mixin |
| `core/info/Field.lua` | Base Field class |
| `core/objects/types/type.lua` | ObjectType, GlobalType, UnitType |
| `core/monitors/Monitor.lua` | Monitor base class |
| `core/monitors/Rule.lua` | Rule base class |
| `core/buffers/Buffer.lua` | Buffer base class |
| `core/alerts/alerts.lua` | Alert + Output classes |

## Developer Docs

Detailed system documentation lives in `docs/src/developer/`:
- Architecture, Modules, UI System, InfoClass & Fields, Object Tracking, Alerts & Outputs
