# Installing with the Installer (recommended)

The WowVision Installer is a Windows program that installs WowVision for you and keeps it up to date. It is the recommended way to install WowVision:

- It finds the World of Warcraft versions on your computer by itself and puts WowVision in the right folder of each, so the folder mistakes described in [Installing by Hand](./manual-installation.md) cannot happen.
- It matches WowVision to your game's patch, so a game patch does not stop WowVision from loading.
- It turns off the game's "run this script?" question, which otherwise interrupts some commands.
- It can install the WoW Login Tool, which makes the login and character screens usable, and a set of addons many players use.
- Run again later, it updates all of it.

Every page of the installer announces itself, and the progress is spoken as it installs, so it works with NVDA, JAWS or Narrator.

The installer runs on Windows only. On a Mac, see [Installing by Hand](./manual-installation.md).

## Download and start

1. Download the installer: [WowVisionInstaller.exe](https://github.com/wow-vision/wowvision-installer/releases/latest/download/WowVisionInstaller.exe). This link always gives you the newest version.
2. Run the downloaded file. Windows asks whether the program may make changes to your computer; choose Yes. The installer needs this because it writes into the game's folder.
3. Windows may also warn that it protected your PC from an unrecognized app, because the installer has no paid signature. Choose More info, then Run anyway.

The installer speaks the language of Windows (English, German or French). You can switch it on the components page, described below.

If a newer version of the installer itself exists, it first offers "Update the installer now (recommended)". Choose it: it takes a few seconds, and the installer restarts and carries on.

## The opening screen

The heading tells you where you stand: "WowVision is not installed yet", "An update for WowVision is available", "WowVision is installed and up to date", or "No World of Warcraft installation found". Below it are the buttons:

- Install now: installs WowVision into the game versions the installer found, with the recommended setup. On a first install this is all you need.
- Update now: updates WowVision where it is installed and keeps the choices you made last time.
- Install WowVision fresh, or for further game versions: the longer way, where you choose the game versions, the folders and the components yourself. See the next section.
- Browse: shown when World of Warcraft was not found. Select your World of Warcraft folder, a game version folder such as `_retail_`, or its Interface\AddOns folder.
- Collect all logs: writes one zip file to your Downloads folder with WowVision's saved data, the game's logs and the installer's own log. Attach it to a bug report.

## Choosing everything yourself

"Install WowVision fresh, or for further game versions" leads through three pages. Next moves on, Back goes back.

1. Which game versions should WowVision be installed into? Tick every version you play: WoW: Forever, The Burning Crusade anniversary, Classic Era, Mists of Pandaria Classic and Retail. All of them are done in one run.
2. Where is each version installed? The folders WowVision will be written to. If one is wrong or missing, use the Browse button next to it.
3. What should be installed? The defaults are the recommended setup; if in doubt, just continue. The page holds:
   - Language of this installer.
   - Which WowVision: Stable release (recommended) or Beta. The stable release is the last numbered version and is best for most players. The beta is rebuilt with every change, so it has the latest fixes and features and can have new bugs. Your choice is remembered for later updates.
   - Additional recommended addons: Questie, AtlasLoot Continued, Details, Pawn, Deadly Boss Mods, GTFO, and BugSack with BugGrabber. All but Pawn are ticked. Each game version gets the build made for it; an addon that does not exist for one of your game versions says so and is skipped there. See [Optional addons](./installation.md#optional-addons) for what WowVision does with Questie.
   - Create a desktop shortcut to the WowVision Updater (ticked): a shortcut on the desktop and in the Start menu, to update later without downloading the installer again.
   - Enable NVDA as a voice in WoW (not ticked): installs the NVDA voice bridge, so NVDA appears in the game's voice list and WowVision can speak through it. See [Speech and Sound](../basics/speech.md).
   - Make all Windows voices available to WoW (not ticked): Windows keeps its newer voices in a list the game cannot see; this copies them into the game's list, after a backup. The game's voice numbers can shift, so check your speech voice afterward.
   - Install the WoW Login Tool (recommended, ticked): a separate program that gives the login, server and character screens an audio menu, for WoW: Forever, The Burning Crusade anniversary and Classic Era. It is the Sku Login Tool; see [Logging In with the Sku Login Tool](./sku-login.md).
   - Reinstall everything (repair) (not ticked): replaces WowVision even when it is current. Use it to repair a broken install.

Then choose Install.

The two voice options change the voice list of your whole computer, which every speech program then offers. That is why they are off by default and why Update now never runs them.

## While it installs

The installer announces each step, and during the download it says the progress every 10 seconds. The progress history is a list you can go through with the arrow keys. Cancel installation stops after the current step; nothing is left half written.

The game has to be closed for a first install into a game version and for the game settings. If it is running then, the installer asks you to close World of Warcraft completely and waits. An update of a WowVision that is already installed is copied even while the game runs; type /reload in the game afterward.

## When it finishes

The last page says "Finished", or "Finished with problems" with the reason for each game version. View event log lists every step of the run, line by line. Close installer ends it.

Then start World of Warcraft from Battle.net, or type /reload if the game was running. Continue with [Switching the addon on](./installation.md#switching-the-addon-on) and [First login](./first-login.md#in-the-world).

## Updating later

Start the WowVision Updater from its shortcut on the desktop or in the Start menu. It is the same program: it first updates itself if needed, then shows the opening screen. Choose Update now. It updates WowVision in every game version it installed to, follows the beta or stable choice you made, and updates the additional addons too.

To change your choices (another game version, the beta instead of the stable release, the voice options), choose "Install WowVision fresh, or for further game versions" instead.

A beta you extracted by hand, or another test build, is left as it is until you choose Reinstall everything, because the installer cannot tell how old it is. A numbered release you extracted by hand is updated normally.

## What the installer leaves on your computer

The installer has no uninstaller of its own, because everything it does is files and a few settings:

- the WowVision folders in each game version's AddOns folder, with a small file WowVisionInstall.json that records which release each folder came from;
- the two game settings: Load out of date AddOns, and no "run this script?" question;
- the updater in your local application data folder (`%LOCALAPPDATA%\WowVisionUpdater`) and its shortcuts;
- the additional addons you chose;
- the WoW Login Tool folder and its shortcuts, if you chose it;
- the NVDA voice bridge and the copied Windows voices, if you chose them.

To remove WowVision, follow [Uninstalling](./managing.md#uninstalling).
