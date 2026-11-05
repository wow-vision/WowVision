# Targeting

WowVision tells you what you target, lets you keep up to five "virtual focus" targets on keys, can switch the game's soft targeting on and off, can take your target's target with a key you assign, and opens the target's menu with a single key. This page covers all of it: the announcements, the keys, and the settings.

All targeting settings live in the WowVision menu (type /wv) under Targeting. Targeting works the same on every supported game version, apart from the notes marked for Retail and WoW: Forever. Soft targeting needs support from the game itself; if your version lacks one of its settings, /wv soft lists it as "not available".

## Targeting keys at a glance

| Key | Binding name | What it does |
|-----|--------------|--------------|
| Shift+I | Soft Target Enemy | Switches soft enemy targeting on or off |
| Shift+P | Soft Target Friend | Switches soft friend targeting on or off |
| Shift+O | Soft Target Interact | Switches soft interact targeting on or off |
| Alt+T | Open Target Menu | Opens the menu of your current target |
| unbound by default | Target of Target | Makes your target's target your target |
| unbound by default | Target Focus 1 to Target Focus 5 | Targets the unit you stored in that virtual focus slot |

You can change or add keys in the keybinding window (WowVision menu, UI, Bindings); see [Keybindings](../basics/keybindings.md). The complete list of all keys is in the [keybinding reference](../reference/keybindings.md).

If the addon Sku is loaded at the same time, WowVision leaves the soft targeting keys, the Target Focus keys and the /focus1 to /focus5 commands to Sku and does not register them. Target of Target and Alt+T are not affected.

## Hearing your target (hard target)

A "hard target" is the target you get the normal way: clicking, pressing Tab, a macro, or /target. Whenever your hard target changes to a new unit, WowVision reads it out.

What you hear is the same text the game shows in the mouse-over tooltip of that unit: its name, level, creature type, guild and so on. If the unit wears a raid marker, the marker name comes first, so you hear for example "Skull Gnoll Brute, Level 12 ...". The markers are Star, Circle, Diamond, Triangle, Moon, Square, X and Skull.

Some details:

- Clearing your target is silent. Only a new target is announced.
- The announcement interrupts whatever is being spoken, so quick target switching is never a backlog of old names.
- If the unit you target is already in combat with you, a short sound plays as well. WowVision decides this from the threat lists of you, your party or raid members and their pets, so it also works when only a party member or a pet is fighting it.
- (Retail and WoW: Forever only) The game hides which raid marker a unit has from addons. WowVision still tells you that there is one, but speaks its number instead of its name: 1 is Star, 2 Circle, 3 Diamond, 4 Triangle, 5 Moon, 6 Square, 7 X and 8 Skull. In some situations the game also hides a unit's identity from addons; the announcement keeps working, because the tooltip text is passed to speech as the game hands it over.

### Settings for hard target announcements

Open Targeting, then Hard Target. There are three alerts, each with the usual alert controls (see [Alerts](../basics/alerts.md)).

Target Change is the announcement above.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled (alert) | On | Switches the whole Target Change alert on or off |
| TTS Alert | On | Speaks the target. Its Priority Message (interrupts) setting is on by default, and Voice lets you pick a voice just for this alert |
| Announce Raid Target Marker on Hard Target | On | Puts the raid marker in front of the target's description |
| Target in Combat Sound | On | Plays the sound when the new target is in combat with you or your group; you can choose a different sound with its Sound setting |

(Classic Era, The Burning Crusade and Mists of Pandaria) Health Monitor reads your target's health aloud as it drops (or rises) in steps of five percent.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled (alert) | On | Switches the health readout on or off |
| TTS Alert | On | Speaks the percentage, for example "85%" |
| Voice Alert | Off | Plays a recorded number from your voice pack instead of text to speech |

The health is rounded up to the next multiple of five, so you hear "95%" as soon as the target is at or below 95 percent, then "90%", "85%" and so on. Nothing is said at full health or at zero. When you change targets, you hear the new target's health right after its name, unless it is at full health.

(Retail and WoW: Forever) There is no Health Monitor here, because the game hides a target's health from addons in combat, just when you need it. Use the game's own Combat Audio Alerts instead, in its Accessibility options: they can say your target's health, in combat too.

Example: you want a quieter fight, so you turn off health readouts.

1. Press Shift+F1 (or type /wv) to open the menu and go to Targeting, then Hard Target.
2. Choose Health Monitor.
3. Turn Enabled off.

Target Crowd Control tells you when your target is crowd controlled, by anyone: stunned, feared, polymorphed and the like. It works in combat too.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled (alert) | On | Switches the whole alert on or off |
| Controlled Sound | On | Plays a sound when your target becomes crowd controlled, or when you switch to a target that already is |
| Free Sound | On | Plays a sound when the crowd control on your target ends, or when you switch from a crowd controlled target to one that is free |
| TTS Alert | Off | Speaks "Controlled" or "Free" instead of, or in addition to, the sounds |

Switching from one free target to another is silent; you only hear the Free Sound when the target before was crowd controlled. Both sounds have a Sound setting where you can pick a different one.

This alert is available on Retail, WoW: Forever and Mists of Pandaria. On The Burning Crusade Anniversary the game gives no crowd control information, so the alert does not appear there.

## Soft targeting

Soft targeting is a game feature that picks a unit for you without a real target: the enemy in front of you, a friendly player, or something you can interact with (an NPC, a mailbox, a corpse to loot). The game's interact key acts on the soft interact target. WowVision lets you switch the three kinds on and off with a key, announces the unit when it changes, and exposes the game's hidden soft targeting options.

There are three kinds:

- Soft Target Enemy (Shift+I): the enemy the game would pick in front of you.
- Soft Target Friend (Shift+P): the friendly unit in front of you.
- Soft Target Interact (Shift+O): the nearest thing you can interact with.

All three are off by default.

### Switching them on and off

Press the key. WowVision toggles the setting and says, for example, "Soft Target Enemy Enabled" or "Soft Target Enemy Disabled". The key behaves exactly like the Enabled switch of the matching alert in the menu. Both turn the game's own soft targeting on (for keyboard and gamepad) or off.

The game does not allow these switches to change during combat. If you press the key in a fight, WowVision says for example "Soft Target Enemy Enabled, after combat", and the change is applied the moment combat ends.

If you have turned the interact key on in the game's own options, WowVision does not turn it off again when you log in; it only switches on the ones you have enabled in WowVision.

### What you hear

While a soft target type is on, WowVision announces each new soft target of that type: the unit's tooltip text, or at least its name, plus a short sound that is different for enemy, friend and interact. When the soft target disappears nothing is said.

Each type is an alert in the Targeting menu named Soft Target Enemy, Soft Target Friend and Soft Target Interact. The alert is off by default; its Enabled setting is what the key flips. Under it you find TTS Alert (spoken, interrupting by default) and Sound Alert, both on by default once the alert is on. You can pick a different sound with the Sound setting of the sound output.

### Arc and range

Every soft target type has two more settings, inside its alert in the Targeting menu: open Soft Target Enemy, Soft Target Friend or Soft Target Interact to find them. They default to the widest arc and the longest range, because the game's own values are made for players who can see what is in front of them. WowVision only writes them for a soft target type you have switched on, so the game's values stay in place for any type you do not use. Game Default, or a range of 0, puts the game's own value back.

| Setting | Default | What it does |
|---------|---------|--------------|
| Soft Target Enemy Arc | 180 Degrees in Front | How wide a cone in front of you soft enemy targeting looks at. Choices: Game Default, Directly in Front, 15 Degrees in Front, 180 Degrees in Front |
| Soft Target Enemy Range | 60 | Maximum distance in yards, 0 to 60. 0 means the game's own range |
| Soft Target Friend Arc | 180 Degrees in Front | The same choices, for friends |
| Soft Target Friend Range | 60 | 0 to 60 yards, 0 means the game's own range |
| Soft Target Interact Arc | 180 Degrees in Front | The same choices, for interact targets |
| Soft Target Interact Range | 20 | 0 to 20 yards, 0 means the game's own range. The upper limit is lower because a long interact reach picks up monsters behind walls and buildings |

### Soft targeting with a hard target

The game has an extra rule for what soft targeting does while you already have a real target. WowVision exposes it as one choice, Soft Targeting With a Hard Target (default Game Default):

| Choice | What happens |
|--------|--------------|
| Game Default | The game's own behavior. Choosing it puts the game's values back |
| Only Without an Attackable Hard Target | While a living enemy is targeted, soft targeting stays out of the way, so the interact key acts on that enemy instead of a corpse or a chair next to it. With a corpse, an NPC or a player you follow targeted, soft targeting keeps working |
| Only Without a Hard Target | Any real target turns soft targeting off |
| Always | Soft targeting works whatever you have targeted |

The mode follows every target change and also your target's death, and it works in combat too.

Make Soft Target the Hard Target (default Game Default) lets the game turn your real target into the soft one. Choices: Game Default, Off, Enemies, Friends. Like the on/off switches, this one is held until combat ends if you change it during a fight.

### Example: loot corpses and still interact with what is next to your target

1. Press Shift+O to switch soft interact on. You hear "Soft Target Interact Enabled".
2. In the Targeting menu set Soft Targeting With a Hard Target to Only Without an Attackable Hard Target.
3. Kill a monster and walk up to its corpse. WowVision says what the soft interact target is as it changes.
4. Press the game's interact key. While the dead monster is your target, soft targeting stays active, so the key loots the corpse. Had you targeted a living enemy next to the corpse instead, soft targeting would step aside and the interact key would act on that enemy.

### Checking the values: /wv soft

/wv soft reads out and prints to chat the current lock mode and every soft targeting game setting with its value and the game's default, for example "SoftTargetEnemy 3 (default 0)". Settings that are waiting for combat to end are marked "after combat" with the value they will get. A setting your game version does not have is listed as "not available". This is useful for bug reports.

## Virtual focus: five stored targets

The virtual focus works like the Sku feature of the same name. You store up to five targets by name and bring each back with its own key. It is independent of the game's own focus target.

The module is called Virtual Focus and sits under Targeting in the menu. It has no settings of its own.

### Storing a focus

Type /focus1 to /focus5 in chat.

- /focus1 with nothing after it stores the name of your current target in slot 1. Without a target, slot 1 keeps its old name and WowVision prints "No target. Use `/focus1 <name>` or target a unit."
- /focus2 Some Name stores that name in slot 2, whether or not you target anything.

WowVision answers in chat, for example "Focus 1 set to Hogger.". Storing is not possible during combat; WowVision then prints "Cannot set virtual focus while in combat." Do it before the pull.

### Using a focus

Bind a key to Target Focus 1 to Target Focus 5 (they are unbound by default; see [Keybindings](../basics/keybindings.md)). Pressing it targets the stored name, exactly like typing /target with that name. Pressing the key also works in combat.

Because the focus is a name, the game targets the nearest unit with that name. Two monsters with the same name cannot be told apart. Virtual focus slots are not saved: after /reload or a new login the slots are empty and must be set again.

### Example: three bosses in a raid

1. Target the first boss and type /focus1.
2. Target the second boss and type /focus2, then the third and /focus3.
3. In the keybinding window assign Alt+1, Alt+2 and Alt+3 to Target Focus 1, 2 and 3.
4. In the fight, Alt+1 targets the first boss and WowVision reads it as it would any target change.

## Your target's target

Target of Target has no key by default, so give it one in the keybinding window. Press it to target whatever your target is targeting: the enemy a group member is fighting, or the group member an enemy is attacking. WowVision reads the new target as it reads any target change. If the enemy is attacking you, you target yourself. It works in combat too, and it does not start an attack.

If you have no target, you hear "No target". If your target has no target, you hear "Your target has no target", and your target stays as it was.

## The target's menu: Alt+T

Press Alt+T to open the same menu that a right click on your target's portrait opens: Copy Character Name, Whisper, Invite and the rest, depending on what you target. Target yourself and you get entries such as Reset All Instances and the loot and dungeon difficulty choices.

Move through the menu with the arrow keys and press Enter on an entry; see [Using the interface](../basics/interface.md). Without a target nothing opens.

## Range to your target

While you have a target, the Range Changed alert, under Hard Target in the Targeting menu, plays your target's distance in yards from a voice pack whenever the distance changes. It is described in [The range readout](../windows/system.md#the-range-readout).

## Related pages

- [Combat](combat.md) for the combat alerts and enemy count.
- [Alerts](../basics/alerts.md) for how alert outputs work.
- [Navigation](navigation.md) for routing to your target.
