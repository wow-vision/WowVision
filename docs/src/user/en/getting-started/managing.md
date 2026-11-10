# Managing WowVision

Where WowVision keeps your settings and how to back them up, how to update WowVision, and how to remove it.

## Where your settings are saved

WowVision keeps its data in the game's own saved variable files. The game writes them when you log out or type /reload, not while you play. If the game crashes or you close it with a task manager, changes since the last logout or reload are lost.

| Saved variable | Holds | Scope |
|---|---|---|
| WowVisionGlobalDB | Most settings, alerts, key bindings, buffers and monitors by default | The whole account |
| WowVisionDB | Settings you moved to "this character", plus your spell history | One file per character |
| WowVisionDump | Diagnostic records: Lua errors, blocked-call records, the controller log, the minimap walking log, the quest probe report and similar | The whole account |
| WowVisionPriceDB | The auction price database (The Burning Crusade, Retail and WoW: Forever) | The whole account |

The files are in the game's WTF folder, inside the version folder you installed to:

- Account-wide files: `WTF\Account\<ACCOUNT NAME>\SavedVariables\` with the names WowVisionGlobalDB.lua, WowVisionDump.lua and, on TBC, WowVisionPriceDB.lua.
- Per-character files: `WTF\Account\<ACCOUNT NAME>\<Realm>\<Character>\SavedVariables\WowVisionDB.lua`.

By default most settings are shared by all your characters. You can make one module's settings belong to a single character instead: in the WowVision menu, put the focus on the module, press Shift+F10 and choose Scope. The key bindings (including controller buttons) are shared the same way, and have their own Scope entry on the Bindings button. See [The WowVision Menu and Settings](../basics/menu-and-settings.md) and [Keybindings](../basics/keybindings.md).

To back up your setup, copy these files with the game closed. To reset everything, delete them with the game closed; WowVision starts with defaults on the next login. If settings keep disappearing, see [settings lost](./troubleshooting.md#my-settings-are-lost).

## Updating WowVision

- With the installer: start the WowVision Updater from its shortcut on the desktop or in the Start menu and choose Update now. See [Updating later](./installer.md#updating-later).
- By hand: download the new zip and replace the folders. See [Updating by hand](./manual-installation.md#updating-by-hand).

WowVision migrates saved settings by itself when an update needs it. Read the release notes on the releases page: they list changes since the last release and say when something resets. The beta is replaced on the same address each time, so you can update it as often as you like.

## Uninstalling

1. Close the game.
2. Delete the WowVision and WowVision_MapData_TBC folders from the AddOns folder.
3. Optionally delete the WowVision saved variable files listed above to remove the stored settings.

The changes WowVision made once on first login (the action bar lock, the camera following style and the chat line sound), and Click to Move if you switched it with the WowVision setting, stay in the game after you remove the addon. Change them back in the game options if you want them as before, as described in [What WowVision changes on a character's first login](./first-login.md#what-wowvision-changes-on-a-characters-first-login).

If you installed with the installer, it may also have installed other things, such as the additional addons, the WoW Login Tool or the voice options. They are listed in [What the installer leaves on your computer](./installer.md#what-the-installer-leaves-on-your-computer). Delete the folders of those you no longer want, and the WowVision Updater shortcuts.

