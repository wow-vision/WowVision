# Bump data tools

The bump module (`core/navigation/bumps.lua`, logic in `core/navigation/bumpLogic.lua`) says what the player bumps
into: the object in the way, outdoors the wall of the building or structure ahead, indoors "wall". It reads the
bump data in `mapdata/bumps/<client>/`, one plain Lua file per zone. These tools write that data and measure how
well the module does with it. Everything runs offline with LuaJIT (Lua 5.1, the game's rules), from the repo root,
and prints plain text.

## Where the data comes from

The chain, from the game's files to the addon:

1. **Export** (not in this repository): the wv-surroundings tools read each client's own map files offline (terrain,
   buildings with their rooms and doorways, objects; the AreaTable and WMOAreaTable database tables) and write
   the surroundings data, the public WowVision_Surroundings repository
   (https://github.com/JeanStiletto/WowVision_Surroundings), one folder per client (`era/`, `tbc/`, `forever/`),
   zone files in format 4 (a Lua header with the zone's frame, then JSON text). The export tools change with
   every round of the surroundings work and are published with the surroundings module. Object names come
   from the model file names (the community listfile) with a word list per language.
2. **Pack** (`pack.lua`, here): keeps of each zone only what naming a bump needs and writes it as Lua into
   `mapdata/bumps/<client>/`, with a `data.xml` per client that `vanilla/`, `tbc/` and `camelot/modules.xml`
   include. Mists and Retail have no data yet: the module loads there and says nothing.
3. **Game**: a zone's text is registered at login and read into tables (`bumpLogic.unpack`) only while the
   player is in the zone.

Only static things that are on screen for everyone are in the data: the objects, buildings and structures of the
world, and the names of places the game shows.

## What a zone file holds

All lists are numbers separated by spaces, in one string each (decoded on zone entry):

- `objects`: per object x, y (tenths of a yard), half length, half width (tenths), angle of the long axis
  (degrees), name number, room (0 outdoors).
- `objectNames`, `interiorNames`, `interiorWalls`, `structNames`, `roomAreas`, `ofTemplate`: per language
  (enUS, deDE, frFR); an empty or missing name falls back to English.
- `interiors`: per building its frame, ox, oy, scale, m00, m01, m10, m11 (world x = ox - scale * (m00 vx + m01 vy),
  world y = oy - scale * (m10 vx + m11 vy)).
- `rooms`: per room its building, its hall map (the UI map of a hall the game calls outdoors, 0 none), the count of
  box values and the floor boxes (x0 y0 x1 y1 in the building's frame), the count of outline values (0 or 4) and
  the outline box.
- `doors`: per doorway room a, room b (0 outside), building, x, y, the plane's normal nx ny, side, half width.
- `structCells`, `waterStructs`: the floor cells of structures (gates, city walls, bridges) as runs along a grid
  row (row, column, count, structure); water edges are no wall.
- `roomsId`: a fingerprint of the rooms and doorways. A room kept over a reload, or handed over by another module
  (`bumps:setRoomSource`), counts only while it is the same.

## pack.lua: write the data

```
luajit tools/bumps/pack.lua <WowVision_Surroundings folder>
luajit tools/bumps/pack.lua <WowVision_Surroundings folder> --check
```

The first writes every client folder it finds; the second only reports stale or orphaned files and exits with 1
when there are any (a data commit that changes no room or object leaves the files as they are).

## stacked.lua: the worst case on stacked floors

```
luajit tools/bumps/stacked.lua <client> [locale]
```

The game gives no height, so where floors lie on top of each other the module follows the room the player walked
into through a doorway. With the room unknown (after a hearthstone into a building), the objects of every room on
that spot count. This tool pushes toward every indoor object from 1 yd away on eight sides with the room unknown
and counts how often an object of another floor is named. It is the bound, not the usual case.

## replay.lua: logged walks through the room tracker

```
luajit tools/bumps/replay.lua <client> <walk log> [locale]
```

How often the tracker knows the room on real walks, how often it is unsure on stacked floors, and whether its
hall state agrees with the log's. The walk log format is in the tool's header (a trail of points every 2 yd with
the game's indoors flag, UI map and subzone). The locale is the game's language of the walk: the subzone names are
compared in it.

## cost.lua: memory and time

```
luajit -joff tools/bumps/cost.lua <client>
```

Per zone the index's memory once unpacked, the unpack time and a lookup's time.

## Results on 2026-11-07 (TBC Anniversary data)

- stacked.lua: another floor's object would be named in 0 to 7.3% of all pushes (Elwynn 3.7%, Dun Morogh 0.9%,
  the Undercity 4.6%, Teldrassil 7.3%), only with the room unknown.
- replay.lua over 26,927 logged trail points (11,106 inside, a German client): room known 98.8%, unknown on stacked
  floors 1.2%; hall state agreeing at 6,131 points, 125 only the log's, 31 only the tracker's.
- cost.lua (JIT off): index 0.2 to 2.4 MB per zone, unpack 2 to 16 ms, a lookup some microseconds.

## Known limits

- No floor heights: the tracker knows rooms, not floors. A module with floor heights can hand its room over
  (`bumps:setRoomSource`).
- A ramp's or stairs' side is not named (it needs the surroundings' place grid); a module that has it can give the
  wall text (the same hook).
- Object names are only as good as the model names: a few are generic ("object").
