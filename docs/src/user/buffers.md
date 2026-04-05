# Buffers

Buffers give you on-demand access to game state — health, mana, money, experience, auras, and more. Rather than waiting for something to be announced, you can check a buffer whenever you want.

## How Buffers Work

A buffer is a list of tracked game objects. An object is just a piece of game state: your current health, your gold, a buff on your character, your PvP flag. Each object updates in real time as the game state changes.

Buffers are organized into groups. You can have multiple buffers per group (for example, a "General" group with separate buffers for vitals, resources, and auras), and multiple groups to organize things however you like. All of this is configurable from the WowVision menu (`/wv`).

## Default Setup

Out of the box, WowVision comes with a General group containing one buffer that tracks:

- **Health** — your current and maximum health
- **Power** — your current resource (mana, energy, rage, etc.)
- **XP** — your experience and progress to the next level
- **Money** — your gold, silver, and copper
- **PvP Status** — whether you're flagged for PvP

## Navigating Buffers

- **Alt+Up** and **Alt+Down** cycle through items in the current buffer. Each item is announced as you land on it (e.g., "250/500 Health").
- **Alt+Left** and **Alt+Right** switch between buffers in the current group.
- **Alt+Ctrl+Left** and **Alt+Ctrl+Right** switch between buffer groups.

## Object Types

These are the types of game state you can track in a buffer:

| Type | What It Tracks | Example |
|---|---|---|
| Health | Current and max health for a unit | "250/500 Health" |
| Power | A specific resource type for a unit | "50/100 Energy" |
| Aura | A buff or debuff on a unit | "Blessing of Protection, 1 stack, 11s remaining" |
| Money | Your total gold | "5g 23s 45c" |
| XP | Experience progress | "XP: 45% (12500 of 25000)" |
| PvP | PvP flag status | "PVP: Enabled" |

Unit-based objects (Health, Power, Aura) can be configured to track any unit — yourself, your target, a party member, and so on.

## Buffer Types

There are two main kinds of buffers:

**Static buffers** contain a fixed list of objects that you choose. The default General buffer is a static buffer — you decide what goes in it and in what order.

**Tracked buffers** automatically populate based on a rule. For example, a tracked buffer set to follow your auras will automatically add and remove items as buffs and debuffs come and go. You don't manage the contents manually.

## Configuring Buffers

When adding an object to a static buffer, you choose the object type and set its parameters — which unit to track, which power type, and so on. For tracked buffers, you set the rule and the buffer handles the rest.
