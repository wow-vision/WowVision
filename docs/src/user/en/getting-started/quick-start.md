# Quick Start

Your first fifteen minutes with WowVision: check that it runs, set up your voice, and try the most important keys. Everything here is explained in more detail on the pages linked in each step.

This page assumes WowVision is installed and your character is standing in the world. If not, start with [Installation](installation.md).

## Step 1: Check that WowVision is running

Press Shift+F1. The WowVision menu opens and WowVision reads its first entry. Press Escape to close it again.

If nothing happens, type /wv in the chat box and press Enter. If that does nothing either, WowVision is not loaded: see [Troubleshooting](troubleshooting.md#wowvision-does-not-load).

## Step 2: Make the voice comfortable

Most players want a faster voice than the default.

1. Press Shift+F1 to open the WowVision menu.
2. Use Down Arrow to find Speech and press Enter.
3. Move to Speech Rate and raise it a few steps (0 is normal; the game's voices accept -10 to 10). The new rate applies to everything WowVision says from then on.
4. Change Speech Voice and Speech Volume the same way if you like.
5. Press Escape until the menu is closed.

A faster way, handy in a macro that runs at login: type `/wv speech 1 8 100` for voice 1, rate 8 and volume 100. `/wv speech` on its own prints your current values and the list of voices with their numbers to the chat window (the first voice usually has number 0). Details in [Speech and Sound](../basics/speech.md).

## Step 3: Learn the window keys

Open your bags with the game's bag key (B by default). WowVision reads the bag window. Now try:

| Key | What it does |
|---|---|
| Up / Down Arrow | Move through the slots |
| Tab / Shift+Tab | Move to the next or previous part of the window |
| Space | Read the item's tooltip |
| Shift+Down / Shift+Up | Read the tooltip line by line |
| Enter | Left click (pick up the item) |
| Backspace | Right click (use or equip the item) |
| Shift+F10 | Context menu with more actions |
| Escape | Close the window |

The same keys work in every game window and in WowVision's own windows. While no window is open, these keys belong to the game again, so you can walk and fight as usual. More in [Using the Interface](../basics/interface.md).

## Step 4: Check your status with buffers

Without opening anything, press Alt+Down a few times. WowVision reads the lines of the General buffer: your health, your mana or other power, experience, money, free bag slots, durability, mail, hearthstone, the time and your PvP status. Alt+Up goes back.

Alt+Left and Alt+Right switch to other buffers, and Alt+Ctrl+Left and Alt+Ctrl+Right to other buffer groups, once you have created some. See [Buffers](../information/buffers.md).

## Step 5: Listen to the world

Just play for a moment and listen. Out of the box WowVision announces:

- your new target when you change targets, and its health in steps of five percent
- the compass direction when you turn
- zone and subzone changes, indoors and outdoors, swimming and flying
- rising tones when you fall, and a clunk when you walk into a wall
- "combat started", the number of enemies fighting you, "combat ended"
- game error messages such as "Out of range"
- chat messages in the tab you are reading

Each of these is an alert you can change or turn off in the WowVision menu. See [Alerts](../basics/alerts.md).

## Step 6: Find your way

- Press F9 to open the scanner: a list of quest givers, quests and other things around you. Enter on an entry starts guiding you there.
- Press F10 to open the navigation window and pick a destination for a route (on versions with map data).
- While a route is running, press I to turn towards the current waypoint, and Alt Gr (or Ctrl+Alt) to hear the distance. Shift+F12 stops the route.

See [Scanner](../world/scanner.md) and [Navigation and Routes](../world/navigation.md).

## Step 7: Other keys worth knowing now

| Key | What it does |
|---|---|
| Shift+F3 | Chat window: read the chat history |
| Shift+F4 | Action bars window |
| Alt+T | Menu of your target (whisper, invite, and more) |
| Shift+I / Shift+O / Shift+P | Switch soft targeting for enemies, interaction and friends on or off |
| Ctrl+Shift+F | Scan the minimap for herbs, ore and other tracked things (where available) |

All keys are listed in the [Keybinding Reference](../reference/keybindings.md), and you can change any of them: see [Keybindings](../basics/keybindings.md).

## Where to go next

- Read [Using the Interface](../basics/interface.md) properly once; it pays off in every window.
- Look through the WowVision menu (Shift+F1) to see which modules and alerts exist.
- If something does not work, see [Troubleshooting](troubleshooting.md).
