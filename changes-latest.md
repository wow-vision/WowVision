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
