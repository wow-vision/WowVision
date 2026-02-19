### All Versions
* Fixed the issue where certain npcs would not list their dialogue options or quests. This was caused by certain npcs using a different window (the quest frame) to list their greeting text and quests.
* Refactored the UI code to better handle required delays in the WoW Speech APIs. Essentially this speeds up speech responsiveness for all versions of the game when navigating through UI elements.
* You can now use shift and the arrow keys (by default) to read tooltips line by line.
* Fixed a bug where dropdown buttons for addon settings would not list their currently selected value after the button type.
* Fixed a bug where navigating through certain types of scroll frame would repeat the newly reached element twice.
* Finally fixed the bug where your position in certain lists wouldn't save when certain windows opened. For example, after entering an input mapping in the bindings menu, the cursor would jump to the top of the input bindings list. Now it will remain on the binding bar you were last at.
* The buffers system can now be configured to add any number of buffers and buffer groups. For example, you can now add a buffer to list auras on the player.
* Fixed a bug where the view cursor on ViewList objects (for example buffers) would not reset to the beginning if all items in them were deleted.
* Fixed a performance issue for spoken announcements that use templates (primarily announcement of buffer items.) Templates are now precompiled. This wasn't too noticeable unless you were rapidly arrowing through buffers.
* Removed a few unused files (the old speech module.)
* Greatly improved UI performance on most screens.

### Classic Versions
* Added a Speech Style dropdown to the speech module. This allows you to configure how speech output is queued, potentially leading to more consistent interrupts. The direct style is the style WowVision used before; buffered is similar to Sku's method (using a speech queue with an artificial delay.)

### Burning Crusade Anniversary
* Fixed a bug where the quest log frame would not scroll correctly and report incorrect information for various buttons.
* Fixed a bug in the character frame where the skill and reputation detail could be wrongly positioned (before their list instead of after.)
* Fixed a bug in the equipment list where the ammo slot would always be labeled "Ammo" whether or not an item was in the ammo slot.