# Spells and Talents

The spellbook lists everything your character can cast, and the talent window is where you spend talent points or choose a specialization. WowVision reads both, and the way they work depends a lot on the game version.

## Where it is available

| Game version | Spellbook | Talents |
|---|---|---|
| Classic Era | Not supported yet. | Not supported yet. |
| The Burning Crusade (TBC) | Spell pages with side tabs, pet tab, show all ranks. | The three talent trees as a grid, spent with one press. |
| Mists of Pandaria (Mists) | Spell pages, Professions, Core Abilities and What Has Changed tabs. Spell flyouts. | Specialization and tier talents. The Glyphs page is not read yet. |
| Retail | Not supported yet. | Not supported yet. |
| WoW: Forever | Category tabs, search, paged spell grid. Spell flyouts. | The class talent tree with one stop per specialization, apply, undo and reset. |

Open the windows with the game's own keys: P for the spellbook and N for talents (unless you changed them). Escape closes them. You can switch WowVision's reading of these windows off with the Enabled toggle in the WowVision menu (Shift+F1), under Windows. On TBC and Mists there is a Spellbook and a Talents entry. On Mists the Talents entry also has a child module Glyphs. On WoW: Forever the class talents are a page of the spellbook window, so the one Spellbook entry switches both.

If the Sku addon is loaded, WowVision does not read the TBC spellbook and talent window, nor the Mists talent window.

Keys that work on spells and talent buttons, besides the usual Tab, Shift+Tab and arrow keys:

| Key | What it does |
|---|---|
| Enter | Left click: casts a spell, learns a talent rank, selects a tab or a specialization. |
| Backspace | Right click: on WoW: Forever talents it unlearns a rank, on a pet spell it toggles autocast. |
| \\ or Ctrl+D | Drag: picks the spell or talent up onto your cursor so you can put it on an action bar (not on the TBC talent grid, see below). See [Action bars](action-bars.md). |
| Space | Reads the tooltip. Shift+Up and Shift+Down move through its lines. |
| Shift+F10 | Context menu of the focused element. |

## The Burning Crusade: spellbook

The window opens on the spells. The stops, in order:

1. Tabs, a row, only while you have a pet with a spellbook: Spellbook and Pet. The open one reads "selected".
2. Side Tabs, a row of check boxes, one per skill line of the book (General, your specializations, and so on). Enter opens that page. They read "checked" for the open one.
3. Spells, the list of the current page. A page holds up to twelve spells, read top to bottom and left to right. Each reads its name and rank: "Fireball Rank 3". Passive spells read "Passive" after the name.
4. Previous Page and Next Page, each their own stop.
5. Show All Spell Ranks, a check box. Off, only your highest rank of a spell is listed.
6. Close.

A page that is empty reads "Empty". The page text is not read, but each press of Next Page rebuilds the list, so press Shift+Tab twice to get back to the spell list and read the new page.

Enter on a spell casts it, the same as clicking it in the book. Use the drag key to pick it up for an action bar instead.

## Mists of Pandaria: spellbook

The window title (normally "Spellbook") names the window. The first stop is Tabs, a row with the book pages: Spellbook, Professions, Core Abilities and What Has Changed, plus any other page tab the game shows. The open page reads "selected". Pick a page with Left and Right and press Enter. The Spellbook page opens on its spells.

### The Spellbook page

- Side Tabs, a row of check boxes filtering the list by skill line (your specializations and the general page).
- Spells: up to twelve per page, in the order the game numbers them. Each spell reads its name and its sub text such as the rank or "Passive", plus the level you learn it at for spells you cannot cast yet.
- Previous Page and Next Page.

There is no Close stop here; press Escape.

### Core Abilities

A row of check boxes, one per specialization, picks whose list shows. Below it is a stop named after the chosen specialization. Each ability reads its name, the level it needs if you have not learned it, and the game's short note, in that order, separated by commas. You can only drag the abilities your own specialization has learned.

### What Has Changed

The changes Mists made to your class, one numbered line per change: "1. Title. Description". Walk them with Up and Down.

### Professions

A professions summary with one stop for each profession slot the game shows (the two main professions and the secondary ones such as cooking, fishing and first aid). A slot you have not learned reads the game's hint text. A learned profession reads its name (with its specialization in brackets), then:

- The skill line: "Apprentice (75/300)".
- Its one or two spell buttons, for example the profession's window or an extra ability such as smelting. They are check boxes. Enter casts or opens the window, and drag picks the spell up for an action bar.
- Unlearn, for main professions. It opens the game's confirmation popup.

### Spell flyouts

Some abilities (mage teleports and portals, hunter pet calls, warlock summons) open a flyout. WowVision opens it as a window named Spell Flyout, one stop with a button per spell. Enter casts the spell, and Escape closes the flyout.

## WoW: Forever: spellbook

Forever uses the modern spellbook. It opens on the spell list; Shift+Tab from there reaches the tabs, Tab the search. The stops are:

1. Tabs: the book's category tabs by name (for example your class, general and pet). The open one reads "selected".
2. Spells: the spells of the current page, grouped under the game's headers (a header is spoken once when you enter its group). A spell reads its name and its sub text (such as the rank), and for spells you have not learned yet the level that is required.
3. A paging row, only when the book has more than one page: Previous Page, the page text ("Page 2/3") and Next Page.
4. Search, an edit box. Typing fills a list of suggestions, see Spell search below.
5. Options, a dropdown menu with the book's display options.

Enter casts the spell, or opens the flyout if the spell is a flyout. Backspace on a pet spell toggles its autocast. The drag key picks the spell up. Space reads the spell tooltip.

If the game opens a page of the book WowVision does not read, it says "Not implemented yet". The talents key opens the talent window described below and not the spellbook; there are no tabs between the two.

## Spell search

On WoW: Forever the spellbook, the class talents and the Legacy trees (see the Legacy window of WoW: Forever) share the same search box. It is a normal edit box:

- Tab to it (or press Enter) and type. Typing starts at once when you arrive by Tab.
- While you type, the game lists suggestions under the box. Up and Down move through them and WowVision speaks the highlighted suggestion and its position: "Fireball, 2 of 7". On the last one it also reads the game's line for the matches that did not fit.
- Enter picks the highlighted suggestion. With nothing highlighted, Enter searches for the text you typed.
- When nothing matches, the game offers its own suggested searches and they are read the same way.
- To leave the search, empty the box and press Enter, or Tab away.
- In the talent window the matches are marked afterwards: a matching talent adds "Search Match" to its line.

Suggestions are spoken only while the focus is on the box and it has the keyboard.

## The Burning Crusade: talents

The stops:

1. Specialization, a row of check boxes, only if the game shows specialization tabs (dual talent specializations). Enter switches.
2. Tabs: the three talent trees, named by the game ("Arms", "Fury", "Protection"). The open one reads "selected".
3. A line with your unspent talent points, as the game words it.
4. Talent Grid: the talents of the open tree, read top to bottom and left to right. Each reads its name and rank: "Improved Heroic Strike rank 2/3". Only talents the game shows are listed.
5. Close.

Enter on a talent spends a point on it at once and the new rank is spoken ("rank 3/3"). The game rules apply: you need the points spent above and the prerequisite talent. Press Space for the tooltip, which says what is missing and what the next rank does. To pick up a talent that is an active ability and put it on your bars, open the context menu with Shift+F10 and choose Drag; the drag key itself does not work on the TBC talent grid.

### Example: spend your first points in a Warrior tree

1. Press N. You land on the tabs stop (or on the specialization row if you have one).
2. Press Tab past the tabs and the points line until you hear "Talent Grid".
3. Press Down to walk the first row and Enter on "Improved Heroic Strike rank 0/3".
4. You hear "rank 1/3". To check the points you have left, press Shift+Tab back to the points line.

## Mists of Pandaria: talents

The first stop is Tabs: Specialization, Talents and Glyphs, named as the game names them. The open one reads "selected".

### Specialization

- Specializations: up to four buttons by name (for example "Arms", "Fury", "Protection"). The active choice reads "selected".
- Specialization Info: the role ("Tank"), the description, then the specialization's abilities by name.
- A Learn button. It is only offered while the game allows you to commit to the chosen specialization.

Enter on a specialization previews it. Press Tab to read the information, then Tab to Learn and Enter. The game asks you to confirm in a popup.

### Talents

One stop named Talents with the six tiers. Each tier is a row named after the level it opens at ("15", "30", and so on) and holds three choices. Up and Down change tier, Left and Right the choice. A talent reads its name, and "selected" when it is the one you have chosen in that tier.

Enter on a talent picks it. You may choose one talent per tier. Changing a talent needs the game's usual conditions (resting, or the tome that allows a change). The drag key picks the talent up if it is an active ability.

After the tiers comes a row of buttons: Learn, when the game shows it, and a talent change button, which reads a spell name and a name in brackets while the game offers it.

### Glyphs

The Glyphs page is not read yet. Opening it gives you one line, "Glyphs not yet implemented", after the tabs, and nothing else. The Glyphs child module under Talents has only the Enabled toggle.

### Example: learn a talent in Mists

1. Press N. The window opens on the Tabs stop. Right to Talents, Enter.
2. Press Tab to enter the talents. Arrow down to the tier you want, for example "30".
3. Use Left and Right to hear the three options of that tier. Space reads each tooltip.
4. Press Enter on the one you want. It now reads "selected".
5. If the game shows a Learn button next to the talents, press Tab to it and Enter.

## WoW: Forever: talents

The class talent window is the talents page of the modern spellbook-and-talents window. It shows all of your class's specializations at once, like the old classic talent window. Press the game's talent key (N).

The stops:

1. Tabs: your primary specialization and, once you have learned dual specialization, the secondary one. The open tab reads "selected". A tab also reads "Active" if it is the specialization you play, or the game's reason if it is locked.
2. The state of the tab: an Activate button when it is not the specialization you are using, otherwise the line "Active".
3. Unspent Points: "Unspent Points, 5".
4. Options and Search, see Spell search above.
5. One stop for each specialization. Its context is the specialization name and the points you spent in it: "Arms, 11 Points" (or "1 Point").
6. The last stop is a row: Apply, Undo Changes and the reset button, which is a menu.

### Reading the talents

Inside a specialization stop each row of the tree is a group named Row 1, Row 2 and so on. If the game holds the row back until you spend points in the tree, the group also reads the game's gate line ("Spend 8 more points..."). Up and Down change row, Left and Right walk the talents of that row.

A talent reads its name, its rank, its state and any search mark, comma separated:

- "Mortal Strike, rank 0/1, Available": you can buy it now.
- "Colossus Smash, rank 0/1, Locked, Requires Mortal Strike": the talent it waits for. When any one of several talents opens it, they read joined with "or".
- "Locked" followed by the game's own gate text, for example how many more points you must spend in the specialization.
- "Invalid": a refund removed something this talent needs.
- "rank 2/3" with no state: partly bought. A talent at full rank has no state word.
- "Search Match" at the end after a search that matches this talent. After the game's search for talents that are not on an action bar, the matching talents carry the game's name for that search instead.
- Talents without a maximum rank to show read only "rank 2", without the "/".

Space reads the full tooltip (description, next rank, cost, and what blocks it).

### Spending and refunding

| Key | What it does |
|---|---|
| Enter | Buys one rank. |
| Backspace | Refunds one rank. |
| \\ or Ctrl+D | Picks up an active ability so you can put it on a bar. |
| Shift+F10 | The context menu: Learn, Left Click, Unlearn, Right Click, Drag and Link Mortal Strike in Chat (with the talent's name). |

Changes are staged. They only become real when you press Apply. Apply reads "Unsaved Changes" while something waits, or the game's reason when it cannot apply. Undo Changes drops all staged changes. The reset button is a dropdown (its label is the game's own): Enter opens the game's menu, where you choose to reset the whole tree or only one part of it.

### Choice talents

Some nodes let you choose between talents. Such a node reads "Choice: A, B" while nothing is chosen, otherwise the name of the chosen one, and is a dropdown: Enter opens a list of the options. Each option reads its name, "Selected" if you have it and "Locked" when you cannot take it. Enter on an option learns it (or buys a rank of the chosen one), Backspace unlearns it. The list stays open after you choose; press Escape to go back to the tree.

### Example: take a talent and apply it on WoW: Forever

1. Press N. Press Tab to the specialization you want, for example "Arms, 11 Points".
2. Arrow down to the row and right to "Mortal Strike, rank 0/1, Available". Space reads the tooltip.
3. Press Enter. It reads "rank 1/1".
4. Press Tab until the last stop, Apply, Unsaved Changes, button, and press Enter.

## Other notes

- Retail: neither the spellbook nor the talent window is read yet. The talent engine (rows, ranks, choice nodes, apply and undo) is already in WowVision and will be used for Retail once a window is built on it.
- Classic Era: not supported.
- Learning new spells from a class trainer is in [NPC windows](npcs.md), the action bar side of moving spells is in [Action bars](action-bars.md).
