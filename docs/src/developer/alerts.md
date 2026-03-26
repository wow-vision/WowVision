# Alerts & Outputs

## Overview

Configurable notification system. Alerts have multiple outputs (TTS, Sound, Voice). Used both by the Module system (module-level alerts) and by Monitors (per-rule-state alerts).

## Files

- `core/alerts/alerts.lua` — Alert + AlertOutput base classes
- `core/alerts/outputs.lua` — TTS, Sound, Voice output implementations

## Alert Class

```lua
local alert = WowVision.alerts.Alert:new({ key = "myAlert", label = "My Alert" })
alert:addOutput({ type = "Sound", key = "sound", label = "Sound Alert", enabled = false })
alert:addOutput({ type = "TTS", key = "tts", label = "TTS Alert", enabled = false })
alert:fire({ text = "Something happened" })
```

**Properties:**
- `key` — Unique identifier (immutable)
- `label` — Display label
- `enabled` — Boolean, persisted
- `outputs` — Array of AlertOutput instances
- `parameters` — InfoFrame for UI configuration

**Methods:**
- `fire(message)` — If enabled, fires all enabled outputs with message
- `update()` — Calls update on all outputs
- `addOutput(info)` — Add output (TTS/Sound/Voice)
- `setDB(db)` / `getDefaultDBRecursive()` — Database persistence
- `setEnabled(enabled)` — Toggle alert

## AlertOutput Class

**Properties:**
- `key`, `label`, `tag` — Identity
- `shouldFire` — Optional conditional function
- `enabled` — Boolean
- `parameters` — InfoFrame for output-specific settings

**Methods:**
- `fire(message)` — Check shouldFire, call onFire
- `onFire(message)` — Abstract, implemented by output type subclasses
- `addParameter(info)` — Add configurable parameter

## Output Types

### TTS (Text-To-Speech)

```lua
alert:addOutput({
    type = "TTS", key = "tts", label = "TTS Alert",
    buildMessage = function(self, message) return message.text end,
    interrupt = false,
})
```

### Sound

```lua
alert:addOutput({
    type = "Sound", key = "sound", label = "Sound Alert",
    getPath = function(self, message) return "Sound/WowVision/alerts/notification.mp3" end,
})
```

### Voice

```lua
alert:addOutput({
    type = "Voice", key = "voice", label = "Voice Alert",
    getPath = function(self, message) return "Path", "directions/" .. message.dir .. ".mp3" end,
    voicePack = "Matthew",
})
```

## Firing Sequence

1. Something triggers `alert:fire(message)`
2. Alert checks `self.enabled`
3. For each output: checks `output.enabled` and `shouldFire(message)`
4. Calls `output:onFire(message)` — type-specific action (speak, play sound, etc.)

## Module Integration

```lua
local module = WowVision.base:createModule("myModule")
local alert = module:addAlert({ key = "myAlert", label = "My Alert" })
alert:addOutput({ type = "TTS", key = "tts", label = "TTS" })

-- Firing:
module:fireAlert("myAlert", { text = "Something happened" })
```

Module methods:
- `addAlert(info)` — Creates Alert, stores in `self.alerts`
- `fireAlert(alertKey, message)` — Fires alert by key
- `getDefaultAlerts()` — Returns default DB for all alerts
- DB auto-bound in `setDBObj()` — `db.alerts[alertKey]`

## Monitor Integration

In the monitors system, alerts are attached to rule states via Alert fields:

```lua
AuraStateRule.info:addFields({
    { key = "applied", type = "Alert", persist = true,
      alert = { key = "applied", label = "Applied" },
      outputs = {
          { type = "Sound", key = "sound", label = "Sound Alert", enabled = false },
          { type = "TTS", key = "tts", label = "TTS Alert", enabled = false },
      } },
})
```

The AlertField type lazy-creates Alert instances and links them to the database when `setDB` cascades through the rule.

## Database Persistence

```
Alert:getDefaultDBRecursive()
├── alert.parameters:getDefaultDB()
└── outputs[]:getDefaultDB()

Alert:setDB(db)
├── parameters:setDB(db)
└── outputs[]:setDB(db.outputs[key])
```

## Custom Output Parameters

```lua
output:addParameter({
    key = "announceRaidMarker",
    type = "Bool",
    label = "Announce Raid Target Marker",
    default = true,
})
-- Accessible as self.db.announceRaidMarker in buildMessage/shouldFire
```
