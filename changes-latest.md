### Summary
This update officially introduces support for BCC Anniversary. It also fixes a number of compatibility issues between different versions of the game, as well as making a large number of behind the scenes changes to support Blizzard's addon changes to Midnight (secret values, etc.) Note that midnight is not well supported, though a lot of the addon's functionality does work with it. Refactors to support secret values were necessary now in case any of these changes are introduced into classic versions of the game (this is unlikely but important to account for.)

### All Versions
* Added support for the item text frame (letters, books, etc.)
* Fixed a bug where adding an input to a binding with no inputs set would add the input twice.
* Fixed an issue where additional non-functioning elements would be listed for the options/game menu for versions of the game using newer Blizzard code (currently Retail and BCC Anniversary.)
* Reverted the change to UI tooltip processing made in a previous version (0.5.2.) This should fix tooltips not being fully loaded before they are read out.
* Compass direction announcements will now work properly in instances that allow for it (for example Mists of Pandaria scenarios.)
* Hopefully fixed eronious indoors alerts in certain rare situations.
* Hopefully fixed an incredibly rare gossip frame bug where no dialog options would be available. If you encounter this please report it.

### The Burning Crusade Anniversary
This patch adds support for BCC Anniversary. Note that many of these screens were implemented fairly quickly as I did not have ptr access before launch. I have extensively tested BCC anniversary, but please let me know if anything is broken.

* Fixed a bug where the pet bar for BCC would throw constant lua errors if you had a pet summoned.
* Added support for the quest log frame
* Added support for the character frame.
* Added support for the talents frame.
* Added support for the Spellbook.
* Added support for the trade skill (crafting) frame.
* Known Issue: Certain scroll frames announce the current item twice when arrowing through them (primarily the skills tab of the character pane.) This doesn't effect their functionality but is a little annoying. This is an issue that will be fixed in a future UI refactor update.

### Mists of Pandaria Classic
* Added support for quest choices (for example the assignment map on The Isle of Thunder.)
* Added support for the professions tab of the spellbook.

### Retail
Note that these changes apply specifically to retail; any removed functionality in the retail version of the addon still exists in the classic versions. Also note that Retail is not well supported now and most likely will not be in the immediate future, but WowVision does work with it.

* Updated to use the latest interface version. WowVision will once again be detected by the game.
* Speech works in retail once again; there are now separate speech modules for classic and retail versions of the game (required due to API changes.) Speech should feel significantly smoother due to the speech API updates.
* Unfortunately I had to remove the hard target health monitor due to the addon changes in Midnight. This functionality is available in the combat audio assist section of settings however.