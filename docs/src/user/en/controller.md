# Playing with a Gamepad

On Retail and WoW: Forever, WowVision can be played with a gamepad next to the keyboard. Both work at the same time, and every WowVision binding can have controller buttons as well as keys. This page explains how to switch it on, what every button does, and how to change the buttons.

(Retail and WoW: Forever. The gamepad main menu and the gamepad action bars exist only on WoW: Forever. The Classic clients have no gamepad interface.)

## Switching it on

In the game options, in the Gamepad section, turn on both:

- Enable Gamepad
- Enable Gamepad UI

WowVision then answers the controller in its windows and in the world. Several things only appear while Enable Gamepad UI is on: the controller buttons in the keybinding window, the four gamepad bars in the action bars window, and the controller log.

## Modifiers: shoulders and triggers

A gamepad sends no Shift, Ctrl or Alt to the game, so WowVision reads the held buttons itself and treats them like those keys:

| Hold this | It works like |
|---|---|
| Left shoulder | Alt |
| Left trigger | Shift |
| Right trigger | Ctrl |
| Both shoulders | The game's shortcut layer (see below) |

A button never counts as its own modifier: the left shoulder pressed alone is just the left shoulder. This is why most keyboard keys have an obvious controller twin. Keyboard Ctrl+Tab (next window) becomes right trigger plus right shoulder, keyboard Shift+Up (previous tooltip line) becomes left trigger plus D-pad up.

## In WowVision windows

While a WowVision window is open, WowVision takes the D-pad and the face buttons. These are the defaults. The names in the first column are the binding names shown in the keybinding window.

| What it does | Controller |
|---|---|
| Up, Down, Left, Right | D-pad |
| Left Click (Enter) | A |
| Right Click (Backspace) | X |
| Close (Escape) | B. Where Escape belongs to the game, B runs the game's own Escape instead; this is the Close (Controller) binding. |
| Read Tooltip (Space) | Y |
| Previous (Shift+Tab) | Left shoulder |
| Next (Tab) | Right shoulder |
| Previous Window, Next Window | Right trigger + left shoulder, right trigger + right shoulder |
| Jump to Beginning, Jump to End | Right trigger + D-pad up, right trigger + D-pad down |
| Previous Tooltip Line, Next Tooltip Line | Left trigger + D-pad up, left trigger + D-pad down |
| Read Tooltip Left, Read Tooltip Right | Left trigger + D-pad left, left trigger + D-pad right (the current tooltip line's left and right text) |
| Context Menu (Shift+F10) | Menu button (the Start button). While the gamepad main menu wheel is open, Start closes the wheel instead. |
| Drag | Left stick press |
| Shift Click (chat links) | Left trigger + A |
| Previous Link in Message, Next Link in Message | Right trigger + D-pad left, right trigger + D-pad right (the parts of a chat line) |

Example: open the menu, go through it and close it.

1. Hold both shoulders and press A. The WowVision menu opens.
2. Press D-pad down to move through the entries. Press A to open one.
3. Press B to go back. Press B again to close the menu.

## In the world

These work all the time, with no window open, and also in combat.

| What it does | Controller |
|---|---|
| Turn to Waypoint | Press the right stick in. |
| Previous Buffer Item, Next Buffer Item | Hold the right stick press, then D-pad up, D-pad down |
| Previous Buffer, Next Buffer | Hold the right stick press, then D-pad left, D-pad right |
| Previous Buffer Group, Next Buffer Group | Hold the right stick press and the left trigger, then D-pad left, D-pad right |

The right stick press does double duty. Held down, it turns the D-pad into the buffer keys. Let go without touching the D-pad, and it counts as a press of its own: turn to the waypoint. See [Buffers](./information/buffers.md) and [Movement](./world/movement.md).

Example: read the lines of your current buffer without leaving the controller. Hold the right stick press, tap D-pad down to hear the next line, tap D-pad right to go to the next buffer, then let go. Because you used the D-pad, the turn to the waypoint does not happen.

## The shortcut layer

Hold both shoulders together, out of combat, and the buttons open WowVision windows whose game buttons only show something to sighted players:

| Press while holding both shoulders | What opens |
|---|---|
| D-pad up | The navigation window ([Navigation](./world/navigation.md)) |
| D-pad down | The chat window ([Chat](./windows/chat.md)) |
| X | The scanner ([Scanner](./world/scanner.md)) |
| A | The WowVision menu |
| Left stick press | The action bars window, which also lists the four gamepad action bars |

## The gamepad main menu (WoW: Forever)

The Start button opens the game's gamepad main menu, a wheel of eight slices that sighted players pick with the right stick. WowVision shows it as a window of two rows of four slices:

- The upper row is the right half of the wheel, clockwise from the top: north, north-east, east, south-east.
- The lower row is the left half: south, south-west, west, north-west.

The window is headed "Main Menu, Page 2 of 3", for example; the wheel has three pages and the emote wheel has none. A slice that the game shows greyed out is read with ", Disabled", and one that is currently open with ", opened". An empty slice is read as "Empty". The slice for the buffs is not supported yet and says "Not supported yet" when you press it.

| Button | What it does |
|---|---|
| Left stick | Moves in the grid, one step at a time. While the wheel is open the stick does not walk your character. |
| A or Enter | Closes the wheel and runs the slice. The window it opens has the focus. |
| Shoulders | Turn the pages of the wheel. |
| D-pad and the other buttons | Stay with the game's wheel and work as they do for sighted players (the D-pad reaches sitting and the emote pages). |
| B or Start | Close the wheel. |

Tracking opens the WowVision scanner and chat opens the WowVision chat window. Every other slice (social, bags, clock, PvP, the emotes) runs the game's own action.

The left stick only moves in the grid out of combat.

## Gamepad action bars (WoW: Forever)

On Forever's gamepad interface your spells sit on the gamepad action bars, not on the keyboard bars. Open the action bars window with Shift+F4, or with both shoulders and left stick press. While the gamepad interface is on, the window lists four extra bars:

- Gamepad Bar: used with no trigger held.
- Left Trigger Bar: used with the left trigger held.
- Right Trigger Bar: used with the right trigger held.
- Both Triggers Bar: used with both triggers held.

Each bar has eight slots, one for each of D-pad left, D-pad up, D-pad right, D-pad down, X, Y, B and A, in that order. Every slot is read with its button, for example "Fireball, D-pad left". The bar name includes its page, such as "Gamepad Bar, Page 1". The shortcut layer's D-pad left and right turn the page, as they do for sighted players. See [Action Bars](./windows/action-bars.md).

## In combat

When combat starts, the window buttons and the shortcut layer go back to the game, just as the keys of WowVision windows do. The right stick press and its combinations (turn to waypoint, buffers) stay with WowVision all the time. When combat ends, WowVision takes its buttons again.

A button press that WowVision uses while you hold a shoulder for the game's targeting counts as using that hold, so letting go of the shoulder afterwards does not change your target.

## Changing the buttons

Every binding lists its controller buttons in the keybinding window, but only while the gamepad interface is on.

1. Open the WowVision menu (Shift+F1, or both shoulders and A), then UI, then Bindings.
2. Move to the binding you want. Its row holds its keys first, then Add (for a key), then its controller buttons, then Add Controller Button.
3. To remove a controller button, activate it (A or Enter). It is removed at once, with no question.
4. To add one, activate Add Controller Button. You hear the binding's name and "Press a controller button". Hold the shoulders, triggers or right stick press you want to combine, and press the button. As you press, WowVision speaks the combination, for example "Left trigger + A button". The button is taken when you let go of it.
5. A shoulder, a trigger or the right stick press that you press and let go on its own is taken by itself, as the button.
6. If the button already belongs to another binding, you are asked "This input conflicts with ...  Replace?". Confirm to take it from the other binding.

The capture gives up and says "Cancelled" if you press Escape on the keyboard, if ten seconds pass without a press, or if combat starts. In combat it does not open at all and says "Not in combat". See [Keybindings](./basics/keybindings.md) for the rest of the keybinding window.

The buttons are spoken as: A button, B button, X button, Y button, D-pad up, D-pad down, D-pad left, D-pad right, Left shoulder, Right shoulder, Left trigger, Right trigger, Left stick press, Right stick press, View button, Menu button and Share button. Combinations are joined with " + ", and the shortcut layer reads as "Both shoulders" and the held right stick as "Right stick press held".

## Reporting a problem

While the gamepad interface is on, WowVision keeps a log of the controller presses and of the speech around them. It is saved into your WowVision data when you log out or type /reload; the session before is kept as well. Type /wv padlog just before you show the problem to start the log afresh. It answers "WowVision pad log started afresh", or "WowVision pad log: only with the gamepad interface on" if the interface is off. Then follow [how to report a bug](./getting-started/troubleshooting.md#reporting-a-bug).
