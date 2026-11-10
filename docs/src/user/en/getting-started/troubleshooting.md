# Troubleshooting

This page lists the problems players run into most, each with the likely cause and what to do. If nothing here helps, the last section explains how to report a bug so that it can be fixed.

Many of the checks use slash commands. You type them in the game's chat box. Some print their answer to your chat window instead of speaking it; open the chat window with Shift+F3 to read it back. Every command is described in [Commands](../reference/commands.md).

Whatever the problem, first type /reload and press Enter. It reloads the interface and fixes most missing data and stuck windows.

## WowVision does not load

Signs: Shift+F1 does nothing, /wv does nothing (or the game says the command does not exist), and you hear no WowVision announcements.

Go through this list in order.

1. Is the addon switched on? Type /enableaddons in the chat box and press Enter. It is the game's own command: it switches on all your addons and reloads the interface. See [Switching the addon on](./installation.md#switching-the-addon-on).
2. Is it out of date? After a game patch the login screen warns you about out of date addons, and the game usually does not load them. Run the WowVision Updater and choose Update now, or, if you installed by hand, download a newer WowVision. See ["Out of date" addons](./installation.md#out-of-date-addons).
3. Did you restart the game? A newly copied addon is only found when the game starts. /reload is not enough.
4. Is it in a nested folder? The TOC files must sit at AddOns\WowVision\WowVision_Standard.toc (and the four siblings), not at AddOns\WowVision\WowVision\WowVision_Standard.toc. Unzipping "into a new folder" causes this. See [the nested folder mistake](./manual-installation.md#the-common-mistake-a-nested-folder).
5. Is it in the right game version's folder? Classic Era uses `_classic_era_`, the Burning Crusade anniversary `_anniversary_`, Mists `_classic_`, Retail `_retail_`, and WoW: Forever `_forever_`. An addon in another version's folder is simply never seen by the game you started. See [Where to put it](./manual-installation.md#where-to-put-it).
6. Is another copy in the way? Two copies of the addon in different folders, or an old copy named WowVision-beta or similar, can confuse the game. Keep exactly one WowVision folder per game version.

To confirm WowVision runs, press Shift+F1. If the menu opens, it works.

## I hear no speech at all

WowVision speaks through the text-to-speech voices that the game offers, which are the voices installed in Windows. Without speech you cannot use the WowVision menu, so these steps use only commands you type blind into the chat box.

1. Reload. Type /reload and press Enter.
2. Reset the speech settings. Type /wv speech 0 0 100 and press Enter. That chooses the first voice, the normal rate and full volume. If you hear "Speech voice ..." afterwards, speech works again.
3. Try another voice. If the first voice stays silent, try the next ones: /wv speech 1, /wv speech 2 and so on. The numbers count the voices installed in Windows, starting at 0.
4. Check the Windows voices. With your screen reader, open the Windows settings, Time and language, Speech, and make sure at least one voice is installed. The game can only use those voices.
5. Did you cut it yourself? Pressing either Ctrl key stops the speech that is running. If you press Ctrl just as something is announced, you hear nothing.
6. Using a voice that hands the text to NVDA (for example SAPI2SR)? If it stays silent, switch to a plain Windows voice with /wv speech and that voice's number, as in step 3.
7. Speech stalls or stops after a while? On Retail, TBC, Mists and WoW: Forever the Speech module has a Speech Queue setting (on by default) that makes WowVision speak one line at a time. On Classic Era the equivalent is Speech Style with the choices Direct and Buffered. If speech stalls, switch that setting.

## Speech is too slow, too fast or in the wrong voice

- Rate and volume: Speech Rate goes from -10 to 10 (default 0) and Speech Volume from 0 to 100 (default 100; WowVision never sends more than 100, because a higher volume would silence the game's speech). Change them in the Speech module of the WowVision menu, or all at once with /wv speech.
- Find your voice number: type /wv speech with nothing after it. It prints your current voice, rate and volume, and lists every voice with its number, such as "Voice 0: Microsoft David Desktop". Your first voice is number 0.
- Set voice, rate and volume in one go: /wv speech 1 9 100 picks voice 1, rate 9, volume 100. Rate and volume may be left off to keep the current values.
- Make it automatic: make a macro containing the line /wv speech 1 9 100 and press it after login or /reload. See [System windows](../windows/system.md) for how to create macros.
- The voice changed after a Windows update. WowVision remembers your voice by its name, not its number, so installing or removing Windows voices does not switch you to another one. If Windows drops a voice for a while, WowVision speaks with the default voice and brings your choice back when the voice returns.
- One alert sounds different from the rest. Every spoken alert has its own Voice setting. It follows the Speech Voice until you pick another one on that alert. See [Alerts](../basics/alerts.md).

More about voices is in [Speech](../basics/speech.md).

## My keys do nothing

First find out which kind of key you mean. There are two.

- Window keys (arrows, Tab, Enter, Backspace, Escape, Space, Home, End and the rest of the navigation) work only while a WowVision window is open. Without a window, those keys do what the game does with them. That is on purpose, so that arrows still walk.
- Global keys (buffers, navigation, Shift+F1, F9, F10, Shift+F3 and so on) work any time.

If a key does nothing, check these causes.

1. You are in combat. Override bindings cannot change during combat, so WowVision hands all window keys back to the game when a fight starts and takes them again afterwards. Global keys keep working. See [Combat](../world/combat.md).
2. No window is open. Window keys need an open window. Press the key that opens one (for example Shift+F1 for the menu) and try again.
3. A game text box has the keyboard. While you type in the chat box or another edit box, letters and arrows go to the text.
4. A key was still held when the window opened. WowVision waits to take its keys until every key it uses is released, so that the game never misses a key release. Let go of all keys, and the window will take them within a moment.
5. Another addon or a game binding has the same key. Open the WowVision menu (Shift+F1), then UI, then Bindings, and look at what the binding is set to. When you add a key that another WowVision binding already uses, you are asked "This input conflicts with ... Replace?". Keys held by other addons or by the game are not checked, so try a different key. See [Keybindings](../basics/keybindings.md).
6. Sku is loaded. WowVision leaves some keys to Sku. See below.
7. You rebound or removed the key. Some bindings need at least one key and cannot be emptied, but most can. The [keybinding reference](../reference/keybindings.md) lists the defaults.
8. Letters jump instead of doing something. In the WowVision menu, in context menus and in dropdown lists, typing a letter jumps to the next entry that starts with it. This can be switched off with Letter Navigation in Menus in the UI module.

### Escape and closing windows

Escape works two ways. For a window made from one of the game's own frames (a merchant, the bags, the mailbox), Escape is left to the game and the game closes its frame; WowVision closes its window as the frame goes away. For WowVision's own windows (the menu, navigation, the scanner, the chat window, the action bars window, and any screen opened inside another one) WowVision handles Escape itself. On a controller, B does the right one of the two. See [Controller](../controller.md).

If a WowVision window will not go away, type /wv close. It closes every open WowVision window at once. The game's own frames stay open.

### The arrow keys do not walk any more, or my character keeps turning

An open WowVision window takes the arrow keys. Close the window (Escape, or /wv close) and the arrows walk again.

If the character turns or runs by itself, it usually means a movement key was held when a window opened and the game missed its release. Press and release the key to stop it. To help the developers find the cause, type /wv keylog to switch key logging on, play until it happens again, and send the WowVision lines from your chat log along with what you were doing. Type /wv keylog again to switch it off.

## A window or key works without Sku but not with it

You have Sku loaded. When Sku is loaded, WowVision deliberately leaves a list of windows, keys and commands to Sku, so the window does not open in WowVision or the key does nothing. The full list is in [Using WowVision together with Sku](./sku.md).

To get the WowVision version of that window or key, turn Sku off:

- Type /disableaddon sku. This turns off Sku and its audio and beacon helper addons and reloads the interface. /enableaddon sku turns them back on.
- These two commands are not available when the BlindSlash addon is loaded. In that case disable Sku in the game's addon list instead.
- The change needs a /reload or a new login to take effect; /disableaddon reloads for you.

Your WowVision settings and key bindings for those features are not deleted while Sku runs; they come back as soon as Sku is off.

## My settings are lost

Settings are saved when you log out or type /reload. A crash, or closing the game from the task manager, loses everything since the last save.

1. Reload first. If settings or other data seem to be missing, type /reload. That often brings them back.
2. They belong to another scope. By default most settings are shared by all characters (account scope). If you moved a module to a single character, its settings only show on that character. Put the focus on the module in the WowVision menu, press Shift+F10 and look at Scope. Key bindings and a few other things are always per character. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).
3. A new release reset one thing. The release notes say when an update changes a setting.

If settings still do not stay, report it (see [Reporting a bug](#reporting-a-bug)) and include the output of /wv dbcheck, which prints a short report about your saved settings to the chat window.

## The game is laggy or stutters

- Close windows you are not using. WowVision rebuilds an open window every moment.
- If the stutter happens while walking outdoors, switch off Announce Tracked Dots While Walking in the Minimap Scanner module; it reads the minimap twice a second while you move. See [Minimap](../world/minimap.md).
- If it happens in combat or in a raid, check how many monitors you have running. See [Monitors](../information/monitors.md).
- Try playing with WowVision as the only addon to see whether another addon is the cause.

To report a lag problem, type /wv gperf: it measures WowVision's per-frame work over 120 frames and reads out the shortest, average and longest times. Include that line in your report.

## Game errors and the "Blocked" announcement

- You hear "Lua error: ..." WowVision reads every script error aloud, but not the same one more than once every five seconds. To read the full text, type /wv errors. It speaks the most recent error and opens a window with all of them and their stack traces. The text is selected, so press Ctrl+C to copy it, and Escape to close the window. /wv errors all also shows older history when BugSack or BugGrabber is installed. /wv errors clear empties the list. WowVision keeps the last 20 errors, and they survive /reload. To stop the spoken errors, switch off Announce Errors in the Errors module. To silence only certain game messages (such as "Out of range"), use Per-Error Filter in the same module; see [Combat](../world/combat.md).
- You hear "Blocked: ..." followed by a name. The game refused a call that WowVision made while a protected action was in progress (a blocked macro is announced too). Blocks caused by other addons are recorded but not spoken. It is not a Lua error, but it means something did not work. Type /wv taint to list the recorded blocks with the time and what had the focus. /wv taint clear empties the list. Mention it in a bug report.
- The error list is empty but something is clearly wrong. If BugSack or BugGrabber is installed, it takes over the error handler and keeps the errors in its own list; /wv errors reads it first.

## Soft targeting behaves strangely

Soft targeting changes game console variables, and some of them cannot change during combat. Type /wv soft to see the lock mode and the value of every soft targeting variable with the game's default in brackets, and a note when a change is waiting for combat to end. For what each soft target setting does, see [Targeting](../world/targeting.md).

## The controller does nothing

Controller support is for Retail and WoW: Forever. In the game options under Gamepad, Enable Gamepad and Enable Gamepad UI must both be on. In combat, WowVision gives the window buttons back to the game. See [Controller](../controller.md) for everything else, including how to start a fresh log with /wv padlog for a bug report.

## I am stuck on a route

The beacon leads you somewhere you cannot get through, or a waypoint never counts as reached. Try these, one after the other:

- Jump forward. A small edge, a step or a root on the ground often stops you, and a jump gets you over it.
- Walk a few steps to the left or right, then turn toward the waypoint again. The direct line can run into a post, a corner or a crate.
- Skip the waypoint: Ctrl+W moves the beacon to the next waypoint.
- Go back one waypoint: Ctrl+S moves the beacon to the previous waypoint. Walk to it and try the stretch again.
- Change the arrival distance with Alt+P. A shorter distance leads you more precisely through a door or a narrow passage. A longer distance counts a waypoint as reached sooner, which helps when you cannot stand on its exact spot.
- Talk to the NPC you are looking for. Sometimes the NPC stands right in front of you, but a counter or a table is in between, as at the bank in Stormwind. You can never reach the last waypoint there. Target the NPC and press your interact key; the game walks you as close as it can and opens the window.
- On a WowNav route, press the key you bound to New WowNav Route Around a Blocked Spot. It searches a way around the spot you are stuck at. See [WowNav](../world/wownav.md#a-blocked-spot).

You can put Next Waypoint, Previous Waypoint and Cycle Arrival Distance on other keys in the keybinding window: WowVision menu, UI, Bindings. See [Navigation](../world/navigation.md#next-and-previous-waypoint) for the route keys.

## Reporting a bug

Please report problems on GitHub: [the WowVision project](https://github.com/wow-vision/WowVision). Open an issue and describe:

- What you did, what you expected to hear, and what happened instead.
- Your game version (Classic Era, TBC, Mists, Retail or WoW: Forever) and your WowVision version, printed by /wv version.
- Which other addons you run, especially Sku, BlindSlash, Questie and BugSack.

Then add whatever logs fit the problem. Each of these is a window with selected text; press Ctrl+C to copy it and paste it into the issue.

| Problem | Command to run and attach |
|---|---|
| A script error | /wv errors |
| "Blocked: ..." or something that works only out of combat | /wv taint |
| Controller problems (Retail, WoW: Forever) | /wv padlog just before you show the problem, then /reload |
| Turn to waypoint turns the wrong way | /wv turnlog |
| Cooldown manager monitors on Retail or Forever | /wv cdmlog |
| A character that turns or runs on its own | /wv keylog |
| Soft targeting | /wv soft |
| Lost settings | /wv dbcheck |
| Minimap scan or walking announcements | /wv mscan log |
| Quest data | /wv quests probe |

Several of these logs are also saved into the WowVisionDump saved variable, which the game writes to disk when you log out or type /reload. Attach the file WowVisionDump.lua from the SavedVariables folder in your WTF directory. Its location is described in [Installing WowVision](./managing.md#where-your-settings-are-saved). It can contain character names, so look through it before you share it.
