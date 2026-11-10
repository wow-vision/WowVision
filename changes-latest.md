### Summary
The minimap scanner works again on WoW: Forever after the game update of 7 November. Also new: a Scanner you can use as a menu, quest sounds while you walk, letter filters in lists, tooltips that compare gear and show auction prices, rebuilt WowNav data for the capital cities, and many fixes.

The full manual is online, in English and German: [WowVision documentation](https://wow-vision.github.io/WowVision/).

### All Versions
* Scanner: switch off the new Scanner as Tree setting (Scanner menu, on by default) to use the scanner as a menu like the WowVision menu: Enter or Right goes one level deeper, Left or Escape goes back, letters jump to entries.
* Scanner: Shift+Down on a quest in Nearby or In Progress reads a full tooltip: the level with the quest colour, the kind of quest, the giver or your progress per objective, and the quest text.
* Chat: a new setting, Addon Messages in Chat (off by default), also writes WowVision's own messages to the main chat tab with "WowVision:" in front: a route started, how far a scan is, why something did not work. They are not spoken a second time.
* Wall detection: no more blocked sound every half second in a fight when you are not holding a movement key, after the interact key walked you into melee.
* Targeting: with Soft Targeting With a Hard Target on one of the Only Without modes, the soft enemy name no longer repeats many times a second. A target the game set by itself from your soft target no longer counts as a hard target.
* Scanner, Quests, In Progress: quests now read with their level ("A Threat Within, Level 5") and sit under their quest log zone (Elwynn Forest, Westfall), one more level. Inside a zone the nearest quest comes first, by the place it guides you to. The new Sort Quests by Proximity setting (Quests menu, on by default) turns the ordering off to keep the order of the log inside each zone.
* WowNav: creatures and objects in the destination list and the route announcements are named in your game language from Questie's database where it knows them (the WowNav data only has English and German), titles included, so searching for "aubergiste" or "cuisinier" works on a French client. New setting Names in Your Language (WowNav Routes menu, on by default).
* Sound: the new WowVision Sound Channel setting (UI menu) picks the game sound channel WowVision's sounds play on, so that channel's volume slider in the game's sound options sets WowVision's volume. Sound Effects stays the default. Retail and WoW: Forever also offer Gameplay Sound Effects.
* Navigation: a new Beacon Volume setting turns the beacon ping down, while near and far still sound different. The Navigation menu's Maps entry is now called Beacon and Routes; its Enabled switch turns off routes and the beacon keys as well as the beacon.
* Quests: the game's quest progress messages have alerts of their own in the Quests module. A count moving plays Sku's progress sound, an objective done plays a new objective sound, and a quest with every objective done plays Sku's quest complete sound instead. They work with the Errors module switched off, and a message you had muted there stays muted.
* Quests: new Nearby quest sounds (Quests menu, Nearby, on by default). Walking around, you hear a directional ping from a quest you can accept, a quest you can hand in, and an open quest objective, each with its own sound, volume, range and Play Once setting; spoken text is there too, off by default. They are quiet in combat, when dead and on a flight path. They use Questie's data, so they play where Questie is loaded. Holiday quests only count while their event runs, which also keeps them out of the Scanner's Nearby list out of season.
* Lists: two different letters typed quickly filter the list, as in Sku: a filter line comes first and only the matching entries follow. Further letters narrow it; Backspace or Left Arrow brings the whole list back; Enter on an entry, or going a level deeper, ends the filter.
* Letters in every window: a new Letter Navigation switch per window, off by default (F10 in the Navigation menu, the Scanner in the Scanner menu, game windows in their entry under Windows). Switched on, every list in that window takes letters and filters, and while such a list is open the letter keys belong to it, so they do not walk your character. In F10 the letters cover all destinations; in the chat window they jump between lines.
* Lists: umlaut keys work for letter navigation. Ü finds only Ü, U finds both.
* Menus: Right Arrow opens the next level and Left Arrow goes one level back, never out of the menu, in the WowVision menu, context menus and dropdown menus.
* New key Close All Windows (Shift+Escape): closes every WowVision window and every game window. A popup waiting for an answer stays open, and so do protected windows in combat. Starting a route or beacon does the same; the new setting for it in the Navigation menu is on by default.
* Scanner: quest progress in Quests, In Progress stays current while the Scanner is open. Backspace on a category, or Navigate to Nearest in its context menu, goes to the nearest entry in it.
* Navigation window (F10): Shift+F10 on a destination offers Auto Direct and Auto Route, which lead you to every unvisited destination of that name in turn. They need Visited Waypoints switched on.
* Visited waypoints: the key Route to the Nearest Unvisited of the Same Name now takes the one with the shortest walk among the nearest, as Auto Route does. Both next-spot keys remember the spots they already led you to, so they no longer send you back to one you left before reaching it. Pressed while Auto Direct or Auto Route is running, they move that chain on to its next spot.
* Navigation: Reverse Route (Ctrl+Shift+R) now walks back from where you are, along the route from its destination to its start.
* Buffers: new settings Always Start at Top (off by default) and Sounds When Opening and Closing (on by default).
* Quest log: new setting Always Start at Top (off by default), which opens the quest log on its first entry instead of the selected quest.
* UI menu: a new Apply Recommended Game Settings button, only a suggestion, turns on auto loot and all action bars and, where the game has it, sets up the game's Audio Assist (your health, target health and resource every 20 percent, and when you are targeted). It does nothing in combat, and reloads the interface after a change.
* Item tooltips: with the Pawn addon installed, the tooltip ends with Pawn's upgrade summary, one line per scale the item upgrades ("Pawn: Hunter: Marksmanship, upgrade of 12 percent, over Rusty Helm"). These replace the upgrade lines Pawn writes itself. The Pawn Summary checkbox under UI, Tooltip, Compare turns it off.
* Item tooltips: gear is compared with what you wear in that slot. Space still reads only the item; Shift+Down walks on into the comparison. The new Compare With Equipped Item setting under UI, Tooltip, Compare picks the comparison: Game (the default) reads the game's own comparison, the one sighted players get on Shift; WowVision says only what differs, spelled out ("Armor: 10 more", "Intellect: 4 less"); None turns it off.
* Tooltips: two new unbound keys, Previous Tooltip Block and Next Tooltip Block (Ctrl+Shift+Up and Ctrl+Shift+Down in the manual), jump between the item, each equipped item and the stat changes.
* Bags, bank and action bars: with the new Skip Empty Slots on Double Arrow setting (UI menu, off by default), pressing the same arrow twice quickly skips the empty slots to the next filled one.
* Windows land on their content: the profession recipe lists and the spellbooks open on the list, the game's settings panel on its search box.
* Search boxes now sit right before what they search, after the filters and options: trade skill windows and bags.
* Navigation window (F10): Backspace on a destination always sets a direct beacon; Enter routes.
* Quest window: the reward you picked reads Selected and Complete Quest names it. Focusing Complete Quest no longer scrolls the rewards.
* Scanner: every category is always there, in the same place; an empty one says Empty and does not open.
* Scanner: Player starts with your own character: name, level, race, class and guild. Group members read the same. After the name comes the zone the character is in ("Bert, Westfall, Level 60, Human, Warrior"). Enter on your own name targets you; Enter on a group member opens the navigation window aimed at them, or says Position unavailable when the game gives none.
* WowVision's own windows (the menu, the Scanner, navigation, action bars, chat) play a sound when they open and another when they close. The new setting Sounds on Opening and Closing WowVision Menus (UI menu, on by default) turns them off.
* Targeting: the Target in Combat sound also plays when only your group is fighting your target.
* Loot: Ctrl+Alt+Y reads the whole tooltip of the item up for a roll, not only its name.
* Wall detection: no more Blocked sound during a fight while the game walks you after the enemy you attack with the interact key.

### Classic

#### The Burning Crusade Classic
* Auction house: the scan result and the full scan cooldown times are now fully translated.

### Modern
* Minimap scanner (WoW: Forever): works again. Since the game update of 7 November (build 1.60.1.70862) the scan said "Nothing new nearby" and walking announced nothing, because the game function it asked (Minimap:UpdateMouseoverAtPoint) does nothing any more. The scanner now moves the minimap under the resting cursor and reads what the game names there, the way Sku does. A scan takes up to about six seconds when much is new. Walking announcements tell several dots of one name apart (mailboxes, herbs) and stay quiet when you only step into or out of a building or a covered street. Quest titles from your quest log are no longer listed as quest givers. While the scanner reads the minimap, it takes no clicks and shows no tooltip, and nothing starts while you place a spell on the ground.
* Auction house: a Full Scan records the prices of the whole auction house. It is off by default; turn on Full Scan under Windows, Auction House, and the button is the last stop on the Buy tab. The game allows one scan every 15 minutes.
* Item tooltips: with Full Scan on, tooltips end with the minimum, average and maximum auction price over up to 30 days, the vendor price per item, and what a vendor charges. The Tooltip Prices checkbox turns the lines off.
* Trainer: Train works as soon as the window opens, and pressing it again and again learns everything in turn.
* Cooldown manager: the window no longer closes itself when the game shows no tabs.
* Quest log: a finished or failed quest says Complete or Failed after its title.

#### Forever
* Target Names: NPC titles such as Innkeeper are read again.
* Search boxes sit right before what they search in crafting, talents, collections, challenges and Who. The spellbook goes tabs, spells, then search and options. The Social window opens on its list.
* Quests: a quest whose area lies in another zone now has a point to navigate to, from the game's world map.
* WowNav data: Stormwind, Ironforge, Undercity, Darnassus, Orgrimmar and Thunder Bluff are rebuilt, and the start zones updated again. The Deeprun Tram is linked like the Sku data, so a route between its two stations follows the tunnel.
* WowNav routes: a route now picks the cheapest pair of checked entry points near you and near the target, so it no longer starts or ends with a detour to a worse one.
* WowNav: new destinations for the central points of caves and for quest exploration objectives.
* Training: the hunter's Beast Training window is now read. It is named after your pet, reads the training points left, and says each skill's cost in training points.
