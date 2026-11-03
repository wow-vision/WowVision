# Character

The character pane is where you see what you wear, your stats, your reputations, your skills, your PvP standing and your currencies. WowVision reads it as a set of stops you move through with Tab, with the contents of each tab laid out as lists you walk with the arrow keys.

## Where it is available

| Game version | What is read |
|---|---|
| Classic Era | Not supported yet. |
| The Burning Crusade (TBC) | Five tabs: the paper doll (equipment, stats, resistances), Pet, Reputation, Skills and PvP. |
| Mists of Pandaria (Mists) | The paper doll (equipment and stats), Reputation and Currency. The Pet tab is listed among the tabs, but its contents are not read yet. |
| Retail | Not supported yet. |
| WoW: Forever | Six tabs: Character (equipment, stats, equipment sets, pet stats), Reputation, Skills, PvP, Currency and Statistics. |

## Opening and closing

Open the pane with the game's own character key (C unless you changed it). The game's keys for single tabs, such as the reputation key, open the same pane on that tab, and WowVision reads whichever tab the game shows.

Press Escape to close it. WowVision closes the game's own panel for you.

If the Sku addon is loaded too, WowVision does not read this window, to avoid two addons fighting over the same keys. Switch Sku off if you want WowVision to read the pane.

You can switch WowVision's reading of this window off and on with the Enabled toggle: open the WowVision menu with Shift+F1, go to Windows, then Character. See [The WowVision menu](../basics/menu-and-settings.md).

## How the pane is laid out

Each tab is a handful of stops. Tab and Shift+Tab move between stops, the arrow keys move inside one. The body of the active tab comes first and the row of tabs is always the last stop. That means:

- When the pane opens you land on the first stop of the current tab, normally the equipment list.
- Shift+Tab from the first stop jumps straight to the tabs, because the stops wrap around.
- To switch tabs, go to the Tabs stop, use Left and Right to pick a tab and press Enter. The tab you are on reads as "selected". The body below it is rebuilt and Tab takes you into it.

The keys that work on most elements here:

| Key | What it does |
|---|---|
| Enter | Left click: pick up an equipped item, open or select a row, toggle a check box. |
| Backspace | Right click: for example uses an equipped trinket. |
| \\ or Ctrl+D | Drag: picks up the focused equipment slot so you can move the item. |
| Space | Reads the tooltip of the focused element. Shift+Up and Shift+Down step through its lines. |
| Shift+F10 | Context menu with Left Click, Right Click and Drag. |

More on these in [Using the interface](../basics/interface.md) and [Reading tooltips](../basics/tooltips.md).

## Equipment

The first stop of the character tab is the Equipment list, one entry per slot, in the order the game draws them: head, neck, shoulders, back, chest, shirt, tabard, wrist, hands, waist, legs, feet, the two finger slots, the two trinket slots, main hand, off hand, ranged and, where the game has one, ammo.

- A filled slot reads the item name followed by its quality as a colour word: "Stormforged Helm, Blue".
- An empty slot reads the name of the slot: "Head", "Finger", "Main Hand".
- On the ammo slot the item reads even when the game gives no link for it.
- A slot the game hides is skipped: on WoW: Forever the ammo slot only shows while you wear a ranged weapon, and Mists has no ammo slot.
- On WoW: Forever the list ends with a line for your level ("Level 60 Human Paladin") and, for a hunter with a pet, the pet's loyalty.

Press Space on a slot to read the full item tooltip with its stats. Press Enter to pick the item up onto your cursor, or to drop the item that is on your cursor into the slot. How the cursor works, and how to equip something from your bags with Backspace, is explained in [Bags and bank](bags-and-bank.md). \\ or Ctrl+D picks the item up too, exactly as dragging it with the mouse would.

## Stats

The stats are read-only lines such as "Strength 142" or "Armor 1500". Press Space to read what a stat means.

### The Burning Crusade

Two stops, both named Stats: a left column and a right column. Each starts with a dropdown that chooses the category the column shows (for example base stats, melee, ranged, spell or defense). Press Enter on the dropdown to open the game's menu, pick a category and the lines below change. After the dropdown come up to six stat lines.

A third stop, Resistances, reads the five resistances (fire, frost, nature, shadow, arcane) the way the game's own tooltip words them.

### Mists of Pandaria

One stop called Stats. Every stat category the game shows is a row; Up and Down switch category (you hear the category name) and Left and Right walk the stats inside the category.

### WoW: Forever

The stats live in a side panel with three views, picked on the sidebar tabs (see below). The Stats stop reads the category headers as announcement levels: moving into a category speaks its name once, then you walk the stat lines with Up and Down.

## Equipment manager (WoW: Forever only)

Choose the equipment manager on the sidebar tabs and the panel changes to your equipment sets. The stops, in order:

1. The set list. Each set reads its name, ", Equipped" if you wear it and ", 2 items missing" if pieces are gone from your bags. Enter selects a set and the row reads "selected".
2. New Set.
3. Once a set is selected, one stop each for Equip, Save, Edit Set and Delete. Equip puts the selected set on. Save stores what you wear now into it. Edit Set opens the name and icon window. Delete asks the game for a confirmation popup, which you answer like any [popup](system.md).

New Set and Edit Set open the set window as a window of its own: a name edit box, an icon type dropdown, an Icon number you change with Left and Right (it reads "3 of 120"; Enter lets you type a number) and the Okay and Cancel buttons. The window opens with the cursor in the name box cleared, so you can use the arrow keys at once; Enter on the name box puts you back into typing.

The sidebar also has a Sidebar Tabs stop (a row of tabs: Left/Right and Enter) and a button that collapses or expands the right panel. When the panel is collapsed only the equipment list and the toggle button are read. The pet stats view is called Pet and lists the stats of your pet.

### Example: switch to your tanking gear on WoW: Forever

1. Press C. You land on the equipment list.
2. Press Tab until you hear the sidebar tabs and choose the equipment manager with Right and Enter.
3. Press Tab to the set list, arrow down to "Tank, 1 items missing" (or whatever you named it) and press Enter.
4. Press Tab until you hear Equip, and press Enter.

## Reputation

Available on TBC, Mists and WoW: Forever.

The faction list is one stop named Reputation. Headers (Classic, Burning Crusade, Alliance Forces and so on) read as "Expanded" or "Collapsed"; Enter on a header folds or unfolds it. A faction reads its name, your standing and progress inside it:

- "Cenarion Expedition - Honored 4500 / 12000"
- On Mists and WoW: Forever, friendship factions read the friendship level the game shows, for example "Friend", with progress towards the next level.
- On WoW: Forever, renown factions read "Renown 12" with progress towards the next level. Once you are at the top standing, the maximum friendship level or the maximum renown, no progress is read, for example "Stormwind - Exalted".

Enter on a faction opens its details. On WoW: Forever the row also reads "selected" while it is the chosen faction; on TBC and Mists it does not. On TBC and Mists the details are a stop of their own, named after the faction. On WoW: Forever they are a Details stop. It reads, in order:

- The faction's description. On WoW: Forever the title and subtitle come first, then the description and the detail rows.
- At War, a check box.
- Move to Inactive, a check box (the game moves the faction to the inactive group at the bottom).
- Watched, a check box that shows the faction on your experience bar. On WoW: Forever the labels of the three check boxes are the game's own words.
- Close on TBC and Mists. View Renown on WoW: Forever for renown factions.

On WoW: Forever the list is preceded by a filter dropdown stop, where you choose which factions the list shows.

### Example: watch a reputation on TBC

1. Press C, then Shift+Tab to reach the tabs, Right to Reputation and Enter.
2. Press Tab to enter the list. Arrow down to "Cenarion Expedition - Honored 4500 / 12000".
3. Press Enter. The faction's details open.
4. Press Tab to reach the faction details. Arrow to Watched, checkbox, unchecked and press Enter. It now reads "checked".

## Skills (TBC and WoW: Forever)

The skills tab lists your skill lines: professions, secondary skills, weapon skills, armor proficiencies and languages.

- On TBC a Collapse All / Expand All button comes first. Its label shows what pressing it will do.
- Headers read "Expanded" or "Collapsed" and fold with Enter.
- On TBC a skill with levels reads its name, rank and maximum: "Mining 150/300". An active bonus shows in brackets: "Mining 150 (+15)/300". Skills without levels (armor proficiencies, languages) read only their name.
- On WoW: Forever every skill reads rank and maximum with spaces around the slash: "Mining 150 / 300", with the bonus in brackets: "Mining 150 (+15) / 300".
- Enter selects a skill ("selected").

The selected skill's details come after the list. On TBC they are a Skill Details stop: the rank line, the description and, for professions you can drop, an Unlearn button. Unlearn opens the game's confirmation popup. On WoW: Forever the details are a Details stop with the same kind of rows.

## PvP

### The Burning Crusade

One stop, PVP, reading as short lines:

- Your honor points and your arena points, each with its value ("Honor Points 1234").
- A group Honorable Kills with "Today: 12", "Yesterday: 8" and "Lifetime: 3540".

The toggle button at the end of the tab switches the statistics between the two views the game offers and reads with the game's own label.

### WoW: Forever

A PvP stop reads the lines of the rank system as the game shows them: the season timer, the current season, your rank and your progress to the next one. A Next Reward button follows, then a Details stop with the rank information.

## Pet (TBC only)

The Pet tab only exists while you have a pet with a pet panel (hunters and warlocks). Without one the tab reads "No pet". With a pet there is a stop named Pet holding:

- name, level, loyalty and training points,
- the experience text,
- the diet ("Diet: Meat, Fish"),
- a group Stats with the five attributes, then attack power, damage, spell damage and armor,
- a group Resistances, which lists only the resistances that are not zero.

All lines are live and update as the pet changes. A Close button is the last stop of the body.

## Currency (Mists and WoW: Forever)

One stop with the list of currencies. Headers read "Expanded" or "Collapsed" and fold with Enter. A currency reads its name and your amount: "Justice Points 2150". Space reads the currency's tooltip with its cap and description.

On WoW: Forever a currency row also reads "selected" when chosen. The chosen currency has a Details stop with two check boxes, one that marks the currency as unused (it moves out of the main list) and one that shows it on your backpack bar, plus a transfer button for currencies you can move between your characters. The check boxes read with the game's own wording.

## Statistics (WoW: Forever only)

One stop with the statistics list as the achievements pane shows it. Category headers fold and unfold with Enter. A statistic reads its name and value: "Total deaths 14".

## What WowVision does not read yet

- Mists: the Pet tab of the character pane, the equipment manager and the titles list.
- WoW: Forever: the titles list of the sidebar.
- Classic Era and Retail: the whole character pane.

Pick up, equip and compare items through [Bags and bank](bags-and-bank.md), and read the equipped item tooltips here with Space.
