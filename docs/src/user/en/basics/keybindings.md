# Keybindings

Every key WowVision uses can be changed. The keybinding screen lists each action, the keys it has, and lets you add keys, remove keys and move a key from one action to another. This page explains how to use it and what the messages mean. The complete list of actions and their default keys is in the [keybinding reference](../reference/keybindings.md).

## Opening the keybinding screen

1. Press Shift+F1 (or type /wv) to open the [WowVision menu](./menu-and-settings.md).
2. Press U to reach UI and press Enter.
3. Press Down to Bindings and press Enter.

You land on the first binding and hear, for example, "Bindings, List, Up, Bar, Up Arrow, Button, 1 of 2". Escape goes back to the UI menu.

Faster: type /wv bind. It opens the same screen directly as its own window; Escape then closes it.

## What the screen looks like

Each action has one row. A row holds, from left to right:

- one button per key the action currently has, named after the key ("Enter", "Up Arrow", "Ctrl-Tab"),
- an Add button,
- with the game's gamepad interface on, one button per controller button and an Add Controller Button button (see [Controller buttons](#controller-buttons-retail-wow-forever)).

The row is announced by the action's name, then "Bar", then the button you land on, for example "Left Click, Bar, Enter, Button, 1 of 2". An action that has no key at all (and no controller buttons showing) has only Add in its row, and is announced as "List" instead of "Bar".

| Key | What it does here |
|---|---|
| Down / Up | Move to the next or previous action. |
| Right / Left | Move along the row of keys, Add and so on. |
| Home / End | Jump to the first or last action. |
| A letter | Jump to the next action whose name starts with it. |
| Enter on a key | Removes that key from the action. |
| Enter on Add | Starts capturing a new key. |
| Escape | Leaves the screen. |

The actions are listed in the order the addon loaded them: the window navigation keys first, then the other modules. To find one, type the start of its name: S jumps to the next action starting with S, S again to the one after, and S then C quickly finds "Scanner". You land on the action's first key, or on Add when it has none. See [Letter navigation in menus](./interface.md#letter-navigation-in-menus).

An action that has no key shows only Add. These are the actions that are "unbound by default": they exist but are waiting for you to give them a key, for example Toggle All Monitors, Route to Your Target or Announce Distance.

## Adding a key

1. Move to the action's Add button and press Enter. WowVision says the action's name and captures the keyboard. While capturing, no key reaches the game or WowVision's own actions.
2. Press the key combination you want, for example hold Alt and press D. As you press, WowVision reads the combination, such as "ALT-D".
3. Let go of the main key. The combination is added to the action. Modifiers are always written in the order Alt, Ctrl, Shift, so "ALT-CTRL-SHIFT-K".

Things to know while capturing:

- Escape cancels the capture. For that reason Escape itself cannot be given to an action here.
- A modifier on its own (just Shift, just Ctrl) cannot be bound. It only counts as part of a combination with another key.
- The combination counts as the modifiers you were holding when the main key went down. It is fine to release Alt a moment before the letter.
- You hear nothing more after the key is added. Press Left from Add to hear the new key's button.

Example: give Announce Distance the key Alt+D.

1. Open the keybinding screen as above.
2. Press Down until you hear "Announce Distance, List, Add, Button".
3. Press Enter. You hear "Announce Distance".
4. Hold Alt, press D, release both. You hear "ALT-D" when the key goes down.
5. Press Left to hear "Alt-D, Button". The key is saved and active at once.

An action can have several keys. Drag, for instance, ships with \\ and Ctrl+D. Add as many as you like.

## Removing a key

Press Enter on a key's button. It is removed immediately, without asking, and you hear where focus lands next. To change a key, add the new one and then remove the old one, or the other way around.

You can remove all keys from most actions; the action then simply has no key until you add one. The exceptions are the vital actions below.

## Conflicts

Two actions cannot share one key. When the key you capture already belongs to another action, you hear one of these:

| What you hear | What it means | What to do |
|---|---|---|
| "This input already exists for this binding." | The action already has this key. | Nothing changed. |
| "This input conflicts with (action name). Replace?" followed by Yes and No | Another action has this key. | Yes takes the key away from that action and gives it to this one. No, or Escape, changes nothing. |
| "Cannot replace this binding as it requires at least one input." | The other action is a vital one and this is its only key. | Give that action another key first, then try again. |

Example: you want Space to act as Left Click as well. Open Add on Left Click, press Space. You hear "This input conflicts with Read Tooltip. Replace?". Press Down to Yes and Enter. Space now clicks, and Read Tooltip has lost its key; give it another one, for instance Shift+Space, if you still want it.

WowVision only checks keys against its own actions. The game's own key bindings are not checked, and while WowVision's key is active it takes precedence. Pick keys you do not need for something else.

## Vital actions

Vital actions keep at least one key at all times, so you can never lock yourself out of the interface. Trying to remove the last key of one gives "Cannot remove; Binding must have at least one input." You can still add another key and then remove the old one.

| Action | Default key |
|---|---|
| Up | Up |
| Down | Down |
| Left | Left |
| Right | Right |
| Next | Tab |
| Previous | Shift+Tab |
| Next Window | Ctrl+Tab |
| Previous Window | Ctrl+Shift+Tab |
| Close | Escape |
| Left Click | Enter |
| Right Click | Backspace |
| Drag | \\ and Ctrl+D |
| Scroll Up | Page Up |
| Scroll Down | Page Down |
| Context Menu | Shift+F10 |

The other actions, such as Jump to Beginning, Jump to End, Read Tooltip, WowVision Menu and Destroy Cursor Item, may have all their keys removed. If you ever remove every key from WowVision Menu, you can still open the menu by typing /wv.

The navigation keys above are only active while a WowVision window is open. With no window open, they belong to the game as usual. Other actions, such as the buffer keys, the scanner key (F9) and the navigation window key (F10), are active all the time. See [Using the interface](./interface.md).

## Where your changes are kept

Key bindings are account-wide, so a key you change on one character changes on all of them. To give one character its own keys, go to Bindings in the UI menu, press Shift+F10, choose Scope, then your character's name. That character gets a copy of the current keys, all of them at once; choose Global to go back to the shared keys. There is no "reset to defaults" button; to restore a default key, add it back from the [keybinding reference](../reference/keybindings.md).

## Keys that stay off when Sku is loaded

If you run the addon Sku as well, WowVision does not take a few keys that Sku also uses, so the two do not fight. These are the four tooltip line keys (Shift+Up, Shift+Down, Shift+Left, Shift+Right), the soft targeting keys (Shift+I, Shift+P, Shift+O) and the five Target Focus keys. Other commands that Sku also has, such as /pquit, /dquit and /focus1 to /focus5, are likewise left to Sku. The keys still show in the keybinding screen, but they do nothing while Sku is loaded. In the same way, WowVision leaves many game windows (bags, merchant, gossip, mail, trade, quest and others) to Sku.

## Controller buttons (Retail, WoW: Forever)

When the game's gamepad options are on, each row of the keybinding screen also shows the controller buttons assigned to the action, followed by Add Controller Button. They work like keys:

- Enter on a controller button removes it.
- Enter on Add Controller Button says the action's name followed by "Press a controller button". Press the button you want. The shoulder buttons, the triggers and the right stick press can be held as modifiers, so "right trigger plus A" is a combination of its own. A modifier pressed and released on its own counts as the button itself.
- The same conflict messages apply. Escape on the keyboard, ten seconds with no button, or the start of combat cancels the capture with "Cancelled". Capturing is not possible in combat: you hear "Not in combat".

The action Close (Controller) has no keyboard key by default. It lets the controller's close button run the game's own Escape on windows where Escape stays with the game.

All the details are on the [Controller page](../controller.md).

## See also

- [Keybinding reference](../reference/keybindings.md)
- [Using the interface](./interface.md)
- [The WowVision menu and settings](./menu-and-settings.md)
