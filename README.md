# WowVision
WowVision aims to provide blind accessibility to the World of Warcraft UI for all versions of the game. It is in a very early alpha state. Expect there to be bugs and inconsistent behavior.
The addon also aims to provide a consistent framework for developers to quickly and relatively easily provide accessibility for the Wow UI. It is also highly modular so modules can be swapped out easily.

## Notes
* To left click an element, press enter. To right click, press backspace. Modifier keys in conjunction with enter and backspace should work as expected.
* You cannot play Wow with this addon alone as of yet. Sku or BlindSlash are still required if you do not have any useable vision and aren't playing with other sighted players.

## Usage
To get started using the addon, type the /wv command into chat (slash w v no spaces.) Make sure to set the speech settings to your liking.
You use traditional windows UI commands to navigate the UI. Use tab and shift tab to navigate through windows. When on lists or grids, use the arrow keys to navigate. Use enter to interact with elements such as buttons or checkboxes. Press escape to close windows. You can also ctrl tab and ctrl shift tab if you have multiple windows open simultaneously (particularly useful for reforging, trade, etc.)

### Controls

Navigate through lists: Arrow Keys
Navigate through panels: Tab, Shift-Tab
Navigate between open windows: ctrl-tab, ctrl-shift-tab
Jump to Beginning or End: Home or End
Left Click: Enter
Right Click: Backspace
Drag: \ or ctrl-d
Buffers: alt-arrow keys
Read tooltip if available: space
Read Chat: shift-f3
Action Bars: Shift-f4
Loot roll info: ctrl-alt-y
Roll Need: ctrl-alt-u
Roll Greed: ctrl-alt-i
Roll pass: ctrl-alt-o
Bonus Roll (if possible): ctrl-alt-p
Destroy Cursor Item: delete or ctrl-alt-backslash

### Notes
* When you open the auction house, Sku will still open its menu (I couldn't find a way to easily disable this.) Simply press escape to close the Sku menu and then the WowVision UI will take full priority and work as it should.
* Ensure you are careful about what you are buying in the auction house and always check the total price. The UI can shift and there are many auction house users that will sell items for very high gold prices to try to trick you into clicking on them by accident. This is most likely to happen when entering a quantity of a commodity to purchase; there will often be a few at a cheap price and then many at a significantly higher one that will get auto included. The total price text element is a good way to easily check. Clicking buy does also ask you to confirm so you can avoid this easily if careful.
* Press space on an element to hear the tooltip, if any. This feature will change and space will not be the final hotkey, but it is what I had to use for now to not interfere with Sku's tooltip mechanism. It will also be read out in its entirety; you can't currently browse it by line. This will all be fixed in a later version.
* When you focus an edit box (tab to it), you automatically are switched to input mode to type in that edit field. Pressing tab will take you out of it as you would expect; hitting escape also does this while leaving your focus on the edit field. This is a bit awkward but it is default game behavior I wouldn't want to immediately change as it may have unintended side effects on the UI. Hitting enter triggers the default functionality of the textbox (for example triggering an auction house search.)
* In dropdown menus, text boxes do not automatically switch you to input mode. You must hit enter, type what you want, then hit enter or escape when done. Dropdown menus also use the up and down arrows to navigate, similar to a Windows context menu.
* In lists, you must hit enter on the element to select it. It isn't like a traditional windows list where simply moving over the element is enough to highlight/check it/etc.
* Some lists are vertical (up and down arrows to navigate) and some are horizontal (left and right arrows to navigate.) Typically tab selectors (such as the auction house buy, sell, and auctions tabs) are horizontal and most other things are vertical.
* The UI may be confusing to navigate. I tried to model the Accessible UI after the game UI as well as I could. I plan on adding an optional more Sku-like style of input if people prefer it. I believe the current method could be significantly faster to navigate though, which is why I implemented it this way first.
* That being said, I had to make some concessions. I added some additional labeling in the auction house for clarity and to prevent some confusion when choosing auctions to cancel, etc. None of the UI flow was simplified and it should be nearly identical to how a sighted player would interact with the UI.

### Known Issues
* NVDASapi is not working in all versions of the game. This is an issue on blizzard's end and will hopefully be fixed. A number of other tts voices stopped working as of the 11.2 patch.
* Not all of the auction house lists tell you whether or not a button is selected, particularly the categories list. You can determine this with deduction but this list is a bit buggy still.
* Certain text does not read as expected, for example the vendor price in the tooltip. This is a complicated issue to solve as it requires additional text parsing on a case-by-case basis. I also believe Sku may be interfering with how speech output is currently working. This will be resolved in a future version. All of the important values can be read well though, especially when paired with Sku's tooltip parsing.