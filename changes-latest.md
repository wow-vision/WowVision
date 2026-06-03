### Summary
This patch fixes a number of issues with Mists of Pandaria Classic. The addon now works again (there were many, many breaking changes to the Blizzard APIs.) There were also a number of additions to TBC Classic thanks to @@JeanStiletto, including full support for the auction house, group finder, and item socketing frame.

### All Versions
* Fixed a rare issue where certain controls in dropdowns would not appear.

### Classic
* Implemented support for the send mail tab of the mailbox (thanks @JeanStiletto).

### The Burning Crusade Anniversary
* Added support for the item socketing frame (thanks @JeanStiletto).
* Added support for the looking for group pane (thanks @JeanStiletto).
* Added support for the auction house thanks to @JeanStiletto.

### Mists of Pandaria Classic
* Updated the minimum toc version numbers; the addon works with Mists once again.
* Added support for the reputation tab of the character frame.
* Fixed an issue where tts readouts were either entirely silent or caused lua errors due to a Blizzard API change. Note that speech will feel significantly different now and it a bit laggier; unfortunately there is nothing I can do about this.
* Fixed an issue where tts volumes above 100% would cause speech to be silent (really Blizzard?)
* Fixed various issues preventing range callouts from working in the latest patch. Note that certain ranges seem to be missing, noteably 2, 3, and 15 yards callouts. There isn't anything I can do about this as the problem is caused by a blizzard API change. I will be investigating this further though so hopefully this can be fixed in future.

### Retail
* Updated the minimum version numbers so the game will allow the addon to be loaded once again.
* Updated the speech module to use the one used by Mists of Pandaria classic to fix a speech queueing issue.