# Monitors

Monitors watch game state and automatically alert you when something changes. While buffers let you check things on demand, monitors tell you what's happening without you having to look. For example, you might set up an Aura Monitor on your target with a rule for Moonfire. When Moonfire is applied, the monitor plays a sound. When it's about to expire, it plays a different sound. When it falls off entirely, it announces "missing" via text-to-speech.

## How Monitors Work

A monitor watches a specific aspect of the game — auras on a target, cooldowns on your spells — and contains one or more rules. Each rule defines what to watch for and what alerts to play when conditions are met. Monitors can track various state on one or more units. You might have an aura monitor set to track target units or you might have a cooldown monitor to track specific spells.

## Monitor Types

### Aura Monitor

Watches buffs and debuffs on a unit (yourself, your target, a party member, etc.).

| Setting | What It Does |
|---|---|
| Unit | Which unit to watch (e.g., "target", "player") |
| Announce on Target Change | Play alerts when you switch targets |

**Aura State Rules** track a specific spell through its lifecycle:

| State | When It Fires |
|---|---|
| Applied | The aura is active on the unit |
| Pandemic | The aura is within the pandemic refresh window |
| Expiring | The aura is about to fall off |
| Missing | The aura is not on the unit |

Each state has its own alerts (sound, TTS) that you can enable and configure independently.

Rule settings:

| Setting | What It Does |
|---|---|
| Spell | Which spell to watch for |
| Applied by Player | Only match auras you cast, not ones from other players |
| Pandemic Window (%) | Percentage of duration remaining to trigger the pandemic (refreshing will extend buff duration) state |
| Expiry Threshold (seconds) | Seconds remaining to trigger the expiring state |

### Cooldown Monitor

Watches your spell cooldowns.

**Cooldown State Rules** track a spell's cooldown through its states:

| State | When It Fires |
|---|---|
| Ready | The spell is off cooldown and usable |
| Charging | The spell has charges and at least one is available, but not all |
| On Cooldown | The spell is on cooldown with no available charges |

Cooldown rules also have event-based alerts for charge changes:

| Alert | When It Fires |
|---|---|
| Charge Gained | A charge becomes available |
| Charge Lost | A charge is consumed |

## Setting Up a Monitor

1. Open the WowVision menu (`/wv`)
2. Navigate to **Monitors**
3. Select **Add** and choose a monitor type
4. Configure the monitor settings (unit, label, etc.)
5. Navigate to **Rules** and select **Add** to create a rule
6. Set the spell and configure which alerts you want

## Configuring Alerts

Each rule state has two alert types:

- **Sound Alert** — plays a sound effect
- **TTS Alert** — speaks a message using text-to-speech

Both are disabled by default. To enable one, navigate into the state (e.g., "Applied"), select the alert type, and toggle it on. It is important that you ensure enable is checked for the state type as well as the alert type. For example for an applied state on an aura, the enabled checkbox for applied might be checked, as well as the enabled checkbox for the sound alert that is part of applied.

## Tips

- **Start simple.** Add one monitor with one rule and make sure it works before adding more.
- **Use "Applied by Player"** for auras in group content so you only track your own debuffs, not other players'.
- that being said, certain effects do not have a source unit (such as trinket procs.) If you want to track one of those, ensure that player only is unchecked for that specific effect.
- **Monitors work alongside buffers.** Use a monitor to alert you when Moonfire falls off, and a cooldown buffer to check your spell timers on demand.
