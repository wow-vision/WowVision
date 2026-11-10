# Movement and Surroundings

This page covers the parts of WowVision that help you move through the world without seeing it: the compass and facing announcements, zone names, indoors and outdoors, swimming and flying alerts, fall detection, wall detection, follow sounds, the corpse run, the camera settings WowVision manages, and the pitch lock.

Everything here is in the WowVision menu (type /wv) under Navigation. The route and waypoint features of the navigation window (F10) have their own page: [Navigation](navigation.md). These features have no keys of their own, and they work on every game version unless a note says otherwise.

| Menu entry | What it holds |
|------------|---------------|
| Navigation | Three settings: Auto-move to Interact Target, Automatically Navigate to Corpse and Announce Remaining Waypoints (described on the [Navigation](navigation.md#what-you-hear) page). The other entries under Navigation (maps, visited places, beacon and so on) are described on the [Navigation](navigation.md) page |
| Navigation, Compass | Facing, zone, indoors/outdoors, flying, swimming and diving alerts |
| Navigation, Fall Detection | Falling sounds and announcement |
| Navigation, Wall Detection | Collision sounds |
| Navigation, Follow | Sounds for following and un-following |
| Navigation, Pitch Lock | Keeps you level in water and air |

Each of these sub-menus has an Enabled switch at the top, so any feature can be turned off completely.

## Compass and surroundings

The Compass module watches your character and speaks when something about your surroundings changes. Each of its entries is an alert (see [Alerts](../basics/alerts.md)): it has an Enabled switch and one or more outputs, usually TTS Alert (speech) and Sound Alert.

| Alert | What triggers it | Default output |
|-------|------------------|----------------|
| Speak Compass Direction | You turn to face a different one of the eight directions | Voice Alert on, TTS Alert off |
| Zone Changed Alert | You enter a new zone | TTS Alert on, Sound Alert off |
| Subzone Changed Alert | You enter a new subzone (an area within a zone) | TTS Alert on, Sound Alert off |
| Outdoors Alert | You go from indoors to outdoors | TTS Alert on, Sound Alert off |
| Indoors Alert | You go from outdoors to indoors | TTS Alert on, Sound Alert off |
| Flying Started Alert | You take off on a flying mount | TTS Alert on, Sound Alert off |
| Flying Ended Alert | You land | TTS Alert on, Sound Alert off |
| Swimming Alert | You enter the water | TTS Alert on, Sound Alert off |
| Diving Alert | Your character goes under the surface | TTS Alert on, Sound Alert off |

### Compass direction

The compass says "north", "northwest", "west", "southwest", "south", "southeast", "east" or "northeast" whenever the direction your character faces moves from one of these eight sectors into another. Each sector is 45 degrees wide and centered on its direction, so "north" covers 22.5 degrees to either side of exactly north.

By default the direction is played from a recorded voice pack (the Voice Alert output) rather than spoken by text to speech. If you prefer text to speech, turn TTS Alert on and Voice Alert off. In the Voice Alert settings you can also choose a different voice pack. See [Speech](../basics/speech.md).

Inside some instances the game does not tell addons which way you face; the compass is then silent there, but all the other alerts in the table keep working.

### Zone and subzone

"Zone Changed Alert" speaks the zone name when you cross into a new zone, for example "Elwynn Forest". "Subzone Changed Alert" speaks the area name, for example "Goldshire". Nothing is said when the area has no name.

### Indoors, outdoors, flying, swimming, diving

You hear "outdoors" or "indoors" when the game decides that you changed from one to the other, "flying" when you take off on a flying mount, "flying ended" when you land, "swimming" when you enter water, and "diving" when you go under the surface. Walking back out of water does not say anything.

### Changing these

Every alert in the table except Speak Compass Direction has a Sound Alert, and it is off by default. To get a sound instead of or in addition to speech, open the alert, turn Sound Alert on and pick a sound with its Sound setting.

Example: you want a sound when you step indoors and no speech.

1. Press Shift+F1 (or type /wv), go to Navigation, then Compass, then Indoors Alert.
2. Turn TTS Alert off.
3. Turn Sound Alert on and choose a sound with Sound.

## Fall detection

When you fall, WowVision plays a rising series of tones that tells you how long you have been falling: the longer the fall, the further the sequence has climbed. It also says "Falling" once when the tones start. The tones are the same as the ones in Sku. After about five seconds the sequence reaches its end.

Settings in Navigation, Fall Detection:

| Setting | Default | What it does |
|---------|---------|--------------|
| Delay (milliseconds) | 200 | How long you must have been falling before anything is played, from 0 to 1000. A higher value hides short drops |
| Ignore Jumps | On | A fall that starts within a little under a second of pressing jump stays silent, so ordinary hops do not play tones. A long drop still alerts once that moment is over |
| Fall Detection (alert) Enabled | On | Switches the whole feature on or off |
| Falling Sound | On | The rising tones. Switch it off to keep only the announcement |
| Falling Announcement | On | Speaks "Falling" once at the start of the tones |

Water is not a fall: a fall that starts while you are swimming, or within a moment of leaving the water (for example jumping out of it), stays silent until you land.

Example: you walk off a ledge. After a fifth of a second you hear "Falling" and the first tone. The tones climb while you drop. When you land they stop.

## Wall detection

Wall detection tells you that you are pushing against something. While you are moving but your position hardly changes, WowVision plays a short clunk. The more you are held back, the more it sounds like a hard stop. This is the same system as Sku's, with the same sounds.

How it works: every fraction of a second WowVision compares how far you actually moved with how far your speed says you should have moved, and grades the shortfall in five steps:

| Grade (sound output) | Meaning |
|----------------------|---------|
| Blocked | You covered less than a quarter of the distance you should have: you are against a wall |
| Mostly Blocked | Between 25 and 45 percent |
| Impeded | Between 45 and 60 percent |
| Slowed | Between 60 and 85 percent |
| Slightly Slowed | Between 85 and 100 percent: something is only slightly in your way |

A sound plays only once three checks in a row are impeded (roughly every half second), so continuous pushing gives a steady rhythm of clunks, not a buzz. As soon as you move freely, the rhythm resets.

Things it takes care of:

- It follows your movement commands, no matter which keys you have bound for moving. Autorun counts as movement too.
- It also covers walks that the game makes for you: when you press the interact key and the game walks you to an NPC, or you use click to move. If such a walk ends before it reaches its goal (you got stuck on something), the Blocked sound plays once.
- Being stunned, rooted, feared or otherwise out of control is never reported as a wall, and nothing is graded while you are on a flight path.
- When you attack with the interact key, your character follows the enemy for the whole fight. Once you are in combat, wall detection stays quiet while your auto-attack is on and you press no movement key. On the way to the enemy, before the fight begins, it warns about an obstacle as usual, and so it does when you press a movement key.
- While swimming, your swimming speed is used for comparison.
- (Retail and WoW: Forever only) In combat the game hides your movement speed, so only a complete standstill can be noticed: you hear the Blocked sound but none of the slower grades.

Settings: open Navigation, Wall Detection, then Wall Detection (the alert).

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled | On | Switches wall detection on or off |
| Blocked, Mostly Blocked, Impeded, Slowed, Slightly Slowed | All on | Five sound outputs, each with its own Enabled switch and Sound choice, so you can for instance keep only the two hardest ones |

## Follow

When you follow another player (the game's follow function), WowVision plays a short sound as following starts and another as it ends. Following also ends by itself when the other player gets out of range, and you hear the stop sound then. As in the game, moving by hand ends following too.

| Setting | Default | What it does |
|---------|---------|--------------|
| Play Sound on Follow or Unfollow | On | Plays the two sounds. Turn it off for silent following |

## Interacting: Auto-move to Interact Target

In the Navigation menu itself:

| Setting | Default | What it does |
|---------|---------|--------------|
| Auto-move to Interact Target | On | Turns on the game's own "Click to Move" option (in the game options). With it on, interacting with a target that is out of reach, for example with the interact key, makes your character walk up to it first |

WowVision switches this on by default because new players otherwise find it hard to reach NPCs. WowVision sets the game's option to match at each login, so change it here rather than in the game's options.

## Corpse run

When you die and release your spirit, WowVision can start walking you to your corpse. This also happens when you log in or reload as a ghost.

| Setting | Default | What it does |
|---------|---------|--------------|
| Automatically Navigate to Corpse | On | After you release your spirit, a route to your corpse starts at once |

Here is what happens: you release your spirit; WowVision looks up where your corpse is, first on your current map and then on the larger maps around it (this finds a corpse that lies in the next zone from the graveyard you woke up in), and says "Corpse". It then starts a route to it, just as if you had chosen the corpse in the navigation window. Where WowNav route data is available (WoW: Forever), a corpse that lies over several floors is routed to the lowest floor that can be reached. If no route can be found, a beacon points straight at the corpse instead. The route is followed like any other; see [Navigation](navigation.md) for how routes and the beacon sounds work.

Details:

- Right after a loading screen the game may not know where the corpse is, so WowVision asks again for a few seconds (up to eight times, once a second) before giving up. If it gives up, you can still find the corpse with the scanner: press F9, and choose the corpse entry under Player. See [Scanner](scanner.md).
- The corpse is only routed to when it lies on the continent you are on. A corpse inside an instance is not walked to from outside.
- Turning the setting off does not stop the scanner entry; it only stops the automatic route.

## Camera

Turning to a waypoint, and the pitch lock below, steer your character by moving the game camera. For that to work reliably WowVision sets two game camera options once for each character, the first time you log in with the addon:

- The camera following style becomes "Always adjust camera", which means the camera always follows behind your character.
- Switching between saved camera views becomes instant.

When it changes one of these options, WowVision prints this message in chat: "WowVision set the camera to always follow behind your character, which turning to waypoints needs. You can change the camera following style in the game options under Controls." If you change the following style back afterwards, WowVision does not change it again for that character.

WowVision also uses camera view slot 5, one of the five views the game lets you save. It resets and snaps to that slot to put the camera straight behind your character and nearly level. If you use Save View 5 yourself, WowVision will overwrite it; use another slot for your own views.

With a gamepad on Retail and WoW: Forever, WowVision briefly turns the gamepad's free look off during a turn to a waypoint, then back on. See [Controller](../controller.md).

## Pitch lock

When you swim or fly, every turn to a waypoint used to tip your character's nose slightly downwards, until you were slowly diving and no key could correct it. The pitch lock prevents that by keeping your character level while you are in the water or in the air. It is on by default.

- It engages by itself as you start swimming (or flying) and lets go as soon as you are on land or on a flight path. You hear nothing.
- Space (swim up, ascend) and X (swim down, descend) keep working; you lose no vertical movement.
- If you are already tilted, the following all bring you back to level: pressing Space or X, the window of an NPC opening after the game walked you to it through water (gossip, quest or merchant window), and the key that turns you to the waypoint (I by default) when you are already facing it. These all rely on camera view slot 5.
- It works in combat.
- Flying: on Classic Era, The Burning Crusade and Mists of Pandaria the lock also holds while you fly. (Retail and WoW: Forever) the lock is only held while swimming, because skyriding steers by pitch.
- To dive and climb by pitch, turn the pitch lock off: open Navigation, Pitch Lock and switch Enabled off. The lock lets go at once.

The game does not let addons read the pitch limit back, so WowVision sets it to the game's normal value whenever you enter the world without the lock being held.

## Diagnostic commands

None of these features has a command, but if a movement key seems stuck after a window opened or combat ended, /wv keylog logs when WowVision takes and releases its keys. See [Combat](combat.md). Turn-to-waypoint problems use /wv turnlog, described on the [Navigation](navigation.md) page.

## Related pages

- [Navigation](navigation.md): routes, waypoints, the beacon and turning to waypoints.
- [Combat](combat.md): what happens to WowVision's keys in a fight.
- [Alerts](../basics/alerts.md): outputs, sounds and voices.
