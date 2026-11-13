# Combat

This page explains what WowVision does when a fight starts and ends, how the combat alerts and the enemy count work, and how the Errors module reads the game's red and yellow messages aloud ("Out of range", "Ability is not ready yet" and so on).

The combat settings are in the WowVision menu (type /wv) under UI, then Combat. The error settings are under Errors.

## What happens when combat starts

WoW does not let addons change key bindings or use many of its functions during combat. WowVision therefore steps aside the moment a fight begins:

- The keys WowVision takes over to navigate its windows (the arrow keys, Tab and Ctrl+Tab, Home and End, the context menu key, letter navigation in menus, and the keys of the element you were on) are handed back to the game. Your movement keys and action bar keys behave exactly as the game intends.
- WowVision stops reading and updating its windows. No new windows are detected and no announcements about windows are made until combat is over.
- Keys that are not about windows, such as the soft targeting switches and the Target Focus keys, stay as they are. Some of them cannot do everything in combat; see below.
- With a gamepad on Retail and WoW: Forever, only the keys needed for the world, such as the right stick press, stay with WowVision. See [Controller](../controller.md).

When combat ends, WowVision takes its keys back as soon as none of the keys it needs is held down, and picks up where you were. Windows that were open stay open, and you are on the same element as before.

If you ever find a WowVision window stuck after a fight, type /wv close. It closes every WowVision window.

### Things that wait for combat to end

- Switching soft targeting on or off, and the Make Soft Target the Hard Target setting: WowVision says "after combat" and applies the change when the fight ends. See [Targeting](targeting.md).
- Storing a virtual focus with /focus1 to /focus5: refused with the message "Cannot set virtual focus while in combat."
- Capturing a new key in the keybinding window: WowVision says "Not in combat".
- The minimap scan and similar actions: they also say "Not in combat". See [Minimap](minimap.md).

### Retail and WoW: Forever: values hidden in combat

(Retail and WoW: Forever only) Blizzard hides a number of game values from addons, especially in combat and in instances. These are the ones that you notice in WowVision:

- Your target's health cannot be read, so there is no target health monitor. Use the game's own Combat Audio Alerts instead, in its Accessibility options: they can say your target's health, in combat too. See [Targeting](targeting.md).
- Your movement speed is hidden in combat, so wall detection can only notice that you are standing still, not that you are slowed ([Movement](movement.md)).
- Raid markers are spoken as numbers.
- Buffs and debuffs are read from their tooltips in combat ([Buffers](../information/buffers.md)).

Classic Era, The Burning Crusade and Mists of Pandaria do not have these limits.

## Your own health and resources

WowVision does not announce your own health or mana by itself. You read them whenever you want from the General buffer:

1. Press Alt+Down (with no window open). The first two lines of the General buffer are your health, for example "250 / 500 Health", and your main resource, for example "50 / 100 MANA".
2. Press Alt+Up to go back to the first line.

The lines are always current, also in combat. A second resource, such as combo points, holy power or soul shards, can be added as a line of its own; see [Watch a power other than your main one](../information/buffers.md#watch-a-power-other-than-your-main-one). The whole General buffer is described in [The default setup: the General group](../information/buffers.md#the-default-setup-the-general-group).

On Retail and WoW: Forever the [Group Health Monitor](../information/group-health.md) can include you: with Include Yourself on, you are number 1 and are announced when you are hurt.

## Combat alerts

Two alerts tell you when a fight begins and ends. They sit in UI, Combat:

| Alert | Default | What you hear |
|-------|---------|---------------|
| Combat Started Alert | On, spoken | "combat started" |
| Combat Ended Alert | On, spoken | "combat ended" |

Each has a TTS Alert output with the usual settings (see [Alerts](../basics/alerts.md)): you can turn the whole alert off with Enabled, turn off the spoken output, or choose a different voice for it. Only the spoken output exists for these two alerts.

## Enemy count

In a fight WowVision says how many enemies are in it, every time that number changes: "1", "3", "2", and "0" when the last one is gone. It is a quick way to know whether the pull went wrong, without reading any list.

### Settings

All in UI, Combat.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enemy Count Alert, Enabled | On | Switches the enemy count on or off |
| Enemy Count Alert, TTS Alert | On | Speaks the number |
| Enemy Count Alert, Voice Alert | Off | Plays a recorded number from your voice pack instead |
| Count Enemies | Attacking You or Your Group | Attacking You or Your Group counts every enemy that you, your pet or a group member is fighting; in a group, while you, your pet or a group member is in combat, also every enemy in combat that no one outside your group has tapped, so a fight your group starts without you counts at once. Attacking You counts only enemies that have you as their main target (those whose aggro you hold) |
| Count Elite Enemies Only | Off | Leaves out normal monsters. Elites, rare elites and world bosses still count |
| Announce Crowd Control | Off | Experimental. With Spell Names or Without Names, the number counts only the enemies still free to fight and crowd control is said apart (see below). Off keeps the plain count |
| Crowd Control Ended Alert, Sound Alert | On | The short sound for a crowd control that ends, with Announce Crowd Control on |

### Nameplates are required

The count comes from enemy nameplates, the health bars a sighted player sees above enemies. Without nameplates there is nothing to count. Turn on enemy nameplates in the game's options (the Enemy Units option in the Nameplates section; in some game versions they are off by default). If you enter combat with the alert on and the enemy nameplates off, WowVision says once: "Turn on enemy nameplates to count enemies". It does not repeat this until you reload the interface or log in again.

Some more things to know:

- An enemy counts only while its nameplate exists, which means within the game's nameplate range (about 45 yards on WoW: Forever).
- Turning on the Minor and Minions nameplate options in the game also counts small trash monsters and enemy pets.
- Only enemies that are hostile to you, alive and in combat count. Neutral monsters count once they are fighting.
- Enemy players count too. In a group, while you, your pet or a group member is in combat, every enemy player in combat near you counts, also one who is fighting someone outside your group: the game never marks a player as tapped. In PvP this gives you the wider picture, all enemy players fighting around you, as the nameplates show it to a sighted player.
- A number that other speech threw away before it was spoken (an interrupting alert such as a target change empties the speech queue) is said again once, when no newer number came within 5 seconds and the count did not change in the meantime. Only the spoken number is repeated: a voice pack number plays at once and is never thrown away. A number that was cut off while it was already being spoken is not repeated. Not on Vanilla.
- A new number is announced only after it has held for 0.3 seconds, so an enemy that flickers out of range and back is not spoken twice. The wait starts again at every change, so a pack that comes in one after another is said as one number, 0.3 seconds after the last enemy. The count is also re-checked every second during a fight, which catches monsters that die or give up quietly.

### Announce Crowd Control

This choice is experimental and off by default. With it on, a sheeped, stunned or feared enemy leaves the number, and you hear what happens to it in as few words as possible:

- A crowd control lands: its name alone, in your client's language. For monsters this is the spell, as the crowd control icon on their nameplate shows it ("Polymorph", "Frost Nova"); for enemy players the game's own word ("Stunned"). The number is one lower now; it is not said again.
- A crowd control ends while the enemy is still in the fight: a short sound, then the new number.
- Only controlled enemies are left: "0" and their names, for example "0, Polymorph", so it is not taken for the end of the fight.
- A controlled enemy dies: nothing by itself; the number or the end of combat says the rest.
- A kill in the same moment as a crowd control says both: "1, Frost Nova".

A typical pull: "3", "Polymorph" (one sheeped), "1", "0, Polymorph" (the others are dead), the sound and "1" (the sheep broke), then "0".

What counts as crowd control is what the game puts in the Crowd Control list on an enemy's nameplate: stuns, fears, polymorphs, roots and the like, not slows. On WoW: Forever, in combat, that list is hidden from addons; WowVision then follows the game's crowd control filter, which may count a slow too. On Retail, in combat and in instances, the auras of enemies are hidden from addons and every enemy counts as free.

One or two crowd controls landing together are named one after the other ("Polymorph, Frost Nova"). Three or more at once, usually one area spell, become a count: "3 Frost Nova" when every name is the same, else "3 controlled". On WoW: Forever the names are hidden from addons in combat: WowVision can speak them but not compare them, so three or more there always say "controlled". The same goes for "0" with three or more controlled enemies left: "0, 3 controlled". Where no name can be read, WowVision says "controlled".

Without Names skips the names, which can be long ("Hammer of Justice"): one control says "controlled", two or more at once "2 controlled". The sound for a control that ends works the same in both. The voice pack output plays only the numbers.

### Example

You pull three monsters in a dungeon. You hear "combat started", then "3". You kill one: "2". Your tank grabs the other two, you switch Count Enemies to Attacking You, and the number now falls to "0" while they are still alive, because none of them is attacking you any more. Switch it back to Attacking You or Your Group to follow the whole fight. When the last enemy dies you hear "0" and "combat ended".

## Errors and info messages

When the game shows you a red message at the top of the screen ("Out of range.", "Ability is not ready yet.", "You are too far away.") or a yellow information message, the Errors module speaks it. It also works on Retail, where the game normally hides some of these (out of range, out of rage, energy or focus, and spell and ability cooldown messages) from the screen: WowVision hears the message itself and says them anyway. It keeps working even when another addon hides the game's error display.

Every message goes through a filter in which you decide, message by message, whether it is spoken, played as a sound, or muted.

### Settings

Open Errors in the WowVision menu.

| Setting | Default | What it does |
|---------|---------|--------------|
| Announce Errors (alert), Enabled | On | The master switch. When off, no game message is spoken at all |
| Announce Errors, TTS Alert | On | How the messages listed under "Always spoken" below are spoken |
| Repeat Delay | 2 | Seconds, 0 to 30. The same message is spoken at most once in this time. This stops "Out of range" from stuttering while you keep a key pressed. 0 switches the delay off |
| Per-Error Filter | | Opens the filter screen described next |

Holding a key down still repeats the message, once every Repeat Delay seconds. The delay counts from the last time the message was actually spoken.

### The per-error filter

Choose Per-Error Filter to see a list of every error and info message you have met so far. Each one is a button. Its name is the message text, with names and numbers replaced by "..." so that all variations of a message share one entry. For example every "... has died." message is one entry whatever the name is. After the name, WowVision tells you what the entry does: Speech, Speech and Sound, Sound or Muted.

Press Enter on an entry to open its settings:

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled | On | Off mutes this message completely |
| TTS Alert | On | Speaks the message. Has the usual Priority Message (interrupts) and Voice settings |
| Sound Alert | Off | Plays a sound when the message appears. Turn it on and choose the sound with Sound |

The first item of the filter screen is Show All Known Errors (off by default). Normally an entry appears only after the message has happened to you once. Turn this on and the list also holds every message the game knows, so you can mute one in advance. The list is sorted alphabetically; in menus you can type the first letters of an entry to jump to it.

The filter is shared by all your characters: a message muted on one character stays muted on all of them.

Example: mute "Ability is not ready yet" but keep "Out of range".

1. Open the menu with /wv, go to Errors, then Per-Error Filter.
2. Find Ability is not ready yet. (if it is not in the list, turn on Show All Known Errors first) and press Enter.
3. Turn Enabled off and leave the screen with Escape. The entry now reads "Muted".
4. Leave Out of range. alone. It is still spoken.

### Always spoken, not filterable

- Messages that the game hands over in a form that cannot be inspected (a Retail restriction) are spoken as they are through the Announce Errors alert, because the filter cannot identify them.
- Lua errors, below.

### Lua errors

WoW's own Lua error window cannot be used with a screen reader. With Announce Errors on, WowVision speaks "Lua error:" followed by the message when an addon error happens. The same error is not spoken again for five seconds, so an error that repeats every frame does not flood speech. The errors are collected, up to the last 20, and are kept over /reload and logout.

## Diagnostic commands

| Command | What it does |
|---------|--------------|
| /wv soft | Reads the soft targeting values (see [Targeting](targeting.md)) |
| /wv errors | Shows the most recent Lua errors with their stack in a window you can copy from, and speaks the newest message. If the addon BugSack/BugGrabber is installed, its errors from this session are listed first |
| /wv errors all | The same, including earlier sessions when BugGrabber is installed |
| /wv errors clear | Clears the error list |
| /wv close | Closes every WowVision window |
| /wv keylog | Switches a log on that prints when WowVision takes and releases its navigation keys. Use it with a bug report if a movement key seems stuck after a window opened or combat ended |

When you report a bug, /wv errors is the first thing to try.

## Related pages

- [Targeting](targeting.md) for target announcements and focus keys.
- [Movement](movement.md) for falling, walls and similar alerts, which also work in combat.
- [Alerts](../basics/alerts.md) for configuring any alert.
