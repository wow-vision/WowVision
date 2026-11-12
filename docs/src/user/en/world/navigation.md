# Navigation: Maps, Routes and Beacons

WowVision can guide you to a place on foot. You pick where you start and where you want to go in the navigation window (F10), WowVision works out a route along known paths, and then an audio beacon leads you from waypoint to waypoint until you arrive. This page covers the navigation window, the beacon and all the keys you use while walking a route.

## How it works in short

1. Press F10 to open the navigation window.
2. Choose your entry point: the place on the known path network where your route starts. The nearest one is already selected for you.
3. Search for a destination and press Enter on it.
4. WowVision says how many waypoints the route has and how long it is, and a beacon starts to ping.
5. Turn towards the beacon, walk, and listen. Each waypoint you reach plays a short sound and the beacon moves on to the next one. At the end you hear "Arrived" and the name of the place.

You can also set a straight-line beacon with no route at all, from the Direct checkbox in the window, from the scanner, or with the /beacon command.

## Which routes you have

Routes need map data: a network of waypoints that are linked to each other, plus the names of the places you can go to. WowVision has two route systems, each with its own data. Which one you have depends on your game version:

| Game version | Routes |
|--------------|--------|
| WoW: Forever | [WowNav](./wownav.md), on by default. You can turn it off and use the classic routes instead. |
| The Burning Crusade | [Classic routes](#classic-routes). |
| Classic Era | Classic routes, if the game loads their map data; see [Map data](#map-data). |
| Mists of Pandaria and Retail | No map data is included. The navigation window opens but its lists are empty. Straight-line beacons, /beacon, the distance announcement and every other key on this page still work. |

Both systems use the same window, the same keys and the same beacon, so this page applies to both, and says so where they differ. What is special about each one is in [Classic routes](#classic-routes) further down and on the [WowNav](./wownav.md) page.

The examples on this page use the plain place names of WowNav. Classic routes read names in a longer form; see [Place names](#place-names).

## The navigation window (F10)

Press F10 to open the navigation window. Press Escape to close it. On a controller, hold both shoulder buttons and press D-pad up (see [Controller](../controller.md)). If the game cannot tell WowVision where you are (for example inside an instance on Retail), the window stays empty.

Pressing F10 while you are in the quest log opens the window aimed at that quest's next target, the same place the Scanner's Enter on the quest leads to: the nearest target of its first unfinished objective, or its turn-in once it is complete. That target heads the destination list and is selected, so Enter starts the route. The quest is the one your cursor is on in the log, or else the one whose details are open. A quest with nowhere to go, or a place without route data, opens the window as usual.

The window has four stops. Move between them with Tab and Shift+Tab, and move inside a list with Up and Down. See [Interface](../basics/interface.md) for the general keys.

| Stop | What it is |
|------|------------|
| Direct | A checkbox. Off every time the window opens. |
| Entry Points | The closest points of the path network: 20 with classic routes, 50 with WowNav. Not shown while Direct is on. |
| Search | A text field that filters the destination list. |
| Destinations | The list of places you can go to. |

When the window opens, you land on the entry point that is already selected, so you can often skip straight to the search.

### Entry points

The entry point is where your route joins the network. WoW is fully three-dimensional, so the closest waypoint is sometimes the road under a bridge or the floor below you. That is why WowVision lists the closest ones and lets you choose.

Each entry reads its name, its distance and the direction relative to where you are facing, for example "Innkeeper Allison (Innkeeper), 4 yards, ahead left". The directions are ahead, ahead right, right, behind right, behind, behind left, left and ahead left. The entry that is chosen is announced with selected.

- The closest entry point is selected when the window opens.
- Press Enter on another entry to select that one instead. You hear selected at once, and again whenever you move back onto it. Only one entry is selected at a time.
- While you swim or dive, the nearest entry that lies in water is preselected instead, if the data knows about water points. With WowNav, if there is no water point nearby, you hear "No water point nearby". The classic data has no water points, so there the nearest entry stays selected.

The route you get includes the walk from where you stand to the entry point. So choose an entry that you can really walk to.

### Direct

Tick Direct (press Enter on the checkbox) if you do not want a route. The entry points disappear, and Enter on a destination sets a straight beacon to exactly that point. You hear, for example, "Direct: Innkeeper Allison (Innkeeper), 120 yards", and on arrival "Arrived" followed by the name. Use this when you are already close, when you are inside a building the network does not know, or when you want to go somewhere in a straight line.

Direct is the first stop. To reach it, press Shift+Tab from the entry points.

You do not need the checkbox for a single straight beacon: Backspace on a destination sets one at once, while Enter still routes. The checkbox is still useful with WowNav, because only with Direct on does the list also show places no route leads to.

### Searching for a destination

Press Tab from the entry points to reach Search. The edit box takes your typing immediately, and what you have typed is read as you type. Type a fragment of a name, for example "auctioneer", and press Enter to apply it. WowVision reads back what you typed. The list below is filtered at once. Tab applies the text as well and moves on to the next stop; Escape closes the edit box without changing the search.

- The search is not case sensitive and matches any part of a place's text. It is one text fragment, not several words: "auctioneer stormwind" finds nothing, but "auctioneer" or "stormwind" each work.
- With WowNav that text is the name in English and German, the categories of the place and its zone. With classic routes it is the whole long name, including the role, the zone and the numbers.
- Leave the box empty to list everything on your continent, up to the nearest 1000 places with WowNav.
- The search covers all of the map data on the continent you are on, so routes can leave the zone you are in.

### Destinations

Press Tab again to reach Destinations. It is one long list, sorted by distance from where you opened the window, the nearest first. It can be very long (up to 1000 entries with WowNav, tens of thousands with classic routes), so it works like a single control rather than a real list of items:

| Key | What it does |
|-----|--------------|
| Up / Down | Previous / next destination. |
| Home / End | First / last destination. |
| Enter | Close the window and start the route (or the straight beacon, if Direct is on). |
| Backspace | Close the window and set a straight beacon to the destination, without a route, whether Direct is on or not. |

Each destination reads its name and its distance, then its position in the list. With WowNav, what the place is and where it is come after the distance, for example "Innkeeper Allison (Innkeeper), 85 yards, quest giver, vendor, innkeeper, Stormwind City, 1 / 342". A destination you reached in the last few minutes is announced with Visited first; see [Visited places](#visited-places). An empty list reads "Empty".

When you press Enter, you hear the route summary, for example "12 waypoints, 340 yards". The yards include the walk to your entry point. The summary can say more about how the route ends: see [The last stretch](#the-last-stretch) for classic routes and [WowNav](./wownav.md#starting-and-following-a-route). If something is wrong you hear No route found, sometimes followed by a short reason such as "unreachable" (no path leads there from your entry point) or "no entry".

### From the scanner

In the scanner ([Scanner](./scanner.md)), Enter on a quest, an NPC or any other placed entry opens the navigation window already aimed at it. The closest entry point and the scanner's entry as destination are both selected, and the focus lands on the destination. Press Enter to route there; if you want a different entry point, press Shift+Tab twice first. Without map data for the continent the scanner sets a straight beacon directly and does not open the window.

## Following a route

### What you hear

When the route starts, WowVision speaks the summary and the beacon begins to ping. Waypoints are not read out one by one. Instead you hear them:

- The beacon pings towards the current waypoint. The ping changes with the direction and the distance to the waypoint. It pings faster the more directly you face the waypoint, about every 0.7 seconds when off course and about every 0.3 seconds when you are aimed at it. Distance is heard in steps of about 6 yards and works out to roughly 180 yards.
- Aligned (a clack) plays when you turn to within 10 degrees of the waypoint. Off course (a click) plays when you turn away again. These only play when you cross that line by turning.
- Waypoint reached (a success sound) plays every time you get close enough to a waypoint, including the last one.
- Right after the sound, WowVision says how many waypoints are left, for example "3 remaining". The waypoint the beacon now leads to counts too. At the last waypoint you hear Arrived instead, and at a portal, the tram or an elevator on a WowNav route you hear WowNav's own guidance. This works on classic routes and WowNav routes alike. The setting Announce Remaining Waypoints in the Navigation module (on by default) turns it off.
- Arrived is spoken at the end of a route, followed by the name of the destination.
- Beacon stopped is spoken when you cancel.

A waypoint counts as reached when you are within the arrival distance of it (see [Arrival distance](#arrival-distance)). With WowNav, a waypoint can also have a larger distance of its own.

### Beacon sounds

All beacon sounds are one alert called Beacon in the Beacon and Routes module (WowVision menu, Navigation, Beacon and Routes, Beacon). The alert and each of its four sounds has its own Enabled switch and its own sound, so each cue can be turned off or changed on its own. See [Alerts](../basics/alerts.md) for how alerts work.

| Sound | Default | When it plays |
|-------|---------|---------------|
| Beacon Sound | Probe (Mid) | The directional ping towards the current waypoint. |
| Beacon Aligned | clack | You turned to face the waypoint. |
| Beacon Off Course | click | You turned away from the waypoint. |
| Waypoint Reached | success sound | You reached a waypoint. |

For Beacon Sound you choose one of the beacon sets: Notification, Probe (Deep), Probe (Mid), Steel Gong and Beacon 6 (Sku's beacon 6). Moving onto an entry in the picker plays a sample. For the other three you pick any sound from the sound list.

### Keys while you walk

| Key | Binding name | What it does |
|-----|--------------|--------------|
| I | Turn to Waypoint | Turns your character to face the current waypoint. See below. |
| Ctrl+I | Turn to Target | Turns your character to face your target. See below. |
| Ctrl+U | Turn to Focus | Turns your character to face your focus. See below. |
| Alt Gr or Ctrl+Alt | (setting) | Speaks the distance to the current waypoint. Held, it repeats every second. |
| Unbound by default | Announce Distance | The same distance announcement on a key of your choice. |
| Alt+P | Cycle Arrival Distance | Switches between the short, medium and long arrival distance. |
| Ctrl+W | Next Waypoint | Skip to the next waypoint. |
| Ctrl+S | Previous Waypoint | Go back to the previous waypoint. |
| Ctrl+Shift+N | Start the Route Again From Here | Starts the last route again from where you stand. |
| Ctrl+Shift+R | Reverse Route | Turns the running route around, back to where it started. |
| Shift+F12 | Cancel Navigation | Stops the route or beacon. |
| F10 | Navigation | Opens the navigation window. |

All of these can be changed in the keybinding window (WowVision menu, UI, Bindings); see [Keybindings](../basics/keybindings.md). The full list is in the [binding reference](../reference/keybindings.md).

### Turn to waypoint (I)

Addons cannot turn your character directly, so WowVision turns the camera and hands the new direction to your character. Press I while you follow a route and your character turns to face the current waypoint. The turn takes a few frames and works standing still or while walking; when you are moving, it aims at where the waypoint will be when the turn ends, so you do not circle a waypoint you are about to reach.

Nothing is spoken when it works. A few things you should know:

- If you already face the waypoint (within about 3 degrees), the press turns nothing. While you swim or fly with the pitch lock on, it levels your character instead; see [Movement](./movement.md).
- A press while a turn is still running is ignored. Pressing a turn key yourself stops the turn where it is.
- Without a route you hear No active waypoint. (The exception is WowNav at a dock or tram station; see [WowNav](./wownav.md).)
- Where the game hides your position and facing from addons (instances on Retail) you hear Turning is not available here.
- On a controller, press the right stick instead of I.

Turning needs two camera settings: the camera following style Always (the game option "Always adjust camera") and instant switching between saved camera views. WowVision sets both once on each character, at the first login where one of them had to be changed, and tells you in the chat: "WowVision set the camera to always follow behind your character, which turning to waypoints needs. You can change the camera following style in the game options under Controls." If you change the following style back later, turns will land in the wrong places. WowVision does not set it again. WowVision also uses saved camera view 5 for turning, so anything you saved there is overwritten. During a turn it briefly changes the game's mouse look speed and puts your own value back afterwards. With a gamepad, free look is switched off for the length of the turn.

### Turn to target and focus (Ctrl+I, Ctrl+U)

Ctrl+I turns your character to face your target, Ctrl+U to face your focus. It is meant for units you cannot click or follow, such as an escort NPC: put it on your focus (/focus) and keep your target free for the fight.

The game tells addons nothing about where an NPC stands, but it does say whether a unit's nameplate is in front of the camera or behind it. So a press switches the camera to first person, turns it around you until the nameplate changes sides, works out the direction from that, and turns you with the same turn as Turn to Waypoint. A press takes about half a second. The camera moves first; your character turns once, at the end. You hear a click when you face the unit. When the unit stands close, or is off screen while offscreen nameplates are off, the press measures with the camera close behind you instead, which takes about a second longer. A unit within about 2 yards cannot be measured that way; you are standing at it then. Walking while you press works, but the result is most exact when you stand still.

- The unit needs a nameplate. For NPCs, friendly NPC nameplates must be on: the game option, or Apply Recommended Game Settings (see [First login](../getting-started/first-login.md)).
- If you already face the unit (within about 3 degrees), nothing turns; you only hear the click.
- Without a target or focus you hear No target or No focus; without a nameplate, No nameplate.
- In dungeons and other instances the game hides friendly nameplates from addons, so you hear Friendly nameplates are hidden here. Enemies still work.
- If your target or focus changes during the press, you hear Lost the nameplate.
- If the game refuses the camera changes the press needs, you hear Turning is not available here; if the nameplate gave no answer, Could not turn to it or Nameplate position is hidden here. Your character does not turn then.
- Pressing a turn key yourself stops it. A press while Turn to Waypoint is still turning is ignored.
- The press uses first person (camera view 1, which cannot be saved over) and puts the camera back behind you afterwards, as Turn to Waypoint does with view 5.

### Arrival distance

The arrival distance is how close, in yards, you must get to a waypoint for it to count as reached. A small distance makes you walk precisely onto each point; a large one forgives wandering. WowVision has three values and one of them is active at a time. It counts for the classic routes and for WowNav. With WowNav, a waypoint that has a larger distance of its own in the data uses that one; see [WowNav](./wownav.md#starting-and-following-a-route).

| Name | Default distance |
|------|------------------|
| Short Range | 0.3 yards |
| Medium Range | 1 yard (active by default) |
| Long Range | 3 yards |

Press Alt+P while following a route to cycle short, medium, long and back to short. WowVision speaks the name and the distance, for example "Long Range, 3 yards". Use the short range in tight places such as a doorway and the long range in open country. The settings are under [Settings](#settings). There, Left and Right change each distance by 0.1 yards, and Enter lets you type one, such as 0.5.

### Announce distance

Alt Gr speaks the distance in yards to the waypoint you are walking to, for example "120 yards", just like Sku. Windows reports Alt Gr as Ctrl and Alt pressed together, so Ctrl+Alt does the same thing. If you hold the keys, the distance is repeated every second while you walk. Only the speech carries it; nothing is written to the chat.

- Without a route you hear No active waypoint; if the game cannot give your position you hear Position unavailable.
- It stays silent while you type in an edit box, so typing characters with Alt Gr (such as @, { or [) does not talk. It is also silent while Shift is held.
- Any other shortcut that uses Ctrl+Alt will also trigger the announcement. If that bothers you, turn off the Announce Distance with Alt Gr setting and bind the Announce Distance binding to a key you do not use otherwise.

### Next and previous waypoint

When you have wandered off, or want to skip a waypoint you cannot reach, press Ctrl+W to move the beacon to the next waypoint or Ctrl+S to go back one. The step plays the waypoint-reached sound and speaks how many waypoints remain, current one included, for example "4 remaining". At the ends you hear End of route or Start of route; only walking to the last waypoint finishes the route. Without a route you hear No active waypoint.

### Restart the route

If you have strayed far from the route, press Ctrl+Shift+N. WowVision plans the last destination you chose again, starting from where you stand now. It works for destinations from the window, from the scanner, from the route to your target, and for the corpse run. With classic routes the router picks whichever of the five nearest waypoints gives the best route. With WowNav the route starts where you stand, if WowNav knows which floor you are on. You hear the route summary again, or No route to start again if you have not chosen a destination yet.

### Reverse the route

Halfway along a route you may remember that you have to go back. Press Ctrl+Shift+R. The route turns around: the new route begins at the destination of the previous one, and its destination is where the previous route started, the entry point you chose in the navigation window. The waypoint the beacon was leading to stays active, so you walk back from where you are and do not go to the old destination first. You hear "Route reversed, back to" and the name of that place, then the summary of the new route with the waypoints and yards still ahead of you. For example, on the way from Priestess Anetta to Marshal Dughan you press Ctrl+Shift+R and hear "Route reversed, back to Priestess Anetta". If the start has no name, you hear "back to the start of the previous route".

This works on classic routes and WowNav routes alike. Afterwards, Ctrl+Shift+N goes to that start again. Without a running route you hear "No route to reverse".

### Cancel navigation

Shift+F12 stops the route or straight beacon: you hear Beacon stopped and the pings end. If nothing is running you hear No active waypoint. /beacon stop does the same.

## Route to your target

The Route to Your Target binding takes the creature or group member you are targeting as the destination. It is unbound by default; bind it in the keybinding window. See also [Targeting](./targeting.md).

What happens depends on who you target:

- A party or raid member. WowVision uses that player's current position.
- An NPC or creature. With classic routes, WowVision looks for the closest waypoint with exactly the same name within 120 yards. With WowNav, it uses the creature's position in the WowNav catalogue. Another spawn of the same kind further away than 120 yards does not count.
- Anything else. You hear Your target's position is not known.

Other things you may hear: You have no target, You are targeting yourself, Position unavailable, No route to your target (no map data here, or WowNav cannot start). With classic routes a route that the router cannot find is reported as No route found with its reason. If it works, you hear the target's name (with classic routes the name of the matching waypoint, in its long form) and then the route summary, and the route starts at once from your position (WowNav) or the nearest entry point (classic routes).

With WowNav, if it cannot tell which floor you are on, you hear "Your floor is not clear here. Choose your start." and the navigation window opens with the target already selected, so you choose the start yourself.

## Visited places

When you walk to the same kind of thing again and again (herbs, ore veins, the spawns of a creature), you do not want to be sent back to a place you just checked. The visited places feature remembers it for you.

- A destination you picked and reached counts as visited for a number of minutes (15 by default, a kind of respawn timer). Only the destination counts, not the waypoints on the way. This works for destinations from the window, the scanner, the route to your target and the corpse run.
- In the destination list, a visited destination is announced with Visited first.
- The memory is kept per character, uses real time, and survives logging out and reloading.
- Forget Visited Waypoints (in the WowVision menu under Navigation, Visited Waypoints) wipes it. You hear "Visited waypoints forgotten".
- The Enabled switch of the Visited Waypoints module turns the whole feature off.

Two bindings, both unbound by default, lead you to the nearest unvisited destination with the same name as the last one you picked:

| Binding | What it does |
|---------|--------------|
| Route to the Nearest Unvisited of the Same Name | Plans a route, entering at the entry point the window would preselect. Of the nearest 8 by straight line it takes the one with the shortest walk, as Auto Route does. |
| Direct to the Nearest Unvisited of the Same Name | Sets a straight beacon there. |

"Same name" means the whole name with WowNav and the name before the first semicolon with classic routes ("Peacebloom"), ignoring capital letters. The spot you are already at, and the ones marked visited, are skipped. So are the spots the keys already led you to, even when you left one before reaching it, until you pick a destination another way. Chain the key and you walk through every spawn of that object, one after the other.

While auto mode runs (below), either key steps the chain on to its next spawn, the same as Ctrl+W past the end of a leg.

Without a destination picked earlier you hear Choose a destination in the navigation window first. If every spawn is visited you hear "No unvisited" and the name, for example "No unvisited Peacebloom found".

### Auto mode

Auto mode does that chaining for you. In the navigation window, press Shift+F10 on a destination or an entry point and choose one of two entries:

- Auto Direct: a straight beacon to the destination. Each time you arrive, the next straight beacon goes to the nearest unvisited destination with the same name.
- Auto Route: a route to the destination. Each time you arrive, the next route goes to the unvisited destination of that name that is the shortest walk away. WowVision checks the nearest 8 by straight line and picks the one with the shortest walk, so a herb across a river does not win over one a little further away on your side. With WowNav this is planned in the background, and you may hear Calculating route first.

You hear "Auto Direct" or "Auto Route" when it starts, then the usual words of each beacon or route. The first leg starts at the entry point you selected in the window, as Enter does. The chain ends when every spawn is visited (you hear "No unvisited" and the name), when any other guidance starts (another destination, a beacon, /beacon, Ctrl+Shift+R), or when you stop the guidance with Shift+F12. Ctrl+Shift+N starts the current leg again and keeps the chain.

Ctrl+W and Ctrl+S step through the chain the way they step through a route. Past the end of the current leg, Ctrl+W goes to the next spawn: with Auto Direct at once, since a straight beacon has only one point, with Auto Route after the route's last waypoint. It skips a spawn you cannot reach or that is empty, and the chain does not offer it again. When a leg finds no route, Ctrl+W moves on the same way. Ctrl+S before the start of a leg goes back to the spawn before. After stepping back, the chain goes on through the spawns it already led to, then to new ones. Before the first one you hear Start of route.

Auto mode needs visited places switched on, because they are what it skips. With the Visited Waypoints module off, both entries only say "Auto mode needs Visited Waypoints switched on".

## Straight beacons and the /beacon command

You can set a beacon without the window. Type these commands in the chat box:

| Command | What it does |
|---------|--------------|
| /beacon | Speaks your position in map percentages, such as "50.5 30.4", and, if a beacon is active, its distance and angle. |
| /beacon 50.5 30.4 | Straight beacon to map coordinates on your current zone map: the numbers quest guides give you. You hear "Beacon set" and the distance. |
| /beacon to bank | Routes to the nearest known place whose name contains "bank". You hear its name, then the route summary. You do not choose an entry point: WowNav uses the one F10 would preselect, and with classic routes the router picks the best of the five nearest waypoints. |
| /beacon world x y | Straight beacon to raw world coordinates. |
| /beacon stop | Same as Shift+F12. |

With /beacon to, an unknown name gives "No route found" and the name. A beacon from /beacon with coordinates ends with "Arrived" when you get close enough, like any route.

## Classic routes

Classic routes are the route system of The Burning Crusade and Classic Era, and of WoW: Forever when you turn WowNav off. Everything on this page applies to them. This section adds what is only true for them.

### Map data

The map data comes in its own addon folder named WowVision_MapData_TBC. It is inside the WowVision download zip next to the WowVision folder, so one extraction installs both (see [Installation](../getting-started/installation.md)). It is switched on automatically as long as the addon is enabled in the game's addon list. Its TOC file is made for The Burning Crusade and WoW: Forever, so on Classic Era the game sees it as out of date and may not load it. WowNav does not use this folder: its data is inside the WowVision folder. Other map data addons for WowVision keep working beside the bundled one.

The bundled data is derived from the survey data of the addon Sku: its waypoints, the links between them and the names of NPCs, creatures and objects. It covers Eastern Kingdoms, Kalimdor, the Deeprun Tram, Outland and Northrend. The Northrend and Death Knight starting area files are included but are never extended beyond what the survey held, so expect more gaps there than in the old world. On a German or French game client the place names are shown in your language.

### Place names

Names in this data are stored in a fixed form: the name, then its role if it has one, then the zone, a spawn number and the map coordinates, all separated by semicolons. For example: "Shailiea;Stormwind City;1;30.38;53.33" or "Eldraeith;Herbalism Supplies;Stormwind City;1;46.66;78.65". WowVision reads the name exactly like that. Your screen reader may pause at the semicolons or read them aloud. The role words are useful when you search: "Questgiver", "Trainer", "Banker", "Auctioneer", "Repair", "Stable Master" and many more are part of the name.

### The last stretch

When a destination is not on the link network (most creatures and objects are not), the route goes through the network to the closest linked waypoint and then ends with a straight leg to the destination. WowVision tells you how long that straight leg is, for example "last 40 yards direct".

## Settings

Open the WowVision menu (/wv), then Navigation, then Beacon and Routes. Settings are shared by all your characters unless you change that in the module's context menu; see [Menu and settings](../basics/menu-and-settings.md).

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled | On | Turns the whole Beacon and Routes module off: not only the beacon but also routes, the keys and /beacon. |
| Arrival Radius | Medium Range | Which arrival distance is active. Alt+P changes it too. |
| Short Range | 0.3 yards | The short arrival distance (0.1 to 20 yards). |
| Medium Range | 1 yard | The medium arrival distance (0.1 to 20 yards). |
| Long Range | 3 yards | The long arrival distance (0.1 to 20 yards). |
| Announce Distance with Alt Gr | On | Whether Alt Gr and Ctrl+Alt speak the distance. The Announce Distance binding works either way. |
| Beacon | (see above) | The beacon alert and its four sounds: Beacon Sound, Beacon Aligned, Beacon Off Course, Waypoint Reached. Each has Enabled and a sound choice; Beacon Sound also has Beacon Volume. |

The Visited Waypoints module (under Navigation) has one setting:

| Setting | Default | What it does |
|---------|---------|--------------|
| Visited For (Minutes) | 15 | How long a reached destination counts as visited (1 to 1440 minutes). |

Close All Windows When a Route Starts (Navigation module, on by default) closes every open window as soon as you start a route or a beacon, so your keys are free for walking; the legs an Auto chain starts by itself leave your windows alone.

Three settings of the Navigation module are related: Announce Remaining Waypoints (on by default) says how many waypoints are left after each one you reach, Automatically Navigate to Corpse (on by default) starts a route to your body as soon as you are a ghost, and Auto-move to Interact Target is explained with the movement features. See [Movement](./movement.md) for those, for the compass and for following a player.

## Diagnostic commands

| Command | What it does |
|---------|--------------|
| /wv turnlog | Lists the last turns made by the I key with their error in degrees, in a window and in the chat, and speaks a summary such as "10 turns, mean error 1.2 degrees". Include this in a bug report if turning goes wrong. |
| /wv unitturnlog | Lists the last presses of Ctrl+I and Ctrl+U, one line each with what the press found and how far you turned, in a window and in the chat. The lines are also saved with your settings. Include this in a bug report if turning to a unit goes wrong. |

## Examples

### Walk from the bank to the auction house (Stormwind)

1. Stand outside the bank and press F10. You land on the closest entry point, announced with selected. That is fine, so leave it alone.
2. Press Tab. You are in Search and can type straight away. Type "auctioneer" and press Enter. WowVision repeats your text.
3. Press Tab to reach Destinations. You hear the nearest auctioneer with its distance and its position in the list. Press Down to hear the next one.
4. Press Enter. The window closes and you hear a summary such as "9 waypoints, 410 yards".
5. Press I to turn to the first waypoint, and walk. When you hear the beacon ping faster, you are facing the right way. Press Alt Gr at any time to hear how far the current waypoint is.
6. If you get lost, press Ctrl+Shift+N to plan the route again from where you stand.
7. At the end you hear "Arrived" and the name of the place.

### Follow a route to a quest NPC

1. Press F9 to open the scanner and find the quest, then its NPC (see [Scanner](./scanner.md)).
2. Press Enter on the NPC. The navigation window opens with the closest entry point and the NPC both selected, focus on the destination.
3. Press Enter. If you want a different starting point first, press Shift+Tab twice to reach the entry points, pick one with Enter, then return with Tab twice.
4. Walk the route as above. If the NPC is not on the path network, the final stretch is not a known path, so use the beacon and Alt Gr. With classic routes the summary says so ("last 25 yards direct"), and WowNav tells you at the end of the network how far the NPC still is.

### Find the next herb

1. Search for "Peacebloom" in the window and walk to the nearest one. When you arrive it counts as visited.
2. Bind Route to the Nearest Unvisited of the Same Name to a key.
3. Press that key. You are routed to the nearest Peacebloom you have not visited. Keep pressing it after each arrival.

## Related pages

- [WowNav](./wownav.md): the route system of WoW: Forever.
- [Movement](./movement.md): compass, facing, following, falling, walls and the corpse run.
- [Scanner](./scanner.md): lists of things around you, with Enter handing over to the navigation window.
- [Targeting](./targeting.md): selecting the target for the route to your target.
- [Alerts](../basics/alerts.md): how to change the beacon sounds.
