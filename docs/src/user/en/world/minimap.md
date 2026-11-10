# Minimap Scanner

A sighted player sees quest givers, vendors, herbs and ore as dots on the minimap. WowVision cannot look at the minimap picture, but it can ask the game what every dot is called. The Minimap Scanner does exactly that: it finds the named dots around you, sorts them by kind, works out roughly where each one is, and lists them in the [Scanner](scanner.md) so you can walk to them. It can also announce new dots as you walk past them.

(Retail and WoW: Forever.) The scanner needs minimap functions that only the newer game clients offer. The Classic clients do not have them: on Classic Era, The Burning Crusade and Mists of Pandaria the scan key answers "Minimap scanner not available on this client", and the walking announcements never start.

## What it finds

The minimap only shows what your character can currently see on it. The scanner reads exactly that, so what it finds depends on your tracking.

- Quest givers. Every dot of an NPC who offers or takes in a quest. The scanner also tells you whether the giver offers a new quest or takes one in (see "Quest givers" below).
- Townsfolk, by tracking type. The scanner switches each of your minimap tracking types on for a moment and notes which new names appear. That sorts the names into these kinds: Auctioneers, Bankers, Battlemasters, Flight Masters, Vendors (food, ammunition, reagent and poison vendors), Innkeepers, Mailboxes, Class Trainers, Trainers (profession trainers), Repair, Stable Masters, and Other NPCs (barbers, transmogrifiers, item upgrade NPCs). You only get a kind if your character has that tracking type. Most of them every character has.
- Gathering nodes. Herbs, ore veins and treasure chests, but only while the matching tracking ability is switched on: Find Herbs, Find Minerals or Find Treasure. See "Gathering nodes" below.
- Points of interest. The towns and landmarks the minimap draws as arrows, such as Goldshire or Stormwind. These are only names with no position, because the game draws those arrows at a fixed distance in the direction of the place.
- Other tracking. If you have a different tracking ability on, for example Track Beasts or Track Humanoids, its dots cannot be sorted by name. They are listed as Unsorted, in the Gathering category of the Scanner. While such a tracking ability is on, the scanner also cannot tell those dots from quest givers, so quest givers without a special tracking type land in Unsorted too.

The scanner sees dots out to the minimap's range: about 233 yards outdoors and 150 yards indoors. Indoors the minimap shows only the building you are in, so an indoor scan only knows that building. The game switches the minimap to its indoor view not only in houses but also in some covered streets, for example parts of Stormwind; WowVision notices that and treats it as indoors.

Names that are titles of quests in your quest log are left out. The minimap draws them as the quest's area or as an arrow at its edge pointing towards it; WowVision already has those quests with their real places under Quests, In Progress in the [Scanner](scanner.md).

## Scanning: Ctrl+Shift+F

Press Ctrl+Shift+F (Scan Minimap) to scan once. The binding can be changed in the keybinding window; see [Keybindings](../basics/keybindings.md). You can also type `/wv mscan`.

You will hear "Scanning minimap" and the result, after a second or two when nothing is new, and up to about six seconds when there is a lot new to place. For example:

- "Scan done, 4 new: 1 Points of Interest, 1 Innkeepers, 2 Quest Givers"
- "Nothing new nearby"

The result counts only entries that are new since the last scan. If entries that were on your list have vanished (a herb you picked, a quest you took), the result adds how many are gone, for example "Scan done, 1 new: 1 Find Herbs, 2 gone". If you scanned indoors it ends with "indoors, this building only".

### Before you scan

A scan temporarily takes over the minimap and the mouse cursor, so a few things must be true. Otherwise the scan refuses or stops:

- Stand still. "Stand still to scan" if you are moving.
- Not in combat. "Not in combat".
- No mouselook. "Stop mouselook to scan" if you are steering with the mouse.
- Close every window. The mouse cursor must rest over the game world, not over a window. By default the scan moves the cursor to the middle of the screen itself (see Centre Mouse Cursor Before Scanning), so any window open at the screen centre blocks it. The message names the window in the way: "Scan canceled, window: " followed by the window's name. Close the window with Escape and scan again.
- Be somewhere with a position. "No position here" appears in places the game cannot locate you, for example some instances.
- Nothing on the cursor. While a spell waits to be placed on the ground, something is held on the cursor or a mouse button is down, the scan does not start: "Scan canceled, targeting" or "Scan canceled, mouse".

Once a scan runs, do not move, turn, use the mouse or enter combat until it ends. Any of these stops it with "Scan canceled, moved", "Scan canceled, turned", "Scan canceled, mouse", "Scan canceled, mouselook" or "Scan canceled, combat". ("Turned" can only happen if the game's Rotate Minimap option is on.) Nothing half-measured is kept, so just scan again. If you press the key during a running scan you hear "Scan already running".

While it runs, the scan briefly switches your tracking types on and off and moves and shrinks the minimap, then puts everything back. Meanwhile the minimap takes no clicks (a click would ping the spot for your group) and its tooltip stays hidden. Quest-area announcements are silenced until it is done. If a tracking type did not come back, WowVision tells you: "Tracking not restored" followed by its name. Switch it on again in the [Scanner](scanner.md) under Tracking.

If something goes wrong inside the scan, you hear "Minimap scan failed".

### Where the results go

Scan results are not spoken one by one. They go into the [Scanner](scanner.md) (F9) and stay there until you log out or `/reload`. The scan gives each entry a position to within a few yards. Which category an entry lands in:

| Kind | Where you find it in the Scanner |
|------|----------------------------------|
| Quest givers | Quests, Nearby; and NPCs, Quest Givers |
| Auctioneers, Bankers, Battlemasters, Flight Masters, Vendors, Innkeepers, Mailboxes, Class Trainers, Trainers, Repair, Stable Masters, Other NPCs | NPCs, under the kind's name |
| Gathering nodes and Unsorted | Gathering |
| Points of Interest | Points of Interest |

Every entry found this way is marked seen in the list, and indoors if it is inside a building. If your quest database already knows an NPC of the same name (see [Quests](quests.md)), the database entry is shown and the seen one is left out.

### Quest givers

A quest giver found by the scan reads as "seen" with one of two states:

- quest available: the NPC offers a quest.
- turn in: you have a finished quest and this NPC is where it is handed in. WowVision recognises this because the game moves a finished quest's map marker onto its turn-in NPC.

If the quest giver is only shown because of the "low level quests" tracking option, it is also marked low level. The game draws the same dot for a quest that is still a level or two out of reach, so "quest available" is a good hint, not a promise.

### Real names on arrival

On the newer clients some NPCs show their title as the minimap name, for example "Skinning Trainer" instead of the person's name. When you arrive at a seen NPC by following a beacon from the Scanner, WowVision looks at the NPCs around you and, if one carries that title, says its real name followed by the name the minimap showed, for example "Olivia Burnside, Skinning Trainer". The real name is remembered for the session, and Enter on the same entry later speaks it again on arrival.

This only works for NPCs the game lets WowVision read, which are your target, your soft target and NPCs with a nameplate. The game hides friendly NPC nameplates by default. If the scanner needs them it tells you once: "Turn on friendly NPC nameplates to learn NPC names". Switch on the game's friendly NPC nameplate option if you want real names.

### Gathering nodes

Herbs, ore and treasure are recognised by name, because the minimap draws all of them as plain dots. The scanner has name lists for the nodes from Classic Era up to Wrath of the Lich King, in English, German and French. A name only has to contain a listed name, so variants like a withered version of a herb still count. Clients in other languages use the English names.

- Find Herbs lists herbs such as Peacebloom, Silverleaf and Kingsblood.
- Find Minerals lists veins and deposits such as Copper Vein and Mithril Deposit.
- Find Treasure lists chests such as Solid Chest.

You must switch the tracking ability on yourself, either from the game's minimap tracking button or in the [Scanner](scanner.md) under Tracking, Minimap Tracking. The scan never switches these abilities for you, because switching them casts a spell. In the Scanner the nodes appear in a Gathering category with one group per ability, named after it (for example "Find Herbs").

Nodes added in later expansions are not in the lists, so the scanner does not recognise them as gathering nodes. It then treats such a node like a quest giver and lists it among the quest givers (or under Unsorted, if another tracking ability such as Track Beasts is on).

## Walking announcements

While you walk, run or fly, WowVision looks at the minimap twice a second and announces names that come into range. This is how you hear a herb, a mailbox or a quest giver appear while you travel. It is switched on by default.

Each announcement is the name, then extras when they apply:

- above or below: the dot is on a different height than you, for example a herb on a cliff above or a node under water.
- indoors: the dot is inside a building or underground.
- the kind: either "quest giver" or the name of the tracking type that shows it, for example "Find Herbs" or "Banker". The kind is only added after a scan has sorted that name. Until then you hear just the name.

Examples:

- "Peacebloom" (no scan yet)
- "Peacebloom, Find Herbs" (after a scan sorted it)
- "Copper Vein, below"
- "Olivia Burnside, Banker"
- "Marshal McBride, quest giver"
- "Innkeeper Farley, indoors, Innkeeper"

Each name is spoken once. It is spoken again only after you have walked far enough away that the dot was out of range, so a flicker at the edge of the minimap never repeats it. If WowVision could not place a dot, for example because it is a town arrow, it falls back to this rule: after 30 seconds of walking outdoors without that name in view it counts as gone.

The announcements use the tracking types you have switched on yourself. They never change your tracking. They are skipped while you stand still, are in combat, are steering with the mouse, a scan is running, or a window sits under the mouse cursor. The first time it runs in a session, the mouse cursor is moved to the screen centre as well (see Centre Mouse Cursor Before Scanning).

Announcements use a game voice of their own, voice 0 unless you pick another, and not your screen reader's voice. Screen readers cut their own speech off at every key press, which would clip announcements while you walk. Change the voice in the alert settings below.

## Settings

Open the WowVision menu, then Minimap Scanner. See [Menu and Settings](../basics/menu-and-settings.md) for how settings work.

| Setting | Default | What it does |
|---------|---------|--------------|
| Announce Tracked Dots While Walking | On | Speaks new dots while you move. Turn it off to scan only on request. |
| Centre Mouse Cursor Before Scanning | On | Before a scan, and before the first walking check of a session, the game's mouse cursor is moved to the screen centre for a tenth of a second, so the minimap can be read under it. Turn it off only if you always keep the cursor at the centre yourself. If the cursor is not over the game world, scanning fails with "window". |
| New Minimap Dot Alert | see below | The alert that speaks the walking announcements. |

### New Minimap Dot Alert

This is a standard WowVision alert; see [Alerts](../basics/alerts.md) for how alert settings work. Open it from the Minimap Scanner settings.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled | On | Switches all walking announcements on or off. |
| TTS Alert, Enabled | On | Speaks the name with a text to speech voice. |
| TTS Alert, Voice | Game voice 0 | Which game voice speaks. It does not follow your Speech Voice setting. The first voice has the number 0. |
| Sound Alert, Enabled | Off | Plays a sound for each new dot. |
| Sound Alert, Sound | none | The sound to play. Pick one before enabling the output, or nothing plays. |

The same text is spoken either way. The scan result messages ("Scan done ...") are not part of this alert. They are spoken like any other WowVision message, with your normal speech voice.

## Example: find the herbs around you

1. Open the Scanner with F9, move to the Tracking category, open Minimap Tracking and switch on Find Herbs with Enter. Close the Scanner with Escape. (A herbalist can also use the game's tracking button.)
2. Stand still and press Ctrl+Shift+F. You hear "Scanning minimap", then for example "Scan done, 3 new: 3 Find Herbs".
3. Press F9 and open the Gathering category, then Find Herbs. Each herb is listed with its distance and direction, for example "Peacebloom, seen, 85 yards, ahead left".
4. Press Enter on one. The [navigation window](navigation.md) opens, aimed at the herb.
5. Walk. While you walk, any further herb coming into range is announced: "Silverleaf, Find Herbs".
6. After you pick the herb, scan again. The result says "Nothing new nearby, 1 gone" or similar, and the herb disappears from the list.

## Example: a quest hub in a new area

1. Arrive at a town and stand still. Press Ctrl+Shift+F.
2. You hear something like "Scan done, 9 new: 1 Points of Interest, 1 Innkeepers, 1 Flight Masters, 1 Mailboxes, 5 Quest Givers".
3. Press F9, open Quests, then Nearby. The seen quest givers are listed nearest first, each marked "seen, quest available" or "seen, turn in". Press Enter on one to go there.

## Diagnostic commands

You only need these for bug reports.

| Command | What it does |
|---------|--------------|
| `/wv mscan` | Same as Ctrl+Shift+F. |
| `/wv mscan list` | Opens a copyable window listing every seen entry with category, distance and map position. |
| `/wv mscan clear` | Forgets every seen entry and the walking memory. You hear "Seen entries cleared". |
| `/wv mscan log` | Shows how the last scan went and the log of the walking announcements. The log is also saved in the saved variables file after `/reload`. |
| `/wv mscan walk` | Shows what the walking check currently remembers. |
| `/wv mscan raw` | Takes one unprocessed reading of the minimap for debugging, for the day the game changes the way dots are named. After /reload the result is in the file `WTF\Account\<account>\SavedVariables\WowVision.lua` (WowVisionDump, minimapRaw), which you can send instead of copying the window. |
| `/wv mscan sku` | Measures the scanner's ways of reading the minimap on the spot where you stand (takes about half a minute; stand still): the view radius, one read of the shrunk minimap, and the scan's and the walking check's searches, each compared with a slow full-size one. The result opens in a window and is saved as WowVisionDump, minimapSku. |

## Related pages

- [Scanner](scanner.md), where the results are listed.
- [Navigation](navigation.md), for walking to an entry.
- [Quests](quests.md), for how seen quest givers join the quest lists.
- [Alerts](../basics/alerts.md) and [Speech](../basics/speech.md), for voices.
