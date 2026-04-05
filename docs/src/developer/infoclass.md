# InfoClass & Fields

## Overview

Declarative property system. Define fields once, get validation, persistence, UI generation, and change events. This is the foundation for configurable objects throughout WowVision.

## Files

- `core/info/Info.lua` — InfoManager class + InfoClass mixin
- `core/info/Field.lua` — Base Field class
- `core/info/InfoFrame.lua` — UI wrapper for parameter APIs
- `core/info/types/` — Field type implementations

## InfoManager

Central registry managing Fields for a class.

```lua
local info = WowVision.info.InfoManager:new()
info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true },
    { key = "label", type = "String", persist = true },
})
```

**Key Methods:**
- `addField(config)` / `addFields(fields)` — Register fields
- `updateField(updates)` / `updateFields(updates)` — Modify existing field config
- `getField(key)` — Retrieve Field by key
- `getFieldValue(obj, key)` / `setFieldValue(obj, key, value)`
- `set(obj, info, ignoreRequired)` — Apply multiple field values (merge or replace mode)
- `getData(obj)` — Extract all field values as a table
- `setDB(obj, db)` — Restore all field values from database
- `getDefaultDB(obj)` — Get default values for database schema
- `getGenerator(obj)` — Generate UI for all fields
- `clone()` — Independent copy for inheritance

## InfoClass Mixin

**IMPORTANT:** InfoClass must be `:include()`d on **every class in the hierarchy** that adds its own fields. When `included(class)` runs, it clones the parent's InfoManager so the child can add fields without corrupting the parent.

```lua
-- CORRECT
local Parent = WowVision.Class("Parent"):include(WowVision.InfoClass)
Parent.info:addFields({ { key = "name", type = "String" } })

local Child = WowVision.Class("Child", Parent):include(WowVision.InfoClass)
Child.info:addFields({ { key = "age", type = "Number" } })
-- Child has name + age, Parent only has name

-- WRONG — forgetting InfoClass on Child
local Child = WowVision.Class("Child", Parent)
Child.info:addFields({ ... })  -- CORRUPTS Parent.info!
```

**Exception:** ComponentRegistry's `createType` auto-includes InfoClass on every type it creates.

**Instance methods provided:**
- `setInfo(config, ignoreRequired)` — Apply config to instance fields, calls `onSetInfo()` hook

## Field Base Class

```lua
{
    key = "fieldName",              -- Required: unique identifier
    type = "String",                -- Field subclass type
    label = "Display Label",        -- UI label
    default = "value",              -- Default value (or function)
    required = false,               -- Must have value
    once = false,                   -- Set only once (immutable after first set)
    persist = false,                -- Save to obj.db
    showInUI = true,                -- Include in generated UI
    sortPriority = 0,               -- UI ordering (lower = first)
    get = function(obj, key) end,   -- Custom getter
    set = function(obj, key, val) end, -- Custom setter
    getValueString = func,          -- Display formatter
    getStrategy = "adaptive",       -- "key" or "adaptive"
    compareMode = "deep",           -- "deep" or "direct" value comparison
}
```

### Field Lifecycle

1. **Definition:** `info:addField(config)` creates a Field instance
2. **Binding:** `field:set(obj, value)` validates, stores, persists, emits event
3. **UI Generation:** `field:getGenerator(obj)` returns UI spec with data binding
4. **Database:** `field:setDB(obj, db)` restores value from saved data

### Persistence Flow

- **On set:** if `persist=true` and `obj.db` exists → `obj.db[key] = value`
- **On restore:** `Field:setDB` temporarily sets `obj.db = nil` to prevent re-persistence during restore, then restores it

### Change Events

```lua
field.events.valueChange  -- emits (obj, key, value) on every change
```

### setInfo vs setDB

- `setInfo(config)` — "merge" mode by default: only sets fields present in config, applies defaults for unset fields
- `setDB(obj, db)` — restores ALL fields from database, no defaulting

## Field Types

| Type | UI Element | Key Features |
|------|-----------|--------------|
| String | EditBox | Text input |
| Number | EditBox | Min/max validation, comparison operators |
| Bool | Checkbox | Toggle, supports function values |
| Choice | Dropdown | Dynamic choices array |
| Array | List editor | Element validation, add/remove/edit |
| Category | Nested group | Contains its own InfoManager for child fields |
| Object | Type+params editor | Object type selector + dynamic parameter UI |
| TrackingConfig | Type+units+params | Object tracking configuration |
| ComponentArray | Factory list | Instance management via factory pattern |
| Alert | Alert editor | Lazy-creates Alert instances, links outputs to DB |
| Template | Format selector | Pre-defined or custom format strings |
| Time | Duration editor | Duration formatting (d/h/m/s) |
| Spell | Spell picker | Spell ID input with name lookup |
| VoicePack | Dropdown | Audio pack selector |
| Reference | Read-only | Delegates to another field |

### Creating New Field Types

```lua
local MyField, parent = WowVision.info:CreateFieldClass("MyType")
function MyField:validate(value) ... end
function MyField:getGenerator(obj) ... end
```

## ComponentArray Field

Manages arrays of runtime-created component instances (e.g., Rules in a Monitor). Uses a factory function to create instances from configs.

```lua
{
    key = "rules",
    type = "ComponentArray",
    persist = true,
    factory = function(config) return registry:createTemporaryComponent(config) end,
    getTypeKey = function(instance) return instance.class.name end,
    availableTypes = function() return { { key = "AuraState", label = "Aura State Rule" } } end,
}
```

`addElement` calls `instance:setDB()` when available to properly cascade DB linking to nested fields.

## Alert Field

Lazy-creates Alert instances. Used by StateRule for per-state alerts.

```lua
{ key = "applied", type = "Alert", persist = true,
  alert = { key = "applied", label = "Applied" },
  outputs = { { type = "Sound", key = "sound" }, { type = "TTS", key = "tts" } } }
```

## ComponentRegistry

Factory pattern for creating typed, extensible class hierarchies at runtime. See `core/components/`.

```lua
-- Create a registry
local registry = WowVision.components.createRegistry({
    path = "monitors/rule",
    type = "class",
    baseClass = Rule,
    classNameSuffix = "Rule",
})

-- createType creates a CLASS (not instance), auto-includes InfoClass
local AuraStateRule = registry:createType({ key = "AuraState", parent = "State" })
AuraStateRule.info:addFields({ ... })

-- createTemporaryComponent creates an INSTANCE
local rule = registry:createTemporaryComponent({ type = "AuraState", spell = 12345 })
```

**Where it's used:**
- `WowVision.monitors.registry` — Monitor types (Aura, Cooldown)
- `WowVision.monitors.ruleRegistry` — Rule types (State, AuraState, CooldownState)
- `WowVision.buffers.registry` — Buffer types (Static, Tracked, Message)

## Database Cascade Pattern

Classes stored in ComponentArrays need proper DB cascade:

```lua
function MyClass:setDB(db)
    self.class.info:setDB(self, db)
end
```

This ensures `InfoManager:setDB` iterates all fields, including AlertField which properly links Alert instances and their outputs to the database.
