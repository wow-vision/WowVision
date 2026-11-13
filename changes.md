# Changes

## V1.0.3

### Summary
The Minimap Scanner is switched off for now on Retail and WoW: Forever: a change by Blizzard broke the minimap reads it depends on. New in this version: WowNav runs on rebuilt map data for every zone, Turn to Target and Turn to Focus turn you to face a unit, a Breath Alert tells you how much air is left, Page Up and Page Down turn pages, group invitations that ask for your role are read, monitors and buffers can be copied, the enemy count in a group starts earlier, and errors in dungeons no longer stop menus and windows.

The full manual is online, in English and German: [WowVision documentation](https://wow-vision.github.io/WowVision/).

### All Versions
* Group invitations that ask for your role (Retail and WoW: Forever, for example from a group finder group) are read: the invitation line, the queue warning, the role checkboxes, Accept and Decline. Before, this window was silent and the invitation ran out. /wv accept and the Accept Group Invitation key accept it with the checked role.
* Bags: the drag key on a bag slot places the bag you are holding, replacing the one in the slot, as Enter does. Before, it only picked up the bag that was in the slot.
* Lists: with the new Sound at the Start and End of Lists setting (UI menu, on by default), Up on the first entry or Down on the last entry of a list plays a short sound and reads the entry again, as in Sku.
* Navigation: new Breath Alert for the breath, fatigue and feign death bars. It speaks the bar's name and how full it is, one line per step down ("Breath 90", "Breath 80", down to "Breath 0"); the Breath Step setting chooses steps of 5, 10, 20 or 25 percent. The Compass screen in the Navigation menu is now called Environmental Alerts, as it holds this and the zone, indoors, flying, swimming and diving alerts; saved settings carry over.
* Paged windows: Page Up and Page Down turn the page while you are on the paged content: the spellbook, the merchant, the mailbox, books and letters, and on WoW: Forever the toy box, heirlooms and appearances. They press the window's own Previous Page and Next Page buttons and put you on the first entry of the new page. The page buttons stay where they were.
* Errors: one part of WowVision that fails no longer stops the rest. Before, an error that repeated every frame (for example a range check in a dungeon) left menus and windows dead until a reload; now the error is still reported, once instead of every frame, and everything else keeps working. The spoken Lua error alert says each error at most once every 5 seconds, also when two errors take turns.
* Range checks: WowVision's copy of LibRangeCheck is now the current upstream version with our fixes, and it is used by every addon that embeds the library. Another addon's older copy can no longer throw errors every frame in dungeons. In dungeons a new target no longer gets the old target's range for a moment.
* Monitors: Announce on Target Change is now a choice of Only Changes (the default, what off did before), Always (what on did before) and Never (a target change is silent; later changes on the new target speak as usual). Saved settings keep their meaning.
* Context menu: Copy on a monitor, a rule, a buffer group or a buffer adds a full copy right after it ("Moonfire Copy 1"), in the same scope; a copied monitor brings its rules.
* Monitors: adding, copying or removing a rule no longer makes every rule of the monitor say its current state again.
* Enemy count: in a group, an enemy fighting your group counts at once, before you join the fight yourself; before, the game kept its threat list from WowVision until you were in the fight, often several seconds. It counts while you, your pet or a group member is in combat and no one outside your group has tapped it, so while nobody in your group is fighting, an enemy that attacks a player outside your group before they hit it does not count. A new number is now said once it held for 0.3 seconds instead of half a second (the length of Sku's wait for a pack; the wait starts again at every change, so a pack that comes in one after another is said 0.3 seconds after the last enemy). A number that an interrupting alert (such as a target change) threw out of the speech queue before it was spoken is said again once when no newer number came within 5 seconds and the count still stands; only the spoken number is repeated, not the voice pack's; before, the old number stood until the count changed, in long fights up to a minute. In a group, enemy players in combat near your fighting group count too, also those fighting someone outside it (the game never marks a player as tapped): in PvP a wider picture of the enemy players around you.
* Recommended game settings: Apply Recommended Game Settings also turns on offscreen nameplates, so while enemy nameplates are shown, an enemy behind you or beside you gets its nameplate at once and the enemy count can say it without waiting for the camera to face it. Enemy nameplates themselves are not switched on by it.
* Navigation: Turn to Target (Ctrl+I) and Turn to Focus (Ctrl+U) turn your character to face your target or focus, found by its nameplate, for example to follow an escort NPC. Apply Recommended Game Settings now also switches friendly NPC nameplates on.

### Modern
* Quest log: Escape on a quest's details goes back to the quest list, as the Back button does. Escape on the list closes the log as before.
* Group health: a number in the urgent part of the scale is no longer cut off at its end (Hedda, Katja and voices without a profile of their own).
* Cooldown Manager Auras monitors: a monitor on Target now hears your own auras while you target yourself. Before, it reported them as Missing, because the cooldown manager labels an aura on you as Player even when you are your own target. In instances, where the game may hide whether you are your own target, the last answer it could read since your target changed holds.
* Cooldown manager (/cdm): the manual explains the game's Lua error when you move an item while a buff the cooldown manager tracks is on you. The change is still saved; make such changes with no tracked buffs on you, and reload before combat, or the next buff in combat brings the same error.
* Dungeons: a menu entry or target name the game keeps hidden no longer causes an error; it is spoken as the game gives it. Typing letters in a list skips such entries. Target names read quest objectives in dungeons too. There the game hides whether an objective is finished, so each objective is read and its count says how far it is.
* Minimap Scanner: switched off for now. A change by Blizzard broke the minimap reads it depends on. The scan key (Ctrl+Shift+F) and /wv mscan say "Due to Blizzard restrictions the minimap scanner is unavailable.", and the walking announcements do not run.

### Forever
* WowNav data: all zones are rebuilt on new map data. New stair logic, a repaired Deeprun Tram.
* WowNav routes: every target of a rebuilt zone now has its own point in the network, and a route to it ends exactly there instead of a step short of it.
* WowNav, ships and zeppelins: choosing a landing walks you to it like to any place. Arriving there says where the vessel waits and names the point on board, and the route to that point starts by itself. These landings have no waiting circle and no boarding beacon.
* WowNav, portals: a route to a portal or an entrance may lead through other portals first, as to the portal room in Stormwind, and a teleport is recognised even when the game gives no height.
* WowNav: when the target lies clearly above or below where the route ends, it says so at the start and on arrival ("Target is above, about 12 yards").
* WowNav: chests in the destination list are called objects.
* WowNav: the zones around you are now prepared a little in every frame instead of each in one piece. Before, walking into a big zone such as the Barrens made the game stand still for a moment, several times in a row.

## V1.0.2

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

## V1.0.1

### Summary
The first update since launch: a rebuilt quest log for Retail and WoW: Forever, a working bank and Send Mail tab on Forever, new WowNav data for the starting zones, and many fixes from launch reports.

The full manual is online, in English and German: [WowVision documentation](https://wow-vision.github.io/WowVision/).

### All Versions
* Buffers are now account-wide by default, so a group or buffer you add or change on one character is there on all of them. Press Shift+F10 on a group and use Scope to keep it on one character.
* Targeting, Names: choose what a target announcement says, with separate choices for in combat and out of combat, and for players, NPCs, mobs, pets and totems. It is off by default, so you hear the full tooltip as before until you turn on Configured Target Announcement. /wv targetinfo lists what each fact says for your target.
* Targeting: a new Target of Target binding makes your target's target your target. It works in combat and has no default key, because R stays the game's reply key.
* Targeting: the Target in Combat sound when tabbing now works in a group.
* Key bindings: letters jump to the next action whose name starts with them, and Home and End go to the first and last action.
* Navigation: after the waypoint reached cue, WowVision says how many waypoints are left. The new Announce Remaining Waypoints setting turns it off.
* Navigation: Reverse Route (Ctrl+Shift+R) turns the running route around.
* Navigation: the three arrival distances (Alt+P) now default to 0.3, 1 and 3 yards, take values from 0.1 to 20, and also apply to WowNav routes.
* Quests: when the quest data names nowhere to walk, the Scanner falls back to the game's quest marker, then Questie's.
* Quest log: F9 opens the Scanner on the quest you are on, and F10 opens the navigation window aimed at that quest's next target.
* Group invitations: /wv accept and a new unbound Accept Group Invitation binding accept an invitation, even in combat.
* Fixed tooltip money lines failing on secret values.

### Modern
* The quest log is rebuilt to match the screen. The details replace the list, with a real Back button. The list gains search, settings, your quest count, quest tags, collapse state and the game's right click menus. Press Right on a quest for its Track Quest checkbox and its objectives. Details now read in the game's order and include the rewards, timer, required money and group size.
* Aura buffers: new settings for the time remaining and the description.
* Setting a raid marker from the target's menu (Alt+T) no longer fails with an addon error.
* Dragging a spell or item off the action bars window now picks it up directly, which avoids action bar errors in combat.
* Bags: combined bags read bag by bag, so a sorted bag now reads in order.
* Social: the friend request confirmation after Add Friend is now read, so Send Request can be pressed.
* Options: moving through the Social category no longer raises the Discord error. The Discord rows now only work from a search made right after a reload, because WowVision cannot scroll to them safely. The manual explains the steps.

#### Forever
* Bank: bank bag slots you have not bought now read their price, and Enter buys the next one, with the game's confirmation.
* Mail: the Send Mail tab now works, with the recipient, subject, body, attachments, money and Send button. Enter in the recipient and subject boxes no longer jumps to the next box.
* Fixed the Need, Greed and Pass keys failing with an error. The Greed key also presses Transmog on items that offer it in Greed's place, and a roll you can't make now says why.
* WowNav data: Elwynn Forest, Dun Morogh, Teldrassil, Durotar, Mulgore, Tirisfal Glades and Zephras Isle are rebuilt with entry points and complete links.
* WowNav routes: routes now start from the network's nearest point within 30 yards, instead of saying "No WowNav network here" a few steps off it.
* WowNav routes: a start and target on one link no longer walk a detour, and most routes no longer end with the unchecked last stretch warning.
* WowNav routes: reaching the last point now says Arrived and the target's name.
* WowNav: the Scanner's Enter on an NPC or object WowNav knows now routes to WowNav's own entry, with its height.

## V1.0.0

### Summary
This is a massive refactor of the codebase thanks to Claude Fable 5 and Opus 5.5. The UI has been entirely redone to increase ease of development and efficiency. Many long-standing UI focus issues have been fixed and overall the game should feel much smoother now.

The full manual is now online, in English and German: [WowVision documentation](https://wow-vision.github.io/WowVision/).

### All Versions
* Much of the addon has been rewritten. The UI framework has been entirely redone, greatly improving efficiency and preventing significant lag spikes on some screens. This should also allow much faster development, as the older framework was overengineered and introducing unnecessary complexity. LLM models, such as Claude code, also have a much easier time with it, allowing us to iterate significantly faster.
* Fixed some rare instances of options screen controls having incorrect or missing tooltips.
* Finally fixed the gossip window acting unpredictably when available dialogue options changed. Additionally the new text is automatically read out.
* Dropdown menus are now fully supported, including submenus.
* The addon now tracks per character and global settings separately. By default most things are global; this can be changed per module via its context menu in the WowVision settings.
* Alert settings are now account-wide as well, so an alert you change on one character changes on all of them. Press Shift+F10 on an alert's button and use Scope to keep it on one character. The first character to log in after this update sets the alerts for the account.
* Key bindings are now account-wide as well, so a key you change on one character changes on all of them. To give one character its own keys, press Shift+F10 on the Bindings button in the UI menu and use Scope. The first character to log in after this update sets the keys for the account.
* Aura buffers: debuffs now say their dispel type (Magic, Poison and so on) in combat and in instances on Retail and WoW: Forever too.
* Fixed Auto-move to Interact Target showing on while the game's Click to Move stayed off, so interacting with a distant target did not walk you there. WowVision now sets the game option at each login to match the setting.
* Targeting: the range readout moved under Targeting, Hard Target, as the Range Changed alert. The separate Range entry in the menu is gone; a character who had switched it off keeps it off.
* Retail and WoW: Forever: the target Health Monitor is gone, because the game hides a target's health in combat. Use the game's own Combat Audio Alerts for it.
* Targeting: soft target arcs default to 180 degrees and ranges to the longest (60 yards for enemies and friends, 20 for interact), written when you switch that type on. They now sit inside each soft target's alert. Game Default and a range of 0 put the game's own value back, and so does Game Default on the two hard target settings.
* Aura buffers: your own buffs and debuffs now say their stack count in combat and in instances on Retail and WoW: Forever too, in a buffer with no filters set. Target, focus and pet auras cannot give theirs there.
* Fixed Shift-Left and Shift-Right throwing an error on tooltips with secret text, such as debuffs in combat.
* Retail and WoW: Forever: Add no longer offers the Tracked Buffer, because nearly everything it could track is hidden from addons there. Use the Aura Buffer for auras and the Spell Cooldowns monitor for cooldowns. Tracked buffers you already have stay as they are.
* Fixed a bug where you could not tab out of certain edit fields.
* Added support for wall/collision detection. If the addon detects you are moving slower than you should be, it will play sounds indicating a collision (this  replicates Sku's behavior.)
* Added support for fall detection. It can be configured to speak when you  begin to fall. It will also play an ascending series of tones as you fall (this works identically to how Sku's did and uses the same sounds.)
* Added propper support for Feaux Hybrid Scroll frames (aka my arch enemy.) Frames that would cause errors when scrolled will no longer do so. Unfortunately however I cannot implement the home and end keys to jump to the first or last item within these. These frames include the who list and the glyph frames for various versions of the game.
* Fixed a bug where home and end would sometimes act unexpectedly, particularly within nested containers.
* Added support for the rest of the options screen.
* Errors: a per-error filter (Errors module, Per-Error Filter). Every game error or info message you have seen gets its own entry with its own speech and sound settings, so you can mute "Ability is not ready yet" and keep "Out of range". Messages that differ only by a name or number share one entry. "Show All Known Errors" lists every error the client knows, before you meet it. A Repeat Delay setting (default 2 seconds) stops the same error from being spoken again while you hold a key. Works on every supported version; on Retail it also speaks the errors Blizzard hides from the error frame, like out of range and out of rage or energy.
* Fixed a bug where certain popups in the options screen would softlock the game.
* Added the scanner. The scanner acts as traditionally seen in other mods, providing a categorized list of various things in the world. These include quest givers, nearby quests, and the location of your corpse for now. Press f9 to use it. Important: The scanner can only give you straight line paths currently pathfinding solutions are being worked on.
* Added the /wv speech command to quickly adjust your speech settings. The syntax is /wv speech voiceID rate volume, for example /wv speech 1 8 100. Note: your first voice has ID 0.
* The first time a character logs in with WowVision, the game's Lock Action Bars setting is turned off, so dragging spells and items off your action bars works without holding the pick up key. This happens once per character; if you lock the bars again in the game options, they stay locked.
* Buffers: Alt+Down now moves toward the newest item in a buffer and Alt+Up toward the first. A new Invert Item Direction setting in the Buffers menu swaps the two keys back for anyone used to the old way.
* Added the Aura buffer type: the buffs and debuffs on the player, target, focus or pet in any combination (the Sources setting), every one the game knows about. Each aura reads its name, stacks, time remaining with the total duration, and for debuffs the dispel type. Only My Auras keeps the ones you cast. Built to work on Retail in combat and in instances, where the game closes its aura list to addons: there each aura is read from its tooltip, name and time remaining, as the game formats it.
* Added two Speech toggles for the game's own text-to-speech sounds (/tts playline and /tts playactivity). The sound between chat lines is turned off once per character.
* The Speech Voice is now saved by the voice's name instead of its number, so installing or removing Windows voices no longer switches you to a different voice; an existing setting keeps the voice it meant. Every TTS alert gained a Voice setting of its own, following the Speech Voice until you pick one, and the minimap walking announcements choose their voice the same way.
* Shift-F12 cancels the active route or beacon.
* Alt-T opens your target's menu, the one a right click on the target's portrait opens (Copy Character Name, Whisper, Invite and the rest). Target yourself for Reset All Instances, loot and dungeon difficulty.
* Dropdown menus: a submenu opened from a menu near the right edge of the screen (such as Set Loot Specialization) no longer reads the parent menu again. Menus long enough to scroll are read in full and scroll to follow your focus; before, they were not read at all. The tooltip key reads a menu row's tooltip. Controls inside a menu row are reachable with left and right, such as the Minimum and Maximum level boxes of the auction house filter; Enter or Escape leaves a box. Sliders in a menu row, such as the voice chat volumes in the player menu, get a line of their own: left and right move them, Enter types a value.
* Letter navigation in menus: in the WowVision menu, its settings screens, context menus (Shift-F10) and dropdown menus, a letter jumps to the next entry starting with it, the same letter again to the one after, and letters typed quickly search together ("go" finds Goldshire). The Letter Navigation in Menus setting (UI) turns it off.
* Shift-F1 opens the WowVision menu.
* Buffers: on a buff or debuff in an aura buffer, Shift-Up and Shift-Down read its whole tooltip line by line (name, description, time left), in combat too.
* Buffers: aura buffers have filters, each set to Any, Only or Not: Cast by Me, Castable or Dispellable by Me, Cancelable, Crowd Control, Dispellable by My Group, Dispellable, External Defensive, Big Defensive, Shown on Raid Frames in Combat and Important, as far as the game version knows them (Not on Retail and WoW: Forever; on the classic versions only for Cancelable). They work in combat too. Only My Auras became Cast by Me.
* Target Crowd Control (Targeting, Hard Target): a sound when your target is crowd controlled by anyone (stunned, feared, polymorphed and the like) and another when it is free again, also when you switch from a controlled target to a free one; speech optional. Works in combat. Retail, WoW: Forever and Mists; TBC Anniversary does not have the game's crowd control filter.
* The German and French translations are complete: 194 strings were missing in German (among them the whole scanner) and 60 in French, and were spoken in English.
* Navigation: the F10 window has a Direct checkbox: with it ticked, Enter on a destination sets exactly that point as a straight beacon, with no route.
* Navigation: destinations you reach are remembered as visited for a while. F10 says "Visited" before them, and two key bindings (unbound by default) take you to the nearest unvisited spawn with the same name, by route or as a direct point.
* Navigation: Ctrl-Shift-N starts the route to your last destination again from where you stand, and the Route to Your Target key (unbound by default) starts a route to your target: a group member where they stand, a creature at its nearest known spawn.
* Navigation: when you die, a route to your corpse starts as soon as you are a ghost. The Automatically Navigate to Corpse setting (Navigation) turns it off.
* Alt Gr (or Ctrl+Alt) speaks the distance to the waypoint you are walking to, like Sku. Holding it repeats the announcement every second. It stays silent while you type in an edit box. The Announce Distance Alt Gr setting in the Maps module turns it off, and the Announce Distance binding puts the same announcement on a key of your choice.
* Speech through NVDA's SAPI bridge voice (SAPI2SR, as Sku's installer sets it up) is now cut when WowVision stops speech: the first line after a stop carries the bridge's interrupt mark, so a new line from a controller or a key no longer waits for the old one to finish. Real voices are unaffected.
* The XP line in the general buffer names the level it fills towards.
* The General buffer gained lines for free bag slots, durability (the most worn item and how many are broken), unread mail with its senders, the hearthstone (ready or its cooldown, and the bind location) and the game clock, and the XP line says how much rested XP you have. Existing characters get the new lines once, before the PvP line; a line you remove stays removed.
* Windows that open on a search box, like the game options, take typing right away.
* WowVision's own text fields do the same: a screen that opens on one, like the tracking parameters of a unit object type, starts typing at once instead of after a tab away and back.
* Fixed key bindings losing Alt when Alt was let go before the key.
* Books and letters no longer read a page number line or stop silently when there is no author.
* Targeting: new soft targeting settings (Soft Targeting With a Hard Target, Make Soft Target the Hard Target, and an arc and range per soft target). Shift+I, Shift+P and Shift+O changed in combat now apply when combat ends. /wv soft reads every value.
* The TBC map data now ships inside the WowVision download as its own addon folder (WowVision_MapData_TBC), so there is nothing separate to install. It also loads on WoW Forever, where the old world routes apply. Other map data addons keep working beside it.
* Bags in list shape read their slots in slot order again (slot 1 first); they had been read from the top left of the grid, which is the last slot.
* Scanner: an in-progress quest now expands to its objectives, and each objective to the NPCs, objects or item sources it is about, with their spawns under those. A complete quest expands to its turn-in. Enter on the quest or an objective still beacons the first open target.
* Trainer: the service filter (Available, Unavailable, Already Known) is a stop before the list. The game hides unavailable services by default on WoW Forever, so a new character heard only its one available skill.
* Scanner: Enter on a quest, NPC or other placed entry now opens the navigation window aimed at it, with the closest entry point and the entry as destination already selected; Enter there routes along the waypoint network and finishes with a straight leg. Without map data for the continent a straight beacon is set as before.
* Added two Merchant settings (Windows > Merchant): "Automatically Sell Poor Items" and "Automatically Repair If Possible", both off by default. When turned on, opening a vendor sells your grey items and repairs your gear on its own, with a chat message confirming what was sold or repaired. Repair is skipped if the vendor doesn't offer it or you can't afford it.
* Fixed the compass's indoors/outdoors, flying, swimming, and diving announcements never firing inside dungeons and other instances, where the game does not report your facing.
* Added Sku's Beacon 6 as a beacon sound.
* Chat: every chat tab now has its own alert in the Chat menu, under the tab's name, with speech, sound and a Speak Messages choice: When the Tab Is Shown (the old behaviour) or Always. A message that reaches several speaking tabs is spoken once. Whisper tabs (whispers in a new tab, Battle.net included) are picked up as the game opens them, so the first whisper is spoken, and share one Whisper Tabs alert that speaks Always by default. In the chat reader, Left and Right switch to the neighbouring tab and read its newest message; the tab strip follows the game's tab order and includes whisper tabs. A new Chat Tab buffer type in buffer groups shows one open chat tab, or the whisper tabs together. Lines already in a tab when it was picked up are no longer spoken, and reopening a closed tab no longer errors. A chat tab buffer opens on its newest line and follows new lines until you move back into older ones.
* Wall detection now also works while autorunning, during walks the game makes for you (the interact key, click to move), and in combat on Retail and WoW Forever, where only a full standstill can be judged because the game hides your speed there. A game walk that ends short of its goal plays the blocked sound once. It stays quiet while you are stunned or rooted, and no longer beeps endlessly after a movement key the game lost track of.
* Questie's one-time "Welcome to Questie" dialog, which asks you to choose between Questie, pfQuest and Blizzard quest objectives on WoW Forever and the newer classic clients, is now read as a window with its three buttons. It used to sit silently in the middle of the screen, where it also blocked every minimap scan.
* The minimap scan's "Scan canceled, window" message now names the frame under the cursor, and the scan log records it.
* Mac: speech no longer says "bookmark" after every line.
* New user manual in English and German: every key, menu, window and setting from the player's point of view, with installation, the Sku login tool 4, troubleshooting, a key and command reference and features per game version. Written for screen readers, without bold or italic markers.
* /wv bind opens the keybinding screen again (the same screen as WowVision menu, UI, Bindings); it used to fail with an error.
* /focus1 to /focus5 without a name and without a target keep the old focus and say so, instead of storing an empty name.
* /wv errors clear empties WowVision's own error list as well when BugGrabber is installed.
* Toggle All Monitors works as a mute: if any monitor is on it turns them all off and says "Monitors off", otherwise it turns them all on and says "Monitors on".
* Buffers: a buffer or buffer group switched off with its Enabled toggle is skipped by the buffer keys. The Chat Tab buffer editor no longer shows two internal rows.
* Buffers: the Power Type list exists on every game version, starts on mana, and a tracked Power buffer no longer throws errors on combo points, holy power, soul shards, runic power, arcane charges or lunar power, or on a resource that appears later.
* The health of a new target is announced even when it sits on the same five percent step as the last target's.
* The voice pack choice of Voice alerts is labelled Voice Pack. Speech Rate (-10 to 10) and Speech Volume (0 to 100) are kept in range in the menu, too.
* Action bars: a companion pet reads its name instead of "Unknown Mount" (and no longer errors on clients without a mount journal); Drag from a slot's context menu counts as a bar pickup, so Delete clears the slot instead of offering to destroy the item in your bags.
* Merchant: the buyback tab no longer adds a good's currency costs to items you sold.
* More messages are translated (Lua errors, the chat settings title, virtual focus messages, route failure reasons, the Mists glyph notice). German: an unchecked check box says "Nicht aktiviert", so it can be told from a disabled control; the demon hunter's Fury is "Zorn"; all navigation distances say "Meter".
* Enemy count (UI, Combat): a new, experimental Announce Crowd Control choice, off by default. With Spell Names or Without Names, the number counts only the enemies still free to fight; a crowd control that lands is said by its name ("Polymorph", or "3 controlled" for an area spell), one that ends plays a short sound before the new number, and "0, Polymorph" means only controlled enemies are left.

#### Forever
* Fixed the minimap scanner and the walking announcements finding nothing after the October 16 client build. The minimap now names its dots only in its new soft cursor mode, which the scan switches on while it runs.
* Fixed characters turning or running on their own, mostly in parties. When a window opened while a movement key was held (a shared quest, a ready check, a popup, or any window once combat ended mid-run), the addon took over the arrow keys at that instant and the game never saw the key released. Windows now wait to take their keys until every key they use is up. On the classic clients a movement key the game lost track of no longer keeps a window from taking its keys. If it still happens to you, type /wv keylog, play until it happens, and send the WowVision keys lines from your chat log along with what you were doing.

### Modern
* Fixed errors on WoW: Forever and Retail when the game hides a unit's identity or raid marker from addons: the target change, soft target, range, tooltip and window announcements no longer fail, and the raid target marker is still announced on target change. Those clients hide which marker it is from addons entirely, so it is spoken as its number (1 Star, 2 Circle, 3 Diamond, 4 Triangle, 5 Moon, 6 Square, 7 X, 8 Skull) instead of its name.
* Added the group health monitor for Retail and WoW: Forever, after Sku's health monitor (off by default): group members are spoken as their numbers (you are 1, your party 2 to 5, raid members by Sku's dial numbers) with a Windows voice of its own, the pitch telling how hurt they are, the lower the health the higher the pitch. Every member below their role's Repeat Below is repeated at the role's interval, one at a time while nothing else is speaking; a death is said once as "number dead"; Alt+H speaks everyone once in number order, "number full" at full health. Group health is secret on these clients, so the monitor never knows anyone's health: it prepares each announcement and the game plays the form whose health range matches. Pitch needs a real SAPI voice (Hedda, Zira and Katja have measured scales); the NVDA bridge voice speaks the numbers without pitch, and the monitor says so once when the bridge is its voice.
* Added support for the bags window.
* Added the cooldown manager settings window (/cdm): the Spells, Auras and Group Buffs tabs, search, the gear menu, each category with its items, the layout dropdown and Revert Changes. Enter on an item picks it up and Enter on another item or on a category's empty slot drops it there; Backspace opens the item's menu for alerts and moves. The alert editor is its own window. Changes made with the keyboard take effect after the interface reloads, because the game rebuilds its on-screen cooldown data from them; the window says so and offers a Reload Interface button. Menu rows with attached buttons (play sample, edit, delete) now read as rows: right arrow reaches the buttons.
* Fixed an entirely unnecessary 1.5 second delay when clicking on gossip options before the text refreshed. This was caused by retail changing which events fire for gossip dialogue.
* Fixed the gossip window staying open after the conversation moved on to a trainer, vendor or quest, or the game closed it.
* Fixed health and power in buffers going silent when read a second time.
* Fixed the Speech Queue setting being ignored.
* Added the chat channels window: the channel list under its headers (Enter selects a channel, Enter on a header folds it, Backspace opens the channel menu), the members of the selected channel with owner, moderator and offline (Backspace opens the player menu), Add, Settings and the new channel box. Shift click on a channel name in the chat reader opens it. The voice buttons are not read yet.
* Added the Cooldown Manager Auras monitor, the first combat alert built for the secrets: for each aura in your cooldown manager's Tracked Buffs and Tracked Bars, alerts when it is applied, enters its pandemic window or drops off your target or yourself, read from what Blizzard's cooldown manager shows, so it works in combat and in instances where aura data is closed to addons. A Speak Tracked Auras key reads the time left and stacks of every tracked aura as the game draws them. The rule's Spell picker lists the auras in your Tracked Buffs and Tracked Bars. When a tracked aura expires in its pandemic window the rule goes straight to Missing, instead of a flash of Applied while the game catches up. The monitors framework now loads on Retail and WoW: Forever as well.
* Added the Spell Cooldowns monitor for Retail and WoW: Forever: Spell Cooldown rules alert when a spell becomes Ready, starts Charging or goes On Cooldown, built on the few cooldown facts the game keeps plain in combat (the global cooldown never counts), and Spell Proc rules alert when a spell's proc glow appears and ends. A Speak Tracked Cooldowns key reads each tracked spell with the time left in plain words, which the game formats so it stays speakable where cooldowns are secret. The Spell picker offers the Essential and Utility spells of your cooldown manager that the game says have a cooldown.
* Added the Retail group finder's Dungeon Finder: the tabs, the Dungeon Finder, Raid Finder and Premade Groups buttons, the roles, the dungeon type (follower dungeons included), the dungeon list with each dungeon's levels and whether it is checked or locked (the tooltip key says why), the rewards of a random dungeon, and Find Group. Follower dungeons let you queue with NPC companions. The other tabs, Raid Finder and Premade Groups are not read yet.
* Added the Social window, which the friends key opens where the game turns it on (WoW Forever does, replacing the old friends list): the Battle.net bar with your BattleTag, status and menu; the Friends, Friend Requests, Recent Allies and Quick Join pages with search, filter and the list under collapsible headers (Enter selects a card, Backspace opens its menu, invite, summon, accept and decline in its context menu); the Raid page with role counts and groups; the ignore list, broadcast, raid info and Add Friend windows. Built on WoW Forever; Retail loads it too but has not been tested there. Recruit a Friend and moving raid members between groups are not read yet.
* Added the guild invitation window (Join or Decline; closing it declines, as in the game), the Guild and Communities window (the list of guilds and communities, chat, roster, guild info with the message of the day and the news, guild benefits, community invitations; the member card, the text editors, the event log and the news filters as windows of their own) and guild control (ranks, permissions, guild bank tabs). Not yet tried inside a guild.

#### Forever
* Updated the addon architecture and toc files to support the WoW Forever beta.
* fixed a number of issues with the options window introduced in WoW Forever.
* Added support for the character pane, including the equipment manager.
* Bags in individual mode: each bag's menu (filters, cleanup, mode switch) sits in the context menu of the bag's first entry, its slot button, whose clicks now read as "Close Bag" or "Place Item". Bag Controls follows only the backpack, which holds search, sort, money and Add Slots. The keyring on WoW: Forever reads as a bag with its own slot button.
* The four locked backpack slots an account without an authenticator is shown are no longer read as empty slots; the Add Slots button stays in the bag controls.
* Added support for the bank: pages and bank types as tabs, one tab stop per bank tab, the bank bag slots, search, sort, money and the purchase of the next bag.
* Added support for the talent window: the primary and secondary specialization tabs with the activate button, the unspent points, the talent search and its options, then each specialization as its own tab stop with the points spent in it. Talents read row by row as drawn, with their rank and whether they are available or locked; a locked talent names the points and the talents it waits for ("or" where any one of them will do). Enter learns a rank, and on a choice talent opens its options; Backspace unlearns; the context menu links a talent in chat and buys back what a reset removed. Apply says when changes are waiting or why it cannot apply them, followed by Undo and the Reset menu.
* The search boxes of the spellbook, the talent window and the Legacy trees read the game's suggestions: while typing, Up and Down speak the highlighted suggestion and its position, and Enter picks it (or searches the typed text when none is highlighted).
* Added support for the Legacy window (the Toggle Legacy key, or the achievements key for its challenges page): the reward track with every level and its reward; the challenges with search, filter and the category tree (the list says which category it shows), each challenge with its Legacy points and a tooltip listing its description, reward and objectives, an opened challenge's objectives and track checkbox, and linking in chat from the context menu; and the three Legacy trees, each tree button with the points spent in it, the points left with the seasonal cap, the points still needed to open a row, and the talents as in the talent window.
* Controller support. With the game's Enable Gamepad and Enable Gamepad UI options on, WowVision answers a gamepad next to the keyboard: the D-pad and face buttons work in WowVision windows (A left click, X right click, B close, Y tooltip, shoulders Tab and Shift-Tab), the right stick press turns to the waypoint and, held, puts the buffers on the D-pad, and the shortcut layer (both shoulders) opens navigation, chat, the scanner, the bars window and the WowVision menu. The gamepad main menu wheel reads as a window of two rows, the bars window lists the four gamepad action bars, and the keybinding window lets you add or remove controller buttons per binding. See the Controller page of the user guide. The left shoulder stands in for Alt, the left trigger for Shift and the right trigger for Ctrl. /wv padlog restarts the controller log kept for bug reports.
* WowNav routes: with the Routes from WowNav setting (Navigation, on by default), every route request (F10, the scanner's Enter, the places list, /beacon to) is planned on Broesel33's navigation network for WoW: Forever and followed with his route rules: lifts, portals, the Deeprun Tram, ships and zeppelins with their docks, avoiding enemy outposts, and group members as targets. F10 then lists WowNav's targets and picks the start the same way as with the route data. Thanks to Broesel33 for the network and the engine.
* WowNav routes: a route through a portal you walk into (the Teldrassil portals) announces the portal ahead and goes on after it, and a portal above or below the route no longer ends it early.
* WowNav routes: fishing spots. 788 places to stand and fish, at the waters of 45 zones, are destinations in F10 (search "fishing"). When you arrive you hear where the water lies and your cast range, a beacon sounds from the water, and I turns you to it, until you walk away from the spot.
* WowNav routes: the F10 entry points list the nearest 50 entries instead of 20. The network's own waypoints within 10 yards of you are always among them, so you can start where you stand even when the nearest place is far away; Show Automatic Waypoints adds the waypoints farther away, and to the destination list.
* WowNav routes: on Zephras Isle the portals say to target and interact with them, the Wind Bridge says to wait for it and has no time limit, their estimated positions are said as such, and the portal to Valanaar is only used for your own faction. Dungeons with several entrances name the wing ("Dungeon entrance: Scarlet Monastery, Graveyard").
* WowNav routes: Broesel33's navigation engine and data are at their latest version. A place on the bottom of a lake is bound to the water above it, and where the network has fine and coarse cells on your floor, the fine one is used.
* Collections: Enter on the tab that is already open only says "selected", so it can no longer close the journal by accident.

### Classic
* Fixed a bug where edit fields for spell IDs (for example in monitors) would behave extremely inconsistently and often not actually set the spell ID correctly.
* Added initial support for the social tab, including friends, ignore, and the who list.
* The guild tab of the friends window (the classic guild window, which TBC Anniversary uses): the message of the day, the roster with level, class, zone or last online, rank and note, Show Offline, the column view and sort headers, Add Member, Guild Control and Guild Information. The member card, the guild information, the event log and guild control (ranks, permissions, guild bank tabs) are windows of their own.
* Aura and Cooldown monitors speak the spell and the translated state ("Moonfire Expiring", "Rebirth On Cooldown", "Rebirth Charge Gained") instead of raw state names such as "on_cooldown".

#### The Burning Crusade Classic
* Updated the TBC speech module to use the retail speech module. Speech output for TBC works again.
* Implemented Sku's pathfinding data into TBC Anniversary. You can pathfind using f10. Note: pathfinding to scanner entries is not yet supported.
* Fixed the spellbook staying silent for characters without a pet; the open tab is read.
* Added the craft window, used by Enchanting and the hunter's Beast Training: the skill bar, the filters, the craft list, the details with reagents, and the Enchant or Train button.
* Added the hunter's stable: the selected pet, the current pet and stable slots, buying a slot. Enter on a slot selects it or puts down the pet you picked up; Drag in a slot's context menu picks the pet up.
* Auction house: the Item Selected alert is in the menu (Windows, Auction House), and the full scan's 15 minute cooldown is kept after a reload even when the scan was aborted.

#### Mists of Pandaria Classic
* Fixed a number of issues with the mounts tab of the collections pane.
* Add support for the Core Abilities and What Has Changed tabs of the spellbook.
* Profession buttons in the spellbook read with a space before the rank in brackets.

## V0.8.0

### Summary
This patch fixes a number of issues with Mists of Pandaria Classic. The addon now works again (there were many, many breaking changes to the Blizzard APIs.) There were also a number of additions to TBC Classic thanks to @@JeanStiletto, including full support for the auction house, group finder, and item socketing frame.

### All Versions
* Fixed a rare issue where certain controls in dropdowns would not appear.

### Classic
* Implemented support for the send mail tab of the mailbox (thanks @JeanStiletto).

### The Burning Crusade Anniversary
* Added support for the item socketing frame (thanks @JeanStiletto).
* Added support for the looking for group pane (thanks @JeanStiletto).
* Added support for the auction house thanks to @JeanStiletto.

### Mists of Pandaria Classic
* Updated the minimum toc version numbers; the addon works with Mists once again.
* Added support for the reputation tab of the character frame.
* Fixed an issue where tts readouts were either entirely silent or caused lua errors due to a Blizzard API change. Note that speech will feel significantly different now and it a bit laggier; unfortunately there is nothing I can do about this.
* Fixed an issue where tts volumes above 100% would cause speech to be silent (really Blizzard?)
* Fixed various issues preventing range callouts from working in the latest patch. Note that certain ranges seem to be missing, noteably 2, 3, and 15 yards callouts. There isn't anything I can do about this as the problem is caused by a blizzard API change. I will be investigating this further though so hopefully this can be fixed in future.

### Retail
* Updated the minimum version numbers so the game will allow the addon to be loaded once again.
* Updated the speech module to use the one used by Mists of Pandaria classic to fix a speech queueing issue.

## V0.7.0

### Summary
This version introduces the monitors and buffers systems. Monitors work similar to Sku monitors (or like a simplified WeakAuras if you're familiar with that.) They allow you to set up alerts for your buff/debuff states and cooldown states for your abilities. Health monitors will be added later when we have better voice pack architecture set up. Buffers are supported for all versions, but monitors are only supported for classic versions of the game due to Blizzard's retail addon restrictions.
This version also fixes numerous bugs and adds a large number of quality of life improvements, including better alert sound configuration and line by line tooltip reading with shift and the arrow keys.

### All Versions
* Fixed the issue where certain npcs would not list their dialogue options or quests. This was caused by certain npcs using a different window (the quest frame) to list their greeting text and quests.
* Refactored the UI code to better handle required delays in the WoW Speech APIs. Essentially this speeds up speech responsiveness for all versions of the game when navigating through UI elements.
* You can now choose to have a sound played for various alerts (such as chat, outdoor/indoor, swimming, etc). For alerts that had preexisting sounds, you can now configure which sound plays.
* For certain tts alerts, you can now configure the message spoken.
* Added LibSharedMedia as an audio source. LibSharedMedia is a library used by many addons (such as WeakAuras) to share sounds, fonts, and other resources between addons. You can now use all of the Weakauras sounds for alerts and monitors for example.
* Updated the sounds in the default WowVision audio pack to remove long silence before many of the files. This also adds a directory of tones.
* You can now use shift and the arrow keys (by default) to read tooltips line by line.
* Fixed a bug where dropdown buttons for addon settings would not list their currently selected value after the button type.
* Fixed a bug where navigating through certain types of scroll frame would repeat the newly reached element twice.
* Finally fixed the bug where your position in certain lists wouldn't save when certain windows opened. For example, after entering an input mapping in the bindings menu, the cursor would jump to the top of the input bindings list. Now it will remain on the binding bar you were last at.
* The buffers system can now be configured to add any number of buffers and buffer groups. For example, you can now add a buffer to list auras on the player.
* Fixed a bug where the view cursor on ViewList objects (for example buffers) would not reset to the beginning if all items in them were deleted.
* Fixed a performance issue for spoken announcements that use templates (primarily announcement of buffer items.) Templates are now precompiled. This wasn't too noticeable unless you were rapidly arrowing through buffers.
* Removed a few unused files (the old speech module.)
* Greatly improved UI performance on most screens.
* Improved labeling for various lists for clarity. Horizontal lists (such as tabs) will be labeled as a "Bar" to denote their navigation direction.
* Fixed a bug in the trade frame where your trades were always labeled as "Empty" even when not empty.
* Fixed a rare Mailbox issue that caused lua errors when opening all mail and you already had a letter open.
* Fixed a bug where buyback items on the merchant frame would have the wrong price label; they were being labeled with the prices of what the button would correspond to on the merchant tab, not the buyback tab. This may also fix some rare mislabeling of stack/stock amounts.
* The controls on various settings screens are now in a much more reasonable order.
* Fixed a very rare error that could occur in the chat module if chat tabs loaded in a very specific way.

### Classic Versions
* Added a Speech Style dropdown to the speech module. This allows you to configure how speech output is queued, potentially leading to more consistent interrupts. The direct style is the style WowVision used before; buffered is similar to Sku's method (using a speech queue with an artificial delay.)
* Added monitors, which act similarly to Sku monitors. Currently Aura (buff/debuff) and Cooldown monitors are supported, but more are coming soon.

### Burning Crusade Anniversary
* Fixed a bug where the quest log frame would not scroll correctly and report incorrect information for various buttons.
* Fixed a bug in the character frame where the skill and reputation detail could be wrongly positioned (before their list instead of after.)
* Fixed a bug in the equipment list where the ammo slot would always be labeled "Ammo" whether or not an item was in the ammo slot.

### Mists of Pandaria Classic
* Fixed an issue in the quest log where the panel containing the info and buttons for the currently selected quest would not update when you clicked on a quest. Blizzard why do you like arbitrarily changing when events fire so much?

## V0.6.0

### Summary
This update officially introduces support for BCC Anniversary. It also fixes a number of compatibility issues between different versions of the game, as well as making a large number of behind the scenes changes to support Blizzard's addon changes to Midnight (secret values, etc.) Note that midnight is not well supported, though a lot of the addon's functionality does work with it. Refactors to support secret values were necessary now in case any of these changes are introduced into classic versions of the game (this is unlikely but important to account for.)

### All Versions
* Added support for the item text frame (letters, books, etc.)
* Fixed a bug where adding an input to a binding with no inputs set would add the input twice.
* Fixed an issue where additional non-functioning elements would be listed for the options/game menu for versions of the game using newer Blizzard code (currently Retail and BCC Anniversary.)
* Reverted the change to UI tooltip processing made in a previous version (0.5.2.) This should fix tooltips not being fully loaded before they are read out.
* Compass direction announcements will now work properly in instances that allow for it (for example Mists of Pandaria scenarios.)
* Hopefully fixed eronious indoors alerts in certain rare situations.
* Hopefully fixed an incredibly rare gossip frame bug where no dialog options would be available. If you encounter this please report it.

### The Burning Crusade Anniversary
This patch adds support for BCC Anniversary. Note that many of these screens were implemented fairly quickly as I did not have ptr access before launch. I have extensively tested BCC anniversary, but please let me know if anything is broken.

* Fixed a bug where the pet bar for BCC would throw constant lua errors if you had a pet summoned.
* Added support for the quest log frame
* Added support for the character frame.
* Added support for the talents frame.
* Added support for the Spellbook.
* Added support for the trade skill (crafting) frame.
* Known Issue: Certain scroll frames announce the current item twice when arrowing through them (primarily the skills tab of the character pane.) This doesn't effect their functionality but is a little annoying. This is an issue that will be fixed in a future UI refactor update.

### Mists of Pandaria Classic
* Added support for quest choices (for example the assignment map on The Isle of Thunder.)
* Added support for the professions tab of the spellbook.

### Retail
Note that these changes apply specifically to retail; any removed functionality in the retail version of the addon still exists in the classic versions. Also note that Retail is not well supported now and most likely will not be in the immediate future, but WowVision does work with it.

* Updated to use the latest interface version. WowVision will once again be detected by the game.
* Speech works in retail once again; there are now separate speech modules for classic and retail versions of the game (required due to API changes.) Speech should feel significantly smoother due to the speech API updates.
* Unfortunately I had to remove the hard target health monitor due to the addon changes in Midnight. This functionality is available in the combat audio assist section of settings however.

## V0.5.3

* Fixed a number of mailbox errors related to blank money amounts from auction invoices.
* Fixed the trainer frame sometimes not having a list of skills to train.

## V0.5.2

* The socketing frame now works again (apparently Blizzard really like changing it for some reason.)
* The UI should now be slightly faster as it no longer tries to display tooltips whenever an element is focused (it only requests that data when the tooltip key is pressed.)

## V0.5.1
This patch fixes a few bugs and introduces virtual focus (allowing you to quickly set multiple focus targets.) It also introduces support for the mounts tab of the collections pane.

* Fixed a bug where trying to access bindings from the /wv UI menu would cause 
errors.
* Added virtual focus. This works as the Sku feature does; you can use the /focus1 through /focus5 commands to set the corresponding virtual focus to either your target or to a specified unit name. Using the corresponding hotkey will /target that unit name. Note that virtual foci cannot be changed while in combat due to Blizzard restrictions.
    * For example I could set my focus1, focus2, and focus3 to each of the bosses in a given raid encounter. Then I could map my focus hotkeys (let's say to alt 1, alt 2, and alt 3). Pressing alt 1 would target the first boss, alt 2 the second, and alt 3 the third.
* Added support for the mounts tab in the collections pane.

## V0.5.0
this patch introduces significant refactors to the UI code, greatly increasing performance. It also fixes some bugs with gem socketing and adds more alerts for flying, outdoors, swimming, and combat start/end.

* Fixed gem socket colors reading as "color" if you didn't have colorblind mode enabled.
* Fixed tainting issue with gem socketing UI that prevented socket buttons from being clicked.
* Majorly refactored the UI code behind the scenes. This increased performance by ~50%. The changes won't be too noticeable, but bags/etc should feel more responsive.
* Fixed a long-standing bug where certain UI elements would be in an incorrect order if certain screens refreshed.
* Fixed a bug where the gossip window would sometimes be blank.
* Fixed a bug where the text elements when picking up available quests were in a random order.
* The significant performance issues with the character pane are now fixed.
* Fixed the long-standing bug where entering combat with certain UI windows open would cause odd behavior, such as certain windows not closing. Now navigation-related hotkeys are just disabled until combat ends.
* Added the /wv close command. If the UI does glitch out again, this will force any remaining UI contexts to close. Please report any further UI bugs.
* The /dquit command will now properly leave battlegrounds and arenas.
* Updated and added various TTS output alerts:
    * For navigation/compass: direction changed, outdoors/indoors, flying start and end, swimming, and diving
    * For UI/Combat: combat start and end

## For Developers
* Added a performance profiler. This can either be used via code or via slash commands for some global WowVision profiling parameters. See Profiler.lua for the class and /wv profile for the global profiling. The global profiling commands are /wv profile, /wv profile report, and /wv profile reset.

## V0.4.0
Unfortunately once again this release resets saved addon data entirely. I had to move away from using a popular addon library (AceDB) due to issues with how it handles default values for certain settings. As a result I had to restructure the data significantly. To be safe, old WowVision data (such as speech settings) will be reset the first time you log into a character. Sorry again for the inconvenience and this should not happen in future updates.

* Refactored all inputs to use the new input system. This will allow for input remapping and more flexibility in terms of what can be keybound and when.
* You can now remap all WowVision inputs. To do so, access UI/bindings from the /wv menu or with the /wv bind command. Note that you must still remap base game bindings from the options menu and that the mod does let you duplicate bindings (so if you bind w, it will replaced the move forward action while in the WowVision UI.)
* Fixed a bug where entering the /wv menu would not correctly keybind elements in that menu if you were in another screen previously. For example if you were in the options screen and typed /wv, hitting enter on an element would click on the currently focused element in the options screen. This should no longer happen.
* The item socketing frame no longer errors in the case of special sockets (Sha-Touched, etc.) Certain socket colors may not be translated though due to how awkward the API is.
* You can now destroy the item on the cursor by pressing the delete key or ctrl-alt-backslash by default. Note that the item must be on the cursor; you can't just arrow over one and press delete. I will change this if people prefer but my initial goal with bindings like this is to match the game's behavior as closely as possible (you have to drag an item to empty space to destroy it with the blizzard UI.) It also adds a layer of safety (on top of the confirmation prompt) to prevent destroying the wrong item by accident.
* Added an optional setting to the UI module that allows you to interrupt speech when a window (such as the game menu) is closed. This defaults to off.
* You can now check WowVision's version with the /wv version command.

## V0.3.4

* All merchant costs are now correctly read (including required currencies such as Justice Points.)
* Locale data has been moved to its own folder and github project for easier editing and management. All messages should still be there but if you receive any localization related errors please let me know.
* Added support for the bank frame and bags.
* Added support for the reforging screen.
* Added support for the item upgrade screen.
* Fixed a bug where containers/bags could sometimes error when items are quickly moved or removed (for example when opening the Keg-Shaped Treasure Chest from the Brewfest event.) The addon was not correctly checking for empty slots.
* Fixed a bug where bags opened in a certain order could have the wrong bag button associated with them (would mostly happen when only a single bag was opened.)
* Fixed a bug where the range to target alert did not have any settings UI.
* Fixed a bug where newly added alerts would sometimes not have the correct enabled/disabled state.
* The target changed alerts now default to interrupting speech.
* Added the Auto Move to Interact Target option (which defaults to true.) Note that this can also be changed in the options menu of Wow's default UI, where it is slightly misleadingly labeled Click to Move.
* Fixed an issue where long numbers with a / between them would read out incorrectly. For example, "300000/300000" would read as "3 0 0 0 0 0 slash 3 0 0 0 0 0".

## V0.3.3
Note that World of Warcraft has changed how their tts code works. This prevents non-standard SAPI voices (such as NVDASapi) from working. If you were using NVDASapi with previous versions of the addon it will not work. Please use the following command to reset your speech voice so you can continue to use the addon.

/run WowVision.base.speech.settings.voiceID = 0 WowVision.base.speech.settings.screenReader = false

* Fixed dialog popups causing error due to a Blizzard API change.
* Fixed buffers not working correctly with SAPI voices.
* Error alerts now use a TTS alert.
* Added more speech interrupts to various hotkey triggered functions to improve the experience with sapi voices. This includes the WowVision menus (particularly when pressing escape) and the loot commands.
* You can now press either control key to interrupt speech.
* Removed the Screen Reader setting from the speech module as it is no longer supported or useful.

## V0.3.2

* Fixed a bug with certain repeating quests that don't give certain rewards a second time (would cause lua errors.)
* Added support for skill trainers.
* Updated the currency frame:
    * Removed the unnecessary x before the count (for example "Valor x1500" now just reads as "Valor 1500")
    * Headers are now correctly identified as headers and read out their expanded/collapsed state.
* The quest log now wraps correctly.
* Fix missing localization for Repair on the merchant screen (which was throwing a lua error.)
* Add zone and subzone readouts when you move to a new area (part of the compass module.)
* Speech alerts via tts/sapi are now labeled as "TTS Alert" instead of "Speech Alert" for clarity. Unfortunately this change will reset your alerts to their default setting.
* Output via recorded voice files (such as compass directions and range numbers) are now refered to as "Voice Alert". This reflects an internal code change that will allow for voice packs.
* The targeting module will now determine whether or not your target is in combat with you with greater accuracy (it will now trigger based on the threat of your raid/party members and their pets.)
* Voice packs are now implemented. For any voice alert, you can change the recorded voice used. Currently only Matthew (the default Sku voice) and Joanna are supported.
* When you use a hotkey to enable a soft target type, it will now always read the name of the first soft target it finds consistently. It would previously not always do this if you disabled and enabled a soft target, which could lead to confusing results.

## V0.3.1

* Add an optional sound that plays when you tab target to an enemy in combat with you.
* The Taxi/flight master map no longer is disabled in WowVision if BlindSlash is enabled. This was added due to out of date information so has been reverted.
* Chat messages are now an alert with an included optional sound on receiving a new chat message.

## V0.3.0
Note: Due to an unanticipated behavior of the Ace3 library (a dependency of this addon) some of your speech and targeting settings may reset when you install this update. Sorry for the inconvenience.

* Added support for old-style scroll frames; the character currency frame will now scroll correctly automatically.
* Fixed a bug introduced in V0.2.3 where targeting settings were being ignored (like announce hard target.)
* Added the /enableaddon and /disableaddon chat commands to enable or disable an addon with the given name. For example /enableaddon blindslash or /enableaddon sku. Known addons (like Sku) have associated addons, so enabling or disabling such addons will enable or disable all associated addons to prevent errors.
* The speech module now defaults to voice ID 0 (probably Microsoft David.) This should prevent issues with NVDASapi installations that some users experience.
* Many settings have been refactored to use the alerts system. I often needed to add settings with repeated behavior (such as I wanted soft targeting to both speak and output a sound.) This behavior is so common that it will now use a standardized UI for similar settings. Practically this just gives you more customizability for various settings.
* Refactored hart target announcements and health monitor to use the alerts system.
* Added support for soft targeting enemy, friend, and interact using the alerts system. This includes sound effects for soft targets. Also fixes a bug where your soft target settings wouldn't actually update sometimes upon an addon reload.
* Added support for the quest log.
* Added support for the tradeskill frame (crafting/professions.)
* Added support for the item socketing frame.
* UI Dropdowns (such as auction house filters) will now work again while Sku is active. This may act oddly with unit dropdowns but is better overall and will work.
* The flight map/taxi frame will now be disabled if both BlindSlash and WowVision are loaded simultaneously (to prevent a pretty bad game freeze/crash.) Navigation with BlindSlash will still work in that frame when this is the case.

### For Developers
* Dev tools (such as printRegions and tpairs) no longer clutter up the global namespace by default. They can be bought back into global scope with the /wv dev command or the WowVision:globalizeDevTools() function.

## V0.2.4
This is an emergency fix to prevent action bars being unusable if a specific action errors out.

## V0.2.3

* Fixed some behind the scenes problems with bags.
* Fixed a bug where certain windows would close when they otherwise shouldn't (mostly a behind the scenes change.)
* Removed map data from the folder (this should result in faster load times.) It wasn't doing anything and needs to be refactored anyway.
* Added object buffers (similar to the views from Sku.) Use alt and the arrow keys to view. Only a general buffer is there currently.
* Added basic support for the currencies tab in the character frame.
* Fixed an issue where rapid target switches would read out every target tooltip in sequence (for example with /target macros that switch between 3 or 4 targets instantly in a row.)
* Fixed the macros screen; you can now pick up macros to place them on action bars.
* Added hotkey labels to action bar buttons.
* Reading of errors can now be turned on and off (thanks to Blind Mikey for the code contribution.)
* Speech can now optionally be interrupted when you switch targets (thanks to Blind Mikey for the code contribution.)
* Target health can now optionally be read out via audio mp3 files instead of tts (thanks to Blind Mikey for the code contribution.)
* Speech will now properly interrupt on UI events (opening menus, etc) when screenreader mode is disabled.
* Fixed several bugs with the taxi frame (flight masters) when you didn't have all waypoints for a given region.
* Added support for the lfd role poll and dungeon ready dialog.
* Added party quit and leave instance group commands (/pquit and /dquit respectively.)

## V0.2.2

* Fixed: The role poll popup... Actually works now.
* Fixed: Loot roll bindings moved to more reasonable keybindings that are listed in the readme.

## V0.2.1

* Fixed: The flight map now works again.

## V0.2.0

* Fixed: Temporarily removed very broken glyphs list.
* Fixed: missing mists .toc file (meaning that the addon can now run with Mists of Pandaria Classic.)
* Added: Loot rolls 
* Fixed: Items 11 and 12 in the Merchant buyback frame were missing.
* Added: Target Health percentages can be automatically announced in intervals of 5%.
* Added: Early implementation of the quest window (certain quest reward types may not be read; this will be fixed if it is the case.)
* Added: Taxi frame (the flight master screen to choose where to fly.)
* Added: Raid target markers can now be read when tab targeting.
* Added: Early support for the mailbox (should read all inbox UI elements.)
* Added: Support for the role poll popup.
* Added: Alternative drag hotkey (ctrl-d).
* Fixed: Prevent Eronious range readouts on friendly targets while in combat (impossible anyway due to Blizzard API restrictions.)

## V0.1.4

* Fixed an issue where buttons could not be right clicked. To right click buttons, press backspace on them.
* Fixed all dropdown menus accidentally being labeled as "test dropdown".
* Implemented Basic support for chat (to access, use shift-f3 or select chat from the /au menu.) Note that it does not yet support the combat log and does not work in combat.
* Now actually fixed input issues with input boxes in settings screens.
* Fixed an issue where buttons would sometimes not accurately show their selected/checked state.
* Fixed an issue where some Scroll Box elements (for example the categories list in the auction house) would have incorrectly ordered buttons or sometimes buttons that don't technically exist yet.
* Fixed an issue where some element properties would not be cleared when they were supposed to be. This should fix some very rare labeling and tooltip issues.
* Fixed an issue where the addon would stop allowing UI input if a supported window was open when combat started.
* Fixed an issue where you could click on/interact with disabled controls such as checkboxes and edit fields.
* Implemented support for most of the options screen.
* Game UI controls (such as checkboxes in the options panel) should now read their state when it changes (for example, checked/unchecked)


## v0.1.3

* Fixed incorrect .toc file data (the addon will no longer be displayed as SpeakAuras in the addon list... Oops.)
* Fixed terrible implementation of edit boxes causing issues with changing setting values under certain conditions.
* Temporarily removed speech delay setting as it can make your game unuseable if set to too-high a value by accident with no way to correct it. More fine-tuning on this setting is needed for it to be useful.