### Summary
This is a massive refactor of the codebase thanks to Claude Fable 5. The UI has been entirely redone to increase ease of development and efficiency. Many long-standing UI focus issues have been fixed and overall the game should feel much smoother now.

### All Versions
* Much of the addon has been rewritten. The UI framework has been entirely redone, greatly improving efficiency and preventing significant lag spikes on some screens. This should also allow much faster development, as the older framework was overengineered and introducing unnecessary complexity. LLM models, such as Claude code, also have a much easier time with it, allowing us to iterate significantly faster.
* Fixed some rare instances of options screen controls having incorrect or missing tooltips.
* Finally fixed the gossip window acting unpredictably when available dialogue options changed. Additionally the new text is automatically read out.
* Dropdown menus are now fully supported, including submenus.
* The addon now tracks per character and global settings separately. By default most things are global; this can be changed per module via its context menu in the WowVision settings.
* Fixed a bug where you could not tab out of certain edit fields.
* Added support for wall/collision detection. If the addon detects you are moving slower than you should be, it will play sounds indicating a collision (this  replicates Sku's behavior.)
* Added support for fall detection. It can be configured to speak when you  begin to fall. It will also play an ascending series of tones as you fall (this works identically to how Sku's did and uses the same sounds.)
* Added propper support for Feaux Hybrid Scroll frames (aka my arch enemy.) Frames that would cause errors when scrolled will no longer do so. Unfortunately however I cannot implement the home and end keys to jump to the first or last item within these. These frames include the who list and the glyph frames for various versions of the game.
* Fixed a bug where home and end would sometimes act unexpectedly, particularly within nested containers.
* Added support for the rest of the options screen.
* Errors: a per-error filter (Errors module, Per-Error Filter). Every game error or info message you have seen gets its own entry with its own speech and sound settings, so you can mute "Ability is not ready yet" and keep "Out of range". Messages that differ only by a name or number share one entry. "Show All Known Errors" lists every error the client knows, before you meet it. A Repeat Delay setting (default 2 seconds) stops the same error from being spoken again while you hold a key. Works on every supported version; on Retail it also speaks the errors Blizzard hides from the error frame, like out of range and out of rage or energy.
* Fixed a bug where certain popups in the options screen would softlock the game.
* Added the scanner. The scanner acts as traditionally seen in other mods, providing a categorized list of various things in the world. These include quest givers, nearby quests, and the location of your corpse for now. Press f9 to use it. Important: The scanner can only give you straight line paths currently pathfinding solutions are being worked on.
* Added the /wv speech command to quickly adjust your speech settings. The syntax is /wv speech voiceID rate volume, for example /wv speech 1 8 100. Note: your first voice has ID 0.
* The first time a character logs in with WowVision, the game's Lock Action Bars setting is turned off, so dragging spells and items off your action bars works without holding the pick up key. This happens once per character; if you lock the bars again in the game options, they stay locked.
* Buffers: Alt+Down now moves toward the newest item in a buffer and Alt+Up toward the first. A new Invert Item Direction setting in the Buffers menu swaps the two keys back for anyone used to the old way.
* Added two Speech toggles for the game's own text-to-speech sounds (/tts playline and /tts playactivity). The sound between chat lines is turned off once per character.
* Shift-F12 cancels the active route or beacon.
* The XP line in the general buffer names the level it fills towards.
* Windows that open on a search box, like the game options, take typing right away.
* Fixed key bindings losing Alt when Alt was let go before the key.
* Books and letters no longer read a page number line or stop silently when there is no author.
* Targeting: new soft targeting settings (Soft Targeting With a Hard Target, Make Soft Target the Hard Target, and an arc and range per soft target). They all default to Game Default, so nothing changes unless you set them. Shift+I, Shift+P and Shift+O changed in combat now apply when combat ends. /wv soft reads every value.
* The TBC map data now ships inside the WowVision download as its own addon folder (WowVision_MapData_TBC), so there is nothing separate to install. It also loads on WoW Forever, where the old world routes apply. Other map data addons keep working beside it.
* Added two Merchant settings (Windows > Merchant): "Automatically Sell Poor Items" and "Automatically Repair If Possible", both off by default. When turned on, opening a vendor sells your grey items and repairs your gear on its own, with a chat message confirming what was sold or repaired. Repair is skipped if the vendor doesn't offer it or you can't afford it.
* Fixed the compass's indoors/outdoors, flying, swimming, and diving announcements never firing inside dungeons and other instances, where the game does not report your facing.
* Added Sku's Beacon 6 as a beacon sound.

### Modern
* Added support for the bags window.
* Added the cooldown manager settings window (/cdm): the Spells, Auras and Group Buffs tabs, search, the gear menu, each category with its items, the layout dropdown and Revert Changes. Enter on an item picks it up and Enter on another item or on a category's empty slot drops it there; Backspace opens the item's menu for alerts and moves. The alert editor is its own window. Changes made with the keyboard take effect after the interface reloads, because the game rebuilds its on-screen cooldown data from them; the window says so and offers a Reload Interface button. Menu rows with attached buttons (play sample, edit, delete) now read as rows: right arrow reaches the buttons.
* Fixed an entirely unnecessary 1.5 second delay when clicking on gossip options before the text refreshed. This was caused by retail changing which events fire for gossip dialogue.
* Fixed the gossip window staying open after the conversation moved on to a trainer, vendor or quest, or the game closed it.
* Fixed health and power in buffers going silent when read a second time.
* Fixed the Speech Queue setting being ignored.

#### Forever
* Updated the addon architecture and toc files to support the WoW Forever beta.
* fixed a number of issues with the options window introduced in WoW Forever.
* Added support for the character pane, including the equipment manager.
* Bags in individual mode: each bag's menu (filters, cleanup, mode switch) sits in the context menu of the bag's first entry, its slot button, whose clicks now read as "Close Bag" or "Place Item". Bag Controls follows only the backpack, which holds search, sort, money and Add Slots. The keyring on WoW: Forever reads as a bag with its own slot button.
* The four locked backpack slots an account without an authenticator is shown are no longer read as empty slots; the Add Slots button stays in the bag controls.
* Added support for the bank: pages and bank types as tabs, one tab stop per bank tab, the bank bag slots, search, sort, money and the purchase of the next bag.
* Added support for the talent window: the primary and secondary specialization tabs with the activate button, the unspent points, the talent search and its options, then each specialization as its own tab stop with the points spent in it. Talents read row by row as drawn, with their rank and whether they are available or locked; a locked talent names the points and the talents it waits for ("or" where any one of them will do). Enter learns a rank, and on a choice talent opens its options; Backspace unlearns; the context menu links a talent in chat and buys back what a reset removed. Apply says when changes are waiting or why it cannot apply them, followed by Undo and the Reset menu.
* Known issue: I tried to support nearby quests and quest givers, but the functions to retrieve this data appear to be bugged in the Forever client.
* Known Issue: WowVision settings are not persisting across reloads or game restarts. This appears to be a bug with the Forever client. I recommend setting up a macro to use the new /wv speech command to quickly set your speech settings upon login or /reload.
* Known Issue: Range readouts are sparse and probably broken. I haven't been able to test this properly yet.

### Classic
* Fixed a bug where edit fields for spell IDs (for example in monitors) would behave extremely inconsistently and often not actually set the spell ID correctly.
* Added initial support for the social tab, including friends, ignore, and the who list.

#### The Burning Crusade Classic
* Updated the TBC speech module to use the retail speech module. Speech output for TBC works again.
* Implemented Sku's pathfinding data into TBC Anniversary. You can pathfind using f10. Note: pathfinding to scanner entries is not yet supported.

#### Mists of Pandaria Classic
* Fixed a number of issues with the mounts tab of the collections pane.
* Add support for the Core Abilities and What Has Changed tabs of the spellbook.