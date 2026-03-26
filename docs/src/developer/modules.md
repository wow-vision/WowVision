# Modules

## Overview

Modules are hierarchical feature containers with alerts, settings, and database persistence. They form the organizational backbone of WowVision's features.

## Files

- `core/module/Module.lua` — Module base class

## Module Class

```lua
local module = WowVision.base:createModule("myModule")
module:setLabel(L["My Module"])
```

### Properties

- `key` — Unique identifier
- `enabled` — Boolean, persisted
- `vital` — If true, cannot be disabled
- `submodules` — Child modules
- `alerts` — Table of Alert instances
- `settings` — Settings data
- `db` — Database reference

### Hierarchy

```
WowVision.base (root)
├── windows
│   ├── character
│   ├── merchant
│   └── mail
├── targeting
├── navigation
│   └── compass
├── chat
├── combat
├── buffers
└── monitors
```

## Creating Modules

```lua
local module = WowVision.base:createModule("myFeature")
module:setLabel(L["My Feature"])

-- Add alerts
local alert = module:addAlert({ key = "notify", label = "Notification" })
alert:addOutput({ type = "TTS", key = "tts", label = "TTS" })

-- Fire alerts
module:fireAlert("notify", { text = "Something happened" })

-- Create submodules
local sub = module:createModule("subFeature")
```

## Database Binding

`Module:setDBObj(db)` cascades DB binding through the hierarchy:

```lua
function Module:setDBObj(db)
    self.enabled = db.enabled
    self.db = db
    -- Bind alerts
    for k, v in pairs(self.alerts) do
        v:setDB(db.alerts[k])
    end
    -- Bind settings
    self.settings = db.settings
    if self.settingsRoot then
        self.settingsRoot:setDB(db.settings)
    end
    self.data = db.data
    -- Recurse to submodules
    for _, submodule in ipairs(self.submodules) do
        submodule:setDBObj(db.submodules[submodule.key])
    end
end
```

Default DB schema:
```lua
function Module:getDefaultDBRecursive()
    return {
        enabled = self.enabled,
        submodules = { ... },
        alerts = self:getDefaultAlerts(),
        settings = self:getDefaultSettings(),
        data = self:getDefaultData(),
    }
end
```

## Update Handlers

Modules can register per-frame update functions:

```lua
module:hasUpdate(function(self)
    -- Called every frame when module is enabled
end)
```

`Module.runAllUpdates()` is called from the main update loop and iterates all registered update handlers.

## Settings UI

Modules can generate settings UI:

```lua
-- Settings root is an InfoFrame
module.settingsRoot = WowVision.info.InfoFrame:new({ key = "settings", label = "Settings" })
module.settingsRoot:add({ key = "volume", type = "Number", label = "Volume", default = 100 })
```

Alert parameters are automatically added to the module's settings UI.

## Lifecycle

1. **Definition:** Module files create modules and configure them (alerts, settings, submodules)
2. **Initialization:** `WowVision:OnInitialize()` reconciles DB, calls `setDBObj()` on the root module
3. **Enable:** `onFullEnable()` hook fires when the module is ready
4. **Update:** `hasUpdate` callbacks run each frame
5. **Disable:** Module can be toggled via `enabled` flag

## Key Methods

| Method | Purpose |
|--------|---------|
| `createModule(key)` | Create child module |
| `setLabel(label)` | Set display name |
| `addAlert(info)` | Add an alert |
| `fireAlert(key, message)` | Fire alert by key |
| `setDBObj(db)` | Bind to database |
| `hasUpdate(func)` | Register update handler |
| `getDefaultDBRecursive()` | Get default DB schema |
| `getDefaultData()` | Override for module-specific data defaults |
| `setVital(bool)` | Mark as non-disableable |
