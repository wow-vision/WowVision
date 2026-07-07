# Class System & Fields

## Overview

`core/Class.lua` is WowVision's object system: classes with **native fields** — declared properties that validate, store, persist, and emit change events through plain Lua assignment. It replaced middleclass and the old InfoClass/InfoManager stack in July 2026. All metatable machinery lives in this one file (plus the complex field types in `core/fieldTypes.lua`); code everywhere else reads and writes fields like ordinary attributes.

The whole system is pure Lua with no WoW API dependencies: `lua tools/headless-tests.lua` runs its full suite, plus construction smokes for alerts, buffers, and monitors.

## Classes

```lua
local Monitor = WowVision.Class("Monitor", Parent)

Monitor:addFields({
    { key = "label",   type = "String", persist = true },
    { key = "enabled", type = "Bool", default = true, persist = true },
})

function Monitor:initialize(config)
    self:applyFields(config)   -- validates, fills defaults THROUGH the set path
    self.tracker = nil         -- plain instance variables work normally
end

local m = Monitor:new({ label = "Test" })
m.enabled = false              -- validates, stores, persists, emits valueChange
print(m.enabled)               -- reads storage, falling back to the default
```

Classes provide `new`, inheritance with direct parent calls (`Parent.initialize(self, ...)`), `isInstanceOf` / `isSubclassOf`, `instance.class`, `Class.name`, `Class.super`, and a minimal `include(mixin)`.

Inheritance of fields is a **super-chain walk computed lazily**: a child declaring fields can never corrupt its parent, declaration order is preserved (parents first), and a child redeclaring a key replaces the parent's field in place. `Class:updateField(def)` overrides an inherited field for that class only.

## Field declarations

| Key | Meaning |
|-----|---------|
| `key` | Required. The attribute name. |
| `type` | Field type registry key (default `Generic`). |
| `default` | Value or `function(obj)`. Applied through the set path by `applyFields`; materialized lazily on reads. |
| `persist` | Persist to the bound db. |
| `global` | **Default true** (account store). `global = false` means per-character. |
| `setting` | Renders on the module settings screen. |
| `label`, `showInUI`, `sortPriority` | Presentation. |
| `required`, `once` | Construction constraints. |
| `validate` | `function(field, value) -> value`; always runs on set, beats the type's validate. |
| `get` / `set` | Custom accessors owning storage. |

## Hard rules

1. **Never wire `get`/`set` accessors that read or write `self.<key>`** — that re-enters the field metamethods and overflows the C stack at construction. Use a plain field and keep helper methods thin wrappers.
2. **Change detection: scalars by value, tables by identity.** Assigning a different-but-equal table still stores it — code that aliases db tables relies on reference semantics.
3. **A stored `false` is a value.** Never use `x and y or z` idioms on field or db reads.
4. **Field definition objects are stable.** Subscribe with `Class:getField(key).events.valueChange:subscribe(subscriber, handler)`; handlers receive `(subscriber, eventName, obj, key, value)`. Sibling classes share inherited field objects.

## DB pairs and scope

An instance binds to storage with `obj:setDB(pair)` where a pair is `{ char = node, global = node, overrides = map }` (a bare node is shorthand for a char-only pair). Restore reads every persisted field from its resolved side; afterwards, writes persist automatically.

A field's side resolves in order: per-field override (`overrides[key]`), object-wide override (`overrides["*"]`), then the field's `global` flag. A char-only pair structurally traps every descendant on the character side — the nesting rule needs no policy code.

Scope switching (`classes.setFieldScope`, `classes.setObjectScope`):

- Switching **to global** *adopts* the account value (seeding it from the current value only when nothing account-wide exists). A character's value never leaks onto other characters.
- Switching **to character** *forks* the current value locally.
- Neither direction deletes the other side; switching is always reversible.

Container types cascade: `Dict` (keyed child instances, e.g. module submodules), `InstanceArray`, and `ComponentArray` thread constrained sub-pairs to children. Component arrays read **both** stores (account entries first), bind each instance to its config *table* (so array positions never matter), and move instances between stores via `field:setComponentScope`.

The stores themselves: `WowVisionDB` (per character) and `WowVisionGlobalDB` (account), each with its own version stamp and migration list in `core/db.lua`. The first character to log in after the global store ships seeds it from their settings.

## Field types

`classes.registerFieldType(key, fieldType)` where a field type is a plain table of optional functions:

```lua
{
    validate = function(field, value) return value end,   -- error() to reject
    toDB     = function(field, obj, value) return dbValue end,
    fromDB   = function(field, obj, dbValue, pair) return value end,
    setDB    = function(field, obj, pair) end,            -- containers take over restore
    getDefaultDB = function(field, obj, scope, forcedChar) end,
    valueString  = function(field, obj, value) return spoken end,
    default  = valueOrFunction,
    api      = { methodName = function(field, ...) end }, -- methods on built fields
}
```

Scalars (`Bool`, `String`, `Number`, `Choice`, `Table`) live in `core/Class.lua`; complex types (`ComponentArray`, `TrackingConfig`, `Template`, `Alert`, `Spell`, `Category`, `Time`, `VoicePack`, `DataBrowse`, `Array`, `Dict`, `InstanceArray`) in `core/fieldTypes.lua`. The `api` table is how a type exposes methods on its built field objects — `field:addElement(obj, x)` on component arrays, `field:getChoices(obj)` on choices.

The graph settings renderer picks a control per field by `field.typeKey` (`settings.registerFieldControl`).

## Standalone fields and FieldSets

`classes.newField(def)` builds a field not attached to any class, for code managing its own collection (the monitors module's container). On plain tables, `field:get(obj)` / `field:set(obj, value)` operate at `obj[key]` and persist to `obj.db`.

`classes.newFieldSet({ key, label })` is a self-owned field collection — the replacement for the old InfoFrame (alert and output parameters, object type parameters). `set:add(def)` returns the field (subscribe to its events, call `addChoice` on choices); values live on the set; `set:setDB(node)` restores; `set:addRef(key, target)` links another set as a child screen; `set:applyTo(obj, config)` applies the schema to an external object with validation and defaults.

## Module settings

```lua
local settings = module:hasSettings()
local rateSetting = settings:add({
    key = "speechRate", type = "Number", label = L["Speech Rate"], default = 0,
})
-- elsewhere:
if module.settings.speechRate > 0 then ... end
module.settings.speechRate = 5    -- validates, persists, emits
```

Settings are fields on a per-module settings class; `module.settings` is its instance. They default to the account store; users re-scope any setting, module, or component from the context menu (Shift-F10 → Scope).
