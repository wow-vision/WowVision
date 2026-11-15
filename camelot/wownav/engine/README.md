# WowNav engine in WowVision

These seven files are Broesel33's WowNav engine, taken from the demo addon of his public data repository
(github.com/Broesel33/WoW_NavigationData, `DemoAddon/WowVisionNavigation/`). The commit they come from is named in
each file's first line. Broesel allowed WowVision to take whatever it needs from WowNav into WowVision; the data stays
in his repository (the submodule `mapdata/WoW_NavigationData`).

- `NavNetwork.lua`: decoder, continent graph, seams, attachment cells, A* search.
- `Guidance.lua`: arrival at a waypoint, gate line, angle bisector, height along a link, re-entry.
- `TargetCatalog.lua`: target contract (`Validate`), the continent's catalogues (`ActivateZones`) with the compact
  logical catalogue kept as it is (`ValidateCatalog`), and the list search over it (`Scan`, `Nearest`, `Materialize`).
- `TargetResolver.lua`: binding a target to the network (exact, approximate, ambiguous, levels).
- `DockNavigation.lua`: docks of the tram, ships and zeppelins: the waiting circle, the arrival text, the boarding
  orientation point, the noted counterpart dock (passive mode) and the turn key's target there.
- `TransitActivation.lua`: walk-in targets (portal, tram entrance): the proof, the prepoint, the capture circle.
- `FishingNavigation.lua`: fishing spots: the water point, the arrival text, the turn key's target and the direction
  tone.

What uses them: `../route.lua` (his route rules from `WowVisionNavigation.lua` and `ActionNavigation.lua`),
`../catalog.lua` (the destination list: his `Navigation.SearchTargets` and `WowVisionNavigationResolveListed`) and
`../module.lua` (with his zone loader's `PreloadNeighbours`), `../dock.lua` (what his core does around `DockNavigation`),
`../fishing.lua` (what his core does around `FishingNavigation`).

## Changes for WowVision

Keep this list current; everything else is his text, line for line (line endings LF).

- `NavNetwork.lua`, packed data: a zone file may be packed (`tools/wownav-pack.lua`): its text sits in
  `WVN7Src` / `WVN7LogicalSrc` / `WVN7DynSrc` and is compiled on first use (`Unpacked`, `IsPacked`,
  `ZoneAvailable`, `ZoneSource`, `LoadZone`, `N.LogicalTargets`, `N.DynTargets`, `N.DropTargets`). A raw table of a
  packed zone is freed after decoding. Unpacked files keep working.
- `NavNetwork.lua`, known misses: inside a job (`N.Job`), a plain search (no outpost avoidance) that ran out without its
  target keeps the set of waypoints it reached; `N.Route` answers "no route" at once for a later target none of whose
  options is in a set that holds all of the start's options (`reachCache`, `KnownUnreachable`; `Pass` returns that set
  on a miss). Same answers, measured on the real data: his floor check (`Prepare`, and our bands of cells) routes every
  candidate of a band, and since data 5b8b5f2 joins the zones, each miss searched the whole continent (Stormwind,
  a target over three floors: 990 misses of 376,767 waypoints each, 1.94 million test slices; with the sets 3,025).
  Since his cost comparison the check covers all starts and goals of a search and runs after the same-link check: a pair
  on one link is never answered from a set (on a one-way link the near end may be out of reach of the far end).
  `N.wholeMisses` and `N.knownMissAnswers` count both for the module's trail.
- `NavNetwork.lua`, closed water: `N.Route` drops a goal on a node that nothing can enter (`N.ClosedWater`: his flag
  `noExit`, no link in its zone in either direction, no seam, no action from it) and answers "no route" at once when
  no goal is left. His S10b keeps such nodes without links for the announcement; the field-mask choice of a cell may
  still offer one first (`ChooseAttachment`; `CellBindings` leaves noExit out of the others only), and each such goal
  searched the whole continent: a corpse run in the Wetlands marsh took 72 s in the game, 0.03 s offline with the
  check. In data 1f8530e: 1,265 such nodes, 911 of them a cell's attachment. `N.closedWaterGoals` counts them for
  the module's trail.
- `NavNetwork.lua`, memory: `N.UnloadZone`, `N.KeepZones` and the hook `N.onZoneUnloaded` drop decoded zones again
  (his core keeps every decoded zone for the session).
- `NavNetwork.lua`, decoding in steps: `N.LoadZoneInSteps(zoneId, budget, clock)` decodes a zone over several calls
  (a coroutine around `Unpacked` and `Decode`; `Chars`, `PrefixSum` and `Decode` take a `pause` function they call
  in their long loops) and answers true once the zone is attached. `N.loading` holds the unfinished zone;
  `N.UnloadZone` lets it go. The module's preloader uses it with 4 ms a frame: since data a9bf246 a big zone decodes
  in up to half a second (the Barrens: 693,671 links), which stopped the game at every zone border. The compile of
  the packed text cannot be split (about 75 ms for the Barrens). `N.LoadZone` still decodes in one piece.
- `NavNetwork.lua`, time slices: `N.Job(fn, ...)` runs any work that searches routes in a coroutine; the A* loop of
  `Pass` yields every 64 expansions once the frame's budget is used. `N.RouteJob` is `N.Job(N.Route, ...)`. No
  `pcall` may stand between a job and the search (Lua 5.1 cannot yield across it).
- `Guidance.lua`: `G.MinArrivalRadius` reads `G.arrivalMin` (WowVision's arrival distance, set by the module)
  instead of his saved variable `arrivalMin`; the wownav module writes the radius Alt-P picks there (0.1 to 20 yd,
  default 1; his default 0 = the data's radius alone).
- The seven files: a header line naming the source commit.

The same packing and reading are offered to Broesel's own pipeline (WowNav PR #1); if his repository ships packed
files, `tools/wownav-pack.lua` is no longer needed.

## Updating

1. Update the submodule `mapdata/WoW_NavigationData` and run `luajit tools/wownav-pack.lua`.
2. Compare his six files in `DemoAddon/WowVisionNavigation/` with the commit named in our headers
   (`git -C mapdata/WoW_NavigationData diff <old> <new> -- DemoAddon/WowVisionNavigation/<file>`); carry his changes
   over, keep the changes listed above, and update the header lines.
3. Check his `WowVisionNavigation.lua` and `ActionNavigation.lua` the same way for changes to the rules that
   `../route.lua` and `../catalog.lua` port, and his `ReadMe.txt` for format changes.
4. Run `luajit tools/headless-tests.lua`.
