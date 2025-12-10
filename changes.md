# Changes

## V0.5.0
this patch introduces significant refactors to the UI code, greatly increasing performance. It also fixes some bugs with gem socketing and adds more alerts for flying, outdoors, swimming, and combat start/end.

* Fixed gem socket colors reading as "color" if you didn't have colorblind mode enabled.
* Fixed tainting issue with gem socketing UI that prevented socket buttons from being clicked.
* Majorly refactored the UI code behind the scenes. This increased performance by ~50%. The changes won't be too noticeable, but bags/etc should feel more responsive.
* Fixed a long-standing bug where certain UI elements would be in an incorrect order if certain screens refreshed.
* Fixed a bug where the gossip window would sometimes be blank.
* Fixed a bug where the text elements when picking up available quests were in a random order.
* The significant performance issues with the character pane are now fixed.
* Fixed the long-standing bug where entering combat with certain UI windows open would cause odd behavior, such as certain windows not closing. Now navigation-related hotkeys are just disabled until combat ends.
* Added the /wv close command. If the UI does glitch out again, this will force any remaining UI contexts to close. Please report any further UI bugs.
* The /dquit command will now properly leave battlegrounds and arenas.
* Updated and added various TTS output alerts:
    * For navigation/compass: direction changed, outdoors/indoors, flying start and end, swimming, and diving
    * For UI/Combat: combat start and end

## For Developers
* Added a performance profiler. This can either be used via code or via slash commands for some global WowVision profiling parameters. See Profiler.lua for the class and /wv profile for the global profiling. The global profiling commands are /wv profile, /wv profile report, and /wv profile reset.

## V0.4.0
Unfortunately once again this release resets saved addon data entirely. I had to move away from using a popular addon library (AceDB) due to issues with how it handles default values for certain settings. As a result I had to restructure the data significantly. To be safe, old WowVision data (such as speech settings) will be reset the first time you log into a character. Sorry again for the inconvenience and this should not happen in future updates.

* Refactored all inputs to use the new input system. This will allow for input remapping and more flexibility in terms of what can be keybound and when.
* You can now remap all WowVision inputs. To do so, access UI/bindings from the /wv menu or with the /wv bind command. Note that you must still remap base game bindings from the options menu and that the mod does let you duplicate bindings (so if you bind w, it will replaced the move forward action while in the WowVision UI.)
* Fixed a bug where entering the /wv menu would not correctly keybind elements in that menu if you were in another screen previously. For example if you were in the options screen and typed /wv, hitting enter on an element would click on the currently focused element in the options screen. This should no longer happen.
* The item socketing frame no longer errors in the case of special sockets (Sha-Touched, etc.) Certain socket colors may not be translated though due to how awkward the API is.
* You can now destroy the item on the cursor by pressing the delete key or ctrl-alt-backslash by default. Note that the item must be on the cursor; you can't just arrow over one and press delete. I will change this if people prefer but my initial goal with bindings like this is to match the game's behavior as closely as possible (you have to drag an item to empty space to destroy it with the blizzard UI.) It also adds a layer of safety (on top of the confirmation prompt) to prevent destroying the wrong item by accident.
* Added an optional setting to the UI module that allows you to interrupt speech when a window (such as the game menu) is closed. This defaults to off.
* You can now check WowVision's version with the /wv version command.

## V0.3.4

* All merchant costs are now correctly read (including required currencies such as Justice Points.)
* Locale data has been moved to its own folder and github project for easier editing and management. All messages should still be there but if you receive any localization related errors please let me know.
* Added support for the bank frame and bags.
* Added support for the reforging screen.
* Added support for the item upgrade screen.
* Fixed a bug where containers/bags could sometimes error when items are quickly moved or removed (for example when opening the Keg-Shaped Treasure Chest from the Brewfest event.) The addon was not correctly checking for empty slots.
* Fixed a bug where bags opened in a certain order could have the wrong bag button associated with them (would mostly happen when only a single bag was opened.)
* Fixed a bug where the range to target alert did not have any settings UI.
* Fixed a bug where newly added alerts would sometimes not have the correct enabled/disabled state.
* The target changed alerts now default to interrupting speech.
* Added the Auto Move to Interact Target option (which defaults to true.) Note that this can also be changed in the options menu of Wow's default UI, where it is slightly misleadingly labeled Click to Move.
* Fixed an issue where long numbers with a / between them would read out incorrectly. For example, "300000/300000" would read as "3 0 0 0 0 0 slash 3 0 0 0 0 0".

## V0.3.3
Note that World of Warcraft has changed how their tts code works. This prevents non-standard SAPI voices (such as NVDASapi) from working. If you were using NVDASapi with previous versions of the addon it will not work. Please use the following command to reset your speech voice so you can continue to use the addon.

/run WowVision.base.speech.settings.voiceID = 0 WowVision.base.speech.settings.screenReader = false

* Fixed dialog popups causing error due to a Blizzard API change.
* Fixed buffers not working correctly with SAPI voices.
* Error alerts now use a TTS alert.
* Added more speech interrupts to various hotkey triggered functions to improve the experience with sapi voices. This includes the WowVision menus (particularly when pressing escape) and the loot commands.
* You can now press either control key to interrupt speech.
* Removed the Screen Reader setting from the speech module as it is no longer supported or useful.

## V0.3.2

* Fixed a bug with certain repeating quests that don't give certain rewards a second time (would cause lua errors.)
* Added support for skill trainers.
* Updated the currency frame:
    * Removed the unnecessary x before the count (for example "Valor x1500" now just reads as "Valor 1500")
    * Headers are now correctly identified as headers and read out their expanded/collapsed state.
* The quest log now wraps correctly.
* Fix missing localization for Repair on the merchant screen (which was throwing a lua error.)
* Add zone and subzone readouts when you move to a new area (part of the compass module.)
* Speech alerts via tts/sapi are now labeled as "TTS Alert" instead of "Speech Alert" for clarity. Unfortunately this change will reset your alerts to their default setting.
* Output via recorded voice files (such as compass directions and range numbers) are now refered to as "Voice Alert". This reflects an internal code change that will allow for voice packs.
* The targeting module will now determine whether or not your target is in combat with you with greater accuracy (it will now trigger based on the threat of your raid/party members and their pets.)
* Voice packs are now implemented. For any voice alert, you can change the recorded voice used. Currently only Matthew (the default Sku voice) and Joanna are supported.
* When you use a hotkey to enable a soft target type, it will now always read the name of the first soft target it finds consistently. It would previously not always do this if you disabled and enabled a soft target, which could lead to confusing results.

## V0.3.1

* Add an optional sound that plays when you tab target to an enemy in combat with you.
* The Taxi/flight master map no longer is disabled in WowVision if BlindSlash is enabled. This was added due to out of date information so has been reverted.
* Chat messages are now an alert with an included optional sound on receiving a new chat message.

## V0.3.0
Note: Due to an unanticipated behavior of the Ace3 library (a dependency of this addon) some of your speech and targeting settings may reset when you install this update. Sorry for the inconvenience.

* Added support for old-style scroll frames; the character currency frame will now scroll correctly automatically.
* Fixed a bug introduced in V0.2.3 where targeting settings were being ignored (like announce hard target.)
* Added the /enableaddon and /disableaddon chat commands to enable or disable an addon with the given name. For example /enableaddon blindslash or /enableaddon sku. Known addons (like Sku) have associated addons, so enabling or disabling such addons will enable or disable all associated addons to prevent errors.
* The speech module now defaults to voice ID 0 (probably Microsoft David.) This should prevent issues with NVDASapi installations that some users experience.
* Many settings have been refactored to use the alerts system. I often needed to add settings with repeated behavior (such as I wanted soft targeting to both speak and output a sound.) This behavior is so common that it will now use a standardized UI for similar settings. Practically this just gives you more customizability for various settings.
* Refactored hart target announcements and health monitor to use the alerts system.
* Added support for soft targeting enemy, friend, and interact using the alerts system. This includes sound effects for soft targets. Also fixes a bug where your soft target settings wouldn't actually update sometimes upon an addon reload.
* Added support for the quest log.
* Added support for the tradeskill frame (crafting/professions.)
* Added support for the item socketing frame.
* UI Dropdowns (such as auction house filters) will now work again while Sku is active. This may act oddly with unit dropdowns but is better overall and will work.
* The flight map/taxi frame will now be disabled if both BlindSlash and WowVision are loaded simultaneously (to prevent a pretty bad game freeze/crash.) Navigation with BlindSlash will still work in that frame when this is the case.

### For Developers
* Dev tools (such as printRegions and tpairs) no longer clutter up the global namespace by default. They can be bought back into global scope with the /wv dev command or the WowVision:globalizeDevTools() function.

## V0.2.4
This is an emergency fix to prevent action bars being unusable if a specific action errors out.

## V0.2.3

* Fixed some behind the scenes problems with bags.
* Fixed a bug where certain windows would close when they otherwise shouldn't (mostly a behind the scenes change.)
* Removed map data from the folder (this should result in faster load times.) It wasn't doing anything and needs to be refactored anyway.
* Added object buffers (similar to the views from Sku.) Use alt and the arrow keys to view. Only a general buffer is there currently.
* Added basic support for the currencies tab in the character frame.
* Fixed an issue where rapid target switches would read out every target tooltip in sequence (for example with /target macros that switch between 3 or 4 targets instantly in a row.)
* Fixed the macros screen; you can now pick up macros to place them on action bars.
* Added hotkey labels to action bar buttons.
* Reading of errors can now be turned on and off (thanks to Blind Mikey for the code contribution.)
* Speech can now optionally be interrupted when you switch targets (thanks to Blind Mikey for the code contribution.)
* Target health can now optionally be read out via audio mp3 files instead of tts (thanks to Blind Mikey for the code contribution.)
* Speech will now properly interrupt on UI events (opening menus, etc) when screenreader mode is disabled.
* Fixed several bugs with the taxi frame (flight masters) when you didn't have all waypoints for a given region.
* Added support for the lfd role poll and dungeon ready dialog.
* Added party quit and leave instance group commands (/pquit and /dquit respectively.)

## V0.2.2

* Fixed: The role poll popup... Actually works now.
* Fixed: Loot roll bindings moved to more reasonable keybindings that are listed in the readme.

## V0.2.1

* Fixed: The flight map now works again.

## V0.2.0

* Fixed: Temporarily removed very broken glyphs list.
* Fixed: missing mists .toc file (meaning that the addon can now run with Mists of Pandaria Classic.)
* Added: Loot rolls 
* Fixed: Items 11 and 12 in the Merchant buyback frame were missing.
* Added: Target Health percentages can be automatically announced in intervals of 5%.
* Added: Early implementation of the quest window (certain quest reward types may not be read; this will be fixed if it is the case.)
* Added: Taxi frame (the flight master screen to choose where to fly.)
* Added: Raid target markers can now be read when tab targeting.
* Added: Early support for the mailbox (should read all inbox UI elements.)
* Added: Support for the role poll popup.
* Added: Alternative drag hotkey (ctrl-d).
* Fixed: Prevent Eronious range readouts on friendly targets while in combat (impossible anyway due to Blizzard API restrictions.)

## V0.1.4

* Fixed an issue where buttons could not be right clicked. To right click buttons, press backspace on them.
* Fixed all dropdown menus accidentally being labeled as "test dropdown".
* Implemented Basic support for chat (to access, use shift-f3 or select chat from the /au menu.) Note that it does not yet support the combat log and does not work in combat.
* Now actually fixed input issues with input boxes in settings screens.
* Fixed an issue where buttons would sometimes not accurately show their selected/checked state.
* Fixed an issue where some Scroll Box elements (for example the categories list in the auction house) would have incorrectly ordered buttons or sometimes buttons that don't technically exist yet.
* Fixed an issue where some element properties would not be cleared when they were supposed to be. This should fix some very rare labeling and tooltip issues.
* Fixed an issue where the addon would stop allowing UI input if a supported window was open when combat started.
* Fixed an issue where you could click on/interact with disabled controls such as checkboxes and edit fields.
* Implemented support for most of the options screen.
* Game UI controls (such as checkboxes in the options panel) should now read their state when it changes (for example, checked/unchecked)


## v0.1.3

* Fixed incorrect .toc file data (the addon will no longer be displayed as SpeakAuras in the addon list... Oops.)
* Fixed terrible implementation of edit boxes causing issues with changing setting values under certain conditions.
* Temporarily removed speech delay setting as it can make your game unuseable if set to too-high a value by accident with no way to correct it. More fine-tuning on this setting is needed for it to be useful.