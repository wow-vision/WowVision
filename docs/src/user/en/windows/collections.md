# Collections and Legacy

The collections journal is where you browse and use your mounts, battle pets, toys, heirlooms and gear appearances. WoW: Forever also has the Legacy window, which holds the Legacy reward track, the challenges (Forever's achievements) and the three Legacy talent trees. This page covers both.

## What is available on which version

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Mounts tab | no | no | yes | not yet | yes |
| Pets, Toys, Heirlooms and Appearances tabs | no | no | not yet (the tab reads "Not implemented yet") | not yet | yes |
| Legacy window | no | no | no | no | yes |

Retail does not load the collections reader yet. Classic Era and TBC have no collections journal in the game at all.

## Opening the journal

Open the collections journal with the game's own key, or from the game's micro menu. WowVision reads it automatically as soon as it opens, and Escape closes it. You can switch the reading off with the Enabled toggle in the WowVision menu (Shift+F1), under Windows, then Collections (or Legacy for the Legacy window).

On WoW: Forever the game has a separate key binding for each tab (mounts, pets, toy box, heirlooms, appearances). Each opens the journal directly on that tab. You can set them in the game's key bindings screen, outside WowVision.

## How the journal is laid out

Everything on every tab follows the same pattern. Press Tab and Shift+Tab to move between sections; use the arrow keys inside a section. See [Interface basics](../basics/interface.md) for the general keys.

1. Tabs: a row of tab buttons. Use Left and Right to move along them. The tab that is open reads "selected".
2. The body of the selected tab: search box, filters, the list, details, and buttons. These differ per tab and are described below.

Keys that work on most rows in the journal:

| Key | What it does |
|---|---|
| Enter | Left click: selects the row, or uses the item (see each tab) |
| Backspace | Right click: opens the game's menu for that row (summon, favorite, and so on). The menu opens as its own list, and Escape closes it |
| Space | Reads the tooltip of the focused row (mount spell, toy, heirloom, appearance item) |
| \\ or Ctrl+D | Drag: puts the mount, pet or toy on your cursor so you can drop it on an action bar. See [Action bars](./action-bars.md) |
| Shift+F10 | Context menu of the focused element |
| Page Up / Page Down | Scroll long lists |

### Tabs on Mists

The tabs are the journal's bottom tabs. Enter switches to the tab. Only Mounts is implemented; every other tab reads "Not implemented yet".

### Tabs on WoW: Forever

The tabs are the journal's icon-only side tabs. WowVision reads each by the name in its tooltip (Mounts, Pets, Toy Box, Heirlooms and Appearances in the game's words). Enter on a tab runs the game's own key for that tab, exactly as pressing the key would, because the game switches these tabs in a way a plain click cannot reach. On the tab that is already open, Enter only says "selected", so it cannot close the journal by accident. Tabs for empty collections may be missing while the game's Only show collected filter is on.

## Mounts (Mists and WoW: Forever)

The mount journal has four stops, in this order:

1. Search: an edit box. When you arrive with Tab you can start typing at once; the list filters as you type.
2. Clear: a button that appears only while the search box holds text. Enter empties the box.
3. Mounts: the list of mounts.
4. A mount button (the game's own Summon or Dismiss button, with the game's label) that works on the mount you selected.

Each mount row reads its name. A mount you are riding right now reads "Flame Wolf (Mounted)". The row you selected reads "selected".

| Key on a mount | What it does |
|---|---|
| Enter | Selects the mount |
| Backspace | Opens the mount's menu: mount or dismount, favorite |
| Space | Reads the mount's spell tooltip |
| \\ | Picks the mount up on your cursor for an action bar |

The mount's description, source and the preview model on the right of the journal are not read yet, and neither is the journal's filter menu.

### Example: summon a mount you have favorited

1. Open the journal with the game's mount key. You hear the journal open on the Mounts tab.
2. Press Tab to the Search box and type "wolf". The list shrinks to wolf mounts.
3. Press Tab to Mounts, use Down until you hear the mount you want.
4. Press Backspace and choose the favorite entry from the menu, or press Enter to select it and Tab to the mount button, then Enter to summon.

## Pets (WoW: Forever)

Stops in order: Filter (a dropdown; Enter opens the game's filter menu), Search (edit box), Pet Journal (the pet list), Details (the selected pet's card), and the Summon button.

A pet row reads its name. If you gave the pet a custom name it reads the custom name first and the species in brackets, "Fluffy (Cat)". Pets you do not own yet add "Not Collected", and favorite pets add "Favorite". The pet whose card is open reads "selected".

| Key on a pet | What it does |
|---|---|
| Enter | Shows the pet's card in Details |
| Backspace | Opens the pet's menu (summon, favorite) for pets you own |
| \\ | Picks up an owned pet for an action bar |

Details reads, one line each: the pet's name (and species under a custom name), where it comes from, and its description. Stats, abilities and the battle team slots are not read yet.

## Toy Box (WoW: Forever)

Stops in order: a progress line (the game's collected counter), Filter, Search, the Toy Box list, and the paging row.

The toy list shows only the current page, up to eighteen toys. Each toy reads its name, then "Not Collected" if you do not have it, then "Favorite" if you marked it. An empty page reads "Empty".

| Key on a toy | What it does |
|---|---|
| Enter | Uses the toy |
| Backspace | Opens the favorite menu (toys you own) |
| Space | Reads the toy's tooltip |
| \\ | Picks the toy up for an action bar |

The paging row is Previous Page, the page number text and Next Page. It is left out when there is only one page. After you change page, press Shift+Tab back to the Toy Box list to read the new page.

## Heirlooms (WoW: Forever)

The heirloom tab appears only while the game offers heirlooms. Stops in order: Class (a dropdown that reads "Class" and your current pick, for example "Class, All"), a Progress line, Filter, Search, the Heirlooms list, and the paging row.

The list is grouped under headers, one per slot group, exactly as the journal page draws them. Each heirloom reads its name, the level it scales to (heirlooms you own), a PvP tag where the game shows one, and "Not Collected" for ones you lack.

Enter on an heirloom creates it in your bags if you own it. With an upgrade item on your cursor, Enter upgrades the heirloom instead. Heirlooms have no right-click menu and no drag.

## Appearances (WoW: Forever)

This is the wardrobe journal, not the transmogrifier. Stops in order:

1. Tabs: Items and Sets, a row. The open one reads "selected".
2. (While shown) Class, a dropdown that reads "Class" and your pick, then Filter and Search.
3. The body of the open sub-tab.

Forever lists only the appearances you have collected in this journal, so "Not Collected" rarely shows on these rows.

### Items sub-tab

- Items: the equipment slots as a vertical list (Head, Shoulders, and so on). When you wear a transmog on your shoulders with a second appearance, the slot splits into left and right shoulder. Weapon enchantment slots read with "Weapon Enchantment". The active slot reads "selected". Enter selects a slot.
- Type: a dropdown that appears only on weapon slots.
- Appearances: the current page of appearances, up to eighteen. Each reads the name of the first item that grants it, then "Not Collected" if you lack it, then "Favorite" if marked. Space reads that item's tooltip. A plain Enter does nothing in the journal; use Backspace to open the game's menu (favorite, and the other entries the game offers).
- The paging row (Previous Page, page text, Next Page) when there is more than one page.

### Sets sub-tab

- Sets: the list of sets. Each reads the set's name, its group (for example a raid tier), the pieces you have out of the total ("5/8"), and "Favorite". Enter selects a set and fills the details, Backspace opens the favorite menu.
- Details: the set's name and group, then each piece in the order they are drawn, as "Item name, Collected" or "Item name, Not Collected".
- A variants dropdown to switch between versions of the set.

### Example: check whether you have all pieces of a set

1. Open the journal with the game's appearances key.
2. Tab to the Tabs row, move to Sets with Right, press Enter.
3. Tab to Search and type the set's name.
4. Tab to the Sets list, Down to the set; you hear for example "Battlegear of Might, Tier 1, 6/8".
5. Press Enter, Tab to Details and read the pieces with Down.

## Legacy window (WoW: Forever)

The Legacy window is part of WoW: Forever's progression. It has three pages, chosen with the side tabs. The window's title names the page you are on.

### Opening

Open it with the game's Toggle Legacy key, from the game's micro menu, or with the achievements key (which opens it on the challenges page). Escape closes it.

### Tabs

The first stop is the Tabs row. The three pages are the reward track, the challenges and the talent trees. Left and Right move along the tabs, Enter opens a page; the open tab reads "selected".

### Reward track page

Stops in order: a summary, then the Rewards list.

- The summary reads the game's Legacy label and level, for example "Renown level, 12" (the game supplies the exact wording), and then the progress to the next level ("Current progress 340/1000") until you reach the maximum.
- Rewards lists every level of the track at once; the page's sideways scrolling is not needed. A level reads "Level 13, Reward name, Earned". "Earned" appears for levels your renown has reached. Several rewards on one level are read in a row, separated by commas.
- Space reads the level card's own tooltip (what the reward does).

### Challenges page

Challenges are Forever's version of achievements, worth Legacy points. Stops in order:

1. Points: your Legacy points earned, "Points 120/500".
2. Filter: a dropdown for completed and incomplete challenges.
3. Search: an edit box.
4. Categories: the category tree.
5. Challenges: the list of the selected category, named "Challenges" followed by the category name.

A category row reads its name, "Collapsed" or "Expanded" if it has sub-categories, "selected" for the chosen one, and "New" when it holds challenges you have not seen yet. Enter selects it and, for a parent category, folds it open or shut. When there are no search matches the game's "no results" text replaces the list.

A challenge row reads its name, its Legacy points ("10 Points"), "Completed" with the date if you earned it on this character, "Tracked" if you track it, then its description and reward text. Enter selects the challenge and unfolds it; Enter again folds it. An unfolded challenge is followed by:

- Objectives: each objective as text, with counts for counted ones ("12/20") and "Complete" for finished ones.
- Track: a checkbox that reads "Checked" or "Unchecked". It is shown while the challenge is not done, and never when the game has switched tracking off.

Space on a challenge reads a tooltip made up of its description, reward and all objectives. The context menu (Shift+F10) holds "Link (challenge) in Chat" to put the challenge link into your chat box.

### Tree page

The three Legacy talent trees (professions, adventure and progression) are bought with Legacy points. Stops in order:

1. Trees: three buttons in a row, one per tree, each reading its name and the points spent in it ("Adventure, 4 Points"). The shown tree reads "selected". Enter switches tree.
2. Points left: "Available points 6" and the seasonal cap.
3. Search: a spell search edit box. While you type, Up and Down read the game's suggestions with their position, and Enter picks the highlighted one (or searches your typed text if none is highlighted).
4. Talents: the tree row by row, read top to bottom, left to right. Each row is a group called "Row 1", "Row 2"..., and a row held back by a spend gate adds the game's gate text (spend N more points). Left and Right move along a row, Up and Down between rows.
5. Apply, Undo Changes and Reset Tree buttons in one row.

A talent reads its name, its rank ("rank 1/2"), and its state: "Available" (you can buy a rank), "Locked" with what it waits for ("Requires Fireblast or Frostbolt" and the points still needed), or "Invalid" if refunding something broke it. A talent that matches your search adds "Search Match". Choice talents read "Choice:" and their options.

| Key on a talent | What it does |
|---|---|
| Enter | Buys a rank (for a choice talent: opens its options) |
| Backspace | Refunds a rank |
| Space | Reads the talent's full tooltip |
| \\ | Picks up an active ability for an action bar |
| Shift+F10 | Context menu: Learn, Unlearn, Drag and "Link (talent) in Chat" |

Buying is staged: nothing is learned until you press Apply. The apply button reads "Unsaved Changes" while changes are waiting. Undo Changes drops them, and Reset Tree refunds the whole tree (also staged until Apply). Choice talents open the game's option list; Enter picks an option, Backspace on one unlearns it, and Escape returns to the tree. The same talent tree reader is used for the class talents; see [Spells and talents](./spells-and-talents.md).

### Example: spend Legacy points on a tree

1. Open the Legacy window with the Toggle Legacy key.
2. On the Tabs row, move to the tree page and press Enter.
3. Tab to Trees and choose the tree you want.
4. Tab to Talents. Use Down to reach a row and Right to find a talent that reads "Available".
5. Press Enter to buy a rank. Repeat for other talents.
6. Tab to the Apply button (it reads "Unsaved Changes") and press Enter.

## What is not read yet

- Mount, pet and appearance previews (the 3D model), the pet battle team and pet stats.
- The mount journal's filter menu.
- Retail's collections journal.

See also: [Windows overview](./overview.md), [Action bars](./action-bars.md), [Tooltips](../basics/tooltips.md), [Version availability](../reference/versions.md).
