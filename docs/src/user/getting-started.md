# Getting Started

## Download

Download the latest release from the [WowVision releases page](https://github.com/wow-vision/wowvision/releases/latest). The release is a `.zip` file containing the addon.

The zip contains two addon folders: WowVision itself and WowVision_MapData_TBC, the map data for navigation on The Burning Crusade anniversary realms and WoW Forever. Both are installed by the same extraction. Other map data addons can be installed beside them.

### Beta builds

Between releases there is one pre-release called **beta**, rebuilt from the latest changes, for testers and for WoW Forever, which changes quickly. It is always at the same address: [the beta pre-release](https://github.com/wow-vision/WowVision/releases/tag/beta), with the zip at `https://github.com/wow-vision/WowVision/releases/download/beta/WowVision-beta.zip`. Its release notes list every change since the last release. Install it the same way as a release; extracting it over an existing WowVision folder replaces the files.

## Installation

Extract the downloaded zip file into your World of Warcraft addons folder. The addons folder is located inside the `Interface/AddOns` directory for the game version you play.

The default World of Warcraft installation directory is `C:\Program Files (x86)\World of Warcraft\`.

Inside that directory, each game version has its own folder:

| Game Version | Folder |
|---|---|
| Classic (Vanilla) | `_classic_era_` |
| The Burning Crusade | `_anniversary_` |
| Mists of Pandaria | `_classic_` |
| Retail | `_retail_` |
| WoW: Forever | `_classic_beta_` (beta) |

Each version folder contains an `Interface/AddOns` directory. For example, if you play The Burning Crusade Classic, you would extract WowVision to `C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\WowVision`.

After extraction, the folder structure should look like:

- `Interface/`
  - `AddOns/`
    - `WowVision/`
      - `WowVision_Standard.toc`
      - `WowVision_Camelot.toc`
      - `WowVision_TBC.toc`
      - `WowVision_Mists.toc`
      - `WowVision_Vanilla.toc`
      - `core/`
      - ...

## Verifying the Installation
Note: Unfortunately we don't yet have an accessible solution for the login screen, but this will be worked on.

Launch World of Warcraft. Once you enter the game, WowVision will initialize automatically. You should hear a speech announcement confirming the addon has loaded.
