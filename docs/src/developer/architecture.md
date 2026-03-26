# Architecture

## Project Overview

WowVision is a World of Warcraft accessibility addon for visually impaired players. It provides TTS announcements, sound alerts, and audio-navigable buffers so players can access game state without a visual display.

Supports 4 game versions via separate TOC files: Vanilla, TBC, Mists, and Retail.

## Directory Structure

```
WowVision/
├── core/           # Main framework (~1.1M) - shared by all versions
│   ├── ui/         # Virtual DOM UI framework
│   ├── info/       # InfoManager/InfoClass/Field system
│   ├── objects/    # Object tracking system
│   ├── alerts/     # Alert/notification system
│   ├── buffers/    # Information buffers (audio-browsable lists)
│   ├── monitors/   # Reactive alert system (monitors + rules)
│   ├── module/     # Module base class
│   ├── components/ # ComponentRegistry factory system
│   ├── navigation/ # Compass, maps, location
│   ├── chat/       # Chat handling
│   ├── windows/    # Window modules (game menu, merchant, mail, etc.)
│   ├── dataBinding/ # Two-way data binding
│   ├── audio/      # TTS and audio playback
│   └── *.lua       # Core files (WowVision.lua, Event.lua, Registry.lua, etc.)
├── classic/        # Classic/Vanilla modules (shared by Vanilla, TBC, Mists)
├── tbc/            # TBC-specific modules
├── mists/          # Mists-specific modules
├── retail/         # Retail-specific modules
├── audio/          # Git submodule: voice packs
├── locale/         # Git submodule: localization strings
├── libs/           # Ace3, middleclass, LibSharedMedia, LibRangeCheck
├── docs/           # mdBook documentation
└── *.toc           # 4 TOC files (one per game version)
```

## Loading Chain

Each TOC file defines the load order:

1. `libs.xml` — Ace3 libraries
2. `[version]/setup.lua` — Version constants (e.g., `UI_DELAY`)
3. `modules.xml` — Core framework (all systems)
4. `[version]/modules.xml` — Version-specific modules

| TOC File | Interface | Setup | Modules Loaded |
|----------|-----------|-------|----------------|
| WowVision_Vanilla.toc | 11507 | classic/setup.lua | classic/ |
| WowVision_TBC.toc | 20505 | classic/setup.lua | classic/ + tbc/ |
| WowVision_Mists.toc | 50500 | classic/setup.lua | classic/ + mists/ |
| WowVision_Standard.toc | 120000 | retail/setup.lua | retail/ |

TBC and Mists both load `classic/` modules first, then layer their own on top. No runtime version checks — the TOC file selection handles everything.

## OOP System

All classes use `libs/middleclass.lua`:

```lua
local MyClass = WowVision.Class("MyClass", ParentClass)
MyClass:include(SomeMixin)
function MyClass:initialize(...) end
local instance = MyClass:new(...)
```

## Core Update Loop

```
WowVision:OnUpdate()
├── WowVision.objects:update()     # Object type updates (unit GUIDs, cooldowns, etc.)
├── Module.runAllUpdates()         # Monitor updates, buffer updates, etc.
└── UIHost:update()                # UI reconciliation, navigation, input
```

`objects:update()` runs first so game state is fresh before monitors and UI process it.

## Key Singletons

| Singleton | Purpose |
|-----------|---------|
| `WowVision` | Main addon (Ace3) |
| `WowVision.base` | Root module |
| `WowVision.objects` | Object type registry |
| `WowVision.ui` | UI element type manager |
| `WowVision.info` | Field type registry |
| `WowVision.dataBinding` | Data binding factory |
| `WowVision.buffers` | Buffer type registry |
| `WowVision.monitors` | Monitor/rule registries |
| `WowVision.components` | ComponentRegistry factory |
| `WowVision.alerts` | Alert/output type registry |
| `WowVision.spellHistory` | Spell cast history |

## Event System

Simple pub/sub used throughout:

```lua
local event = WowVision.Event:new("myEvent")
event:subscribe(subscriber, function(self, eventName, ...) end)
event:emit(arg1, arg2, ...)
event:unsubscribe(subscriber)
```

## Registry Pattern

Key-value store used for all type registries:

```lua
local reg = WowVision.Registry:new()
reg:register("key", value)
local item = reg:get("key")
-- reg.items = ordered array, reg.itemKeys = parallel key array
```

## Database / Persistence

WoW SavedVariables store persistent data in `WowVisionDB`. On initialization:

1. `WowVision:OnInitialize()` reconciles saved data with default schema
2. `WowVision.base:setDBObj(db)` cascades DB binding through the module hierarchy
3. Each module, alert, and field gets linked to its DB section
4. Field changes auto-persist via `obj.db[key] = value` in `Field:set()`

Classes stored in ComponentArrays (like Rules, Monitors) need a `setDB(db)` method that cascades through `self.class.info:setDB(self, db)` to properly link nested fields like Alerts.

## Version-Specific Differences

### Speech API
- **Classic/Mists:** `C_VoiceChat.SpeakText(voiceID, text, destination, rate, volume)`
- **Retail:** `C_VoiceChat.SpeakText(voiceID, text, rate, volume, false)` (different param order)

### Setup Constants
- **Classic:** `UI_DELAY = 0.01` (slower updates for older clients)
- **Retail:** `UI_DELAY = 0` (immediate updates)
