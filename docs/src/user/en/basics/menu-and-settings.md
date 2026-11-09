# The WowVision Menu and Settings

The WowVision menu is where you configure the addon: speech, alerts, navigation, buffers, monitors, windows and more. It works like every other WowVision window, so everything in [Using the interface](./interface.md) applies. This page explains how the menu is laid out, how each kind of setting is edited, and how settings are stored per character or for the whole account.

## Opening and closing the menu

| How | What happens |
|---|---|
| Shift+F1 | Opens the menu (the WowVision Menu binding). |
| /wv | Opens the menu. Typing /wv followed by something WowVision does not know also opens it. |
| Escape | Goes back one level. On the first level, closes the menu. |
| /wv close | Force-closes all WowVision windows. |

When the menu opens, speech stops and you hear its name and the first entry, for example "WowVision, List, Buffers, Button, 1 of 13". The exact number of entries depends on your game version.

In combat WowVision steps aside, so open the menu before a fight or after it, see [Combat](./interface.md#combat).

You can reach the screen of a module that has settings of its own directly with /wv gsettings followed by its short name, for example /wv gsettings speech. The names are the module names in lower case, with dots for submodules:

| Command | Opens |
|---|---|
| /wv gsettings speech | Speech |
| /wv gsettings ui | UI |
| /wv gsettings ui.tooltip.quality | UI, Tooltip, Quality |
| /wv gsettings ui.combat | UI, Combat |
| /wv gsettings navigation.compass | Navigation, Compass |
| /wv gsettings navigation.maps | Navigation, Beacon and Routes |
| /wv gsettings chat | Chat |
| /wv gsettings targeting | Targeting |
| /wv gsettings errors | Errors |
| /wv gsettings navigation.falling | Navigation, Fall Detection |

If the name does not match a module that has settings of its own, for example ui.tooltip or one of the game windows, WowVision prints "No settings found for" and the name in chat. The command is a shortcut meant for testers; the menu always gets you to the same screens.

## How the menu is laid out

The menu is a tree. The first screen lists the modules, in alphabetical order. Pressing Enter on a module opens its screen, which in turn may list submodules. Each screen is a list; Escape goes back up.

A module's screen holds, from top to bottom:

1. An Enabled checkbox. Every module except Speech and UI has one. Turning a module off stops its features at once, its keys, alerts and windows included, and the choice is remembered for this character.
2. Its submodules, as buttons, in alphabetical order.
3. Special entries some modules add. For example the UI module has a Bindings button, the Buffers module its list of buffer groups, and the Errors module a Per-Error Filter button.
4. The module's own settings.
5. The module's alerts, each as a button. See [Alerts](./alerts.md).

Example: opening Chat reads "Chat, List, Enabled, Checkbox, Checked". Press Down to move through the chat tab alerts and its other entries.

Because it is a list that owns the keyboard, you can press letters to jump: S for Speech, T for Targeting. See [Letter navigation](./interface.md#letter-navigation-in-menus).

### What is on the first screen

| Entry | Game versions | What it holds | More |
|---|---|---|---|
| Auction Prices | The Burning Crusade | Price history and extra price lines on item tooltips. | [Tooltips](./tooltips.md#prices-in-tooltips-the-burning-crusade-only) |
| Buffers | All | Your buffer groups and buffers, and the Invert Item Direction setting. | [Buffers](../information/buffers.md) |
| Chat | All | One alert per chat tab, whisper tabs, chat box sounds. | [Chat](../windows/chat.md) |
| Errors | All | How game error and info messages are spoken. | [Combat](../world/combat.md) |
| Minimap Scanner | All | Minimap scan and the walking announcements. | [Minimap](../world/minimap.md) |
| Monitors | All | Aura, cooldown and other monitors. | [Monitors](../information/monitors.md) |
| Navigation | All | Atlas, Beacon and Routes, Compass, Fall Detection, Follow, Pitch Lock, Visited Waypoints, Wall Detection and more. | [Movement](../world/movement.md), [Navigation](../world/navigation.md) |
| Quests | All | Quest log tools, quest area and quest progress alerts. | [Quests](../world/quests.md) |
| Scanner | All | The scanner (F9). | [Scanner](../world/scanner.md) |
| Speech | All | Voice, rate, volume and speech behaviour. | [Speech](./speech.md) |
| Targeting | All | Target announcements, soft targeting, focus targets. | [Targeting](../world/targeting.md) |
| UI | All | Window behaviour, bindings, combat, cursor, tooltips. | below |
| Windows | All | One entry per game window WowVision makes accessible. | [Game windows](../windows/overview.md) |

Under Navigation on WoW: Forever there is also WowNav Routes, see [WowNav](../world/wownav.md).

### The UI module

Press U in the main menu, then Enter. It contains:

| Entry | Default | What it does |
|---|---|---|
| Combat | | Enemy count and the combat started and ended alerts, see [Combat](../world/combat.md). |
| Cursor | | Only an Enabled checkbox. Turning it off removes the Destroy Cursor Item key. |
| Tooltip, then Quality | | Which item quality colours are spoken, see [Tooltips](./tooltips.md#item-quality-in-names). |
| Bindings | | The keybinding screen, see [Keybindings](./keybindings.md). |
| Interrupt Speech on Window Close | Off | Cut off speech whenever a window closes. |
| Letter Navigation in Menus | On | Let letter keys jump to entries in menus. Turn it off if you need your letter keys to keep working while a menu is open. |
| WowVision Sound Channel | Sound Effects | The game sound channel every WowVision sound plays on: alert sounds, voice packs, the beacon and the previews in the sound browsers. The entries are named like the volume sliders in the game's sound options, so that slider is then WowVision's volume. A channel you use for little else gives WowVision a volume of its own. Retail and WoW: Forever also offer Gameplay Sound Effects. |

### The Windows module

Every game window WowVision handles has its own entry here, for example Game Menu, Merchant, Mail and Loot, each with an Enabled checkbox and sometimes settings of its own. Turning a window's module off makes WowVision ignore that window completely, so the game window stays as the game made it. That is useful if you prefer another addon's handling for one particular window.

## How each kind of setting is edited

| Kind | What you hear | How to change it |
|---|---|---|
| Checkbox | "Enabled, Checkbox, Checked" | Enter flips it and says the new state. |
| Number | "Delay (milliseconds), Number, 200" | Left and Right change it by one, and say the new value. Enter opens a typing box: type a number and press Enter. Values outside the allowed range snap to the nearest allowed value. |
| Choice | "Count Enemies, Dropdown, Attacking You or Your Group" | Enter opens the list of choices. You land on the current one. Enter on another picks it and returns; Escape closes the list unchanged. |
| Text | "Message, Edit, hello" | Enter opens a typing box with the text selected. Type, then Enter to accept or Escape to cancel. Arriving by Tab opens the box at once. |
| Duration | "(name), Number, 1 minute 5 seconds" | Like a number. Left and Right move one second at a time; typing takes seconds. |
| Voice | "Voice, Dropdown, Microsoft Zira Desktop" | A choice over your installed TTS voices. |
| Voice pack | "Voice Pack, Dropdown, Matthew" | A choice over the recorded voice packs. See [Speech](./speech.md#recorded-voice-packs). |
| Sound or beacon picker | "Sound, Button, chat.mp3" | See [Picking a sound](#picking-a-sound). |
| Spell | "Spell, Button, Starsurge (78674)" | See [Picking a spell](#picking-a-spell). |
| Template | "Template, Button, Default" | See [Editing a template](#editing-a-template). |
| Alert | the alert's name, as a button | Opens the alert's screen, see [Alerts](./alerts.md). |
| Group of settings | a button | Opens a screen with the settings inside, for example Hard Target under Targeting. |
| List of things | "Monitors (3), Button" | See [Lists of things](#lists-of-things). |
| Anything else | "Label, value" as plain text | Read only. |

### Picking a sound

The Sound setting of an alert's sound output, and the Beacon Sound setting of a beacon, open a browser of audio files.

1. Press Enter on Sound. You land in a list of folders.
2. Go into Sound, then WowVision for the sounds that ship with WowVision, or LibSharedMedia for the sounds that other addons have registered. Inside WowVision the folders are alerts, errors, notes and falling.
3. Moving onto a file plays it so you can listen before you choose. Moving onto the next file stops the previous sound.
4. Press Enter on the file you want. WowVision returns to the setting and reads the new value.

Escape goes back one folder without choosing anything. The top of the browser also shows Voice and Beacon folders, which hold files for other kinds of output.

Beacon pickers work the same way, but you pick one of the beacon sounds (Notification, Probe (Deep), Probe (Mid), Steel Gong, Beacon 6), and moving onto one plays a sample beacon.

### Picking a spell

Monitor rules and some other features have a Spell setting.

1. Press Enter on Spell. A screen opens with Spell Name at the top and a list below it.
2. For a spell you know the name or ID of, press Enter on Spell Name and type the name or the number. Enter accepts. If the game does not know it, you hear "Not Found" and can try again.
3. Otherwise pick from the list below, which holds the spells WowVision has seen on this character (cast by you or met as auras), sorted by name, each read as "Name (ID)". Enter picks it.
4. Once chosen, WowVision returns to the setting and reads "Name (ID)".

### Editing a template

Buffer items use templates to decide how their text is spoken, for example "{percent}% ({current} [of] {maximum})". The Template setting offers:

- Enter on Template opens a list of the templates that exist for that kind of object. Press Enter on one to use it. Default means the standard wording.
- Custom lets you type your own format. WowVision says Format and opens the typing box. Typing nothing and pressing Enter goes back to the default.

In your own format, write the name of a value in curly braces to insert it, for example {percent}. Square brackets insert a translated word, for example [of] (read as "of" in English). Slashes in the fixed text of a format are spoken with spaces around them. Type {{ or [[ for a literal brace or bracket. The values you can use depend on the object, and are listed with it in [Buffers](../information/buffers.md).

### Lists of things

Buffers, buffer groups, monitors and rules are lists of things you can add and remove. A setting for such a list reads as its name and a count, "Monitors (3)".

1. Enter opens the list. Each existing item is a button.
2. Enter on an item opens its editor: its settings, and at the bottom a Remove button that deletes it without asking.
3. Add at the end of the list opens Select Type. Pick a type and the new item is created, named "New" and the type, and its editor opens at once.
4. Shift+F10 on an item gives it a Scope entry, see below.

Some settings hold a simple list of values (for instance a list of numbers). It is read as "Name (count)", and opens a screen with one row per value: the value's own control, followed by a Remove button, and Add at the end.

## Per-character and account-wide settings

WowVision keeps two stores of settings:

- The account store, shared by all characters on your account.
- The character store, for this character only.

Most settings start out account-wide, so the speech voice or alert sounds you set on one character apply to all of them. The first character to log in after the account store was introduced filled it from its own settings (that character keeps its copy as well); characters that log in later simply use what is there.

Which modules are enabled is always per character, whatever you choose. The Errors module's per-error filter is the opposite: it is always shared by all characters of the account, so an error you muted on one character stays muted on all of them. The two game sound checkboxes of the Speech module are the game's own settings and are not stored by WowVision at all.

### Changing the scope

Shift+F10 on a persisted setting opens the context menu, and it contains Scope. Press Enter to open it. It offers two radio entries: Global, and your character's name. The checked one is where this setting lives.

- Choosing Global makes the setting follow the account. It takes the account's value. If the account has no value yet, this character's value becomes the account's.
- Choosing your character name gives this character its own copy, starting from the current value. You can then change it without affecting other characters.

Nothing is ever deleted when you switch, so changing your mind is safe.

The same Scope entry appears in other places:

- On a module's button in the menu, it switches every setting and alert of that module at once. For Buffers and Monitors it also moves all their groups or monitors.
- On an alert's button, it moves that alert with all its outputs.
- On the Bindings button in the UI menu, it moves all your key bindings at once.
- On a single item in a list of buffer groups or monitors, it moves just that item.

If a module's settings are split between the two, neither Global nor the character name is checked.

Example: you want a faster speech rate on your alt only.

1. Shift+F1 to open the menu, S until Speech, Enter.
2. Down to Speech Rate, then Shift+F10.
3. Down to Scope, Enter, Down to your character's name, Enter.
4. The menu closes and you are back on Speech Rate. Change the rate; your main character's rate stays as it was.

## When settings are saved

The game writes WowVision's settings to disk when you log out, reload the interface or exit the game, not the moment you change them. If the game crashes, changes from the current session can be lost. If you are changing important settings, finish with /reload.

If your settings seem to vanish between sessions, /wv dbcheck prints how the saved settings were loaded, which is useful for a bug report. See [Troubleshooting](../getting-started/troubleshooting.md).

## Resetting

There is no reset button in the menu. To put one setting back, set it to the default shown in this manual (settings are documented with their defaults). To start completely fresh, see [Troubleshooting](../getting-started/troubleshooting.md).

## See also

- [Using the interface](./interface.md)
- [Alerts](./alerts.md)
- [Speech and sound](./speech.md)
- [Keybindings](./keybindings.md)
