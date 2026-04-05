### Summary
This version introduces the monitors and buffers systems. Monitors work similar to Sku monitors (or like a simplified WeakAuras if you're familiar with that.) They allow you to set up alerts for your buff/debuff states and cooldown states for your abilities. Health monitors will be added later when we have better voice pack architecture set up. Buffers are supported for all versions, but monitors are only supported for classic versions of the game due to Blizzard's retail addon restrictions.
This version also fixes numerous bugs and adds a large number of quality of life improvements, including better alert sound configuration and line by line tooltip reading with shift and the arrow keys.

### All Versions
* Fixed the issue where certain npcs would not list their dialogue options or quests. This was caused by certain npcs using a different window (the quest frame) to list their greeting text and quests.
* Refactored the UI code to better handle required delays in the WoW Speech APIs. Essentially this speeds up speech responsiveness for all versions of the game when navigating through UI elements.
* You can now choose to have a sound played for various alerts (such as chat, outdoor/indoor, swimming, etc). For alerts that had preexisting sounds, you can now configure which sound plays.
* For certain tts alerts, you can now configure the message spoken.
* Added LibSharedMedia as an audio source. LibSharedMedia is a library used by many addons (such as WeakAuras) to share sounds, fonts, and other resources between addons. You can now use all of the Weakauras sounds for alerts and monitors for example.
* Updated the sounds in the default WowVision audio pack to remove long silence before many of the files. This also adds a directory of tones.
* You can now use shift and the arrow keys (by default) to read tooltips line by line.
* Fixed a bug where dropdown buttons for addon settings would not list their currently selected value after the button type.
* Fixed a bug where navigating through certain types of scroll frame would repeat the newly reached element twice.
* Finally fixed the bug where your position in certain lists wouldn't save when certain windows opened. For example, after entering an input mapping in the bindings menu, the cursor would jump to the top of the input bindings list. Now it will remain on the binding bar you were last at.
* The buffers system can now be configured to add any number of buffers and buffer groups. For example, you can now add a buffer to list auras on the player.
* Fixed a bug where the view cursor on ViewList objects (for example buffers) would not reset to the beginning if all items in them were deleted.
* Fixed a performance issue for spoken announcements that use templates (primarily announcement of buffer items.) Templates are now precompiled. This wasn't too noticeable unless you were rapidly arrowing through buffers.
* Removed a few unused files (the old speech module.)
* Greatly improved UI performance on most screens.
* Improved labeling for various lists for clarity. Horizontal lists (such as tabs) will be labeled as a "Bar" to denote their navigation direction.
* Fixed a bug in the trade frame where your trades were always labeled as "Empty" even when not empty.
* Fixed a rare Mailbox issue that caused lua errors when opening all mail and you already had a letter open.
* Fixed a bug where buyback items on the merchant frame would have the wrong price label; they were being labeled with the prices of what the button would correspond to on the merchant tab, not the buyback tab. This may also fix some rare mislabeling of stack/stock amounts.
* The controls on various settings screens are now in a much more reasonable order.
* Fixed a very rare error that could occur in the chat module if chat tabs loaded in a very specific way.

### Classic Versions
* Added a Speech Style dropdown to the speech module. This allows you to configure how speech output is queued, potentially leading to more consistent interrupts. The direct style is the style WowVision used before; buffered is similar to Sku's method (using a speech queue with an artificial delay.)
* Added monitors, which act similarly to Sku monitors. Currently Aura (buff/debuff) and Cooldown monitors are supported, but more are coming soon.

### Burning Crusade Anniversary
* Fixed a bug where the quest log frame would not scroll correctly and report incorrect information for various buttons.
* Fixed a bug in the character frame where the skill and reputation detail could be wrongly positioned (before their list instead of after.)
* Fixed a bug in the equipment list where the ammo slot would always be labeled "Ammo" whether or not an item was in the ammo slot.

### Mists of Pandaria Classic
* Fixed an issue in the quest log where the panel containing the info and buttons for the currently selected quest would not update when you clicked on a quest. Blizzard why do you like arbitrarily changing when events fire so much?