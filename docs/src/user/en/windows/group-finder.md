# Group Finder, Ready Check and Role Poll

This page covers everything about finding and forming groups: the Looking for Group tool where you list yourself or browse other players' groups, the ready check and role poll popups that appear once a group exists, the dungeon-ready popup, accepting a group invitation in combat, and two commands to leave a group quickly.

## What is available on which version

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Looking for Group tool (listing, browse) | no | yes | not yet | not yet | yes |
| Dungeon Finder (follower and specific dungeons) | no | no | not yet | yes | no |
| Who tab inside the group finder | no | no | no | no | yes |
| Ready check popup | yes | yes | yes | yes | yes |
| Dungeon-ready popup and role check popups | where the game shows them | where the game shows them | yes | yes | where the game shows them |
| /pquit and /dquit | yes | yes | yes | yes | yes |
| /wv accept and the Accept Group Invitation key | yes | yes | yes | yes | yes |

On Mists the dungeon finder, raid finder and premade groups windows themselves are not read yet. On Retail the Dungeon Finder is read, but the Raid Finder, Premade Groups and the other tabs of the window are not. The popups that come out of them (dungeon ready, role check) are read, and /dquit leaves the group afterwards.

If the addon Sku is loaded, WowVision leaves the ready check, dungeon-ready and role popups and the /pquit and /dquit commands to Sku.

## The Looking for Group tool (TBC and WoW: Forever)

The tool has two tabs on The Burning Crusade (Listing and Browse) and three on WoW: Forever (Listing, Browse and Who). Open it with the game's group finder key or from the micro menu. WowVision reads it as soon as it opens, and Escape closes it.

The first stop is the Tabs row. Left and Right move along it; the open tab reads "selected".

- On TBC, Enter on a tab switches to it.
- On WoW: Forever, Enter on the Listing or Who tab runs the game's key for that tab, because posting a listing only works when the game itself switches the tab. Those game keys toggle the window, so Enter only does something on a Listing or Who tab that is not the open one. Pressing Enter a second time right after switching would close the window, as the key does. Enter on Browse switches normally.

Use Tab and Shift+Tab to move between sections of a tab; use the arrow keys inside a section. See [Interface basics](../basics/interface.md).

### Listing tab: put yourself or your group on the list

Stops from top to bottom:

1. Options (when shown): a button that reads "Ignore suggested level" followed by "Checked" or "Unchecked". Enter opens the game's small menu where you can tick it. When ticked, activities outside your level range also appear. On TBC it is on both tabs; on WoW: Forever on the Browse tab only.
2. Categories, when you have not chosen one yet. Each category is a button; Enter picks it. An empty list reads "Empty".
3. Activities, after you chose a category (this replaces the categories). A tree of activity groups and activities. Each row reads:
   - the activity name, then its suggested levels where it has them, for example the game's "(15 - 25)",
   - "Checked" or "Unchecked",
   - "Expanded" or "Collapsed" for a group that can fold.
   Enter ticks or unticks. Ticking a group ticks everything in it. To fold or unfold a group open the context menu (Shift+F10) and choose Expand/Collapse. A group with no activity at your level starts folded.
4. Back: returns from the activities to the categories (when the game shows its Back button).
5. Roles: three checkboxes, Tank, Healer and Damage Dealer, when you are alone. When you are in a group it is instead a role dropdown and a button to start a role poll (the game's own labels). A New Player Friendly checkbox may follow.
6. Comment: an edit box for the text other players see. When you arrive with Tab you can type at once.
7. WoW: Forever only, after the comment, and only while the activities (not the categories) are showing: Play Style (a dropdown that reads "Play Style" and your pick; the game requires one before you can post), a checkbox for the level range filter of the activity list, and a voice chat dropdown that reads its label and your pick.
8. The game's Post button (its label is whatever the game shows).

If the game cannot list you right now (for example because of your level or group state) the whole tab is replaced by the game's explanatory text, read as one line.

### Example: list yourself for a dungeon (TBC)

1. Press the group finder key. The window opens on the Listing tab.
2. Tab to Categories, press Down to "Dungeons" and press Enter.
3. You are now in Activities. Down to "Shadow Labyrinth", press Enter; it reads "Checked".
4. Tab to Roles, tick Damage Dealer with Enter.
5. Tab to Comment, type "dps, know the fights", Tab on.
6. Tab to the Post button and press Enter. Other players can now see your listing.

### Browse tab: look for a group

Stops from top to bottom:

1. Category filter and Activity filter: two dropdowns (the game's own labels). Enter opens the game's menu.
2. Search: a button that refreshes the results with your filters.
3. Options (the "Ignore suggested level" button described above).
4. Browse Groups: the results.
5. Two buttons that appear when a group is selected: the game's buttons for messaging the leader and for inviting (their labels are the game's).

Each result in the list reads: the leader's name, the activity short name, the party size and the comment, separated by " - ", for example:

> Thrall - Shadow Lab - 3/5 Members - need healer, no ninjas

On WoW: Forever the list has two collapsible headers, Solo Players and Groups, each reading "Expanded" or "Collapsed". Enter on a header folds it. A selected result reads "selected".

| Key on a result | What it does |
|---|---|
| Enter | Selects the group |
| Backspace | Opens the game's menu for that listing (whisper and the like) |
| Space | Reads the group's tooltip |

If you post a listing and the game reports "Blocked: Search()", WowVision says "Group search blocked, reload to search again". The game's own Search button then stays disabled until you type /reload. This is a game restriction, not a fault in your settings.

### Example: find a group for a dungeon (TBC)

1. Open the group finder and move to the Browse tab on the Tabs row.
2. Tab to the category dropdown, press Enter, choose "Dungeons".
3. Tab to the activity dropdown and choose the dungeon.
4. Tab to Search and press Enter.
5. Tab to Browse Groups and use Down to listen to the results.
6. On a group you like press Enter, Tab to the button for messaging the leader and press Enter.

### Who tab (WoW: Forever)

On WoW: Forever the friends window has no Who tab, so the group finder holds it. It is a player search. Stops:

1. Filter: a dropdown for class, race, zone and sort order.
2. Search: an edit box. Enter inside it searches with your text and the filter. The game's separate search button is left out because Enter does the same.
3. A list named after the tab (usually "Who"), one row per player: name, "Level 60 Warrior", race, zone and guild, joined by commas. Enter highlights the player, Backspace opens the player menu (whisper, invite).
4. A totals line. It is read only when the server found more players than it sent; the server sends at most 50.

The context menu (Shift+F10) of a result has Invite first, then the player menu's entries.

## The group finder on Retail

On Retail the group finder key (or the micro menu) opens the game's Looking for Group window. WowVision reads it as soon as it opens, and Escape closes it. WoW: Forever does not use this window; it has the Looking for Group tool described above. Only the Dungeon Finder is read so far.

Tab and Shift+Tab move between the stops of the window; the arrow keys work inside a stop. The stops from top to bottom:

1. Tabs: the tabs along the bottom of the window (Group Finder, Player vs. Player, Mythic+ Dungeons and whatever else your game shows). Left and Right move along the row; the open tab reads "selected". Enter opens a tab.
2. The Group Finder tab's buttons: Dungeon Finder, Raid Finder and Premade Groups, in the game's words. The open one reads "selected". Enter opens it.
3. The page of the open button. Only the Dungeon Finder is read. On any other tab or button you hear "This tab is not supported yet".

### Dungeon Finder

The stops of the Dungeon Finder, from top to bottom:

1. Roles: Tank, Healer and Damage Dealer checkboxes, and a Leader checkbox where the game shows it. Left and Right move along them; Enter ticks one, and it reads "Checked" or "Unchecked".
2. The type dropdown. It reads the game's label and your current choice. Enter opens the game's menu, where you pick what you want to queue for: a random dungeon, follower dungeons or specific dungeons, as your character allows.
3. The page for that type:
   - For a random dungeon: the rewards the game lists for it, read as one line.
   - For follower dungeons: first the game's short explanation, then the list of follower dungeons.
   - For specific dungeons: the list of dungeons.
4. Find Group: the game's button that puts you in the queue. Enter presses it.

Each row of a dungeon list reads, in order:

- the dungeon's name,
- its levels, for example "(Level 60)" or "(Levels 15 - 25)", where the game gives them,
- its state: "Checked", "Unchecked", "Partially Checked" (a header with only some of its dungeons ticked), or "Locked",
- for a header that groups dungeons, "Expanded" or "Collapsed".

Enter ticks or unticks a dungeon. Ticking a header ticks everything in it. To fold or unfold a header, open the context menu (Shift+F10) on it and choose Expand/Collapse.

A locked dungeon cannot be queued for. To hear why, press the tooltip key (Space by default; see [Tooltips](../basics/tooltips.md)) on the row: the game's lock reason is read, for example that you are too low level.

If your group is still looking for members, or you have the deserter penalty, the game covers the finder with a message. WowVision then reads that message and its buttons instead of the type page, and the roles, the type dropdown and Find Group stay where they were.

### Example: queue for a follower dungeon

1. Press the group finder key. The window opens on the Group Finder tab.
2. Tab to the group finder buttons, Down to Dungeon Finder if it is not selected, and press Enter.
3. Tab to Roles and tick the role you want with Enter.
4. Tab to the type dropdown, press Enter, and choose Follower Dungeons.
5. Tab to the list. Down to the dungeon you want and press Enter; it reads "Checked".
6. Tab to Find Group and press Enter. When the queue pops, the Dungeon Ready popup described below appears.

## Ready check

When a party or raid leader starts a ready check, WowVision opens a window named Ready Check and focuses it. It reads:

1. the question text, for example "Thrall has initiated a ready check",
2. the game's Ready (yes) button,
3. the game's Not Ready (no) button.

Press Tab to the button you want, Enter to answer. The window closes after you answer or when the check ends. The two buttons use the game's own texts (in English "Ready" and "Not Ready").

## Dungeon ready popup

When a dungeon queue pops, the game's "Dungeon Ready" popup opens in WowVision under the game's own title. It reads, in order:

1. your role, for example "Your role: Tank",
2. the progress text, how many members have accepted, where the game shows it,
3. instance information, where the game shows it,
4. the Enter Dungeon button, and
5. the Leave Queue button.

Tab moves between the buttons, Enter presses one.

## Role poll and role check

The two role popups, the leader's party Role Poll and the dungeon queue's role check, read identically. The title is the game's text. Then:

1. Roles: a list of the role checkboxes the game shows, from Tank, Healer and Damage Dealer. Enter toggles one; each reads "Checked" or "Unchecked".
2. Accept, Decline and a Close button, each its own stop (a button the game hides is not listed).

Example: a leader starts a role poll. You hear the popup's title. Down to Healer, press Enter (it reads "Checked"), then Tab to Accept and press Enter.

## Accepting a group invitation in combat

When someone invites you to a group, the game shows an invitation popup, which you answer like any other popup. In combat WowVision cannot open the popup for you, so it stays out of reach until the fight ends. These two ways accept the invitation at any time, also in combat:

| Way | What it does |
|---|---|
| /wv accept | Accepts the invitation that is shown |
| Accept Group Invitation key | The same as a key. It is unbound: give it a key in the keybinding window (/wv bind) |

You hear "Group invitation accepted". Without an invitation you hear "No group invitation". To decline, answer the popup after the fight or let the invitation run out.

## Leaving a group quickly: /pquit and /dquit

Two slash commands work in any chat box without opening a window:

| Command | What it does |
|---|---|
| /pquit | Leaves your party at once |
| /dquit | Leaves your dungeon finder group if you are in one. If you are also inside a battleground or arena, it leaves that as well. Outside a dungeon finder group and outside a battleground or arena it does nothing |

Use /pquit for an ordinary party, even inside a dungeon you walked into. /dquit may make the game show a confirmation popup, which you answer like any other popup (see [System windows](./system.md)). Both commands are also listed in [Commands](../reference/commands.md).

## What is not read yet

- The Dungeon Finder, Raid Finder, Scenario Finder and Premade Groups windows on Mists.
- On Retail: the Raid Finder, Scenario Finder, Premade Groups, Player vs. Player and Mythic+ Dungeons tabs. Each says "This tab is not supported yet".
- The group finder's application dialogs: the list of players who applied to your listing, and the invitation you get after applying to someone else's group.
- The battleground and arena queue popups.

See also: [Social windows](./social.md), [Windows overview](./overview.md), [Chat](./chat.md).
