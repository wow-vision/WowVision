# Scanner

The Scanner is a list of things around you and where they are: quests, quest givers, NPCs, your corpse, party members, gathering nodes and more. It plays the part of the "what is near me" list that players know from other accessibility addons. You look through it with the arrow keys, hear how far away each entry is and in which direction, and press Enter to be guided there.

Press F9 to open the Scanner. Press Escape to close it. The key is called Scanner in the keybinding window and can be changed there; see [Keybindings](../basics/keybindings.md). The Scanner works on every game version, but what it can list depends on the version and on the data available. See "Version notes" at the end.

Pressing F9 while you are in the quest log opens the Scanner right on that quest, under Quests, In Progress: the quest your cursor is on in the log, or else the quest whose details are open. Press Right to hear its objectives, or Enter to be guided to its next target.

## How it is laid out

The Scanner is one tree. The top level holds categories, categories hold entries, and many entries hold more entries below them. Entries that hold more are groups. You hear "collapsed" or "expanded" after a group's name.

| Key | What it does |
|-----|--------------|
| Down and Up | Move to the next or previous entry. |
| Right | Open a collapsed group, or step into an open one. |
| Left | Close an open group, or step out to its parent. |
| Enter | On an entry with a position: guide you there (see below). On a group without a position: open or close it. On a checkbox in the Tracking category: switch it on or off. |
| Backspace | On entries that have extra text (quests): open a small read-only list with that text. |
| Tab | Jump from the tree to the Refresh button and back. |
| Escape | Close the Scanner. |

Everything else works as in any WowVision window; see [Using the interface](../basics/interface.md) for Home, End and type-ahead.

For each entry with a position you hear its name, an extra note when it has one, the distance and direction from where you stand now, and its place in the list. For example: "Marshal McBride, seen, quest available, 85 yards, ahead left, 3 of 12". The distance and direction are worked out when you land on the entry, so they follow you as you walk. The directions are relative to the way you face: ahead, ahead left, left, behind left, behind, behind right, right, ahead right.

### A snapshot, not a live list

The Scanner builds its lists once, when you open it. It does not change while it is open, so it never slows the game down in the middle of a fight or a flight. Only distance and direction update. To bring the lists up to date without closing the window, press Tab to the Refresh button and press Enter. You hear "Refreshed". Opening the Scanner again also builds fresh lists.

Which groups you have opened is remembered between openings until you log out. On your first opening of a session every category is open except Tracking.

If a category has an error while it is being built, you hear a line starting with "Error" in its place and the rest of the Scanner still works. A group with nothing in it reads "Empty".

## The categories

Categories appear in this order. Some are left out while there is nothing to list.

### Player

- Corpse: while you are dead or a ghost, the place where your body lies, if the game reports it on the current map. Press Enter to be guided to it, the usual way to find it on a corpse run.
- Not dead: shown instead while you are alive.
- Graveyards: the graveyards of the map you are on, each with its distance. Open the group to see them.

### Group

Your party or raid members. Each is listed by name. The game only gives a position for group members who are on your map. When you press Enter the navigation window aims at the member's position at that moment. With WowNav on WoW: Forever, WowNav is told which member you chose, so a new route or Ctrl+Shift+N reads the member's position again instead of using the old one; see [WowNav](wownav.md). If the member is no longer on your map you hear "No position of the group member available". The Group category is left out while no member can be placed.

### Quests

Two sub-groups: Nearby and In Progress. These are filled from the quest data your game version offers: see [Quests](quests.md).

Nearby lists quests you could pick up around you, nearest giver first. Each entry shows the quest name, then "Level" and the quest level, whether it is Daily or Repeatable, and the name of the giver. Where a giver is only a seen quest giver (found by the [Minimap Scanner](minimap.md)) the entry shows the giver's name instead, marked seen, quest available or turn in, low level when applicable, and indoors. Press Backspace on a quest to read its objective text. Which quests are listed depends on the Nearby Level Range and Include Repeatable Quests settings; see [Quests](quests.md).

If the data source is still starting, you hear "Loading". Without any data source at all the whole Quests category holds the single line "No quest data source".

In Progress lists your quest log. Each entry shows the quest title with its level ("A Threat Within, Level 5"; the level is the log's, so it can differ a little from the level of a scaled quest) and its state: "Complete", "Failed", or "2 of 3" for how many objectives are done. The list is nearest first, by the place Enter on each quest would take you to, so a quest you can hand in a few steps away comes before one on the other side of the zone; quests with no place to walk to come last. The Sort Quests by Proximity setting turns this off to keep the order of the log; see [Quests](quests.md). Press Backspace to read its objective text. Open a quest to see its objectives:

1. A quest in progress expands to its objectives (only when the data source knows the quest; a quest it does not know shows just its state), for example "Kobold Vermin slain: 3/10". A finished objective is marked "Complete".
2. An objective expands to what it is about: the creatures, objects or item sources that count towards it. An item source is named like "Linen Cloth from Defias Thug". Each of these shows a note: its title, "seen" if the Minimap Scanner found it, "indoors", the number of spawns and, when there is only one spawn, where it is.
3. Something with several spawns expands again to each spawn, named by its place, for example "Valley of the Four Winds, Halfhill Market, 80 yards". A spawn marked phased out is one that probably does not exist for your character right now, but it is kept in case the guess was wrong.
4. A quest that is complete expands straight to the turn-in NPC or object instead, marked "turn in".

So you hear what to look for before you hear where. Example: you have the quest "Wolves Across the Border" with the objective "Prowler slain: 3/10". Land on the quest and you hear its name and "0 of 1" (no objective finished yet). Press Right: the first entry is the objective, "Prowler slain: 3/10". Press Right again: "Prowler, 12 spawns". Press Right once more and you walk through the spawns, nearest first, each with its place name and distance. Press Enter on the one you want.

The quest line and the objective each also carry a position of their own, the first unfinished target, so Enter on the quest itself guides you to the nearest place where you can make progress. A complete quest guides you to its turn-in.

Some objectives name nothing to walk to: an area to explore, a creature the quest data has no spawns for, or a place on another continent. Then WowVision falls back on the game's own quest marker, the area the game shows on your map for the quest's current step, and the entry says "game quest marker". If the game marks nothing, WowVision takes Questie's own map marker for the next open objective, the point Questie shows on your map, and the entry says "Questie marker". If an objective has several Questie markers, it expands to them, nearest first. The game's marker also guides you to the turn-in of a complete quest whose turn-in is not known, and to a quest that Questie does not know. Enter guides you to any of these like to any other place. Only when neither the game nor Questie marks anything does the entry have no place.

### NPCs

- Quest Givers: the NPCs who offer the quests listed under Nearby, each with the number of quests beneath it ("3 quests"). Open one to see its quests. A giver found only by the minimap scan is a single entry marked "seen".
- Role groups: Vendors, Repair, Trainers, Flight Masters, Innkeepers, Bankers, Auctioneers, Stable Masters, Battlemasters, Spirit Healers, Class Trainers, Mailboxes, Other NPCs, Rares. Each lists the NPCs of that kind in your current zone and within the Scan Radius, nearest first.

How many show depends on the data. With a quest database (Questie, see [Quests](quests.md)) all of them can show. Without one, a role group only appears once the Minimap Scanner has seen an NPC of that kind, and the groups for Spirit Healers and Rares never appear. Entries the minimap scan found are marked "seen". An NPC the database already lists is not repeated as seen.

### Points of Interest

The towns and landmarks the last minimap scan saw on the minimap. These are names only, without a position, so Enter does nothing on them. Shown only after a scan found some. See [Minimap Scanner](minimap.md).

### Gathering

Herb, ore and treasure nodes found by the minimap scan, with one group for each tracking ability, named after it, such as "Find Herbs" or "Find Minerals". A group "Unsorted" holds dots from other tracking abilities that could not be sorted. Shown only after a scan found some. Each node is marked "seen" and "indoors" where it applies. See [Minimap Scanner](minimap.md).

### Tracking

This category starts closed. It holds the tracking and map filter choices that a sighted player toggles from the minimap and the world map menus. They are checkboxes: Enter switches the one you are on, and you hear its new state.

- Minimap Tracking: every tracking type of your character, such as Find Herbs, Find Minerals, Auctioneer, Banker, Flight Master, Innkeeper, Mailbox, Repair and Vendors. What you switch on here is what the minimap, and therefore the Minimap Scanner and its walking announcements, can show.
- Map Filter: the world map's filter options: quest objectives on the map, quest levels, quest difficulty colors, dungeon entrances, low level quests and tracked items. The names come from the game. Press Backspace on one to read the game's description of it. A filter that your game version does not have is not listed.

## What Enter does

Enter on an entry that has a position closes the Scanner and starts guiding you. What happens next is the [navigation window](navigation.md):

- If there is route data for the continent you are on, the navigation window opens with the nearest entry point to the route network and your chosen entry already selected as the destination. Press Enter there to start walking the route. It follows the waypoint network and finishes with a straight last leg to the entry.
- If there is no route data, you hear "Beacon set" followed by the distance in yards, for example "Beacon set 40 yards", and a sound beacon guides you in a straight line. When you arrive you hear "Arrived".

With WowNav on (WoW: Forever), an NPC or object that WowNav's own place list knows near that spot is taken from that list: the same creature, or else a place with the same name. The route then knows the target's height and floor, so it leads onto the right floor and ends without the warning that the last stretch is unchecked. A target WowNav does not know is routed to as before.

For a seen NPC found by the minimap scan, arriving also triggers the real-name lookup described in [Minimap Scanner](minimap.md).

## Settings

Open the WowVision menu, then Scanner. See [Menu and Settings](../basics/menu-and-settings.md).

| Setting | Default | What it does |
|---------|---------|--------------|
| Scan Radius | 500 | How many yards around you the role groups and seen entries reach. From 50 to 5000. It does not limit the Nearby or In Progress quest lists. |
| Entries Per Category | 25 | The most entries listed in one group, nearest first. From 5 to 200. |

The related quest settings live in the Quests module: see [Quests](quests.md).

## Example: find a quest giver and go to him

1. Press F9. You hear "Scanner" and the first category.
2. Move to Quests with Down, press Right to open it, then open Nearby.
3. The first entry is the closest quest, for example "A Threat Within, Level 1, Marshal McBride, 40 yards, ahead, 1 of 4".
4. Press Backspace to read what the quest asks of you, then Escape to come back.
5. Press Enter. The Scanner closes and the navigation window opens, or you hear "Beacon set 40 yards" if there is no route data.
6. Walk to the giver. You hear "Arrived".

## Example: corpse run

1. Release your spirit.
2. Press F9. The Player category says "Corpse" with distance and direction.
3. Press Enter to be guided. Follow the beacon or the route.

## Version notes

- Classic Era, The Burning Crusade and Mists of Pandaria: the quest groups and NPC role groups use the Questie addon when it is loaded. Without Questie, WowVision falls back to the game's own quest map data where the client has it, as Retail does; where it does not, you hear "No quest data source".
- Retail: the quest lists come from the game's own quest map data. There are no spawn tables, so each quest entry has a single position, and the NPC groups only list quest givers, who appear as "Quest Giver" at a place rather than by name. There are no role groups.
- WoW: Forever: uses Questie when it is loaded, otherwise the game's own quest data. The game's own quest data is often incomplete there, so the Minimap Scanner fills in quest givers, NPC kinds, gathering nodes and points of interest. See [Minimap Scanner](minimap.md).
- Tracking appears only where the game provides minimap tracking types.
- Graveyards appear when the game can list them for the map.
- Group member positions can only be read where the game exposes them.
- Enter opens the [navigation window](navigation.md) where map data exists for the continent, and falls back to a straight beacon elsewhere.
- The Scanner is also on the controller shortcut layer; see [Controller](../controller.md).

## Related pages

- [Minimap Scanner](minimap.md), which fills Gathering, Points of Interest and the "seen" entries.
- [Quests](quests.md), for quest data and Questie.
- [Navigation](navigation.md), where Enter takes you.
