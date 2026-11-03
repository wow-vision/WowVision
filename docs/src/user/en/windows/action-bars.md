# Action Bars

The Action Bars window shows every action bar the game currently displays, one bar after the other, so you can hear what is on each slot, use a slot, and rearrange your spells, items and macros. Press Shift+F4 to open it.

## Opening the window

| Key | What it does |
|-----|--------------|
| Shift+F4 | Opens the Action Bars window. Unlike most windows, it does not need a game frame to be open first. It is called Action Bars in the keybinding window and can be rebound there. |
| Escape | Closes the window. |

With the gamepad interface on (Retail and WoW: Forever), the same window can also be opened from the controller's shortcut layer: hold both shoulder buttons and press the left stick. See [Controller](../controller.md).

You cannot navigate the window while you are in combat. WowVision gives its keys back to the game during combat so that your own key bindings keep working, and takes them again when combat ends. Use your normal bindings for abilities in a fight.

## How the window is laid out

The whole window is one tab stop. Each bar is a labeled row inside it:

- Left and Right walk along the slots of the current bar.
- Up and Down switch to the previous or next bar. You land on the first slot of that bar.
- Home and End jump to the first or last slot of the bar you are on.

Tab does nothing here, because the whole window is a single stop.

When you move to a different bar, WowVision says the bar's name first, then the slot. Each slot ends with its position in the bar, for example "3 of 12".

Only bars that exist right now are listed. The window reads them in this order:

| Bar as announced | What it is | When it is listed |
|------------------|------------|-------------------|
| Action Bar | The main bar, twelve slots. It follows whatever the game shows there, including a different page or a stance or form that swaps the bar. | Always. |
| Pet Bar | The pet's commands and abilities (Attack, Follow, Stay and so on). | While you have a pet with a bar. |
| Stance Bar | Warrior stances, druid and rogue forms, paladin auras and similar. | While the game shows a stance bar for your class. |
| Bottom Left Bar | The first extra bar. | Only if it is switched on in the game options. |
| Bottom Right Bar | The second extra bar. | Only if it is switched on in the game options. |
| Right Bar | The third extra bar. | Only if it is switched on in the game options. |
| Right Bar 2 | The fourth extra bar. | Only if it is switched on in the game options. |

The four extra bars are off by default in the game. Turn them on in the game options under Action Bars (see [System windows](./system.md) for the options window). A bar you switch off disappears from the window.

On WoW: Forever, when the gamepad interface is on, four more bars are added. See [Gamepad action bars](#gamepad-action-bars-wow-forever).

Not read: the bars that Retail added beyond the four above (Action Bars 5, 6 and 7), the extra action button, the zone ability button, and the vehicle or possess bars. Use your normal game key bindings for those.

## What a slot says

### Main bar and extra bars

A slot reads the name of what is on it, followed by the key the game shows on that button in brackets:

- "Fireball (1)"
- "Healing Potion (s-2)"
- "Empty"

The key text is exactly what the game draws on the button, so Shift, Ctrl and Alt appear in the game's short form such as `s-`, `c-` and `a-`. An empty slot only says "Empty".

The label updates while you are standing on it. If you pick a spell up from a slot, it immediately reads "Empty". Spells, items, macros, mounts, battle pets, equipment sets and flyouts are all read by name. Rarely a slot reads "Unknown", followed by technical details such as an id and a type; that is something the addon cannot name yet. A slot whose button the game has switched off says "Disabled" after its name.

### Pet Bar

Each slot reads the command or ability name. If the ability can be cast automatically, it also says Auto Casting or Not Auto Casting:

- "Attack"
- "Growl Auto Casting"
- "Empty"

### Stance Bar

Each slot reads the stance, form or aura name, for example "Defensive Stance". There is no key text on these slots. Only the stances you have learned are listed.

### Tooltips

Press Space on any slot to read its tooltip, which is the spell or item tooltip the game would show under the mouse. See [Tooltips](../basics/tooltips.md).

## Using a slot

| Key | What it does |
|-----|--------------|
| Enter | Left click: uses the slot, so it casts the spell, uses the item or runs the macro. |
| Backspace | Right click on the slot, exactly as with the mouse. |
| \\ or Ctrl+D (Drag) | Picks up whatever is on the slot and puts it on your cursor. The slot becomes empty. |
| Delete or Alt+Ctrl+\\ (Destroy Cursor Item) | Takes the picked-up spell, macro or reference away for good. See below. |
| Shift+F10 | Opens the context menu of the slot: Left Click, Right Click and Drag. |

Using abilities is faster with your normal game key bindings. The window is for checking and rearranging your bars.

## Moving and removing things

WoW uses a cursor: you pick something up, and then you put it down somewhere. WowVision does the same with keys.

Example: move Fireball from the first slot of the main bar to the fifth.

1. Press Shift+F4.
2. Walk to the first slot with Left and Right. It says "Fireball (1)".
3. Press \\ (or Ctrl+D). Fireball is now on your cursor, and the slot reads "Empty".
4. Walk to the fifth slot.
5. Press \\ again. Fireball goes into the fifth slot. If there was something in that slot, it swaps onto your cursor, and you can place it somewhere else the same way.

Example: take a spell off your bar for good.

1. Focus the slot and press \\. The spell is on your cursor.
2. Press Delete. The cursor is cleared and the spell is gone from the bar. There is no confirmation, because a spell on an action bar is only a shortcut and nothing is lost. You can always drag it from the spellbook again.

The same works for macros, mounts and equipment sets. An item on an action bar is also only a shortcut: Delete just clears it, and the item stays in your bags.

Use the Drag key (\\ or Ctrl+D) when you pick something up from an action bar, rather than the Drag entry in the slot's context menu. The key tells WowVision that the thing on your cursor is only a bar shortcut, so Delete will never offer to destroy the real item. If you pick up an item shortcut through the context menu instead, WowVision treats it as a real bag item, and Delete then opens the destroy confirmation for that item. This matters only for items on a bar. Spells, macros and the like are only ever cleared.

Delete does nothing when your cursor is empty. This is deliberate: you cannot destroy something by merely focusing it. The Delete key works wherever you are in the game, not only inside this window, as long as something is on your cursor.

For items taken from your bags see [Bags and bank](./bags-and-bank.md), which also explains how to destroy a real item.

To place a spell on a bar from the spellbook, pick it up in the spellbook (see [Spells and talents](./spells-and-talents.md)), then open this window with Shift+F4 and drop it on a slot. The cursor stays with you between windows. To place a macro, see [System windows](./system.md#macros).

## Lock Action Bars is turned off for you

The game has a setting called Lock Action Bars. When it is on, dragging an action off a bar does nothing unless you also hold the game's pick-up key, and nothing tells you why. That makes dragging look broken.

The first time each character logs in with WowVision, the setting is turned off, and WowVision prints this message in the chat:

"WowVision unlocked your action bars so that dragging works. You can lock them again in the game options under Action Bars."

This happens once per character. If you lock the bars again in the game options, they stay locked, and WowVision will not change them again. If the game refuses the change (for example during combat), WowVision tries again at the next login. If you hear nothing at login, either the bars were already unlocked, or this character was handled before.

## Gamepad action bars (WoW: Forever)

(WoW: Forever only.)

When the game's gamepad interface is on, your spells sit on the gamepad action bars rather than on the keyboard ones. These bars have eight slots each. The window lists four extra bars, in this order:

| Bar as announced | Which controller buttons use it |
|------------------|---------------------------------|
| Gamepad Bar | No trigger held. |
| Left Trigger Bar | The left trigger held. |
| Right Trigger Bar | The right trigger held. |
| Both Triggers Bar | Both triggers held. |

The bar's name is followed by the page the game is on, for example "Gamepad Bar, Page 1". The pages are turned with the D-pad left and right in the controller's shortcut layer (both shoulder buttons held), as for a sighted player.

Each slot reads like a normal slot, followed by the controller button that triggers it:

- "Frostbolt, A"
- "Empty, X"

The eight slots are, in order: D-pad left, D-pad up, D-pad right, D-pad down, and then the four face buttons (the left, top, right and bottom ones). The button names follow your controller's own naming. These slots have no key text. These bars only appear while the game's Enable Gamepad UI option is on. See [Controller](../controller.md) for the controller keys of WowVision itself.

## Settings and alerts

The Action Bars window has no settings you can change and no alerts. The only stored value is a hidden note that this character's bars were already unlocked. Like every window, it has an Enabled switch in the WowVision menu, under Windows, then Bars. See [Menu and settings](../basics/menu-and-settings.md).

## Troubleshooting

- A bar is missing. The game does not show it. Switch it on in the game options under Action Bars.
- Drag does nothing. The bars are locked, probably because you locked them yourself after the first login. Unlock them in the game options under Action Bars.
- The window does nothing in a fight. WowVision gives its keys back to the game in combat. Leave combat first.
- Enter casts the spell instead of picking it up. That is correct. Enter is a click. Use \\ or Ctrl+D to pick up.
