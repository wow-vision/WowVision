# Reading Tooltips

Almost everything in WoW has a tooltip: item stats, spell descriptions, button explanations, option help. WowVision reads a control's name when you land on it, and gives you the tooltip on demand, either all at once or line by line.

## The keys

| Key | Binding name | What it does |
|---|---|---|
| Space | Read Tooltip | Reads the whole tooltip of the focused control, from the first line to the last. |
| Shift+Down | Next Tooltip Line | Moves to the next line of the tooltip and reads it. |
| Shift+Up | Previous Tooltip Line | Moves to the previous line and reads it. |
| Shift+Right | Read Tooltip Right | Reads only the right-hand column of the current line. |
| Shift+Left | Read Tooltip Left | Reads only the left-hand column of the current line. |

All five can be changed in the [keybinding screen](./keybindings.md). Press Ctrl at any time to stop the speech if a long tooltip is too much.

## How reading works

Space reads every line in order, one after the other, in a single go. Blank lines add nothing to what you hear. Lines that have text on both sides (a left column and a right column) are read left first, then right: the line with "Head" on the left and "Plate" on the right is read "Head Plate", and "Armor" with "120" is read "Armor 120".

Shift+Down and Shift+Up walk through the tooltip one line at a time, skipping blank lines. The first Shift+Down after you land on a control reads the first line; the first Shift+Up reads the last line. When you reach the first or last line, pressing again simply reads that line again.

Shift+Left and Shift+Right are for two-column lines. After moving to a line with Shift+Up or Shift+Down you can hear just its left side or just its right side. This is handy for stat breakdowns or comparison tooltips where the numbers are on the right. If you have not moved to a line yet, they read line one.

Your position in the tooltip starts over every time you move to a different control.

The same keys work on an aura in a buffer: while you are on a buff or debuff in an aura buffer, Shift+Down and Shift+Up read its name, its description and the time left, line by line, also in combat. See [Aura buffer](../information/buffers.md#aura-buffer).

Example: you are on a piece of armor in your bags.

1. Press Space and listen to the whole item, for example "Fur Boots. Binds when picked up. Feet Cloth. Common. Item Level 12. 8 Armor." (The exact lines depend on the item.)
2. You only want the armor line again. Press Shift+Up: you hear the last line.
3. Press Shift+Up until you reach the line you want. Press Shift+Right to hear only its right column.

## What gets added to item tooltips

When the tooltip belongs to an item, WowVision adds two lines the game does not always show in plain text:

- The quality name (Poor, Common, Uncommon, Rare, Epic, Legendary, Artifact, Heirloom), placed directly under the item's slot line (or under the item's name when it has no slot line).
- The item level, directly after the quality. If the game shows its own item level line (which accounts for upgrades), that line is moved there instead of adding a second one. Only equippable items get an item level.

Money in a tooltip is read with its coins. The game shows gold, silver and copper as small coin pictures, which speech would leave out. WowVision reads the sell price and other amounts as "Sell Price: 1 Gold, 23 Silver, 45 Copper". An item worth only a few coins reads, for example, "Sell Price: 7 Copper".

## Item quality in names

In lists and slots, item names carry the quality as the colour a sighted player sees the name in, so you hear "Fur Boots, White" or "Thunderfury, Orange". This only affects names. The tooltip always reads the quality name ("Common", "Legendary") whatever you choose below.

| Quality | Colour you hear | Setting name |
|---|---|---|
| Poor | Grey | Grey (Poor) |
| Common | White | White (Common) |
| Uncommon | Green | Green (Uncommon) |
| Rare | Blue | Blue (Rare) |
| Epic | Purple | Purple (Epic) |
| Legendary | Orange | Orange (Legendary) |
| Artifact | Light Gold | Light Gold (Artifact) |
| Heirloom (and the WoW Token) | Light Blue | Light Blue (Heirloom) |

To change them, open the [WowVision menu](./menu-and-settings.md) with Shift+F1, then UI, Tooltip, Quality. Every colour is a checkbox, on by default. Turn one off to stop hearing that colour after item names. The Enabled checkbox at the top of the Quality menu switches all of them off at once.

Example: you find too many "White" and "Grey" items cluttering your bag readout. Turn off White (Common) and Grey (Poor). Names now read "Linen Cloth" for those, while "Fur Boots, Green" keeps its colour.

## Prices in tooltips (The Burning Crusade only)

On The Burning Crusade, item tooltips can carry extra price lines, read like any other line:

- Auction Price, the last price seen at the auction house, with how many days ago it was seen (left out when it was seen today),
- the Day Mean, the average over the last several days, read with its number of days (for example "7-Day Mean"),
- Vendor Sell, what a vendor pays for the item,
- Vendor Buy, what a vendor charges, once you have seen the item at a merchant.

These come from the price database WowVision builds as you use the auction house. A line only appears when WowVision has that price: an item you never saw at the auction house gets no auction lines, and one you never saw at a merchant gets no Vendor Buy line. The Tooltip Prices checkbox in the Auction Prices menu (on by default) switches the extra lines off or on. The same menu has History Days (21), Mean Days (7) and Auto Scan (off), see [Auction House](../windows/auction-house.md).

## Controls without a tooltip

Not every control has a tooltip. Where there is none, Space is left alone for the game, which means it makes your character jump if you are not typing. The Shift+arrow keys do nothing in that case.

## When you hear nothing

- An item the game has not loaded yet can have an empty tooltip at first. WowVision asks again when you press Space, by which time the information has usually arrived. Press Space once more if you heard nothing.
- The tooltip keys read what belongs to the control you have focus on. They have nothing to read when no window is open.
- If you also run the addon Sku, WowVision leaves the four Shift+arrow tooltip keys unbound so that the two addons do not fight over them. Space still works.

## Diagnostic command

If tooltips are missing or wrong in a particular window, focus the control, then type /wv gtooltip. WowVision speaks and displays what the tooltip reader knows about the control, which helps when you report a bug. See the [slash command reference](../reference/commands.md).

## See also

- [Using the interface](./interface.md)
- [Keybindings](./keybindings.md)
