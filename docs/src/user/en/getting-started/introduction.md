# Introduction

WowVision is an addon for World of Warcraft that makes the game playable without seeing the screen. It speaks through the text to speech voices built into the game and into Windows, so you do not need a screen reader running, although you can use one alongside it.

This manual explains WowVision from the player's point of view: what each feature does, which keys you press, what you will hear, and what you can change.

## What WowVision does

It reads the game's windows and lets you use them with the keyboard. Bags, merchants, quest givers, the talent tree, the mailbox, the auction house and many more are read like a desktop application: the arrow keys and Tab move, Enter is a left click, Backspace a right click, Space reads the tooltip. See [Using the Interface](../basics/interface.md) and [Game Windows](../windows/overview.md).

It tells you what happens around you. Your new target, the zone you enter, when you start falling, run into a wall, enter combat, how many enemies are fighting you, game error messages like "Out of range", incoming chat messages. Every one of these alerts can be spoken, played as a sound, or turned off. See [Alerts](../basics/alerts.md).

It keeps information ready for you. Buffers are lists you can read at any time with Alt and the arrow keys: your health and mana, gold, experience, free bag slots, the buffs and debuffs on you or your target, the messages of a chat tab, and whatever else you add. See [Buffers](../information/buffers.md).

It watches things for you. Monitors alert you when a debuff falls off your target, a spell is ready again, or a proc happens. See [Monitors](../information/monitors.md).

It guides you through the world. The navigation window (F10) plans routes along a network of waypoints and leads you there with sound beacons; the scanner (F9) lists quest givers, quest objectives and other things nearby; the minimap scan finds herbs and ore. See [Navigation and Routes](../world/navigation.md), [Scanner](../world/scanner.md) and [Minimap](../world/minimap.md).

It gives you extra controls. Soft targeting switches, five focus targets, a menu for your target, keys for loot rolls, and on Retail and WoW: Forever gamepad support. See [Targeting](../world/targeting.md) and [Controller](../controller.md).

## Supported game versions

| Version | Status |
|---|---|
| The Burning Crusade (anniversary realms) | Actively developed |
| Mists of Pandaria Classic | Actively developed |
| WoW: Forever | Actively developed, changes quickly |
| Classic Era | Shared features only |
| Retail | Shared features only |

"Shared features only" means everything that works on all versions is there (the interface, speech, alerts, buffers, chat, navigation, targeting and many common windows), but some game windows of that version are not read yet. The details are in [Features by Game Version](../reference/versions.md).

WowVision is in alpha. Things change from release to release, and some windows are still missing. Your bug reports help: see [Troubleshooting](troubleshooting.md#reporting-a-bug).

## WowVision and Sku

Many blind players know Sku, the older accessibility addon. WowVision was written with Sku players in mind: many sounds and behaviours (falling tones, wall sounds, the Alt Gr distance key, focus targets) work the way Sku players expect. You can install both; WowVision then leaves a number of windows and keys to Sku. See [Using WowVision together with Sku](installation.md#using-wowvision-together-with-sku).

WowVision does not read the login and character selection screens yet. The Sku login tool can get you through them: see [Logging In with the Sku Login Tool](sku-login.md).

## How this manual is organized

- Getting Started — [Installation](installation.md), [logging in](sku-login.md), the [Quick Start](quick-start.md) for your first minutes, and [Troubleshooting](troubleshooting.md).
- [Basics](../basics/index.md) — the interface, tooltips, speech, the settings menu, alerts and keybindings. Read these first.
- [Information on Demand](../information/index.md) — buffers and monitors.
- [In the World](../world/index.md) — targeting, combat, movement, navigation, minimap, scanner and quests.
- [Game Windows](../windows/overview.md) — every game window WowVision reads, one page per topic.
- [Controller](../controller.md) — playing with a gamepad on Retail and WoW: Forever.
- [Reference](../reference/index.md) — all keys, all commands, features per version, glossary and FAQ.

## Conventions in this manual

- Keys are written in bold, with a plus sign for keys pressed together: Ctrl+Shift+F means hold Ctrl and Shift and press F.
- Names of settings, buttons and menu entries are written in bold, exactly as WowVision speaks them, for example the Invert Item Direction setting.
- Spoken examples are in quotation marks: "250 / 500 Health".
- Features that exist only on some game versions are marked, for example (WoW: Forever only).
- Every key mentioned here is the default. You can change all of them; see [Keybindings](../basics/keybindings.md).

## Getting help

Questions, ideas and bug reports go to the [WowVision project on GitHub](https://github.com/wow-vision/WowVision).
