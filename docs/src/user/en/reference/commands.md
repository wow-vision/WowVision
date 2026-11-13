# Slash Commands

WowVision adds slash commands that you type in the game's chat box. This page lists every one of them: what it does, how to type it, an example, and on which game versions it exists.

## How commands work

There are two kinds.

- /wv commands start with /wv followed by a word, for example /wv speech 1 9 100. The word is not case sensitive. /wv on its own opens the WowVision menu, and so does /wv followed by a word that is not a command.
- Global commands are their own slash word, for example /beacon or /pquit.

Type a command in the chat box (open it with Enter or the game's chat key) and press Enter. Answers come back in different ways:

- Spoken by WowVision.
- Printed to your chat window. Open the WowVision chat window with Shift+F3 to read printed lines.
- Shown in a window of selected text. Press Ctrl+C to copy the text, for example into a bug report, and Escape to close the window.

Unless a command says otherwise, it exists on all game versions: Classic Era, The Burning Crusade (TBC), Mists of Pandaria (Mists), Retail and WoW: Forever.

## At a glance

| Command | What it does | Versions |
|---|---|---|
| /wv | Opens the WowVision menu | all |
| /wv speech | Sets or lists speech voice, rate and volume | all |
| /wv bind | Open the keybinding window | all |
| /wv close | Closes every WowVision window | all |
| /wv version | Prints the WowVision version | all |
| /wv accept | Accepts a group invitation, also in combat | all |
| /beacon | Sets a beacon, routes to a named place, or reads your position | all |
| /focus1 to /focus5 | Sets a virtual focus target | all, not with Sku |
| /pquit | Leaves your party | all, not with Sku |
| /dquit | Leaves the dungeon group or battleground | all, not with Sku |
| /enableaddon, /disableaddon | Turns an addon on or off and reloads | all, not with BlindSlash |
| /wv soft | Reads soft targeting values | all |
| /wv targetinfo | Lists what each fact of the target announcement says for your target | all |
| /wv mscan | Minimap scan and its log | where the minimap scan works |
| /wv quests | Quest data check | all |
| /wv errors | Shows Lua errors | all |
| /wv taint | Shows blocked protected calls | all |
| /wv dbcheck | Reports saved variable state | all |
| /wv turnlog | Lists the last turns to a waypoint | all |
| /wv unitturnlog | Lists the last turns to a target or focus | all |
| /wv keylog | Logs window key handling | all |
| /wv padlog | Restarts the controller log | Retail and WoW: Forever (gamepad interface on) |
| /wv cdmlog | Cooldown manager monitor log | Retail and WoW: Forever |

## Everyday commands

### /wv

Opens the WowVision menu, the same as Shift+F1. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

### /wv speech

Sets your speech voice, rate and volume in one go. It is handy in a macro that you press after login or /reload.

Syntax: /wv speech voice rate volume

| Argument | Meaning |
|---|---|
| voice | The number of a voice. Your first voice is number 0. |
| rate | The speech rate, from -10 to 10. Values outside are cut to that range. Optional. |
| volume | The volume, from 0 to 100. Optional. |

Rate and volume may be left off to keep the current values.

With nothing after it, /wv speech prints your current voice, rate and volume and lists every installed voice with its number, for example "Voice 0: Microsoft David Desktop".

Example: /wv speech 1 9 100 picks voice 1, rate 9, volume 100, and speaks "Speech voice ... rate 9, volume 100". An unknown voice number prints "No voice with id 5. Type /wv speech to list the voices". Anything that is not numbers prints "Usage: /wv speech voiceID rate volume, for example /wv speech 1 9 100".

Versions: all. See [Speech](../basics/speech.md).

### /wv bind

Opens the keybinding window directly, the same screen as WowVision menu (Shift+F1), UI, Bindings. Escape closes it. See [Keybindings](../basics/keybindings.md).

### /wv close

Closes every open WowVision window at once. Use it when a window seems stuck. The game's own frames are not closed. Versions: all.

### /wv version

Prints the installed WowVision version to your chat window, for example V0.9.0, or "beta" for the beta pre-release. Versions: all.

### /wv accept

Accepts the group invitation that is shown and says "Group invitation accepted". It also works in combat, where WowVision cannot open the invitation popup. Without an invitation it says "No group invitation". An invitation that asks for a role needs a checked role first, otherwise it says "Choose a role first". The Accept Group Invitation key does the same; it is unbound. Versions: all. See [Group Finder](../windows/group-finder.md).

### /beacon

Sets a straight-line beacon, routes to a named place, or tells you where you are. The beacon then plays its sound and speaks as you walk. This is the same beacon the navigation window uses. See [Navigation](../world/navigation.md).

| Typed | What it does |
|---|---|
| /beacon | Speaks your position on the zone map (for example "50.5 30.4") and, if a beacon is active, its distance and the degrees to turn |
| /beacon x y | Sets a beacon to map coordinates on the current zone map: the percentages quest guides give, like 50.5 30.4 |
| /beacon world x y | Sets a beacon to raw world coordinates |
| /beacon to name | Routes to the nearest known place whose name contains the text, using the map data. Say a part of a name, such as "mailbox". |
| /beacon stop | Stops the beacon or route, the same as Shift+F12 |

Examples: /beacon 50.5 30.4 says "Beacon set 245 yards" and starts a straight-line beacon to that spot; it does not open the navigation window. /beacon to innkeeper speaks the place it found and starts a route to it, or says "No route found innkeeper". /beacon 12 with only one number says "Usage beacon x y".

Versions: all. /beacon to needs map data for the continent you are on; see [Navigation](../world/navigation.md).

### /focus1 to /focus5

WoW only supports one focus target. WowVision adds five virtual ones, which you can then target with the Target Focus 1 to Target Focus 5 bindings (unbound by default).

Syntax: /focus1 (or 2 to 5), optionally followed by a unit.

- /focus1 with nothing after it sets focus 1 to your current target. Without a target it keeps the old focus and prints "No target. Use `/focus1 <name>` or target a unit."
- /focus1 party1 sets it to the unit or name you give, anything that the game's /target command understands.

With a target, WowVision remembers the target's name, so two creatures with the same name cannot be told apart. It prints "Focus 1 set to Name." It does not work in combat and says "Cannot set virtual focus while in combat." Versions: all. When Sku is loaded, the command is not registered. See [Targeting](../world/targeting.md).

### /pquit

Leaves your current party. Versions: all. Not registered when Sku is loaded.

### /dquit

Leaves your dungeon or looking-for-group party, and in a battleground or arena leaves the battleground. Outside an instance and outside a looking-for-group party it does nothing. Versions: all. Not registered when Sku is loaded.

### /enableaddon and /disableaddon

Turns an addon on or off and reloads the interface straight away.

Syntax: /enableaddon name and /disableaddon name. The name is the addon's folder name, and it is not case sensitive. Without a name they print "Syntax: `/enableaddon <name>`". The interface reloads even when no addon with that name exists.

Example: /disableaddon sku. The name sku is special: it switches the Sku addon together with its audio data and beacon addons, so nothing is left half-loaded. /enableaddon sku turns them all back on.

Do not use /disableaddon wowvision; it would turn WowVision itself off. These commands are not registered when the BlindSlash addon is loaded. Versions: all.

## Utility commands

### /wv soft

Reads the soft targeting mode and every soft targeting game value, one line each: first the lock mode (Soft Targeting With a Hard Target), then lines such as "SoftTargetEnemy 3 (default 0)". A value waiting for combat to end is marked "after combat" with the value it will get, and a value your game version does not have is marked "not available". The lines are printed to chat and spoken. See [Targeting](../world/targeting.md).

### /wv targetinfo

Lists, for your current target, everything the target announcement can say: the kind of unit, whether In Combat or Out of Combat applies right now, and every fact of that kind with what it says for this target, whether its checkbox is on, and whether your game version offers it. Then the lines of the target's tooltip, and last the announcement as you hear it. The list opens in the results window and is printed to chat, and the announcement is spoken. A fact the game hides in that moment shows as <secret>. This helps with bug reports. See [Targeting](../world/targeting.md#what-the-announcement-says-names).

### /wv mscan

The minimap scanner. Typed alone it scans now, the same as Ctrl+Shift+F. See [Minimap](../world/minimap.md).

| Typed | What it does |
|---|---|
| /wv mscan | Scans the minimap now |
| /wv mscan list | Shows every entry the scanner has seen this session |
| /wv mscan clear | Forgets every seen entry and the walking memory, and says "Seen entries cleared" |
| /wv mscan log | Shows how the last scan and the walking check went (for bug reports) |
| /wv mscan walk | Shows what the walking check remembers |
| /wv mscan raw | Shows one unparsed read of the minimap; also saved for sending after /reload (for bug reports) |
| /wv mscan sku | Measures the scanner's minimap searches on the spot where you stand (for bug reports) |

Versions: the command exists everywhere, but scanning needs a game version whose minimap can be read; otherwise you hear "Minimap scanner not available on this client".

### /wv quests

A quest data check. It prints in chat what WowVision knows about quests. It needs a quest data source: Questie where installed, otherwise the game's own quest data. Without one it says "No quest data source", and "Questie is still loading" while Questie is starting.

| Typed | What it does |
|---|---|
| /wv quests near (or just /wv quests) | Lists up to ten nearby quests with level, giver and distance |
| /wv quests log | Lists the quests in progress with their objectives |
| /wv quests go questId [start, objectives or finish] | Lists the targets for that quest phase (default objectives) |
| /wv quests raw [mapId] | Dumps the raw data of the quest source (when it has one) |
| /wv quests probe | One report of every quest and map point source the game offers, in a window with a spoken summary; also saved to the WowVisionDump saved variable. It works even without a quest data source. |

Versions: all. See [Quests](../world/quests.md).

## Diagnostic commands

These are for finding and reporting problems. [Troubleshooting](../getting-started/troubleshooting.md) says when to use each.

### /wv errors

Shows the Lua errors of this session. It speaks the most recent one and opens a window with the whole list and the stack traces. If the BugGrabber or BugSack addon is installed, its list is read first.

| Typed | What it does |
|---|---|
| /wv errors | This session's errors |
| /wv errors all | Also the older errors BugGrabber kept |
| /wv errors clear | Empties WowVision's list, and BugGrabber's too if it is installed |

It prints "No Lua errors recorded" if there are none. WowVision keeps the last 20 of its own list across /reload.

### /wv taint

Shows the calls the game blocked because of taint (a protected action attempted from addon code), with time, event, addon, function, and what the interface had in focus. WowVision keeps the last 30. Without records it says "No blocked calls recorded".

/wv taint clear empties the list. The records are written to the WowVisionDump saved variable when you type /reload. You also hear "Blocked: ..." when WowVision itself is blocked.

### /wv dbcheck

Prints a short report about your saved settings to the chat window. You do not need to understand it: add it to a bug report when your settings get lost. See [My settings are lost](../getting-started/troubleshooting.md#my-settings-are-lost).

### /wv turnlog

Lists the last turns made by Turn to Waypoint, one line each with its error in degrees, in a window and in chat. It speaks a summary such as "12 turns, mean error 2.4 degrees", or "No turns yet".

### /wv unitturnlog

Lists the last presses of Turn to Target and Turn to Focus (up to 40), one line each with the time, the unit, what the press found and how far your character turned, in a window and in chat. It speaks how many presses there are. The lines are also saved with your settings, so they are there after a reload.

### /wv keylog

Switches the key log on or off, and prints "WowVision key log on" or "off". While on, chat shows when windows take, wait for and release the navigation keys, and what the held-key check saw. Use it when a character turns or runs by itself.

### /wv padlog

Starts the controller log afresh. It prints "WowVision pad log started afresh", or "WowVision pad log: only with the gamepad interface on". The command is registered on every game version, but it only logs with the gamepad interface on, which means Retail or WoW: Forever. See [Controller](../controller.md).

### /wv cdmlog

Shows what the Cooldown Manager Auras rules saw.

| Typed | What it does |
|---|---|
| /wv cdmlog | The log of what the rules saw (also speaks the newest line) |
| /wv cdmlog clear | Empties the log |
| /wv cdmlog spells | Lists the tracked buff and bar entries of your cooldown manager |
| /wv cdmlog cooldowns | Lists the essential and utility entries |

Versions: Retail and WoW: Forever. See [Monitors](../information/monitors.md).

## Game commands used by WowVision

These belong to the game, not to WowVision:

- /reload reloads the interface and saves your settings to disk.
- /tts playline and /tts playactivity switch the game's sounds around text to speech. WowVision shows both as settings in the Speech module (Sound Between Chat Lines and Activity Sound When Unfocused).
- /cdm opens the game's cooldown manager settings, which WowVision reads as a window (Retail and WoW: Forever).

## For developers and bug reports

These commands are for the people who work on WowVision. You will normally never need them, but a developer may ask you to run one.

| Command | What it does |
|---|---|
| /wv dev | Makes a few developer helper functions available to the game's script line |
| /wv tests [suite] [--verbose] | Runs the built-in tests and shows the results in a window |
| /wv gmenu | Opens the WowVision menu (the same as /wv) |
| /wv gsettings module | Opens one module's settings screen, for example /wv gsettings speech |
| /wv gnode | Dumps the structure of the focused element |
| /wv glive | Dumps the live-watch state of the focused element |
| /wv gdump expression | Evaluates a Lua expression and describes the result |
| /wv gperf | Measures the interface update loop over 120 frames and reports minimum, average and maximum milliseconds |
| /wv gdrop | Dumps the open dropdown menu |
| /wv bigmenu [number] | Opens a long scrolling test menu with the given number of entries (60 if left off), with checkboxes, radio buttons, a level range, a row of controls and a slider; a pick is printed in chat |
| /wv bigmenu dump | Opens the same test menu and, one second later, dumps it as /wv gdrop does |
| /wv cctest [unit] | Tests whether a unit (your target if left off) is crowd controlled and prints how the result changes over the next frames |
| /wv cctest watch | Switches a check on or off that prints a line for every target change, showing the crowd control result frame by frame |
| /wv gtooltip | Dumps the tooltip reader state |
| /wv profile | Profiler: alone it starts, or report, reset, stop |
| /wv testcd | Builds a test cooldown monitor |
| /wv dump waypoints or /wv dump links | Writes Sku's waypoint data into the WowVisionDump saved variable; needs Sku loaded, then /reload |
| /uiinsp | Opens a small key inspector that prints the name of every key you press; Escape closes it |

Everything in this table may change or disappear without notice.
