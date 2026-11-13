# Alerts

An alert is something WowVision tells you without being asked: you changed zone, combat started, your target changed, you walked into a wall. Every alert can speak text, play a sound, play a recorded voice, or several of these at once, and every part can be switched on, off or changed in the [WowVision menu](./menu-and-settings.md). This page explains how alerts are built, how to change them, and lists every alert by module.

## Alerts and outputs

Each alert has:

- an Enabled switch that turns the whole alert on or off, and
- one or more outputs, the ways it reaches you. Each output has its own Enabled switch and its own settings.

There are four kinds of output.

| Output | Menu name | What it does |
|---|---|---|
| Text to speech | TTS Alert | Speaks text with your TTS voice, for example "combat started". |
| Sound | Sound Alert (or a more specific name) | Plays one sound file, for example a click or a chime. |
| Recorded voice | Voice Alert | Plays a recording from a [voice pack](./speech.md#recorded-voice-packs), for example "north" or a number. |
| Beacon | Beacon Sound | A directional sound that tells you where a waypoint is. Only used by navigation. |

An alert speaks only when the alert and the output are both enabled. Turn an alert off to silence all of it; turn one output off to keep the rest.

Example: Zone Changed Alert has a TTS Alert (on) and a Sound Alert (off). Out of the box, you hear the zone's name. If you want a chime as well, switch on the Sound Alert. If you only want the chime, switch off the TTS Alert too.

Alert settings are account-wide, so an alert you change on one character changes on all of them. To give one character its own version of an alert, press Shift+F10 on the alert's button and use Scope, see [per-character and account-wide settings](./menu-and-settings.md#per-character-and-account-wide-settings). The per-error filter of the Errors module is always shared by all your characters, and the alerts inside a monitor follow that [monitor's own scope](../information/monitors.md#account-wide-or-per-character).

## Finding and changing an alert

Alerts sit at the bottom of the screen of the module they belong to, after its settings, each as a button. (The Chat module lists its tab alerts right after Enabled, and Targeting keeps the three target alerts inside Hard Target.)

1. Open the WowVision menu with Shift+F1 and go into the module, for example Navigation, then Environmental Alerts.
2. Move down to the alert, for example Zone Changed Alert, and press Enter.
3. The alert's screen opens with an Enabled checkbox at the top, followed by one button per output. Alerts that have a setting of their own (such as Speak Messages for chat) show it here too.
4. Press Enter on an output, for example Sound Alert, to open its settings.
5. Escape goes back one level at a time.

### What an output's screen holds

Every output screen starts with Enabled. After that, depending on the kind of output:

| Setting | Output | What it does |
|---|---|---|
| Priority Message (interrupts) | TTS | When on, the current speech is stopped before this alert speaks. Off by default, except for alerts that must be heard at once, such as the Target Change alert and the soft target alerts. Not offered on the New Minimap Dot Alert, which is spoken by a game voice of its own. |
| Voice | TTS | Which TTS voice speaks this alert. Until you choose one it follows your Speech Voice setting and shows that voice's name. |
| Message | TTS | Only on TTS outputs that take their text from elsewhere, such as Announce Errors and the TTS Alert of a monitor rule. Alerts with wording of their own (combat started, a zone name, a chat message and so on) do not have it. When you type text here, it is spoken every time instead of the usual text. Leave it empty to hear the usual text. |
| Sound | Sound | A button that opens the sound browser. It reads the current file's name. See [Picking a sound](./menu-and-settings.md#picking-a-sound). Some sound alerts have a fixed sound and only the Enabled checkbox. |
| Voice Pack | Voice | Choose between the recorded voices Matthew and Joanna. |
| Beacon Sound | Beacon | A browser like the sound browser, for the beacon sounds. Moving onto one plays a sample at the chosen Beacon Volume. |
| Beacon Volume | Beacon | How loud the beacon pings are, 10 to 100 in steps of 10 (100 by default). Each 10 below 100 plays the pings one loudness level quieter; near and far targets still sound different. To silence the beacon, turn its Enabled off. |

Example: have your target's name spoken by a different voice.

1. Shift+F1, then T for Targeting, Enter.
2. Down to Hard Target, Enter, then to Target Change, Enter.
3. Down to TTS Alert, Enter, then Down (past Priority Message (interrupts)) to Voice, Enter.
4. Pick a voice from the list with Enter.

Example: put the compass on TTS instead of recorded voice.

1. Shift+F1, N (Navigation), Enter, then E for Environmental Alerts, Enter.
2. Open Speak Compass Direction. Open Voice Alert and turn Enabled off. Go back and open TTS Alert, turn Enabled on.

## The alerts, module by module

Menu paths read from the first level of the WowVision menu. The state in brackets is the default of each output. "On" means enabled. Where the default says nothing, the output is on.

### UI

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| Combat Started Alert | UI, Combat | You enter combat. | TTS "combat started" |
| Combat Ended Alert | UI, Combat | You leave combat. | TTS "combat ended" |
| Enemy Count Alert | UI, Combat | The number of enemies in the fight changes. Needs enemy nameplates switched on in the game: if they are off when combat starts, WowVision says "Turn on enemy nameplates to count enemies" once per session. See [Combat](../world/combat.md). | TTS (the number), Voice Alert (off; recorded numbers) |

### Navigation

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| Speak Compass Direction | Navigation, Environmental Alerts | The direction you face changes (north, northeast, east and so on). | Voice Alert (on; recorded directions), TTS Alert (off) |
| Zone Changed Alert | Navigation, Environmental Alerts | You enter a new zone. Speaks the zone's name. | TTS, Sound Alert (off) |
| Subzone Changed Alert | Navigation, Environmental Alerts | You enter a new subzone, such as a town district or a cave. Speaks its name. | TTS, Sound Alert (off) |
| Outdoors Alert | Navigation, Environmental Alerts | You step outside. Says "outdoors". | TTS, Sound Alert (off) |
| Indoors Alert | Navigation, Environmental Alerts | You go inside. Says "indoors". | TTS, Sound Alert (off) |
| Flying Started Alert | Navigation, Environmental Alerts | You take off on a flying mount. Says "flying". | TTS, Sound Alert (off) |
| Flying Ended Alert | Navigation, Environmental Alerts | You land. Says "flying ended". | TTS, Sound Alert (off) |
| Swimming Alert | Navigation, Environmental Alerts | You enter water. Says "swimming". | TTS, Sound Alert (off) |
| Diving Alert | Navigation, Environmental Alerts | You go under water. Says "diving". | TTS, Sound Alert (off) |
| Breath Alert | Navigation, Environmental Alerts | A breath, fatigue or feign death bar runs down by one step (Breath Step, default 10 percent). Says the bar's name and percent, "Breath 80". | TTS (game voice), Voice Alert (off), Sound Alert (off) |
| Fall Detection | Navigation, Fall Detection | You fall. The announcement is said once when the falling sounds start. | Falling Sound (a rising series of sounds; the longer the fall, the higher the sound), Falling Announcement (TTS "Falling") |
| Wall Detection | Navigation, Wall Detection | You are moving but something holds you back. | Five sounds for five degrees of blocking: Blocked, Mostly Blocked, Impeded, Slowed and Slightly Slowed. |
| Beacon | Navigation, Beacon and Routes | A route or beacon is active. | Beacon Sound (a directional ping that speeds up as you turn towards the target), Beacon Aligned (a click when you face it), Beacon Off Course (when you turn away), Waypoint Reached (when you arrive) |

Inside instances the game does not report which way you face, so Speak Compass Direction stays silent there while the other compass alerts keep working. The settings of Fall Detection (Delay (milliseconds), Ignore Jumps) are in the module's screen, see [Movement](../world/movement.md). The arrival settings of Beacon are in [Navigation](../world/navigation.md).

### Targeting

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| Target Change | Targeting, Hard Target | You target something. Speaks the facts you picked under Targeting, Names (by default name, level and the like), optionally starting with its raid marker. | TTS with Priority Message (interrupts) on and the setting Announce Raid Target Marker on Hard Target (on); Target in Combat Sound (plays a chime when your target is in combat with you or your group) |
| Health Monitor | Targeting, Hard Target | The target's health crosses a 5 percent step. Speaks the step, for example "75%". Not on Retail and WoW: Forever, where the game hides the health in combat; see [Targeting](../world/targeting.md). | TTS, Voice Alert (off; recorded numbers) |
| Target Crowd Control | Targeting, Hard Target | Your target becomes crowd controlled by anyone (stunned, feared, polymorphed and the like), or you switch to one that is; and again when it is free, or when you switch from a crowd controlled target to a free one. Not available on The Burning Crusade Anniversary. | Controlled Sound, Free Sound, TTS Alert (off; speaks "Controlled" or "Free") |
| Soft Target Enemy, Soft Target Friend, Soft Target Interact | Targeting | The game's soft target of that kind changes. Speaks the facts you picked under Targeting, Names, and plays a sound. The whole alert is off by default. Switch each alert on with Shift+I (enemy), Shift+P (friend) and Shift+O (interact), or its Enabled checkbox. It also holds the arc and range of that soft target, see [Targeting](../world/targeting.md). | TTS, Sound Alert |
| Range Changed | Targeting, Hard Target | The upper end of the range to your target changes, or you target something new. Says the number as a recording. | Voice Alert |

See [Targeting](../world/targeting.md) for the settings that go with these.

### Chat

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| One alert for each chat tab, named as the tab is named in the game (for example General) | Chat | A message arrives on that tab. | TTS Alert (speaks the message), Sound Alert (a chat sound), and the choice Speak Messages: When the Tab Is Shown (the default) or Always |
| Whisper Tabs | Chat | A message arrives on any whisper tab. One alert covers all whisper tabs. | The same, but Speak Messages defaults to Always |
| Chat Box Opened | Chat | The chat box takes the keyboard. | Sound Alert |
| Chat Box Closed | Chat | The chat box gives the keyboard back. | Sound Alert |

A message that reaches several tabs that speak is spoken only once. Temporary chat windows are not listed. See [Chat](../windows/chat.md).

### Errors

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| Announce Errors | Errors | The master switch for game error and info messages ("Ability is not ready yet", "Out of range"). It also voices Lua errors and messages the filter cannot sort. | TTS Alert |
| One entry for each message you have seen | Errors, Per-Error Filter | That message appears. Quest progress messages are left to the quest progress alerts of the Quests module. | TTS Alert (on), Sound Alert (off) |

The Per-Error Filter lists each message with its state read after its name: "Speech", "Sound", "Speech and Sound" or "Muted". Open one to change it. The Show All Known Errors checkbox at the top lists every message the game knows, including ones you have not met yet. Repeat Delay (2 seconds, 0 to 30) stops the same error from being spoken again while you hold a key. See [Combat](../world/combat.md).

### Other modules

| Alert | Menu path | When it fires | Outputs |
|---|---|---|---|
| New Minimap Dot Alert | Minimap Scanner | While you walk, a named dot comes onto the minimap. Speaks its name, level, whether it is indoors, and its kind. Needs Announce Tracked Dots While Walking (on). | TTS (spoken by the game's voice 0 unless you choose another voice), Sound Alert (off) |
| Quest Area Alert | Quests | You enter or leave the area of a quest. Says "Entering area: " or "Leaving area: " followed by the quest title. | TTS, Sound Alert (off) |
| Quest Progress Alert | Quests | The game shows a quest count moving. Says the game's message, for example "Kobold Vermin slain: 3/8". | TTS, Sound Alert (on) |
| Objective Complete Alert | Quests | The game shows an objective done, as "... (Complete)" or "Objective Complete.". Says the game's message. | TTS, Sound Alert (on) |
| Quest Complete Alert | Quests | Every objective of a quest is done, read from your quest log. Plays in place of the objective's sound; its speech says the quest's title and "Complete". | TTS (off), Sound Alert (on) |
| Available Quest Sound | Quests, Nearby | A quest you can accept has its giver near you. Plays a directional ping and says, for example, "Quest available: A Threat Within, 30 yards". Needs Questie. | Beacon Sound (on), TTS Alert (off) |
| Turn-In Quest Sound | Quests, Nearby | A complete quest in your log has the person to hand it in to near you. Plays a directional ping and says "Quest to turn in: " and the quest. Needs Questie. | Beacon Sound (on), TTS Alert (off) |
| Quest Objective Sound | Quests, Nearby | A quest in your log has an open objective near you. Plays a directional ping and says "Quest objective: " and the quest. Needs Questie. | Beacon Sound (on), TTS Alert (off) |
| Item Selected | Windows, Auction House | You select an auction in the browse list. Says "Selected: " and the item's name. (The Burning Crusade only.) | TTS |

See [Minimap](../world/minimap.md) and [Quests](../world/quests.md).

### Monitors

Monitors have alerts of their own, one per state of each rule. The rule types and their alerts are:

- Aura rule: Applied, Pandemic, Expiring and Missing.
- Cooldown rule: Ready, Charging and On Cooldown, plus Charge Gained and Charge Lost on Classic Era, The Burning Crusade and Mists of Pandaria.
- Cooldown Manager aura rule (Retail and WoW: Forever): Applied, Pandemic (not on WoW: Forever, which has no pandemic window) and Missing.
- Spell cooldown rule (Retail and WoW: Forever): Ready, Charging and On Cooldown.
- Proc rule (Retail and WoW: Forever): Proc and Proc Ended.

Each alert has a Sound Alert and a TTS Alert, and both outputs start off, so a new monitor is silent until you switch them on. The monitors page explains how to set them up. See [Monitors](../information/monitors.md).

## Tips

- Unsure what an alert sounds like? Open its Sound Alert output and arrow through the sounds: each one plays as you land on it.
- If you do not want to hear a certain game message, silence it with the Per-Error Filter instead of switching off Announce Errors.
- If a TTS alert is cut off too quickly by other speech, switch on Priority Message (interrupts) for it. If it keeps cutting off everything else, switch it off.

## See also

- [The WowVision menu and settings](./menu-and-settings.md)
- [Speech and sound](./speech.md)
- [Combat](../world/combat.md)
