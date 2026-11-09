# Quests

This page covers everything about quests that WowVision does for you: reading the quest log, reading and answering a quest giver's window, hearing when you enter the area of a quest objective, and finding quest givers and objectives with the [Scanner](scanner.md). It also explains the Questie addon, which supplies most of the quest data on the classic game versions.

## Where quest data comes from

WowVision needs to know where quests start and where their objectives are. It gets that from up to three sources, and uses whichever your game version offers:

| Source | Used on | What it knows |
|--------|---------|---------------|
| Questie (a separate addon) | Classic Era, The Burning Crusade, Mists of Pandaria, WoW: Forever | Everything: every quest in the game, quest levels, giver names, the creatures, objects and items behind each objective with all their spawn points, and the kind of every NPC (vendor, trainer, innkeeper and so on). |
| The game's own quest map data | Retail; WoW: Forever, Mists of Pandaria, Classic Era and The Burning Crusade when Questie is missing and the client has this data | The quests offered on your current map and one point per quest in your log. Givers have no names ("Quest Giver" at a place) and there are no spawn tables. |
| Seen NPCs from the [Minimap Scanner](minimap.md) | WoW: Forever | The quest givers and other NPCs the minimap scan has found since you logged in. It fills the gaps where the game offers no quest data of its own. |

WowVision uses Questie whenever it is loaded and the game's own data otherwise. Where neither exists, the Scanner's Quests and NPCs categories hold the single line "No quest data source". With Questie it always works. Your quest log windows and quest giver windows work without any of these sources. Only finding places needs them.

### Questie: what you need to do

1. Install the Questie addon for your game version and keep it enabled. See [Installation](../getting-started/installation.md).
2. Log in. Questie builds its quest database at login. Until it is ready, quest lists in the Scanner say "Loading" and `/wv quests` says "Questie is still loading". It usually takes a few seconds.
3. Open the Scanner with F9 and look at Quests and NPCs.

What Questie adds that the game's own data lacks:

- Quest names, levels and giver names in the Nearby list.
- For quests in progress, the creatures, objects and item sources behind each objective, with every spawn point.
- NPC role groups in the Scanner's NPCs category: Vendors, Repair, Trainers, Flight Masters, Innkeepers, Bankers, Auctioneers, Stable Masters, Battlemasters, Spirit Healers, Class Trainers, Mailboxes and Rares. Questie's NPC list is indexed in the background after login, so these groups may say "Loading" for a short time.
- Place names for spawns, such as "Elwynn Forest, Goldshire" or "Valley of the Four Winds, near Halfhill, 40 yards".

Questie only includes quests and spawns that exist for your character. Spawns hidden because of the story phase your character is in are listed as phased out; they are kept at the end of the list in case the guess is wrong.

On WoW: Forever, Questie ships a version built on Classic Era data. WowVision prefers it over the game's own quest data, because the game's own quest data is often empty there.

## The quest log window

Open the quest log with the game's own key (L by default). WowVision reads the window that opens on your version. The list and the details are separate tab stops, so press Tab to move between them and the buttons.

In the quest list, Up and Down move between headers and quests. Press Enter on a quest to select it, which fills the details. Press Enter on a header to collapse or expand it. Press the tooltip key to hear the quest's tooltip; see [Tooltips](../basics/tooltips.md).

### The Burning Crusade

(The Burning Crusade only.)

- Quests are read as "[Complete] [Daily] Quest Title". The tags Complete, Failed, Daily and Weekly appear when they apply. The selected quest says "selected". Zone headers say "Collapsed" or "Expanded".
- The details are one group called Details: the quest title, its description, the objectives text and each objective, such as "Kobold Vermin slain: 3/10".
- Buttons follow as their own stops: collapse all, abandon and share, with the game's own captions.
- The game shows only six quests at a time. WowVision scrolls the list for you as you move.

### Mists of Pandaria

(Mists of Pandaria only.)

- The same reading as The Burning Crusade for quests and headers.
- Objective lines follow your progress while the log is open.
- Buttons: abandon, share and track, with the game's own captions.

### Retail and WoW: Forever

(Retail and WoW: Forever.) On these versions the quest log is part of the world map. The key opens a panel beside the map, and WowVision reads that panel.

The panel shows one of two views, as it does on screen: the list, or the details of one quest. The details replace the list.

The list view opens first. Press Tab to move from the quest list to the search box, then the settings, and back to the list.

- The list shows zone headers and quests, under a name that gives your quest count. Press Enter on a header to collapse or expand it. Backspace on a header opens the game's menu with Track All and Untrack All.
- A quest reads like "[12] Wolves Across the Border, Green, selected, tracked". The color word (Grey, Green, Yellow, Orange, Red) is the game's difficulty color for your level, as a sighted player sees it. "selected" and "tracked" are added when they apply, and a tag such as Elite or Dungeon follows the title. A finished quest adds "Complete" after its title, a failed one "Failed", where the game shows its check mark or its red Failed icon.
- Press Enter on a quest to open its details. Backspace opens the game's menu for that quest, with Track, Focus, Share and Abandon.
- Press Right on a quest to reach its Track Quest checkbox. Enter checks or unchecks it. If the game's Show Objectives setting is on, the quest's objectives follow to the right of the checkbox.
- The search box filters the list as you type. Tab into it to start typing.
- Settings opens the game's menu, which holds the Show Objectives setting.

The details view opens on the quest's title. Press Tab to move from the text to the rewards, then to the buttons.

- The Details group reads in the game's order: the title, the objectives text, any timer, each live objective, any required money, the group size, and the description.
- The Rewards group lists everything the quest gives, including items, money and experience. Press Space on an item to read its tooltip. Choosing a reward does not happen here. That happens when you turn the quest in.
- The buttons are one row, so move along it with Left and Right: Back, abandon, track (it reads Untrack when the quest is tracked), share, and the map button when the quest has one. Their captions are the game's own, and the caption is spoken again after you press the button.
- Press Enter on Back to return to the list, on the quest you opened. Shift+Tab from the text reaches Back straight away.

### Classic Era

WowVision has no quest log window for Classic Era, so the game's own quest log is not read there. With Questie installed you can still read your quests through the [Scanner](scanner.md), under Quests, In Progress.

The quest log windows above are left to Sku when the Sku addon is loaded alongside WowVision.

## Quest giver windows

When you talk to an NPC who has quests, the game opens a quest window. WowVision reads whichever page of it is showing. The window's title is the NPC's name. On the details, progress and reward pages the text is one list in one tab stop, followed by its buttons as separate stops, so one Tab takes you from the text to the buttons. On the greeting page the greeting text is one stop and each quest is a stop of its own.

| Page | What you hear | Buttons |
|------|---------------|---------|
| Greeting (the NPC has several quests) | The greeting text, then Quests: each as "Available Quest: Title" or "Accepted Quest: Title" | Goodbye |
| Details (a quest is offered) | Details: title, description, objectives header, objectives, then the rewards | Accept, Decline |
| Progress (you come back unfinished or finished) | Progress: title, text, and the items still required | Continue, Goodbye |
| Reward (turn-in) | Reward: title, text, and the rewards | Complete Quest, Cancel |

The buttons are the game's own, with the game's captions, which may differ slightly from the ones above.

Rewards are read in groups:

- A list of choices, introduced by the game's own sentence ("You will be able to choose one of these rewards"). Each choice reads as the item name, with " x 5" after it when you get several.
- A list of items you receive.
- Money and experience, as plain lines.

To pick a reward, press Enter on the item you want. That is a real click, so the item becomes selected. Then Tab to Complete Quest and press Enter. Item tooltips work with the tooltip key.

A quest giver may offer quests through the gossip window first; those entries are read as "Available Quest: Title" and "Accepted Quest: Title" as well. See [NPC windows](../windows/npcs.md).

If Sku is loaded, WowVision leaves this window to Sku.

### Quest choice dialog

(Mists of Pandaria only.) Some quests that offer a choice between several options show a Quest Choice window instead. It reads the question, then each option as its own tab stop: the option text, the reputation, item and currency rewards it gives, and its choose button. A final Close button leaves the window without choosing.

## Quest area alert

When you walk into or out of the shaded area where a tracked quest's objectives are, WowVision tells you:

- "Entering area: Wolves Across the Border"
- "Leaving area: Wolves Across the Border"

This works for quests you are tracking, and also in combat. A quest announces each state only once, so you do not hear a repeat.

During a minimap scan the area alert is silenced for a moment. The scan switches tracking on and off, which the game would otherwise report as leaving and entering every area.

The alert is the Quest Area Alert in the Quests module. See [Alerts](../basics/alerts.md) for how alerts work.

| Setting | Default | What it does |
|---------|---------|--------------|
| Quest Area Alert, Enabled | On | Switches the announcement on or off. |
| TTS Alert, Enabled | On | Speaks the announcement. |
| TTS Alert, Priority Message (interrupts) | Off | When on, the announcement cuts off what is being spoken. |
| TTS Alert, Voice | Follows your Speech Voice | Choose a voice for this alert alone. |
| Sound Alert, Enabled | Off | Plays a sound instead of or besides the speech. |
| Sound Alert, Sound | none | Which sound to play. |

## Quest progress alerts

The game shows quest progress as a message in the middle of the screen. WowVision speaks those messages as the game words them, and plays a sound for what happened, with three alerts of their own:

- Quest Progress Alert: a count moves, for example "Kobold Vermin slain: 3/8" or "Linen Cloth: 2/6". Its sound is success1, the one Sku plays.
- Objective Complete Alert: an objective is done, for example "Explore the Mine (Complete)", or the game's "Objective Complete." message, which names no objective. Its sound is objective_complete.
- Quest Complete Alert: every objective of a quest is done, so it is ready to hand in. Its sound is success2, the one Sku plays, and it plays in place of the objective's sound. The game sends no message for this, so WowVision reads it from your quest log. Its speech, the quest's title and "Complete", starts switched off, because you already hear the game's line for the last objective.

The game's line is spoken at once. When an objective is done, its sound waits a moment, less than half a second, to learn whether that finished the quest. Each alert has TTS and Sound and can be switched off on its own. They work whatever the Errors module does, also with it switched off, and these messages do not appear in its Per-Error Filter. If you had muted one of these messages there, or switched Announce Errors off, its alert starts switched off. See [Alerts](../basics/alerts.md).

## Finding quests and objectives

The [Scanner](scanner.md) turns quest data into places you can walk to. It is the main way to find quests with WowVision.

- Quests, Nearby: quests you can accept around you, nearest giver first.
- Quests, In Progress: your log. Each quest the data source knows opens to its objectives, each objective to the creatures, objects and item sources it is about, and each of those to its spawns.
- NPCs, Quest Givers: the same givers, grouped by NPC.

Enter on a quest, an objective, a target or a spawn guides you to its place. See [Navigation](navigation.md).

How places are described in the lists: a spawn reads with its zone, then the best hint WowVision has for the place inside the zone. If a landmark on the map, such as a town or camp, is within about 600 yards, the spawn reads "near Halfhill, 40 yards", or just "Halfhill, 40 yards" when the explored map also names the spot Halfhill. If the quest data names the subzone, it is named first. If no landmark is close, the area name of the explored map is used. This is a description to help you picture the place, not an exact address.

## Settings

Open the WowVision menu, then Quests. See [Menu and Settings](../basics/menu-and-settings.md).

| Setting | Default | What it does |
|---------|---------|--------------|
| Nearby Level Range | 5 | The Nearby list hides quests that are more than this many levels below your level. From 0 to 60. Set 60 to see every quest, or 0 to see only quests at or above your level. |
| Include Repeatable Quests | On | Whether repeatable and daily quests appear in the Nearby list. |
| Sort Quests by Proximity | On | Whether the In Progress list is nearest first, by the place Enter on each quest would take you to (the next open objective, or the turn-in once a quest is complete). Quests with no place to walk to follow, in the order of your log. Turn it off to keep the order of the log. |
| Quest Area Alert | see above | Announcements when entering or leaving an objective area. |
| Quest Progress Alert, Objective Complete Alert, Quest Complete Alert | see above | Announcements of quest progress. |

The Nearby list also leaves out quests you cannot take yet, because of your level or a missing prerequisite.

## Example: work through a quest

1. Walk to a quest giver. The game opens the quest window. You hear the NPC's name, then "Quests" with "Available Quest: A Threat Within" or the details of the single quest.
2. Press Down to read the description and objectives. Press Tab, then Enter on Accept.
3. Press F9, open Quests, then In Progress. The quest is listed, "A Threat Within, 0 of 1". Press Right to open the objective and Right again to see what to kill, then press Enter on a spawn to be guided there.
4. In the field, you hear "Entering area: A Threat Within" when you reach the objective area.
5. When the objective is done, the quest reads "Complete". Press F9, open it, and press Enter on the turn-in. Talk to the NPC, press Tab to Complete Quest, choose a reward if there is a choice, then Enter.

## Diagnostic commands

Useful for bug reports. Output goes to the chat window.

| Command | What it does |
|---------|--------------|
| `/wv quests` or `/wv quests near` | Lists up to ten nearby quests with level, giver and distance. |
| `/wv quests log` | Lists your quest log with each quest's state and objectives. |
| `/wv quests go ID [start\|objectives\|finish]` | Lists where quest number ID sends you for that phase. Default is `objectives`. |
| `/wv quests raw [mapID]` | Dumps what the game's own quest data says for a map. Only where the game's own data is the source. |
| `/wv quests probe` | Runs a three second test of every quest and map data source the game offers, opens the report in a copyable window and saves it for the bug report. It speaks "Quest probe running, 3 seconds" and then a short summary. |

Messages you might hear: "No quest data source", "Questie is still loading", "No nearby quests", "No quests in progress", "No targets".

## Related pages

- [Scanner](scanner.md) and [Minimap Scanner](minimap.md).
- [Navigation](navigation.md) for what happens after Enter.
- [NPC windows](../windows/npcs.md) for gossip, merchants and trainers.
- [Alerts](../basics/alerts.md).
