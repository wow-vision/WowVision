# System Windows

This page covers the windows that belong to the game itself rather than to the world: the game menu, the game options, popups and confirmation dialogs, the macro window and the color picker. It also describes the range readout, a small helper that tells you how far away your target is.

If you need the WowVision menu instead, which holds WowVision's own settings, see [Menu and settings](../basics/menu-and-settings.md).

## The game menu

Press Escape when no window is open and the game opens its game menu. WowVision reads it as a window called Menu.

- Every button is its own stop, from top to bottom. Use Tab and Shift+Tab to move between them. The arrow keys do not move between buttons here.
- Press Enter to use the one you are on.
- Press Escape again to close the menu and go back to the game.

The buttons are the game's own and depend on the version. They normally include Options, Macros, Logout, Exit Game and Return to Game, and on some versions Help, Store, Interface and Edit Mode. Each is read with its game label.

When another WowVision window is open, Escape closes that window first. The game menu opens on the next press.

## The game options window

Options in the game menu opens the game's settings window. The WowVision reader covers almost all of it: its tabs, the category list, the search box and nearly every kind of setting row. Open it from the game menu.

The Discord rows in the Social category only work from a search made right after a reload. WowVision cannot scroll to them safely, and once it has scrolled the settings list in any category, these rows are unreliable until you reload: they may read Sign In even when you are signed in, and the game refuses them. To use them, type /reload, open the options, Tab to the search box before moving into the settings list, type Discord, and Tab to the list. Enter on one of these rows without searching says "Reload, then search settings for Discord, to use this". Once you are signed in, the game disables the sign-in button, which then reads Disconnect. The game has no way to sign out.

### The parts of the window

The stops, in order:

1. Tabs: Game and AddOns, as a row. The tabs are only there when the game shows them. A fresh WoW: Forever install has no tabs until an addon registers settings.
2. Search: a text box. Tabbing into it makes it ready for typing at once. Type part of a setting's name and the list shows matching settings from every category. Tab leaves the box.
3. Categories: the category list, such as Gameplay, Controls, Graphics, Audio, Interface, Social and Keybindings. Group headers are read as "Name, Separator". Enter on a category shows its settings.
4. Settings: the settings of the chosen category. This stop is named for the category, for example "Audio".
5. Defaults: the game's button that resets the current category to its defaults. The game asks you to confirm in a popup.

When you choose another category, the settings stop starts at its top again.

### The settings

How each kind of row sounds and works:

| Setting | What you hear | How to change it |
|---------|---------------|------------------|
| Checkbox | The name and "Checked" or "Unchecked". | Enter toggles it. The new state is spoken. |
| Slider | The name and the value. | Left and Right change the value by one step. Enter opens a box where you can type the exact number. |
| Dropdown | The name and the current choice. | Enter opens the game's dropdown menu as a WowVision menu. Pick with Enter. Dropdowns with several ticks, such as which chat types to show, list the chosen entries, or "None". |
| Button | The name and the button's caption, such as "Cooldown Manager, Open Edit Mode". | Enter presses it. |
| Color swatch | The name and the current color. | Enter opens the color picker. See [The color picker](#the-color-picker). |
| Section header | The name and "Separator". | Nothing to press. |

Some rows hold two controls, such as a checkbox and a slider, or a checkbox and a color swatch. They are read as a pair: the name, then the first control and its position, for example "1 of 2". Use Down (or Right) to reach the second control and Up (or Left) to come back. The second control reads Disabled while its checkbox is off, as the game greys it out.

A control that the game has greyed out says "Disabled", and pressing Enter on it does nothing. A setting row also has a tooltip. Press Space to read the explanation the game gives for it.

Special rows:

- Graphics Quality has two tabs, Base and Raid and Battlegrounds. Each has a quality slider from 1 to 10, then a list of detail dropdowns (shadows, liquid, particles, textures and so on). The raid tab has its own Enabled checkbox. View distance, environment detail and ground clutter are sliders from 1 to 10 as well.
- Item Quality Colors (the Colorblind category): one swatch for each item quality, named for the quality, such as Poor, Common and Rare.
- Raid Frame Preview and Nameplate Preview are spoken only as text, because the preview is a picture.
- Some rows put an explanation next to a checkbox. It is read as part of the checkbox.
- The game's own text-to-speech voice row is a dropdown with a sample button beside it, read as a pair like the two-control rows above.
- A row of a kind WowVision does not know yet is read as "Setting type", the game's name for the row type, and "not implemented". Please report these. See [Troubleshooting](../getting-started/troubleshooting.md).

### Keybindings

The Keybindings category lists the game's own key bindings, in sections.

- A section header says "Expanded" or "Collapsed". Enter folds or unfolds it.
- Some sections start with a short explanation line, which is read like any other text.
- Each binding is a pair of buttons, named for the action, for example "Jump". Each button reads the key it holds, or "Not Bound". Use Left and Right to choose between the two.
- Enter on a button starts rebinding. Press the key (or key combination) you want. When it works, WowVision says "Rebinding successful".
- Backspace removes the key from that button.

This changes the game's bindings. WowVision's own keys (the ones that move you through windows) are changed in WowVision's keybinding window instead. See [Keybindings](../basics/keybindings.md).

Example: turn on Auto Loot.

1. Press Escape, then Tab to Options and press Enter.
2. Press Tab to Search and type "auto loot".
3. Press Tab until the settings list and read down to Auto Loot.
4. Press Enter to turn it on or open the choices, depending on your game version. The new state is spoken.
5. Press Escape to close the window.

## Popups and confirmation dialogs

Many questions in the game appear as small boxes in the middle of the screen: a group invitation, a resurrection offer, a summon, a "do you want to bind this item?" check, and the "delete this item?" confirmation. WowVision opens a window called Popup for each box, and reads it. All the boxes that are open at the same moment are listed in one window, one after the other, each with its own Popup heading.

A box has up to three parts, each its own stop:

1. The text of the question. It is re-read when it changes, for example in a countdown such as "You will be teleported in 30 seconds". When the box is one where the game lets you press Enter to accept, pressing Enter on the text presses the first button for you.
2. A text box, only when the dialog asks you to type something, such as a name or the word DELETE. It reads the box's hint, then what you typed. Enter puts the game's keyboard focus into it, so type your text, and then Enter again accepts the dialog (this is the game's own behavior), or Escape cancels it.
3. The buttons, each a stop of its own, with the game's labels: Accept, Decline, Okay, Cancel, Yes, No and so on. Press Enter to use one.

Escape cancels the box in the same way as the game does.

Example: accept a group invitation.

1. You hear the popup: the name of the player and "invites you to a group".
2. Press Tab to Accept. Press Enter.

If the addon Sku is loaded, WowVision leaves popups to Sku.

## Macros

Open the macro window with the game menu (Macros) or with the slash command `/macro`. The window reads in two modes.

### The main window

The stops, in order:

1. Tabs: the two tabs, general macros and your character's macros. The current one says "selected".
2. Macros: your macros as a list, by name. Enter selects one, and the selected one says "selected". The list says "Empty" if the tab has no macros.
3. Drag to pick up macro: the button that stands for the icon of the selected macro. Press \\ (the Drag key) here to pick the macro up onto your cursor.
4. Edit: the button that opens the name and icon box. It reads with the game's own caption, normally Change Name/Icon.
5. Macro Text: a text box with the macro's commands. Tab into it and type. Tab out again to leave.
6. The buttons the game shows right now, each its own stop: Cancel, Save, Delete and New.

### The name box

After New or Edit, the window shows a smaller box. It has the name text box, Okay and Cancel. WowVision does not read the icon list, so you cannot choose an icon. A new macro gets whatever icon the game starts with.

Example: make a macro and put it on your action bar.

1. Type `/macro` in the chat box and press Enter.
2. Tab to the New button (press Shift+Tab from the top to wrap around to it) and press Enter.
3. In the name box type "Heal", then Tab to Okay and press Enter.
4. Tab to Macro Text. Type `/cast Healing Touch` and press Tab.
5. Tab to Save and press Enter.
6. Shift+Tab back to Drag to pick up macro, and press \\. The macro is on your cursor.
7. Open the bars window with Shift+F4, walk to an empty slot and press \\. The slot now reads "Heal". See [Action bars](./action-bars.md).

## The color picker

Color swatches in the options, and in some addon windows, open the game's color picker. The wheel itself needs a mouse, so WowVision reads the same colors as numbers instead.

The stops, in order:

1. Current Color: a spoken description of the color, for example "Current Color: dark grayish blue, Slate Gray". It updates as you change the sliders.
2. Original Color: the color you started with (only when the game knows it).
3. Red, Green and Blue: each a number from 0 to 255, followed by the description of the whole color, so you hear what the color has become. Left and Right change it by one. Enter lets you type an exact value.
4. Opacity: only when the color has transparency, as a percentage. Left and Right change it by 5 percent, and Enter lets you type a value.
5. Hex Color: a text box with the color as hex, where the game has one. Type a code and the sliders follow.
6. Okay and Cancel, in a row.

Example: set a color to pure red.

1. Enter on a color swatch in the options. The color picker opens.
2. Tab to Red. Press Enter, type 255, and press Enter.
3. Tab to Green, type 0. Tab to Blue, type 0.
4. Tab to Current Color to hear the description, then Tab to Okay and press Enter.

## The range readout

(Available on all versions.) While you have a target, WowVision tells you its distance in yards, so you know whether you are in range for a spell. It plays a recorded voice saying the number, for example "thirty". It speaks when you target something and whenever the distance changes to a different step. It says nothing while you have no target.

The distances come from the same range checks the game's own spells and items use, so you hear steps such as 5, 8, 10, 20, 30, 35 or 40. The number is an upper limit, not an exact measurement: "thirty" means your target is within thirty yards. Some steps are missing on some versions because the game gives no check for them. In combat the range to a friendly target is not available.

When the target is farther away than the longest check the game offers, nothing is said, and the readout speaks again when you come back into range.

To change it, open Targeting, then Hard Target, in the WowVision menu, and choose Range Changed:

| Setting | Default | What it does |
|---------|---------|--------------|
| Range Changed, Enabled | On | Switches the whole readout on or off. |
| Voice Alert inside it, Enabled | On | The recorded voice. |
| Voice Alert inside it, Voice Pack | Matthew | Says whose recorded voice reads the numbers. |

The range alert has no text-to-speech and no sound output, only the voice. For how alerts and voice packs work, see [Alerts](../basics/alerts.md) and [Speech](../basics/speech.md).

## Settings and alerts

| Window | Settings | Alerts |
|--------|----------|--------|
| Game menu | None | None |
| Game options | None | None |
| Popups | None | None |
| Macros | None | None |
| Color picker | None | None |
| Range | Range Changed, in Targeting, Hard Target (above) | Range Changed |

Each of these windows is a module under Windows in the WowVision menu, and each has an Enabled switch that stops WowVision from reading it. Range has no entry of its own: its Enabled switch is on the Range Changed alert. See [Menu and settings](../basics/menu-and-settings.md).

## Troubleshooting

- Escape opens the game menu instead of closing my window. The window already closed. Press Escape again to leave the game menu.
- A popup seems to be missing. Press Ctrl+Tab to cycle to it. A popup and another window can be open together.
- I cannot set a color to a color name. The color picker only takes numbers or a hex code.
