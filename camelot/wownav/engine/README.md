# WowNav engine in WowVision

These six files are Broesel33's WowNav engine, taken from the demo addon of his public data repository
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

What uses them: `../route.lua` (his route rules from `WowVisionNavigation.lua` and `ActionNavigation.lua`),
`../catalog.lua` (the destination list: his `Navigation.SearchTargets` and `WowVisionNavigationResolveListed`) and
`../module.lua` (with his zone loader's `PreloadNeighbours`), `../dock.lua` (what his core does around `DockNavigation`).

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
  `N.wholeMisses` and `N.knownMissAnswers` count both for the module's trail.
- `NavNetwork.lua`, memory: `N.UnloadZone`, `N.KeepZones` and the hook `N.onZoneUnloaded` drop decoded zones again
  (his core keeps every decoded zone for the session).
- `NavNetwork.lua`, time slices: `N.Job(fn, ...)` runs any work that searches routes in a coroutine; the A* loop of
  `Pass` yields every 64 expansions once the frame's budget is used. `N.RouteJob` is `N.Job(N.Route, ...)`. No
  `pcall` may stand between a job and the search (Lua 5.1 cannot yield across it).
- `Guidance.lua`: `G.MinArrivalRadius` reads `G.arrivalMin` (WowVision's arrival distance, set by the module)
  instead of his saved variable `arrivalMin`; the wownav module writes its own setting there (0 to 10, default 0 =
  the data's radius, like his).
- The six files: a header line naming the source commit.

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
