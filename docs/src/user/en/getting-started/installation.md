# Installing WowVision

This page shows you how to download WowVision, put it in the right folder for your game version, switch it on, and what to expect the first time a character logs in. It also covers where WowVision keeps your settings, how to update it, and how to remove it.

WowVision starts working once your character is standing in the world. It cannot yet read the login screen, the realm list or the character selection screen. To get through those, see [Logging In with the Sku Login Tool](./sku-login.md), or ask a sighted friend to help the first time.

## Download

WowVision is published on GitHub. There are two kinds of download, and both are a single zip file.

- The latest release. The stable version. Download it from the [WowVision releases page](https://github.com/wow-vision/WowVision/releases/latest). The zip is named after the version, for example WowVision-V0.9.0.zip, and is a large download (around 100 MB).
- The beta pre-release. Between releases there is one pre-release called beta. It is rebuilt every time the developers change something, so it is for testers and for WoW: Forever, which changes quickly. It always lives at the same address: [the beta pre-release page](https://github.com/wow-vision/WowVision/releases/tag/beta). The zip itself is always at https://github.com/wow-vision/WowVision/releases/download/beta/WowVision-beta.zip. The release notes on that page list every change since the last release.

Install both kinds the same way. If you install the beta over an older copy, it simply replaces the files.

### What is in the zip

The zip holds two addon folders at its top level:

- WowVision: the addon itself. It contains everything for all game versions, including the translations and the sounds and voice recordings WowVision plays. You do not need to download translations or audio separately.
- WowVision_MapData_TBC: the map data that lets navigation (the F10 window and routes) work on The Burning Crusade anniversary realms and on WoW: Forever. See [Navigation](../world/navigation.md). It is not meant for the other game versions, so you can leave it out there. WoW: Forever can also route with WowNav, whose navigation data is already inside the WowVision folder (see [WowNav](../world/wownav.md)).

Both folders are installed by the same extraction. Other map data addons that other people publish can be installed beside them.

## Where to put it

Extract the zip into the AddOns folder of the game version you play. Each game version has its own folder inside your World of Warcraft installation. The usual installation folder is C:\Program Files (x86)\World of Warcraft\.

| Game version | Folder inside the installation | AddOns folder |
|---|---|---|
| Classic Era (Vanilla) | `_classic_era_` | `_classic_era_\Interface\AddOns` |
| The Burning Crusade (TBC) anniversary | `_anniversary_` | `_anniversary_\Interface\AddOns` |
| Mists of Pandaria (Mists) | `_classic_` | `_classic_\Interface\AddOns` |
| Retail | `_retail_` | `_retail_\Interface\AddOns` |
| WoW: Forever | `_forever_` | `_forever_\Interface\AddOns` |

If the Interface and AddOns folders do not exist yet, create them. If you play several versions, extract the zip once into each version's AddOns folder.

Example: you play The Burning Crusade. Extract the zip into C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns. Afterwards the folders WowVision and WowVision_MapData_TBC sit inside that AddOns folder.

### The folder structure that is correct

After extraction, the AddOns folder must contain:

- `WowVision`
  - `WowVision_Vanilla.toc`
  - `WowVision_TBC.toc`
  - `WowVision_Mists.toc`
  - `WowVision_Standard.toc`
  - `WowVision_Camelot.toc`
  - the folders `core`, `classic`, `retail`, `libs`, and so on
- `WowVision_MapData_TBC`
  - `WowVision_MapData_TBC.toc`
  - and its map files

The test: the TOC files must sit directly inside the WowVision folder.

### The common mistake: a nested folder

Many unzip programs offer to extract "into a new folder named after the zip". If you accept, you can end up with a folder inside a folder, so the TOC files are at AddOns\WowVision\WowVision\WowVision_Standard.toc. The game then finds no addon at all, and WowVision silently never loads. The same happens if you extract the zip to your desktop and then copy the zip's own folder into a folder called WowVision.

To fix it, move the inner WowVision folder up so that the TOC files are one level higher, and delete the empty outer one. Always extract directly into the AddOns folder and let the zip create the two folders itself.

## The five TOC files

A TOC file is a small list that tells the game what an addon is and which files to load. WowVision ships one per game version, and the game picks the right one by itself; you never choose.

| Game version | TOC file used | What loads |
|---|---|---|
| Classic Era | `WowVision_Vanilla.toc` | the shared core, the shared Classic modules, and the Classic Era modules |
| The Burning Crusade | `WowVision_TBC.toc` | the core, the shared Classic modules, and the TBC modules |
| Mists of Pandaria | `WowVision_Mists.toc` | the core, the shared Classic modules, and the Mists modules |
| Retail | `WowVision_Standard.toc` | the core and the Retail modules |
| WoW: Forever | `WowVision_Camelot.toc` | the core, the Retail modules, and the Forever modules (with a few Classic and Mists parts for windows the Forever client shares with them) |

There is no setting for the version. If a feature is only on some versions, the manual says so, for example (Retail and WoW: Forever only). See [Versions](../reference/versions.md) for the full table.

## Translations and sounds

WowVision comes with text in English, German and French; the language of your game client decides which one is used, and any other client language falls back to English.

The sounds, beacon tones and recorded voices (voice packs) are inside the WowVision folder too. If you ever see a "missing sound" problem, the cause is a damaged or partial extraction: delete the folder and extract the zip again.

## Optional addons

WowVision works on its own. It also knows three other addons and uses them when they are installed. They are listed in WowVision's TOC files as optional, so the game loads them first when they are enabled.

| Addon | What it is | What WowVision does with it | Listed on |
|---|---|---|---|
| Sku | The long-standing accessibility addon | When Sku is loaded, WowVision steps back from a list of windows, keys and commands and leaves them to Sku. See [Using WowVision together with Sku](#using-wowvision-together-with-sku). | all versions |
| BlindSlash | Another accessibility addon, used on Retail | The two commands /enableaddon and /disableaddon are not registered when BlindSlash is loaded. | Retail, Mists, WoW: Forever |
| Questie | The quest database addon | WowVision reads quest givers, objectives and places from Questie when it is installed, and from the game's own quest data when it is not. Questie asks a one-time question when it first starts, and WowVision reads that as a window. | Classic Era, TBC, Mists, WoW: Forever |

For everything about quests and Questie, including the first-start question, read [Quests](../world/quests.md).

## Switching the addon on

New addons are only found when the game starts, so restart the game after copying the files. A /reload is not enough for a brand new addon.

On the character selection screen, open the AddOns list (a button at the lower left of the screen). Find WowVision in the list and make sure it is checked. Check WowVision_MapData_TBC too if you play The Burning Crusade or WoW: Forever. The game remembers this choice per character; the list has a drop-down to pick one character or all characters.

### "Out of date" addons

When the game gets a patch, addons built for the old patch are marked out of date and are not loaded. At the top of the AddOns list there is a check box called Load out of date AddOns. Check it if WowVision is flagged out of date. WowVision is normally updated soon after a patch, so check the releases page for a new version too.

The map data folder is built for the Burning Crusade and Forever clients. Classic Era uses nearly the same world as The Burning Crusade, so it works there too; turn on Load out of date AddOns if the game flags it. On Mists and Retail leave it off; it is not meant for those versions.

If the character selection screen is a problem for you, the Sku Login Tool can drive it. See [Logging In with the Sku Login Tool](./sku-login.md). If WowVision does not load, go to [Troubleshooting](./troubleshooting.md).

## First login

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

- The game's Click to Move option follows the Auto-move to Interact Target setting in WowVision's Navigation menu (on by default), which makes interacting with a distant target walk you to it. WowVision only writes to the game when that setting changes: switching it off turns Click to Move off, and WowVision turns it off again at each login while the setting is off. Leaving it on does not by itself switch the game option on, so if you want Click to Move, check that it is on in the game options under Controls, or toggle the WowVision setting off and on.
- The soft targeting options change nothing until you set them yourself. See [Targeting](../world/targeting.md).

The General buffer also gains a few new lines (free bag slots, durability, mail, hearthstone, game clock) the first time an existing character logs in after an update that adds them. See [Buffers](../information/buffers.md).

## Where your settings are saved

WowVision keeps its data in the game's own saved variable files. The game writes them when you log out or type /reload, not while you play. If the game crashes or you close it with a task manager, changes since the last logout or reload are lost.

| Saved variable | Holds | Scope |
|---|---|---|
| WowVisionGlobalDB | Most settings, alerts, buffers and monitors by default | The whole account |
| WowVisionDB | Settings you moved to "this character", plus your key bindings and spell history | One file per character |
| WowVisionDump | Diagnostic records: Lua errors, blocked-call records, the controller log, the minimap walking log, the quest probe report and similar | The whole account |
| WowVisionPriceDB | The auction price database (TBC only) | The whole account |

The files are in the game's WTF folder, inside the version folder you installed to:

- Account-wide files: `WTF\Account\<ACCOUNT NAME>\SavedVariables\` with the names WowVisionGlobalDB.lua, WowVisionDump.lua and, on TBC, WowVisionPriceDB.lua.
- Per-character files: `WTF\Account\<ACCOUNT NAME>\<Realm>\<Character>\SavedVariables\WowVisionDB.lua`.

By default most settings are shared by all your characters. You can make one module's settings belong to a single character instead: in the WowVision menu, put the focus on the module, press Shift+F10 and choose Scope. The key bindings (including controller buttons) are saved per character. See [The WowVision Menu and Settings](../basics/menu-and-settings.md) and [Keybindings](../basics/keybindings.md).

To back up your setup, copy these files with the game closed. To reset everything, delete them with the game closed; WowVision starts with defaults on the next login. If settings keep disappearing, see [settings lost](./troubleshooting.md#my-settings-are-lost).

## Updating WowVision

1. Close the game completely.
2. Download the newer release or the beta zip.
3. Extract it into the same AddOns folder, as at the first install, and agree to replace files. For a clean update, delete the old WowVision and WowVision_MapData_TBC folders first, so no leftover file from an older version stays behind. Your settings are not in these folders and are not lost.
4. Start the game and log in. Type /wv version to see the new version.

WowVision migrates saved settings by itself when an update needs it. Read the release notes on the releases page: they list changes since the last release and say when something resets. The beta is replaced on the same address each time, so you can update it as often as you like.

## Uninstalling

1. Close the game.
2. Delete the WowVision and WowVision_MapData_TBC folders from the AddOns folder.
3. Optionally delete the WowVision saved variable files listed above to remove the stored settings.

The changes WowVision made once on first login (the action bar lock, the camera following style and the chat line sound), and Click to Move if you switched it with the WowVision setting, stay in the game after you remove the addon. Change them back in the game options if you want them as before, as described in the table above.

## Using WowVision together with Sku

WowVision and Sku can be installed side by side, and many players run both. They do not fight over the same windows: when Sku is loaded, WowVision deliberately steps back from the windows, keys and commands listed below and leaves them to Sku. Everything not on the list is still handled by WowVision.

### How it works

When the game loads WowVision, it checks which addons are already loaded. If Sku is among them, every window, key binding and command marked as "belongs to Sku" is switched off for that session: the window simply never opens in WowVision, the key is not taken over, the command is not registered. The decision is made once at login, so enabling or disabling Sku needs a reload (/reload) or a new login to take effect. Nothing is deleted: your WowVision settings and key bindings for these features stay as they are and come back as soon as Sku is off.

If a window is not read by WowVision and you have Sku loaded, this is almost certainly why. To switch Sku off for a session, disable it in the game's addon list, or type /disableaddon sku (it turns off Sku and its helper addons and reloads the interface; /enableaddon sku turns them back on). These two commands are themselves skipped when the BlindSlash addon is loaded.

### What Sku keeps when both are loaded

Windows on every game version:

- Bags.
- Gossip and other NPC dialogs.
- Merchant.
- Mailbox.
- Popups (the game's confirmation dialogs).
- Quest giver window (accepting and handing in quests).
- Flight master (taxi map).
- Trade window.
- Trainer.
- Ready check and the dungeon ready popup.
- Role poll (the role check popups).
- Guild invitation.

Additional windows on Classic Era, The Burning Crusade (TBC) and Mists of Pandaria (Mists):

- The Friends and Social window, with its Friends, Ignore, Who and Guild pages.
- The guild member card, guild information, guild event log and guild control windows of the classic guild window.

Additional windows on The Burning Crusade (TBC) only:

- Character pane.
- Spellbook.
- Talents.
- Trade skills and the crafting (Craft) window.
- Pet stable.
- Quest log.

Additional windows on Mists of Pandaria (Mists) only:

- Character pane.
- Talents.
- Quest log.
- Item upgrade.
- Reforging.

Additional windows on Retail and WoW: Forever:

- Guild and Communities, with its member card, text editor, event log and news filters.
- Guild control.
- The Social window with its side windows (ignore list, Battle.net broadcast, Battle.net unavailable notice, raid info, Add Friend).
- Cooldown manager window and its alert editors.
- Quest log.
- On WoW: Forever only: Character pane and the gear set popup.

Keys that Sku keeps (WowVision does not take them over while Sku is loaded):

- The tooltip line keys: Previous Tooltip Line and Next Tooltip Line (Shift+Up and Shift+Down), Read Tooltip Left and Read Tooltip Right (Shift+Left and Shift+Right).
- The soft targeting toggles Soft Target Enemy, Soft Target Friend and Soft Target Interact (Shift+I, Shift+P and Shift+O).
- Target Focus 1 to Target Focus 5.

Commands that Sku keeps: /focus1 to /focus5, /pquit (leave party) and /dquit (leave dungeon or battleground group).

### What WowVision still does for you

Everything else works as usual: speech and alerts, the buffers and monitors, targeting announcements, movement and navigation, the minimap scan, the scanner, the chat window and chat announcements, the chat channels window, the action bars window, the loot window, the auction house, the collections and professions windows where Sku has no equivalent, the game menu and options, and the WowVision menu.

## Where to go next

- [Quick Start](./quick-start.md): the first fifteen minutes.
- [Troubleshooting](./troubleshooting.md): if WowVision does not load or does not speak.
- [Commands](../reference/commands.md): everything you can type, including /wv speech.
