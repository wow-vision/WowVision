### All Versions
* Added support for the item text frame (letters, books, etc.)
* Fixed a bug where adding an input to a binding with no inputs set would add the input twice.
* Fixed an issue where additional non-functioning elements would be listed for the options/game menu for versions of the game using newer Blizzard code (currently Retail and BCC Anniversary.)
* Reverted the change to UI tooltip processing made in the previous version. This should fix tooltips not being fully loaded before they are read out.

### The Burning Crusade Anniversary
* Added support for the quest log frame
* Added support for the character frame.
* Added support for the talents frame.
* Added support for the Spellbook.
* Added support for the trade skill (crafting) frame.

### Mists of Pandaria Classic
* Added support for quest choices (for example the assignment map on The Isle of Thunder.)
* Added support for the professions tab of the spellbook.

### Retail
Note that these changes apply specifically to retail; any removed functionality in the retail version of the addon still exists in the classic versions.

* Updated to use the latest interface version. WowVision will once again be detected by the game.
* Speech should work in retail once again.
* Unfortunately I had to remove the hard target health monitor due to the addon changes in Midnight. This functionality should be available in the combat audio assist section of settings however.
* Speech should feel significantly smoother due to the speech API updates.