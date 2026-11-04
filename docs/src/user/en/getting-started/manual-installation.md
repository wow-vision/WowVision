# Installing by Hand

This page installs WowVision without the installer: on a Mac, where the installer does not run, or if you prefer to manage your addons yourself. On Windows, [the installer](./installer.md) is easier and does all of this for you.

When the files are in place, continue with [Switching the addon on](./installation.md#switching-the-addon-on).

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

Extract the zip into the AddOns folder of the game version you play. Each game version has its own folder inside your World of Warcraft installation. The usual installation folder is C:\Program Files (x86)\World of Warcraft\. On a Mac it is usually World of Warcraft in your Applications folder, with the same version folders inside.

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

## Updating by hand

1. Close the game completely.
2. Download the newer release or the beta zip.
3. Extract it into the same AddOns folder, as at the first install, and agree to replace files. For a clean update, delete the old WowVision and WowVision_MapData_TBC folders first, so no leftover file from an older version stays behind. Your settings are not in these folders and are not lost.
4. Start the game and log in. Type /wv version to see the new version.

## Next steps

- [Switching the addon on](./installation.md#switching-the-addon-on) and [First login](./first-login.md#in-the-world).
- [Troubleshooting](./troubleshooting.md): if WowVision does not load.
