# Your First Login

## Getting through the login screens

WowVision starts working once your character is standing in the world. The login screen, the realm list and the character selection screen come before that, and the game only loads addons once a character enters the world, so no addon can read those screens; only the game itself could make them accessible. WoW: Forever reads its login screens aloud, but they still need the mouse.

The WoW Login Tool from the Sku project gets you through them. It is a small Windows program that runs next to the game and gives these screens a spoken menu. It supports Classic Era, The Burning Crusade anniversary and WoW: Forever; on Mists of Pandaria Classic and Retail it does not work, so ask a sighted helper there. Sign in to Battle.net through the Battle.net app, which works with a screen reader on Windows and on Mac. Tick "keep me logged in" once, so the game logs you in by itself when you start it from there.

In short:

1. Install the tool. The [installer](./installer.md) does this for you (Install the WoW Login Tool is ticked by default) and puts a WoW Login Tool shortcut on your desktop. To install it by hand, see [Getting and installing it](./sku-login.md#getting-and-installing-it).
2. Start the tool, on WoW: Forever before the game. On the very first run it asks for your voice, language, region and game type: Right goes in, Up and Down choose, Enter confirms. You hear "Setup completed. Start the game now."
3. Start the game. The tool says "Login mode for" with your game version, then "Main menu".
4. On Classic Era and The Burning Crusade: go to Select character and press Right, choose your character with Up and Down and press Enter, then press Enter on Login with selected character. The tool says "Play mode". On WoW: Forever the game speaks each item while the tool moves to it; see [Using the tool on WoW: Forever](./sku-login.md#using-the-tool-on-wow-forever).

If the tool does not switch between its menu and the game by itself, press Alt+F1. Creating a character, changing the realm, the full key list and the tool's own troubleshooting are in [Logging In with the Sku Login Tool](./sku-login.md).

## In the world

Once your character is in the world, WowVision starts on its own. It has no spoken "loaded" announcement.

Check that it is running in either of these ways:

- Press Shift+F1. The WowVision menu opens and its first entry is read out. This is the quickest test.
- Type /wv in the chat box and press Enter. This also opens the menu. /wv version prints the installed version to your chat window.

Then give [Quick Start](./quick-start.md) a few minutes: it covers the first settings to look at, especially your speech settings.

### What WowVision changes on a character's first login

A few game settings get in the way of how WowVision works, so WowVision changes them once for every new character. It does this a single time; if you change a setting back afterward, WowVision leaves your choice alone.

| What changes | Why | How to undo it |
|---|---|---|
| Lock Action Bars is turned off | With the bars locked, dragging a spell or item off an action bar does nothing unless you hold the pick up key, and nothing tells you so. WowVision prints a note in your chat window the first time. | In the game options, under Action Bars, check Lock Action Bars again. |
| The camera is set to always follow behind your character (the camera following style Always adjust camera) and view changes become instant | Turning to a waypoint turns the camera and then copies its direction to the character. This only works reliably with that style. WowVision prints a note in your chat window. | In the game options under Controls, change the camera following style. Turn to Waypoint will then become unreliable. |
| The game's Sound Between Chat Lines is turned off | The game plays a short sound between two chat lines it reads aloud, and that sound would play between all of WowVision's announcements. | It is a setting in the Speech menu of WowVision (Sound Between Chat Lines), or type the game's own command /tts playline. |

Two more things follow WowVision settings rather than happen once:

- The game's Click to Move option follows the Auto-move to Interact Target setting in WowVision's Navigation menu (on by default), which makes interacting with a distant target walk you to it. WowVision sets the game option at each login to match that setting, so to turn it off, use the WowVision setting rather than the game's.
- When you switch on a soft target type, WowVision sets its arc to the widest and its range to the longest. Types you leave off keep the game's values. See [Targeting](../world/targeting.md).

The General buffer also gains a few new lines (free bag slots, durability, mail, hearthstone, game clock) the first time an existing character logs in after an update that adds them. See [Buffers](../information/buffers.md).

### Recommended game settings (optional)

The UI menu has a button, Apply Recommended Game Settings. It is only a suggestion: nothing changes unless you press it, and every setting stays yours to change afterward in the game options. It sets:

- Auto loot on, and all action bars shown.
- Offscreen nameplates on: while the game shows enemy nameplates, an enemy behind you or beside you gets its nameplate at once, so the enemy count can say it right away. Enemy nameplates themselves are not switched on here; see [Nameplates are required](../world/combat.md#nameplates-are-required).
- Friendly NPC nameplates on, so that Turn to Target and Turn to Focus find NPCs (see [Navigation](../world/navigation.md#turn-to-target-and-focus-ctrli-ctrlu)).
- The game's Audio Assist on, saying your health, your target's health and your resource every 20 percent (the health as the number alone), and when you are targeted (without the attacker's name). Combat start and end, target name and your debuffs are switched off.

Key bindings, camera, soft targeting and sound volumes are not touched. The button does nothing in combat. After a change the interface reloads, then WowVision says what changed and prints the same to your chat window. Resource and "targeted" are kept per specialization by the game; press the button again after switching specialization.

## Where to go next

- [Quick Start](./quick-start.md): the first fifteen minutes.
- [Managing WowVision](./managing.md): where your settings are saved, and how to update and remove WowVision.
- [Using WowVision together with Sku](./sku.md): if you also have Sku installed.
- [Troubleshooting](./troubleshooting.md): if WowVision does not load or does not speak.
- [Commands](../reference/commands.md): everything you can type, including /wv speech.
