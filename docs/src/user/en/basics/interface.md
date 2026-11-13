# Using the Interface

When a game window opens, such as your bags, a merchant or the character pane, WowVision reads it and lets you move through it with the keyboard, much like a desktop application. This page explains the keys that work in every window, what you hear on each kind of control, and how menus, lists, text fields and the context menu behave.

The same navigation keys also drive WowVision's own screens: the [WowVision menu and settings](./menu-and-settings.md), the [keybinding screen](./keybindings.md), context menus and the game's dropdown menus.

## When WowVision takes your keys

WowVision only takes the navigation keys while a window is open. With no window open, the arrow keys, Tab, Enter and the rest do what the game normally does with them (walking, turning, jumping, and so on).

- Game windows are detected automatically. When one opens, WowVision stops any speech and reads where you have landed.
- When more than one window is open, Ctrl+Tab and Ctrl+Shift+Tab switch between them (see [Several windows at once](#several-windows-at-once)).
- Escape on a game window is left to the game, which closes its own windows with its own sounds. On WowVision's own screens, Escape is WowVision's: it goes back one level, or closes the screen when you are on the first level. These are the WowVision menu and everything inside it, context menus, game dropdown menus, and windows that exist only in WowVision, such as the chat window (Shift+F3), the navigation window (F10), the scanner (F9) and the action bars window (Shift+F4).
- /wv close force-closes every WowVision window. It is the way out if a window ever gets stuck.

If a window opens while you are holding a movement key, for example a shared quest or a ready check popping up as you run, WowVision waits until you let go of the keys it needs before it takes them. This stops your character from running or turning on its own.

## The keys

All of these can be changed in the [keybinding screen](./keybindings.md). Most are "vital": they can be moved to another key, but never removed completely.

| Key | Binding name | What it does |
|---|---|---|
| Up / Down | Up, Down | Move to the previous or next control. |
| Left / Right | Left, Right | Move sideways along a row; on a group, collapse or expand it; on a number, make it smaller or larger. |
| Tab / Shift+Tab | Next, Previous | Jump to the next or previous tab stop (a whole section of a window, such as a list or a row of buttons). |
| Home / End | Jump to Beginning, Jump to End | Jump to the first or last control of the list or row you are in. |
| Enter | Left Click | Press the control (a real left click on game buttons). |
| Backspace | Right Click | Right click the control. |
| Space | Read Tooltip | Read the full tooltip of the control. See [Tooltips](./tooltips.md). |
| Shift+Up, Shift+Down, Shift+Left, Shift+Right | Tooltip lines | Move through the tooltip line by line, or read its left or right column. |
| Shift+F10 | Context Menu | Open the actions menu for the focused control. |
| Ctrl+Tab / Ctrl+Shift+Tab | Next Window, Previous Window | Switch between open windows. |
| Escape | Close | Close the window (the game closes game windows itself). |
| Page Up / Page Down | Scroll Up, Scroll Down | Scroll a long list by a page on the lists that need it, or turn the page of a paged list or text (see [Long lists](#long-lists-and-scrolling)). |
| \\ or Ctrl+D | Drag | Pick up whatever is in the focused slot onto the cursor. |
| Delete or Alt+Ctrl+\\ | Destroy Cursor Item | Get rid of the item or assignment on the cursor. |
| Shift+F1 | WowVision Menu | Open the WowVision menu (same as typing /wv). |
| Ctrl | (not a binding) | Press Ctrl on its own at any time to stop the current speech. |

Enter and Backspace carry your modifier keys along: Shift+Enter is a shift-left-click, Ctrl+Backspace a ctrl-right-click, and so on. This matters in WoW, where modifier clicks often do something different, for example shift-clicking an item to link it in chat.

Every navigation key stops whatever is being spoken before it announces the new control, so you can arrow quickly through a list without a backlog building up.

## What you hear

When you land on a control, WowVision reads it in this order: its name, what kind of control it is, its current value or state, whether it is selected or disabled, and finally its position in the list.

| What you hear | Meaning |
|---|---|
| Button | Press it with Enter. |
| Checkbox, then Checked or Unchecked | Enter flips it. |
| Radio, then Checked or Unchecked | One choice out of several, used mainly in menus. |
| Dropdown, then the current choice | Enter opens the list of choices. |
| Number, then the value | A number or slider. Left and Right change it; Enter lets you type a value. |
| Edit, then the text in it | A text box. |
| selected | The current tab or choice. |
| Disabled | The control cannot be used right now. |
| 3 of 12 | Position among its siblings. Only spoken when there is more than one. |
| Expanded or Collapsed | A group header that can be opened with Right and closed with Left. |

Windows are made of nested containers, and WowVision tells you when you enter a new one, naming it from the outside in: List for a vertical list, Bar for a single row of controls (such as a row of tabs), Panel for a section with several tab stops. When you keep moving inside the same container only the control is read. When you leave a container and enter another, the new container's name is read first.

Examples:

- Moving into a list named Categories: "Categories, List, Combat, 1 of 3".
- Moving down inside it: "Display, 2 of 3".
- A setting: "Interrupt Speech on Window Close, Checkbox, Unchecked, 1 of 2".
- A choice: "Speech Voice, Dropdown, Microsoft Zira Desktop".
- A number: "Speech Rate, Number, 3".
- A bar of tabs: "Tabs, Bar, General, Button, selected, 1 of 4".

### Changes are spoken while you stay put

While a control has focus, WowVision watches it. If its text, its checked state or its enabled state changes by itself, for example a Post button becoming usable once you filled in a form, or a quest text refreshing, the new value is spoken without you pressing anything.

## Moving around

### Arrow keys and rows

Up and Down move through the controls in the order they appear. Where controls sit side by side in a row, Left and Right move along the row. Moving up or down from a row lands on the first control of the next row, except in grids and tables that are laid out in columns, where you stay in the same column.

If you press Up on the first entry of a list or Down on the last one, you hear a short sound and the entry is read again, as in Sku. The Sound at the Start and End of Lists setting (UI menu, on by default) turns this off; the arrow key then does nothing and nothing is said. Left and Right at the edge stay silent, and so do the chat messages. Windows do not wrap around with arrow keys.

### Skipping empty slots

With the Skip Empty Slots on Double Arrow setting switched on (UI menu, off by default), in your bags, the bank and the action bars you can press the same arrow key twice quickly (within a quarter of a second) to skip the empty slots: you land on the next slot that holds something. Keep tapping quickly to hop from item to item. If nothing follows in that direction, you land on the last slot, which reads "Empty". Two different arrow keys in a row never count as a double press.

### Tab stops

Large windows are divided into tab stops, usually a list, a row of buttons, a search box and so on. Tab and Shift+Tab jump between them, wrapping around from the last to the first. Each stop remembers where you were, so Tab takes you back to the entry you left, or to the selected entry when you come into a stop for the first time. A window with a single stop, such as a simple menu, ignores Tab.

### Home and End

- In a group that expands and collapses, they jump to the first and last entry on the same level.
- In a row of controls (an action bar, a row of tabs), they jump to the first and last control of that row.
- Anywhere else they jump to the top or bottom of the list you are in.

### Groups that open and close

Some windows show expandable groups, for example category headers. They read as "Section, Collapsed".

- Right on a collapsed group opens it and says "Expanded". If it turns out to have nothing in it, WowVision closes it again and reads it as it was.
- Right on an open group moves into its first entry.
- Left on an open group closes it and says "Collapsed".
- Left on an entry inside a group moves back up to the group's header.

## Pressing and using controls

### Buttons

Enter presses a button. For buttons that belong to the game, WowVision performs a real click, so everything behaves exactly as for a mouse user. Backspace performs a right click. A button that cannot be used right now says "Disabled" after its name.

On WowVision's own screens (the menu, the keybinding screen), only Enter does anything; Backspace is not used.

### Checkboxes

Enter flips the checkbox and immediately says "Checked" or "Unchecked".

### Dropdowns

There are two kinds, and they feel almost the same.

WowVision's own choice lists (such as the Speech Voice setting). Enter opens a short list of the choices. You land on the current one, which reads, for example, "Microsoft Zira Desktop, Button, Selected". Move with Up and Down and press Enter on a choice to pick it. WowVision returns to the setting and the new value is read. Escape closes the list without changing anything.

The game's dropdown menus (filters, the player menu you get on a character, the gear menus in some windows). When the game opens one, WowVision shows it as a list and puts you on its first entry.

- Entries read as buttons, or, for entries that can be ticked, as checkboxes and radio buttons with "Checked" or "Unchecked".
- The menu itself is announced as "Dropdown, List" when you enter it.
- Section titles inside a menu (a character's name, "Interact") are not stops. They are read once, as part of the first entry you land on in their section.
- An entry that opens a submenu reads as "Dropdown". Enter opens it and puts you on its first entry. Escape closes the deepest submenu and returns you to the entry above; another Escape closes the whole menu.
- A menu entry with extra buttons attached (a play, edit or delete button next to an item) is a row: press Right to reach the buttons and Left to come back.
- Long menus scroll. WowVision reads every entry, also the ones out of sight, and scrolls the menu for you as you move down.
- A menu entry can hold several controls side by side, such as a minimum and a maximum box for a level range, or a checkbox and a button. Such an entry is a row: Right moves along its controls from left to right and Left moves back. Where an entry has a title, you hear the title with the first control.
- A slider in a menu gets a line of its own below its entry, read as Number. Left and Right move it by one step and Enter lets you type a value, as described under [Numbers and sliders](#numbers-and-sliders).
- In a text box inside a menu (for example the level range boxes), Enter puts the cursor in the box and, after you typed, Enter again leaves the box and takes you back to the menu entry. Escape does the same.
- The tooltip key (Space) reads the tooltip of the entry you are on, where the game gives it one. See [Tooltips](./tooltips.md).
- Dropdown menus take letters too, see [Letter navigation](#letter-navigation-in-menus).

Example: in the auction house filter menu, Down to the Level Range row. You hear its title and the Minimum box. Press Enter and type "20", press Enter to leave the box, then Right to move on to the Maximum box.

Example: right clicking a player portrait opens the player menu. Down to Invite, Enter. For an entry that opens a submenu, press Enter to open it, Down to the entry you want, Enter again.

### Numbers and sliders

Sliders in the game options and numeric settings in WowVision read as Number.

- Left makes the value smaller and Right larger, by one step (one unit for WowVision settings, one slider step in game options). The new value is spoken after every press.
- Enter opens a small typing box to enter the value directly (see [Typing text](#typing-text)). Type the number and press Enter. A value outside the allowed range is moved to the nearest allowed value. If what you typed is not a number, nothing changes.

Example: on Speech Rate, Number, 0, press Right three times to hear "1", "2", "3".

### Typing text

There are two kinds of text boxes.

WowVision's own text settings (for example a custom message for an alert). Enter opens a typing box. WowVision says the name and reads what is in it, with the text already selected, so whatever you type replaces it. Each key you type reads the text so far. Enter accepts, Escape cancels, and Tab accepts and moves on to the next control. When you arrive on such a field by Tab (not by arrow keys), or when a screen opens with the cursor on it, the typing box opens at once.

The game's text boxes (search boxes, form fields). They read as "Edit" followed by what is in them. Enter puts the cursor in the box. When you arrive by Tab, or when a window opens with its cursor on a search box (the game options do), you can start typing immediately. Tab or Shift+Tab leaves the box and moves to the next or previous control. The box otherwise behaves exactly as in the game, including its own handling of Escape.

The search boxes of the spellbook, the talent window and the Legacy window (WoW: Forever only) offer suggestions as you type. Up and Down read the highlighted suggestion and its position, and Enter picks it, or runs your typed search if none is highlighted.

### Copy boxes

A few actions hand you text to copy, for example Copy Character Name in the player menu of a chat message, or copying a chat message. WowVision says "Copy now" and puts the text, already selected, into a small edit box. Press Ctrl+C to copy it, then Escape to close the box. The text is not read out again, because you just heard it.

### Long lists and scrolling

You never have to scroll yourself. When you arrow onto an entry that is off screen, the window scrolls to show it, so the game's own tooltip and highlight work too.

Page Up and Page Down scroll a list by a full page and put you on the nearest entry that came into view. They are only needed on the long lists whose scrolling the game protects: the friends, ignore and who lists and the guild roster on Classic Era, The Burning Crusade and Mists of Pandaria. On those lists Home and End do nothing, because the game does not allow a jump of that size.

Some windows show their content in pages: the spellbook, the merchant, the mailbox, books and letters, and on WoW: Forever the toy box, heirlooms and appearances. While you are on that content, Page Up and Page Down press the window's Previous Page and Next Page buttons and put you on the first entry of the new page. On the first or last page nothing happens. In a book the new page's text is read when it arrives. The page buttons are also reachable with Tab.

## Letter navigation in menus

In lists that own the keyboard, you can press a letter to jump to the next entry whose name starts with it. This works in:

- the WowVision menu and every settings screen inside it, the key bindings included (there a letter finds an action by its name),
- context menus,
- the game's dropdown menus.

Every other window has its own Letter Navigation switch, off by default: the navigation window in the Navigation menu, the Scanner in the Scanner menu, and each game window in its own entry of the Windows menu. Switched on, every list in that window works the same way.

How it behaves:

- Press a letter to move to the next entry starting with it. Press the same letter again to move to the one after, wrapping around at the end.
- Type two different letters quickly (within half a second) to filter the list. You land on a line that says Filter and what you typed; below it are only the entries containing those letters anywhere in their name. Every further letter narrows the list, however slowly you type it.
- While a list is filtered, Backspace or Left Arrow brings the whole list back. Enter on an entry, or going one level deeper, also ends the filter.
- Accents are ignored, so U finds "Übersicht". Pressing an umlaut key finds only entries with that umlaut, so Ü finds "Übersicht" but not "Ultra". Leading numbers and punctuation in a name are skipped.
- If nothing matches what you typed, you hear "No results".
- If you press the same single letter again and the entry you are on is the only one that starts with it, that entry is read again.

While such a list is open, every letter key belongs to it: W, A, S and D do not move your character, and letter keys of the game such as B for the bags do nothing. For the menus, you can turn this off with the Letter Navigation in Menus setting (UI menu, on by default). The keys are also released whenever you enter combat or close the list.

Example: at the top of the WowVision menu, press S once to reach Scanner, S again for Speech, then T for Targeting.

## The context menu

Shift+F10 opens a menu of extra actions for the control you are on. You hear "Menu" and then its entries.

- On a real game button you usually get Left Click, Right Click and Drag. Some windows add what the click does, for example "Sell, Right Click", and window-specific actions such as linking an item in chat or inviting a player.
- On a setting in the WowVision menu you get a Scope submenu (see [per-character and account-wide settings](./menu-and-settings.md#per-character-and-account-wide-settings)).
- On an entry in a list you build yourself in the WowVision menu (a monitor, a rule, a buffer group, a buffer) you get Copy: it adds a full copy right after the entry, named "<name> Copy 1" (or the next free number), and speaks that name. The copy lives where the original lives (account or character), and a copied monitor brings its rules along.
- If a control has no actions, you hear "Menu Empty".

Inside the menu use Up and Down, Enter to run an entry (the menu closes afterwards, except for entries that act on the game directly), and Escape to close it. Submenus read as "Dropdown" and open with Enter. Entries with a Checked or Unchecked state read as radio buttons. Letters jump to entries, as described above.

Example: you are on a bag slot and want to drag its item. Press Shift+F10, Down to Drag, Enter. Or just press \\ on the slot.

## Several windows at once

Some actions open more than one window at the same time, for example visiting a merchant opens the merchant and your bags. Each open window keeps its own position.

- Ctrl+Tab moves to the next open window, Ctrl+Shift+Tab to the previous one. WowVision reads the whole path of the window you land on, from the window name down to the control.
- Bags that open together with another window (at a merchant, for instance) do not take focus away from the one you are using, but you can reach them with Ctrl+Tab.
- When you close a window, focus moves to another open window and its path is read.

## Combat

In combat the game protects its keys, so WowVision steps aside completely. Your navigation keys go back to the game, no new announcements are made for windows, and nothing is read on your behalf. Windows that are open stay open. As soon as combat ends, WowVision takes its keys back and your windows and focus are as you left them.

Alerts and your keybound announcements (buffers, target announcements and so on) are not affected: those keep working in combat. See [Combat](../world/combat.md).

## Cursor and dragging

The game moves items around through the cursor. Whatever you pick up, a bag item, a spell, a macro, a mount, is attached to it, and you hear what it is.

- Enter (left click) on a bag or equipment slot picks up its item. Enter on another slot places it there, or swaps.
- Backspace (right click) usually uses the item: equips it, drinks it, opens it, depending on the item and the window.
- \\ or Ctrl+D is Drag: it picks up whatever the focused slot holds, with the game's own rules (locked bars or unlearned spells refuse, as for a mouse). Drag is also in the context menu.

On an action bar, Drag empties the slot immediately and puts its spell, item or macro on your cursor. Then you can drag another slot to put it there, or press Delete (or Alt+Ctrl+\\) to throw it away.

- A spell, macro, mount or an item reference picked up from an action bar is only an assignment, so Delete just clears it, without asking.
- A real item picked up from your bags is destroyed by Delete only after the game asks you to confirm, so your inventory stays safe. Items of rare quality or better get the game's stronger confirmation, which asks you to type "DELETE" in the game's popup.

See [Action Bars](../windows/action-bars.md) and [Bags and Bank](../windows/bags-and-bank.md) for window-specific details.

## Diagnostic commands

These are mainly for bug reports. The first three speak their result and open it as a text you can copy.

| Command | What it does |
|---|---|
| /wv gnode | Describes the focused control and the game frame behind it. |
| /wv glive | Describes what WowVision is watching on the focused control. Useful when something is not being spoken as it changes. |
| /wv gdrop | Describes the open dropdown menu and the focused menu entry. |
| /wv keylog | Switches a log on or off ("WowVision key log on" or "off" appears in the chat frame). While it is on, the chat frame shows a line each time WowVision takes, waits for or releases the navigation keys and the letter keys. Use it if a character turns or runs on its own when a window opens. Send the lines starting with "WowVision keys" from your chat log along with what you were doing. |

The full list of commands is in the [slash command reference](../reference/commands.md).

## See also

- [Tooltips](./tooltips.md)
- [Keybindings](./keybindings.md)
- [The WowVision menu and settings](./menu-and-settings.md)
- [Controller support](../controller.md)
