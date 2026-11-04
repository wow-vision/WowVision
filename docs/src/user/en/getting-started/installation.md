# Installing WowVision

There are two ways to install WowVision. This page helps you choose one, and covers what comes after either: the addons WowVision works with, and switching the addon on. Then continue with [Your First Login](./first-login.md).

## Two ways to install

- With the installer (recommended). The WowVision Installer is a Windows program that does everything for you: it finds your game versions, puts WowVision in the right folders, sets the game settings WowVision needs, and can install the WoW Login Tool and other useful addons along the way. Run again later, it keeps everything up to date. Every step is spoken. See [Installing with the Installer](./installer.md).
- By hand. You download the zip and extract it into the game's AddOns folder yourself. Use this on a Mac, where the installer does not run, or if you prefer to manage your addons yourself. See [Installing by Hand](./manual-installation.md).

Both give you the same WowVision. Whichever way you choose, come back to this page for [switching the addon on](#switching-the-addon-on), then go on to [Your First Login](./first-login.md).

## Optional addons

WowVision works on its own. It also knows three other addons and uses them when they are installed. They are listed in WowVision's TOC files as optional, so the game loads them first when they are enabled.

| Addon | What it is | What WowVision does with it | Listed on |
|---|---|---|---|
| Sku | The long-standing accessibility addon | When Sku is loaded, WowVision steps back from a list of windows, keys and commands and leaves them to Sku. See [Using WowVision together with Sku](./sku.md). | all versions |
| BlindSlash | Another accessibility addon, used on Retail | The two commands /enableaddon and /disableaddon are not registered when BlindSlash is loaded. | Retail, Mists, WoW: Forever |
| Questie | The quest database addon | WowVision reads quest givers, objectives and places from Questie when it is installed, and from the game's own quest data when it is not. Questie asks a one-time question when it first starts, and WowVision reads that as a window. | Classic Era, TBC, Mists, WoW: Forever |

For everything about quests and Questie, including the first-start question, read [Quests](../world/quests.md).

## Switching the addon on

New addons are only found when the game starts, so start the game, or restart it, after installing. A /reload is not enough for a brand new addon.

The game switches on new addons by itself. After the installer, WowVision simply loads when your character enters the world, and after an installation by hand it normally does too. Check it with Shift+F1, as described under [First login](./first-login.md#in-the-world).

The game's own list of addons, on the character selection screen, needs the mouse, so you do not have to use it. If WowVision does not load because addons were switched off there, for example by a sighted helper, type the game's own command /enableaddons once your character is in the world. It switches on all your addons and reloads the interface.

### "Out of date" addons

When the game gets a patch, an addon whose TOC file was made for the old patch is out of date. The login screen then shows a warning that you have out of date addons, and the game usually does not load them at all; the Load out of date AddOns check box in the game's AddOns list no longer changes that. The fix is a WowVision whose TOC matches the patch:

- With the installer: it matches WowVision's TOC to your game's patch on every run. After a patch, run the WowVision Updater and choose Update now.
- By hand: download a newer WowVision from the releases page. It is normally updated soon after a patch.

The map data folder is made for The Burning Crusade and WoW: Forever only. On the other game versions the game sees it as out of date, so leave it out when you install by hand. The installer only puts it into The Burning Crusade and WoW: Forever.

If the character selection screen is a problem for you, the Sku Login Tool can drive it. See [Logging In with the Sku Login Tool](./sku-login.md). If WowVision does not load, go to [Troubleshooting](./troubleshooting.md).

## Where to go next

[Your First Login](./first-login.md): getting through the login screens, and what happens when your character enters the world.
