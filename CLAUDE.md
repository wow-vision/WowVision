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
| `libs/` | Ace3, LibSharedMedia, LibRangeCheck |
| `locale/` | Git submodule: localization strings |
| `audio/` | Git submodule: voice packs |
| `docs/` | mdBook user and developer documentation |

**Loading order**: `libs.xml` -> `[version]/setup.lua` -> `modules.xml` (core) -> `[version]/modules.xml`. Version is determined by which TOC file WoW selects, no runtime checks.

## Class System (`core/Class.lua`)

The custom class library: classes with NATIVE fields and db persistence (it replaced middleclass and the old InfoClass in July 2026). All metatable magic lives in this one file; downstream code is plain Lua.

```lua
local Monitor = WowVision.Class("Monitor", Parent)
Monitor:addFields({
    { key = "label", type = "String", persist = true },
    { key = "enabled", type = "Bool", default = true, persist = true, global = false },
})
function Monitor:initialize(config)
    self:applyFields(config)      -- validates, fills defaults THROUGH setters
    self.tracker = nil            -- plain instance vars work normally
end

local m = Monitor:new({ label = "Test" })
m.enabled = false                 -- validates, stores, persists, emits valueChange
m:setDB({ char = charNode, global = globalNode })
```

**Field declarations** (`Class:addFields`): key, type (registry key), default (value or function(obj)), persist, `global` (DEFAULT TRUE -- `global = false` means per-character), setting (renders on the module settings screen), label, required, once, validate, get/set (custom accessors), showInUI.

**HARD RULES:**
- NEVER wire a field to get/set accessors that read or write `self.<key>` -- that re-enters the field metamethods and overflows the C stack. Use a plain field; keep helper methods thin.
- Change detection: scalars by value, TABLES BY IDENTITY. Assigning a different-but-equal table still stores it (reference semantics).
- A stored `false` is a value, never treat it as nil (no `x and y or nil` on field reads).
- Inheritance is a super-chain walk computed lazily -- a child declaring fields can NEVER corrupt its parent. `Class:updateField(def)` overrides an inherited field for that class only.
- Field definition OBJECTS are stable; subscribe to `Class:getField(key).events.valueChange` -- handlers receive `(subscriber, eventName, obj, key, value)`.

**DB pairs and scope:** `setDB({ char = node, global = node, overrides = map })`. Each field routes by scope: per-field override, then object-wide override (reserved `"*"` key), then the field's `global` flag. A char-only pair structurally traps everything below it (nesting rule). Containers (Dict, InstanceArray, ComponentArray) cascade setDB to child instances. Scope switching: `classes.setFieldScope` / `classes.setObjectScope` -- switching TO GLOBAL adopts the account value; switching TO CHARACTER forks the current value; nothing is ever deleted.

**Field types** (`classes.registerFieldType(key, {validate, toDB, fromDB, setDB, getDefaultDB, valueString, default, api}`): scalars live in `core/Class.lua`; complex types (ComponentArray, TrackingConfig, Template, Alert, Spell, Category, Time, VoicePack, DataBrowse, Array) in `core/fieldTypes.lua`. The `api` table exposes methods on built fields (`field:addElement(obj, x)`).

**FieldSet** (`classes.newFieldSet`): a standalone self-owned field collection (alert/output parameters, ObjectType parameters). `set:add(def)` returns the field; values live on the set; `set:setDB(node)` restores; `set:applyTo(obj, config)` applies a schema to an external object.

**Module settings:** `local settings = module:hasSettings()` then `settings:add({...})` declares a field on a per-module settings class; read/write as `module.settings.key`. `settings:addRef(key, alert.parameters)` links parameter screens.

**Stores:** WowVisionDB (per character) + WowVisionGlobalDB (account). Per-store migrations in `core/db.lua`. Settings default to the account store; monitors/buffers move per instance via the context menu (Shift-F10 -> Scope).

**Testing:** the class system is pure Lua -- `lua tools/headless-tests.lua` runs the full suite plus construction smokes for alerts, buffers, and monitors. Add a smoke when converting or adding a class family.

## Core Systems

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

-- Add fields to the type class
AuraStateRule:addFields({ { key = "spell", type = "Spell", persist = true } })

-- Create instances of a type
local rule = registry:createTemporaryComponent({ type = "AuraState", spell = 12345 })
-- This calls AuraStateRule:new(config)
```

**Key concepts:**
- `createType(config)` creates a **class** (not an instance).
- `createTemporaryComponent(config)` creates an **instance** of a registered type class.
- `createComponent(config)` creates and registers a named instance.
- `config.parent` specifies inheritance: `createType({ key = "AuraState", parent = "State" })` makes AuraStateRule inherit from StateRule.
- The `type = "class"` registry type (ClassRegistryType) handles the class creation. Field inheritance comes from the class system's chain walk.

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

- **Classes**: `WowVision.Class("Name", Parent)`; fields via `Class:addFields`
- **Registries**: key-value stores for type registries (objects, fields, elements, windows, outputs)
- **Fields**: declare configurable/persistable properties with Class:addFields; access as plain attributes
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
| `core/Class.lua` | The class library: classes, fields, db pairs, scope |
| `core/info/Field.lua` | Base Field class |
| `core/objects/types/type.lua` | ObjectType, GlobalType, UnitType |
| `core/monitors/Monitor.lua` | Monitor base class |
| `core/monitors/Rule.lua` | Rule base class |
| `core/buffers/Buffer.lua` | Buffer base class |
| `core/alerts/alerts.lua` | Alert + Output classes |

## Developer Docs

Detailed system documentation lives in `docs/src/developer/`:
- Architecture, Modules, Graph UI, Class System & Fields, Object Tracking, Alerts & Outputs
