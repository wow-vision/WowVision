# Logging In with the Sku Login Tool

WowVision starts working once your character is standing in the world. The game only loads addons at that point, so no addon, WowVision included, can read the screens before it; only the game itself could make them accessible. WoW: Forever reads its login screens aloud, but they still need the mouse, so the tool helps there too. To get through the login screen, the realm list, the character screen and character creation, you can use the WoW Login Tool (version 4.x) that comes with Sku. This page explains what it is, how to get it, and how to use it, so that you can hand over to WowVision as soon as you enter the world.

## What it is

The WoW Login Tool is a small Windows program that runs next to the game. It is the "start menu" tool of the Sku project. It is not an addon and it is not part of WowVision. It does not read or change the memory of the game. It only looks at the game window and presses keys and mouse clicks, the same things a sighted player does.

With it you can:

- Log in on the account screen when the game did not log you in by itself.
- Change the realm.
- Choose a character and enter the world.
- Create a character, including a name check.
- Delete a character.
- Hear the pop-up messages of the game read out loud, for example "name not available".

This page describes WoW Login Tool version 4. The tool says its version number when it starts.

How it works depends on the game version:

- On Classic Era and The Burning Crusade (TBC) Anniversary, the tool looks at the screen with Windows text recognition (OCR) and reads it to you with its own voice. It announces real character names, levels, classes and zones, and the real realm list.
- On WoW: Forever, the game reads its own login screens aloud with its text to speech voice. The tool does not read the screen to you there. Instead it moves the mouse for you from item to item, and the game speaks each one.

### Which game versions it supports

| Game version | Support in version 4.x |
|---|---|
| Classic Era | Supported. |
| The Burning Crusade Anniversary (2.5.x) | Supported. |
| WoW: Forever (live client) | Supported, with the whole character creation including all appearance options. |
| Mists of Pandaria Classic | Not supported. The tool announces that this game version is not supported yet. |
| Retail and Cataclysm Classic | Selectable in the setup, but not supported. |

The tool detects the game version itself (see "First start"). Wrath of the Lich King clients are not supported either.

## What you need

- Windows 10 or Windows 11. The tool uses functions built into Windows (window capture and text recognition), so nothing is sent over the internet.
- AutoHotkey version 2 (see "Getting and installing it").
- The game itself, started at least once.
- For the screen reader voice option: NVDA. See "Voice and speech" below.

The Windows text recognition needs the language of your game client. The tool uses the language you choose in its setup: English, German, French, Russian or Spanish. If Windows has no text recognition for that language, the tool falls back to the languages of your Windows profile. It keeps running, but it may read names and realms badly.

A Mac version of the tool exists, but this manual does not cover it.

## Getting and installing it

The easiest way is the [WowVision Installer](./installer.md): its Install the WoW Login Tool option is ticked by default. It installs the tool for WoW: Forever, The Burning Crusade anniversary and Classic Era, brings the AutoHotkey it needs, copies the screen recognition files and the clearer font into Classic Era and The Burning Crusade, and puts a WoW Login Tool shortcut on your desktop and in the Start menu. Start the tool from that shortcut.

### By hand

1. Install AutoHotkey version 2 from [https://www.autohotkey.com/](https://www.autohotkey.com/).
2. Download WoW-Login-Tool.zip from the [WoW Login Tool version 4 download page](https://github.com/Sku75/Sku-WoW-Addon-TBC/releases/tag/login-tool). That release always holds the newest tool. Unzip it. The folder inside is called WoW Login Tool. Best put that folder into your World of Warcraft folder, next to the game version folders. On WoW: Forever the tool finds the game's settings file from there, or in the default install folder.
3. Open the folder CopyTheContentOfThisFolderToInterface inside the tool folder. It holds five folders. Copy all five.
4. Open your World of Warcraft installation folder (often C:\Program Files (x86)\World of Warcraft) and then the folder of your game version:
   - _anniversary_ for The Burning Crusade Anniversary
   - _classic_era_ for Classic Era
5. Open its Interface folder and paste the five folders. Agree to overwrite existing files.
6. Recommended on Classic Era and TBC: run the script install_wow_fonts.ps1 from the tool's fonts folder as administrator. It replaces the game fonts with a clearer font that the text recognition reads much better. By default it works on the TBC Anniversary folder. For Classic Era, pass the folder with the parameter -ClientDir. The parameter -Remove undoes the change. The change takes effect when the game starts the next time.
7. Start the tool by running START.ahk in the v2 folder with AutoHotkey version 2.

On WoW: Forever you do not need the five texture folders or the font.

Things to know about the install:

- The five copied folders overwrite game interface files that have the same names. If another addon changes the same files, it will be affected. If the tool says the "screen recognition textures are missing from the game folder", copy the five texture folders again.
- After a new tool version, copy the five folders again. Old copies can stop the tool from recognising the screens.

## First start

1. Start the tool. It says "Login tool version" and its number, for example 4.1. On the very first run it says "Setup mode" and asks you to set up four things with the arrow keys, in this order: voice ("Go right to select a voice"), language, region (Europe or USA) and game type. Move Right to go in, Up and Down to choose, and press Enter to confirm. Each choice is confirmed with "selected". At the end you hear "Setup completed. Start the game now."
2. After that the tool is in Pause mode and waits quietly.
3. Start the game. As soon as the tool sees the game window and knows the screen, it says "Login mode for" followed by your game version, region and language, for example "Login mode for Burning Crusade, Europe, English". While it works you hear a short repeating sound. It then says "Main menu". If the game was already running, tab back into it.

The tool works out the game version itself. When that differs from the version saved in its setup, it switches and says "game version detected" with the name. For a client it has no setup for (for example Mists of Pandaria or Wrath) you hear "This game version is not supported yet." and the version number. If it guesses wrong, use Select game type in the menu to set it by hand. The choices are Cataclysm, Classic Era, Burning Crusade, Retail and WoW Forever. A hand-picked game type stays fixed. Detect game type automatically, an entry in the same list, switches back to automatic.

Changing the language, the region or the game type later makes the tool restart itself ("selected. Restarting script to apply. Please wait."), so you hear the version again. Changing the voice does not.

Tips for the Forever client:

- Start the tool before you start WoW: Forever. At start-up, while the Forever game is not running, the tool turns on the game's screen narration, switches off the first-start narrator question, and sets the narration voice and speech rate in the game's settings. When it changes something you hear "narration settings written for Forever". The game only reads these settings when it starts. If the game is already running, the tool leaves the settings alone and says nothing about it.
- If you hear the game's default voice instead of yours after a first install, close the game and start the tool first, then the game.

## The modes

- Setup mode: only on the very first start, while you choose voice, language, region and game type.
- Pause mode: the tool waits. It is active whenever the game window does not have the focus.
- Login mode: the spoken menu for the login, realm and character screens. It starts automatically when the tool sees one of those screens.
- Play mode: you are in the world. The tool lets all keys through to the game. WowVision (and Sku, if installed) work from here.

The tool changes mode by itself. Each time you leave the game window and come back, it starts again from the main menu. That is by design. The Alt+F1 key switches the mode by hand (see the key table).

If the tool does not switch by itself between Login mode and Play mode, press Alt+F1.

These rules keep the tool working:

- While it works and plays its waiting sound, do not press keys, click, move the mouse or switch windows.
- Keep the game window in front and visible. Do not play with it minimised.
- To stop a running action, press Alt+F1.

## Using the tool on Classic Era and TBC

### Log in to the account screen

If the game could not log you in by itself, it sits on the account screen. The tool then says "Not logged in. Either there is no connection to the server, or account name and password still have to be entered in the game." Its menu then offers only things that work without a login: Account name, Password, Log in, Save account name, then voice, language, game type, region and version.

1. Move to Account name and press Enter. (Right only repeats the entry.) You hear the current content of the field ("Account name: empty" if there is none) and then "Type now. Enter ends the entry, Escape leaves it." Type your account name and press Enter. The tool reads the account name back.
2. Move to Password and do the same. You hear "Type now. The password is never read back." The password is never read back, and Enter ends the entry without logging in.
3. Choose Log in with Enter. You hear "Logging in. Please wait." The tool reads out any pop-up (for example a wrong password), closes it and says "The login did not go through." If the game is just connecting, the tool only reads the message and waits.
4. Save account name switches the game's own "remember account name" box on or off and says "Save account name: on" or "off".

While you type in a field, the arrow keys go to the game so you can correct typos. The tool never stores your password and has no automatic login. Closing and reopening the Battle.net app is often the faster way back. On Forever the game narrates its own login screen instead.

### The main menu

The main menu has these entries, in this order:

1. Select character
2. Login with selected character
3. Create new character
4. Change server
5. Delete character
6. Select voice
7. Select language
8. Select game type
9. Select region
10. A version entry. It reads "WoW Logintool V3.0, Version: V3.0". That is not the release number of the tool. The release number is spoken when the tool starts.

Use Up and Down to move between the entries, Right to go into an entry that has a submenu, Left to go back, and Enter to run an entry. Wording differs in other languages and can change in future versions.

### Select a character and enter the world

1. Go to Select character and press Right. The tool lists your characters by real name, level, class and zone, for example "1: Anna, level 1 Priest". If there is none, you hear "Empty. No characters on this server."
2. Choose the character with Up and Down (Page Down and Page Up jump ten) and press Enter. The tool says the name followed by "selected" and moves on to Login with selected character.
3. Press Enter to enter the world. The tool says "Play mode". If it does not, press Alt+F1.
4. A new character may start with an intro movie. When it ends, you stand in the world and WowVision takes over.

Counting a realm with many characters can take several seconds. The tool says "Please wait, the character list is being rebuilt." and, on a long list, counts aloud every ten characters. A realm can hold many characters, but the game screen shows nine at a time. The tool counts all of them, so that all of them are in the list. If it could not count them, it says "The character list may be incomplete. Press Alt F1 twice to rebuild it."

### Change the realm

1. Go to Change server and press Enter. The tool opens the game's realm list and reads the live list from the screen. That takes a few seconds, with the waiting sound. Then you are on the first realm. The entries are the realms (with their type and load), then one entry per category (the tabs of the game's realm list, spoken "select category" and the tab name), and as the last entry Close server selection. Choosing a category reads that tab's realms.
2. Choose a realm and press Enter. The tool says "Changing server. Please wait." and then "Server changed" followed by the realm name.
3. The tool checks which realm the game really shows and warns you if it is a different one: "Attention. The game is on a different server" and the name. Change the server again before you play there.

Special cases:

- On a realm that has no characters of yours yet, the game goes straight to character creation. The tool says "No characters on this realm yet."
- Some Classic Era realms show a hardcore or PvP warning. The tool reads the text and says "Press Enter to agree, or press Escape to decline." It never answers for you.
- The tool does not handle realm queues. While the game shows a connecting message, the tool reads it and waits. After about a minute it says "The game is still connecting. Press Escape to cancel."
- If the game itself opens the realm list, you hear "The game has opened the server selection." and the realms appear as a menu. Close server selection is the last entry.
- While the game is connecting (login, realm change, game start), a pop-up with only one button is read but never pressed. That one button is "Cancel", and pressing it would stop your login.

### Create a character

1. Go to Create new character and press Right.
2. Choose the gender, then the race, then the class (only classes the race can play are listed), then the starting zone. Use Right to go deeper and Left to step back. Press Enter on the starting zone.
3. The tool says "Enter the name for the new character and press enter, or escape to cancel character creation." Type the name and press Enter.
4. If the game rejects the name, it shows a pop-up. The tool reads the pop-up aloud, closes it, empties the name field and asks for the name again. Try another name.
5. After success you hear "Character created". The list is rebuilt, and the tool returns to the main menu. The new character is not selected for you.
6. If something else goes wrong, for example the realm already holds the maximum number of characters, the game's pop-up is read the same way. If the tool gets no answer for about 18 seconds, you hear "Something went wrong. Please restart the game and try again."

Name rules: no spaces, the same letter not three times in a row, and the first letter is made a capital for you.

Press Escape during the name entry to cancel. The tool says "Creation is canceled. Please wait." You cannot choose the look of the character on Classic Era and TBC. The game's default look is used.

On a hardcore realm the game asks you to agree to the hardcore rules before the character is created. The tool reads the rules page by page and asks for Enter (agree) or Escape (decline).

On a new account the game also shows Blizzard's social contract. The tool scrolls it to the end and accepts it for you: "Blizzard's social contract is open. Accepting it, please wait." Then "Social contract accepted." If that fails, you hear that sighted help is needed once: scroll the text to the end and press accept.

### Delete a character

1. Select the character you want to delete first (see "Select a character and enter the world"). The tool uses the game's Delete button, so it deletes the character that is selected in the game right now. Right after the tool has counted the list, that is character 1.
2. Choose Delete character and press Enter. The tool reads the game's confirmation pop-up aloud. It names the character, so check the name before you go on.
3. The tool asks you to type the word DELETE, in capital letters, and press Enter. The tool does not type the word for you. If the game does not accept it, you hear the request again. Press Escape to cancel (you hear "Deleting is canceled. Please wait").
4. On success you hear "Character deleted" and the list is rebuilt.

The word is DELETE in English. In other tool languages it is the word of that language (LÖSCHEN, EFFACER, BORRAR, УДАЛИТЬ).

## Using the tool on WoW: Forever

On Forever the tool works differently, so the keys do different things. The game reads each item aloud when the mouse rests on it. The tool moves the mouse for you.

1. When the tool recognises the game it says "Login mode for WoW Forever" with your region and language. The game narrates the first screens: the screen reader question (switched off by the tool), the login screen, the ruleset cards and the experience cards. If the tool meets a screen it cannot name, you hear "Forever mode: the game reads the screen itself. Press Control Alt F3 to save a screenshot for calibration." That is a hint for bug reports. Keep going with the arrow keys.
2. Up and Down move to the next or previous item on the screen. The game speaks each one. At the ends of the list the cursor goes around.
3. Page Up and Page Down jump five items. They stop at the first and last item.
4. Enter clicks the item. On a text field, Enter starts typing mode. You hear "typing mode, Enter or Escape to leave". Type, then press Enter or Escape to give the keyboard back to the tool. Escape is also passed on to the game.
5. Left and Right change the value of an appearance option. On any other item, Left reads the screen again and Right says the current item again.
6. Escape closes an open list of choices. Otherwise it goes to the game, so it backs out of a screen or opens the game menu.
7. The tool also knows the code of conduct (it scrolls to the end by itself and leaves the cursor on Accept), the character list with the delete dialog, and the game menu you get with Escape.
8. The Enter World button switches the tool to Play mode. Alt+F1 goes back to Login mode, for example to return to the character screen.

### Create a character on Forever

Character creation is fully covered. The two creation pages are:

- Race and class. The races are listed per faction. Hear them with Up and Down. Both rows of classes and the body type are reachable.
- Appearance and name. The page has the full name field, a second name field if the game shows one, the name check, the dice button for a random name, and the appearance options with their current value.

On the appearance page, press Left and Right to change an option. The tool then says the new value and the number, for example "4 of 10". For hair styles and similar choices it adds the name of the choice shortly after, once the screen shows it. Colour options have no name in the game. The tool names the colour roughly, for example "light brown". Reddish light colours are called pink. Names can include a strength such as pale, dull, strong or bright.

Press Down on the lowest option to scroll the list further. The tool jumps to the next option. When the list ends, it goes on to Finish.

The name check shows a small icon next to the name field: a green tick (name free), a red cross (with a reason) or nothing while the game checks or the field is empty. The tool says what the icon shows: that the name is available, the reason the name was rejected, or "no result of the name check yet". It waits up to about two and a half seconds for the result after you type.

### Repeating items

The game says each text only once per run. If you hear nothing after moving to an item you already heard, the tool speaks it again for you. This is normally on when you use the screen reader bridge voice and off with a real voice. It can be changed with the setting repeatecho (see "Settings and files").

## Key reference

In Login mode and during first-time setup the tool takes these keys. In Play mode they go to the game.

| Key | Classic Era and TBC | WoW: Forever |
|---|---|---|
| Up / Down | Previous or next menu entry | Previous or next item on the screen |
| Page Up / Page Down | Ten entries up or down | Five items up or down |
| Right | Open the submenu, or say the entry again if it has none | Next value of an appearance option; elsewhere says the current item again |
| Left | Back to the menu above | Previous value of an appearance option; elsewhere reads the screen again |
| Enter | Run the entry; confirms a name, a deletion, or the end of typing in a field; agrees to a hardcore warning | Click the item; in a text field starts typing and ends it |
| Escape | Cancels name entry, deletion and the end of typing in a field; declines a hardcore warning. Otherwise it goes to the game | Closes a list, ends typing, or goes to the game |
| Alt+F1 | Switch between Login mode and Play mode, and stop a running action | Switch between Login mode and Play mode |
| Alt+Escape | Quit the tool (you hear "Terminated"; works in every mode) | Quit the tool |
| Ctrl+Alt+F2 | Full screen screenshot to the Windows clipboard | The same |
| Ctrl+Alt+F3 | Saves a screenshot for the developers to the tool's data\captures folder and says "screenshot saved" (for bug reports) | Saves a screenshot for the developers to the tool's data\captures folder and says "screenshot saved" (for bug reports) |
| Numpad 7 | Play mode only: sets a camera view and right-clicks near your character | The same |
| Numpad 8 | Play mode only: sets a camera view and left-clicks a little closer to the middle of the screen | The same |

The two Numpad keys are helpers for Play mode and are not needed with WowVision.

Alt+F1 does not keep the tool switched off while you stay on a login or character screen: within a second or two it sees that screen again and goes back to Login mode. To stop the tool for real, press Alt+Escape, or switch away from the game window (Alt+Tab). The tool then sits in Pause mode.

## Voice and speech

- The tool speaks through a Windows speech voice (SAPI), not through the screen reader. Choose the voice in the first-start setup or later with Select voice. A voice is tested silently first. If a voice does not work, you hear "This voice does not work, choose another one" and your old voice stays.
- If the voice list is empty, you hear "No voices found, press Enter to keep the system voice."
- The special entry SAPI2SR is not a real voice. It is a bridge that hands the text to NVDA, so you hear it in your own screen reader voice. With that voice, arrow keys cancel NVDA's speech. With a real voice, speech is interrupted on every move as usual.
- On Forever the narration voice is the position of your chosen voice in the Windows voice list. The speech rate is 5 by default. See "Settings and files". If you hear the wrong voice on Forever, set voice= in forever.ini. The tool's log lists all voices with their numbers.
- The output device can be changed with gAudioOutputMatch in the settings file. Enter a part of the device name. Empty means the system default.

## Settings and files

The tool's files are in the WoW Login Tool folder. They are small text files. Edit them with the tool closed.

| File | What it holds |
|---|---|
| data\settings.ini | Your setup: game type (and whether you picked it by hand), voice, language, region, output device. Delete this file, with the tool closed, to run the first-start setup again. |
| data\forever.ini | Forever options: voice= (number of the Windows voice, counting from 0), rate= (-10 to 10, 0 is normal), volume= (0 to 100), repeatecho= (1 or 0), echo= (1 makes the tool speak every item, for debugging), wheelnext=up (turns the direction of the mouse wheel steps around if the game's list scrolls the other way). Without a voice line, Forever gets the voice you chose in the tool. |
| log.txt | The log of the current run. The last five runs are kept as log-1.txt to log-5.txt. |

### What the tool writes to the game

On Forever, while the game is closed, the tool writes the narration settings into the game's settings, so that the game speaks with your voice.

## Tips

- Sign in through the Battle.net app, which works with a screen reader on Windows and on Mac, and tick "keep me logged in" once. The game then logs you in by itself, and the tool starts at the realm and character screens.
- Read these steps on a second device. Every time the game window loses the focus, the tool pauses and restarts from the main menu when you come back.
- Listen to the character list again after you create or delete a character. The list is rebuilt and the numbers can change.
- Be patient. Realm lists and character counts take seconds. The tool plays a waiting sound while it works.
- On Classic Era and TBC turn off overlays and colour changes (see Troubleshooting).
- Once you hear "Play mode" and the world has loaded, WowVision is in charge. If you hear nothing from WowVision, check [Troubleshooting](troubleshooting.md).

## How WowVision and the login tool work together

The tool ends at the world. In Play mode it only watches the screen and offers the two Numpad camera helpers. From then on, everything is WowVision (see the [Quick Start](quick-start.md)).

- The tool does not need WowVision and WowVision does not need the tool.
- You can keep the tool running in the background while you play. If you want it off, press Alt+Escape.
- When you come back to the character screen, for example after you log out, start from the beginning of this page again. On Forever press Alt+F1 to get back into Login mode.
- WowVision lists the Sku addon as an optional addon. It does not use the login tool. If the Sku addon is loaded, WowVision turns some of its keys, windows and commands off so the two do not fight over keys, for example the focus keys, soft targeting, the tooltip line keys (Shift+Up, Shift+Down, Shift+Left, Shift+Right), and windows such as gossip, trade, mail and training. The commands /pquit, /dquit and /focus1 to /focus5 are then left to Sku.
- If you want WowVision to take over completely, the command /disableaddon sku turns Sku and its audio and sound packs off and reloads the interface. /enableaddon sku turns them back on. These two commands do not exist when BlindSlash is loaded.

The full list of windows, keys and commands that WowVision leaves to Sku is in [Using WowVision together with Sku](sku.md).

## Troubleshooting

| Problem | What to try |
|---|---|
| The tool stays in Pause mode and says nothing when the game is open | The tool only works while the game window has the focus, and only after it has recognised the game window. Click into the game window. On some computers it works better to start the game first and the tool second. If nothing helps, restart the tool and the game. |
| "Unknown screen. Close the dialog in the game, then press Alt F1 twice." | The game shows a screen the tool does not know, often the game menu or a dialog. Close it (Escape), then press Alt+F1 twice. |
| "The screen recognition textures are missing from the game folder" | Copy the five texture folders again (see "Getting and installing it"). |
| The tool does not recognise any screen | Turn off the Discord in-game overlay (User Settings, Game Overlay). Hide the Nvidia overlay with Alt+R. Reset HDR, high contrast, brightness and colour filters in Windows and in the game. |
| "The game is starting. Please wait." for a long time | The game is still loading. The tool only says "Unknown screen" after about 12 seconds without recognising anything. |
| "Something went wrong. Please restart the game and try again." | An action failed. The tool beeps twice and drops into Pause mode, then picks the screen up again by itself. Press Alt+F1 to stop a running action, then try again. If it keeps happening, restart the game and the tool. |
| "Not logged in" on the account screen | Use Account name, Password and Log in, or restart Battle.net and the game. |
| "The server list did not load. Please try again." | The realm list was empty when read. Wait a few seconds and open Change server again. |
| Names, realms or pop-ups are read wrongly or as nonsense | The language set in the tool probably does not match the language of the game client. The tool reads the screen with that language. Change it with Select language. |
| You hear the game's default voice on Forever | Close the game, start the tool, then start the game, so the tool can write the narration settings. |
| The tool is quiet or says "This voice does not work" | Choose another voice in Select voice. If no voice works, check the Windows speech settings. |
| Repeated items on Forever are silent | Set repeatecho=1 in forever.ini and restart the tool. |
| Something is still wrong | Take the log. The tool's own log is the file log.txt in its folder. Report it on the WowVision Discord, with the log and the tool version, which the tool says when it starts. |

## Known limits

- The appearance options on Classic Era and TBC are not available.
- On Forever, very quick changes in a long list (for example hair styles) may briefly say the wrong value before the tool corrects itself.
- The tool needs a Windows PC. A Mac version exists but is not covered here.
- The license text before the first login still needs sighted help once. The tool handles the social contract inside the game.

## Sources

- [WoW Login Tool version 4 download (the "login-tool" release with WoW-Login-Tool.zip)](https://github.com/Sku75/Sku-WoW-Addon-TBC/releases/tag/login-tool)
- [Sku Discord invite, for help](https://discord.gg/AzFwTDmpbk)

See also: [Installation](installation.md), [Quick Start](quick-start.md) and [Troubleshooting](troubleshooting.md).
