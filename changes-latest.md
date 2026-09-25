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
* Added two Merchant settings (Windows > Merchant): "Automatically Sell Poor Items" and "Automatically Repair If Possible", both on by default. Opening a vendor now sells your grey items and repairs your gear on its own, with a chat message confirming what was sold or repaired. Repair is skipped if the vendor doesn't offer it or you can't afford it.

### Modern
* Added support for the bags window.
* Fixed an entirely unnecessary 1.5 second delay when clicking on gossip options before the text refreshed. This was caused by retail changing which events fire for gossip dialogue.

#### Forever
* Updated the addon architecture and toc files to support the WoW Forever beta.
* fixed a number of issues with the options window introduced in WoW Forever.
* Added support for the character pane, including the equipment manager.
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