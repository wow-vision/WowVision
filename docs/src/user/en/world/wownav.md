# WowNav (WoW: Forever)

WowNav is the route system of WoW: Forever. It was made by Broesel33 for blind players, from a survey of the real walkable ground of the game world, and WowVision includes it with his permission. It knows where you can really walk, including stairs, bridges and the floors of buildings, and it can take you to portals, elevators, boats, zeppelins and the Deeprun Tram. This page explains what it does, how it differs from the classic routes and how to use it.

You use WowNav through the same navigation window and the same keys as the classic routes. Read [Navigation](./navigation.md) first; this page only describes what changes.

(WoW: Forever only. The other game versions use the classic routes.)

## Turning WowNav off

WowNav is on by default. Every route request goes to it: the navigation window (F10), the scanner's Enter, /beacon to, the route to your target, the corpse run and the visited-places keys. The classic routes are not used while it is on.

To use the [classic routes](./navigation.md#classic-routes) instead:

1. Open the WowVision menu (/wv), then Navigation, then WowNav Routes.
2. Turn off Routes from WowNav.

There is also an Enabled switch for the WowNav Routes module itself, which must stay on for WowNav to work.

## What it covers

The data comes with WowVision (in the release and beta downloads) and needs nothing else installed. It covers 51 zones on four maps:

- Eastern Kingdoms (26 zones, including the capitals Stormwind, Ironforge and Undercity, and Riverglades)
- Kalimdor (23 zones, including Orgrimmar, Thunder Bluff and Darnassus, Mount Hyjal and Shendralas)
- The Deeprun Tram
- Zephras Isle

About 111,000 places (NPCs, creatures, objects), 242 places to get somewhere else (dungeon entrances, portals, elevators, docks, tram stops, crossings between zones) and 788 fishing spots at the waters of 45 zones can be chosen as destinations.

Things WowNav does not do:

- No instances. Dungeon and raid interiors do not exist in the data. Dungeon entrances do, and you can walk to them. Entrances of some of the dungeons that are new in WoW Forever are missing.
- No vehicles in a route. Routes are always on foot. A boat, a zeppelin or the tram is not part of a route: WowNav guides you to its dock and you board it yourself.
- No flight paths.
- No danger warnings about enemies or creature levels. The only exception is the enemy outpost warning described below.
- Diving is yours. Water is flat in the data. The only dive route is the Ruins of Blackfathom in Darkshore.

On a map the data does not know, F10 lists nothing and /beacon to answers "No route found". The scanner's Enter then sets a straight beacon, as it does without map data. Where WowNav has data, the scanner's Enter on an NPC or object that WowNav's place list knows near that spot routes to WowNav's own entry of it, with its height; see [Scanner](./scanner.md). If the place list of a map cannot be read at all, you hear "WowNav catalogue not usable" followed by a reason; include it in a bug report.

## How it differs from the classic routes

| | Classic routes | WowNav |
|---|---|---|
| Game versions | TBC and WoW: Forever | WoW: Forever |
| Entry points in F10 | The 20 nearest linked waypoints, named like the places | The 50 nearest entries: places that sit on the path network (an NPC, a door, a portal) and the network's own waypoints within 10 yards of you. With Show Automatic Waypoints, the network's waypoints farther away too |
| Destinations | Every named waypoint of the continent, nearest first | The nearest 1000 places that match your search, each with its categories and zone |
| Search | Matches the name, role and zone as one text | Matches names in English and German, categories, search aliases and the zone name |
| Names | "Name;Role;Zone;1;30.38;53.33" | Plain names such as "Innkeeper Allison (Innkeeper)" (many NPCs carry their job in brackets), and descriptive names such as "Portal to Orgrimmar" |
| Floors | Not known | Knows floors and asks which floor you mean when it cannot tell |
| Portals, tram, elevators, docks | A waypoint like any other | Special handling with spoken guidance |
| When you wander off | You press Ctrl+Shift+N | Finds its way back by itself and has a key for a new route around a blocked spot |
| Arrival distance | Alt+P short, medium, long | The same; a waypoint with a larger distance of its own in the data uses that one |

## The navigation window with WowNav

F10 works as described in [Navigation](./navigation.md): Direct, Entry Points, Search and Destinations. What is different:

### Entry points

The entry points are the 50 nearest entries: the places that sit on the network (the flight master in front of you, a door, a portal) and the network's own waypoints right beside you. You choose where your route starts, as with the classic routes. WowNav never works out your start by itself, except for Ctrl+Shift+N and the route to your target, which start where you stand if that is clear. When you choose a place as your start, your route begins at that place itself.

- The network's own waypoints within 10 yards of you are always in the list, so you can start right where you stand even when the nearest place is far away. With Show Automatic Waypoints on, the waypoints farther away join the list as well. A waypoint is read as "Auto, height 54": only its height in yards is said.
- While you swim or dive, the nearest water point within 100 yards is always in the list and preselected. If there is none you hear "No water point nearby".
- If there is nothing of the network near enough, the list says Empty, and a route request answers "No WowNav network here".

### Destinations

Each destination reads its name, its distance, what it is and where it is, for example "Innkeeper Allison (Innkeeper), 85 yards, quest giver, vendor, innkeeper, Stormwind City". The extra words come from the categories of the place. They are: quest giver, trainer, vendor, flight master, innkeeper, banker, stable master, auctioneer, spirit healer, spirit guide, NPC or mob, chest, herb or ore, object, quest item, interaction object, mailbox, anvil, forge, door, book, chair, sign, fishing spot, switch, trap, spell focus, capture point, destructible building, guild bank, trapdoor, waypoint, orientation point, transport, live target, zone transition, transit, ship, tram, dungeon, portal, zeppelin, elevator and dive. You can search for any of these words, for the name or for a zone name: "banker", "mailbox", "Ironforge".

- The list shows at most the nearest 1000 matches. When it was cut, the first entry you hear starts with "The nearest 1000 of 4821 results".
- A destination with no network point near it (see Target Radius Around the Network (Yards)) is left out. A place whose zone has not been prepared yet is offered unchecked, and checked when you choose it.
- Extra information may come first, before the categories: "inexact +3.2 yards" (the place is not exactly on the network), "choose the floor" (the place is over several floors), "floor unknown", "no network point within the radius" or "water surface, diving depth 12 yards".
- Places to get somewhere else have descriptive names: "Dungeon entrance: The Deadmines", "Portal to Orgrimmar", "Ship dock to Auberdine", "Zeppelin dock to Grom'gol", "Tram dock toward Ironforge", "Deeprun Tram entrance", "Elevator: Thunder Bluff", "Crossing to Westfall", "Dive here" and "Surface here". Where two places of a zone would sound the same, they get "(lower)", "(upper)", a height or a number added. The place words in these names come from the game client. On a German client the names are German.
- Fishing spots are named after the water they cast into: "Fishing spot on the shore: Crystal Lake" or "Fishing spot on pier or quay: The Temple Gardens", with a number when several spots of a zone have the same name. Search for "fishing" or "fishing spot". See [Fishing spots](#fishing-spots).
- A dungeon with several entrances names the wing: "Dungeon entrance: Scarlet Monastery, Graveyard".
- The boarding points of docks are listed too: "On the ship", "On the zeppelin" and "At the vehicle", with the name of the dock as the extra words.
- With Direct on, no destination is dropped as unreachable, because a straight beacon needs no route.

If you choose a place a step further than the network reaches, WowNav ends the route at the network and says so; see [What you hear at the end](#what-you-hear-at-the-end).

### Asking for the floor

When your destination lies over several floors (a tower, a multi-storey building) and nothing says which one you want, a small window opens: Choose the target's floor. It has one button per floor, lowest first, for example:

- "Floor 1 of 3, lowest, height 40"
- "Floor 2 of 3, height 52"
- "Floor 3 of 3, highest, height 64, no path from here"

no path from here means that floor cannot be reached from your starting point. Move with Up and Down and press Enter on the floor you want; the route is then planned. Your own floor is never asked, because you chose your start in F10. A corpse run takes the lowest reachable floor without asking.

## Starting and following a route

When you choose a destination, WowNav searches for the route in small steps so the game does not stutter. If the search takes more than a second, you hear "Calculating route". Then you hear the summary, for example "14 waypoints, 520 yards".

The summary may continue:

- "approximate, 4 yards" (the place is not exactly on the network; "height unknown" may be added) or "water surface, diving depth 12 yards".
- "then the portal" (or "the tram", "the elevator", "a dive", "surfacing"): the route ends at a transit that is described below.
- "Approximate target position." when the data's position of the place is itself an estimate.
- "Warning: there is no way around the enemy outpost, the route leads through it." or "Warning: the target lies in an enemy outpost.", only with Avoid Enemy Outposts on.

The beacon, its sounds, Ctrl+W, Ctrl+S, Shift+F12, Alt Gr and I all work as in [Navigation](./navigation.md). The differences:

- A waypoint counts as reached within the Alt+P arrival distance, or within its own distance from the data when that is larger. The areas of portals, the tram and elevators widen with Alt+P too.
- Ctrl+W and Ctrl+S step along the route's own waypoints.
- Ctrl+Shift+N plans the last destination again from where you stand, but only if WowNav knows which floor you are on. If you stand beside the network, the route starts at its nearest point within 30 yards. Otherwise you hear "Your floor is not clear here", or "No WowNav network here" when nothing of the network is within 30 yards.
- Shift+F12 ends everything WowNav does: the search, the route, a transit that waits for its far end, the dock guidance and the beacon at a fishing spot.
- /beacon to name takes the nearest place with that name, from WowNav's list, with the entry point F10 would preselect.

### While you walk

WowNav watches your progress and speaks only when it matters:

| You hear | What it means |
|----------|---------------|
| "Last network point; the last stretch is unchecked, move carefully" | The path network ends before your destination. The rest is a straight walk. |
| "Back on the route" | You wandered off but stood on a later part of the route, which is now current. |
| "One waypoint back" | You were pushed off sideways at a narrow gate, so the beacon went back one waypoint. |
| "Route ended" | The route is finished, usually because you left the map. |
| "Route ended outside the network's zones." | You walked out of the area the data knows. |

If you get stuck, WowNav tries to re-enter the route and step back at gates, but it never plans a new route on its own. That is your decision: press the key below. If you die, the route stops without a word.

### What you hear at the end

- On the network, or within 1.5 yards of its end: "Arrived" and the name of the place.
- Close to the network but farther from its end: "The network ends 4.2 yards from the target; search the surroundings yourself. The last stretch is unchecked." If the data does not know the height, "horizontally" is added.
- A water target: "The network ends 6.1 yards from the water surface position; diving depth 12.0 yards. The rest of the way and the diving are yours, the last stretch is unchecked."

### Route status and new route

Two bindings are unbound by default; bind them in the keybinding window (WowVision menu, UI, Bindings), see [Keybindings](../basics/keybindings.md):

| Binding | What it does |
|---------|--------------|
| WowNav Route Status | Says what WowNav is doing: "Searching the route to Allison", "En route to Allison, waypoint 3 of 14", "Waiting for the far end of the portal", "Riding to the noted dock Ship dock to Auberdine", "At a dock, waiting", "At a fishing spot" or "No active route". |
| New WowNav Route Around a Blocked Spot | Use it when you are stuck on a link (a fence, a closed door, a ramp you cannot climb). The link you are on is blocked in the plan, and a new route is searched from the last waypoint you reached. You hear "Searching a new route". Without a route you hear "No active route". |

## Transit: docks, boats, zeppelins, trams, portals and elevators

### Docks

A dock is a waiting place for a ship, zeppelin or tram stop. Choosing one in F10 routes you to its waiting point on foot. When you arrive, you hear what to wait for, for example: "Dock Ship dock to Auberdine reached. Wait here for the ship. Board when you hear it arrive. The beacon shows the boarding direction; I turns you toward it." The beacon then leads to a boarding point a few yards ahead and ends there: "Boarding point Ship dock to Auberdine reached". WowNav cannot tell when the vehicle is there; you board by ear.

If you stand at a dock and choose the other end of the same line, nothing is walked. WowNav notes it and says where the ride goes and with what, for example "Ride to Ironforge with the Deeprun Tram: wait here, board by ear and get off at the last stop. Near it, I turns you toward the dock." When you come near that dock later, you hear its name followed by "is near; I turns you toward it", and I now faces that dock. Choose the dock again to walk the rest of the way. This only works for a line whose docks are on the same map, such as the Deeprun Tram: the list only holds places of the map you are on, so the dock at the far end of a sea crossing to another continent cannot be chosen from here.

Being in a station (within about 100 yards of a dock) counts as having reached it, so you can choose the far dock without walking to the near one first. Choosing a dock of your own station, such as the other dock in Menethil Harbor, walks to it as usual.

### Portals, the tram entrance and walk-in places

Portals and the tram entrance work by walking into them. A route ends at the portal, and WowNav says so before you reach it, because a portal teleports at once: "Ahead: walk into the portal; the route goes on after it". Walk into it. When you come out at the far end, you hear "The route goes on", and WowNav searches the rest of the way from there. If nothing happens within about 90 seconds (longer for rides, which wait three full cycles of the vehicle) you hear "The transit took too long; route ended". The Wind Bridge of Zephras Isle has no such limit: it comes at its own time.

If you choose the portal or the tram entrance itself as your destination, you are guided to a point just before it and told: "Prepoint reached. Walk straight ahead through the entrance or portal; the beacon stays on until the activation area." Then: "In the activation area. Keep walking straight ahead; only a map change confirms the transition. The route stays on until then." After the map change you hear "Map change after the activation area; route ended. The destination is not confirmed."

### Elevators and dives

An elevator is a place to wait: "Use the elevator; the route goes on after it. Board only when the vehicle is safely there." A dive is "Dive here; the route goes on after it", and the way back up is "Surface here; the route goes on after it". The route goes on after you are at the other end.

### The turn key without a route

The I key normally needs a route. At a dock it also works without one: at a reached dock it turns you to the boarding point, and near a noted dock it turns you to that dock. At a fishing spot you reached, it turns you to the water.

### Zephras Isle

The portals and the Wind Bridge of Zephras Isle are included. Their positions are estimates, so WowNav adds "The position is approximate." to what it says there. The portals are not walked into: you target the portal and interact with it. A route through one ends there with "Target the portal with soft targeting and interact with it; the route goes on after it". The Wind Bridge comes at its own time: "Wait here until you hear the Wind Bridge, then step into the wind current; the route goes on after it". There is no time limit for it. Once you have arrived at the far end, the route goes on.

The portal to Valanaar takes the Horde and the Alliance to different places. A route only uses the way that belongs to your faction.

If you choose one of these portals or the waiting point of the Wind Bridge itself as your destination, you hear at the prepoint "Prepoint reached. Walk on to the portal; the beacon stays on until you are there." (for the bridge "Prepoint reached. Walk on to the waiting point of the Wind Bridge; the beacon stays on until then."). At the portal you hear "At the portal. Target it with soft targeting and interact with it; the route stays on until the transition is confirmed.", at the bridge "At the waiting point of the Wind Bridge. Wait until you hear the bridge, then step into the wind current."

## Fishing spots

WowNav knows 788 places to stand and fish, at the waters of 45 zones. A fishing spot stands on solid ground on the shore, or on a pier, a jetty, a quay or a bridge. You may wade in shallow water there, but you never have to swim. From the spot, the water lies 10 to 20 yards ahead in one direction, the range of your cast.

1. Press F10, search "fishing" and choose a spot in Destinations, for example "Fishing spot on the shore: Crystal Lake (3), 120 yards, fishing spot, Elwynn Forest".
2. Follow the route. When you arrive, you hear where the water lies, seen from the way you face: "Fishing spot on the shore: Crystal Lake (3) reached. The water is ahead to the left. Cast range about 10 to 20 yards. Press I to turn to the water." The directions are straight ahead, ahead to the left, to the left, behind to the left, behind you, behind to the right, to the right and ahead to the right.
3. A beacon now sounds from the water, 15 yards out, in the middle of your cast range. Press I to face the water, then cast.
4. The beacon stops when you walk away from the spot (more than 20 yards), when you press Shift+F12 or when you start a new route.

The water point is only there to face. WowNav never routes you into the water. If the network ends farther from the spot than your cast range, you hear the usual "The network ends ... from the target" instead, and no beacon starts.

## Settings

Open the WowVision menu (/wv), then Navigation, then WowNav Routes.

| Setting | Default | What it does |
|---------|---------|--------------|
| Enabled | On | Switches the whole module on or off. |
| Routes from WowNav | On | Sends every route request to WowNav instead of the classic routes. |
| Road Preference (Percent Longer) | 60 | A route on roads and paths may be this many percent longer than the shortest way. 0 means always the shortest. Up to 300. Swimming also counts as this much longer. When you change it during a route, one second after you stop adjusting you hear "Searching the route again with the new road preference". |
| Avoid Enemy Outposts | On | Routes go around the outposts and capitals of the opposing faction. Where there is no way around, the route leads through and warns you. Changing it re-plans a running route. |
| Show Automatic Waypoints | Off | Adds the network's own waypoints within 60 yards of you to the destination list, and mixes the waypoints up to 300 yards away into the entry points. Without it, the entry points still list the waypoints within 10 yards of you. They read "Auto, height N". |
| Target Radius Around the Network (Yards) | 30 | How far from the network a place may lie and still get a route (1 to 100). Farther places have no network point. |
| Height Tolerance of a Floor (Yards) | 3 | The height band that counts as one floor (0 to 20). |
| Step Back at Gates | On | When you drift sideways at a gate, the beacon goes back one waypoint ("One waypoint back"). |
| Prepare Neighbouring Zones | On | Prepares your zone and the zones next to it in the background, so the first route there does not wait. |

## Examples

### Walk to a trainer in a city

1. Press F10. The entry points are the network's waypoints right beside you and the nearest places on the network, for example a flight master. The closest is already selected.
2. Press Tab and type "trainer", then Enter.
3. Press Tab to reach Destinations. You hear, for example, "Einris Brightspear (Hunter Trainer), 140 yards, quest giver, trainer, Stormwind City". Down reads the next one.
4. Press Enter. You hear the summary, such as "12 waypoints, 330 yards". Press I to turn and follow the beacon. At the end: "Arrived Einris Brightspear (Hunter Trainer)".

### Take the boat from Menethil Harbor to Auberdine

1. In Menethil Harbor, press F10, search "Auberdine" and choose "Ship dock to Auberdine" in Destinations.
2. Follow the route to the dock. You hear "Dock Ship dock to Auberdine reached. Wait here for the ship. Board when you hear it arrive."
3. Press I to face the boarding direction and board the ship when it arrives.
4. Ride to Auberdine. Once you have landed on Kalimdor, press F10 there and choose your next destination as usual.

### Use a portal

1. Press F10, search "portal" and choose "Portal to Orgrimmar" (or any portal you need).
2. Walk the route. Before the portal you hear "Ahead: walk into the portal; the route goes on after it".
3. Walk into the portal. On the other side you hear "The route goes on", then the new summary.

### A blocked spot

1. You follow a route and walk into a fence the data does not know about. WowNav tries to find its way back by itself.
2. If you are still stuck, press the key you bound to New WowNav Route Around a Blocked Spot. You hear "Searching a new route".
3. Follow the new beacon. The blocked link is avoided for the rest of this route.

## Related pages

- [Navigation](./navigation.md): the navigation window, beacons, arrival distance and all route keys.
- [Scanner](./scanner.md): its Enter opens the navigation window with WowNav as well.
- [Movement](./movement.md): the compass, following, falling and the corpse run.
- [Interface](../basics/interface.md): general keys in WowVision windows.
