# Graph UI Framework

The graph framework is WowVision's replacement UI system, ported from the WrathAccess/Tanglebeep key-graph design (which descends from Factorio Access). It is migrating screens away from the virtual-DOM system described in [UI System](./ui-system.md); both run side by side until the migration finishes. The design rationale and migration plan live in [ui-rewrite-plan.md](./ui-rewrite-plan.md).

Status: the game menu is the first migrated screen. New screens should be written on this framework; copy the closest existing graph screen as your starting point.

## The model in one paragraph

A screen is a render function that rebuilds a flat graph of nodes from live game state every tick and on every keypress. Nodes are keyed by stable identity, connected by directional edges (up, down, left, right, plus the tab pair). Movement follows edges; interaction happens at nodes. There is no retained widget tree: focus is an identity re-validated against the fresh graph on every rebuild, with deterministic repair when the focused node disappears. The framework composes and speaks all announcements; screen code only supplies labels and handlers and never calls speech directly.

## Core pieces

All code lives in `core/graph/` under the `WowVision.graph` namespace.

- `ControlId` — two-tier node identity. `ControlId.forObject(frame)` when a game object backs the node (focus follows the object even if it moves position); `ControlId.structural("someKey")` for generated content; `ControlId.referenced(obj, "key")` for both. Structural keys must be stable across rebuilds.
- `KeyGraph` — the engine: movement, three-tier focus reconciliation (same object, then same structural key, then nearest survivor in the previous traversal order), tab-stop cycling with remembered positions, tree expand/collapse operations.
- `Builder` — how renders are constructed. See the reference below.
- `Announcer` — composes speech by diffing the old and new focus paths; only newly entered levels speak.
- `Host` (`WowVision.graphHost`) — screen stacks, the per-tick update, the live watch, and input routing.

## Writing a screen

The complete game menu screen, from `core/windows/GameMenu.lua`:

```lua
local graph = WowVision.graph

local function render(builder, screen)
    local frame = GameMenuFrame
    if frame == nil or not frame:IsShown() then
        return -- adding no nodes closes the screen
    end
    graph.nodes.proxyButtonMenu(builder, { label = L["Menu"], frame = frame })
end

module:registerWindow({
    type = "FrameWindow",
    name = "GameMenuFrame",
    frameName = "GameMenuFrame",
    graphScreen = { render = render },
})
```

That is everything: a render function and a window registration carrying `graphScreen`. Window detection (FrameWindow polling, event windows, interaction windows) works exactly as before; a `graphScreen` window opens a graph screen stack instead of the old element context.

## Node factories

Prefer the factories in `core/graph/nodes.lua` (`graph.nodes`) over hand-writing vtables. Every factory takes a single config table:

- `nodes.proxyButton({ target = frame, label = ?, allowHidden = ? })` — a real Blizzard button; Enter and Backspace click it securely as true left and right clicks. The label defaults to reading the frame's text live. All proxy factories return nil for hidden targets — hidden pooled Blizzard frames carry stale state from prior occupants, so an unshown control is someone else's control — and `addItem` skips nil vtables. `allowHidden = true` opts out for frames clickable while hidden (action bar buttons).
- `nodes.button({ label = ..., onActivate = fn, onSecondary = fn?, stateText = fn? })` — a synthetic button.
- `nodes.text({ label = ..., live = ? })` — a read-only line; set `live` to watch it.
- `nodes.proxyButtonMenu(builder, { label = ?, frame = ? or buttons = ? })` — a whole tab-cycled menu of proxy buttons: one stop per button, one announcement context, positions stamped across the set. This is the game menu's entire body.
- `nodes.frameText(frame)` — the live label function proxy factories use; handy on its own.
- `nodes.hybridScrollList(builder, { scrollFrame, count, emit, key?, label?, id?, rowHeight? })` — pilots button-pool scroll frames (HybridScrollFrame and kin, like the quest log): entries enumerate from the API. The discipline, inherited from the old ProxyScrollFrame: focusing an entry ALWAYS scrolls it to a calibrated position (re-stamping the pool synchronously), then verifies by finding the button whose index matches, rolling the scroll back if none does. Pool buttons rebind as the frame scrolls — never trust an index-to-button mapping except immediately after scrolling to that index. Both scroll adapters also watch for drift each tick while their entry is focused (`onFocusTick`): secure clicks bind to a frame at engage time, so if the pool scrolls between engage and the press (a Blizzard re-scroll, a wheel event), the adapter re-aligns and asks the host to re-engage.
- `nodes.attachScrollFrame(vtable, scrollFrame, regionOrFunction)` — for plain (non-virtualized) ScrollFrames: scrolls the real viewport (through its scrollbar when present) so the region is visible when the node gains focus. Content in these frames is fully instantiated; only the view moves.
- `nodes.attachHover(vtable, frameOrFunction)` — runs the frame's OnEnter script when the node gains focus and OnLeave when it loses it, appended after any existing hooks. This is how the game's own tooltips and highlights follow focus (the tooltip reader reads what hover produced). proxyButton and scroll rows do this automatically; attach it on hand-written vtables over Blizzard frames.
- `nodes.scrollBoxList(builder, { scrollBox, rowLabel, label?, key?, id?, button?, row?, emit? })` — pilots a Blizzard ScrollBox: one node per data-provider element, labels from row data (required — offscreen frames cannot be read at announce time), focus scrolls the row into view, and clicks resolve the materialized row button lazily and secure-click it. `button` maps the row frame to a clickable child; `row` replaces the default vtable entirely, receiving `helpers = { onFocus, target }` to compose.

Value controls take get and set functions (plus optional `valueText`); the settings renderer builds those from InfoClass fields, and other screens pass their own closures:

- `nodes.toggle({ label, get, set })` — Enter flips it; speaks Checked/Unchecked, live while focused.
- `nodes.number({ label, get, set, step, largeStep })` — left/right adjust, Enter opens typed entry through the host's shared edit box. Clamping belongs to the setter (Field validation handles it on settings).
- `nodes.choice({ label, get, set, choices })` — Enter opens a child screen of the options, landing on the current pick; choosing sets and returns. `choices` is a list or function returning `{ label, value }` entries.
- `nodes.textInput({ label, get, set })` — Enter opens typed entry.
- `nodes.proxyEditBox({ editBox, label, autoInput?, hookTab?, fixAutoFocus? })` — a real Blizzard edit box. Tabbing to it hands it keyboard focus so typing starts immediately (the `onTabFocus` vtable hook, fired only on tab-pair arrivals — arrows just read it); Enter does the same; Tab from inside leaves the box and moves on. `fixAutoFocus` disables Blizzard's autofocus for boxes that re-grab the keyboard on their own refreshes.

Hand-written vtables remain the escape hatch for anything the factories don't cover.

## Settings screens

`graph.settings.renderInto(builder, infoFrame)` renders an InfoClass settings tree: Bool, Number, Choice, and String fields map to the value factories wired straight to Field get/set (validation and persistence ride along), unsupported field types read as label plus value, and child categories become buttons pushing child screens. `graph.settings.screen(infoFrame)` wraps a tree as a `graphScreen` config; register more field controls with `graph.settings.registerFieldControl(typeKey, factory)`. For side-by-side testing, `/wv gsettings speech` (or any dot path under WowVision.base) opens a module's settings as a graph window.

Escape and frameless windows: a stack whose config sets `captureClose = true` (settings.screen does) holds the close key while focused, as does any stack with a pushed child screen — the opt-in cases where the game cannot close our UI for us. Everywhere else Escape stays with the game.

The module menu: `graph.settings.renderModuleInto(builder, module)` mirrors the old ModulePanel — an Enabled toggle for non-vital modules, sorted submodule buttons pushing child screens, then the module's settings. A module contributes extra menu items by defining `getGraphMenuItems(builder)` (the graph counterpart of `getAdditionalMenuUI`); the ui module (Bindings) and buffers module do. `/wv` opens this menu; `/wv oldmenu` reaches the legacy menu during the remaining migration.

Component arrays: ComponentArray fields render as a button reading "Label (N)" that opens a list screen — one button per component (identity follows the instance), plus Add when the field declares available types. A component's editor renders its class fields through `settings.renderObjectInto` (a component may take over by defining `renderGraphSettings(builder)`) plus a Remove button; Add goes through a type selector and drops you straight into the new component's editor. Nested component arrays (buffer groups containing buffers) recurse naturally.

Every field type now has a control (`core/graph/fieldControls.lua`): Time (a Number speaking formatted durations), VoicePack (a choice over registered packs), Spell (typed name-or-id entry plus recent-spell quick picks), Alert (opens its parameters InfoFrame), Template (registered templates plus a Custom format entry), Object (type choice plus parameter fields through the params proxy), TrackingConfig (type choice plus a copy-edit parameters screen validated on Save), and Array (element-editor rows with Remove, and Add). Opener buttons carry their current value as a live value part.

Rules the render function must follow:

1. Read live game state fresh every call. Never cache game data between renders in upvalues; the whole point is that the graph is always current. Screen-local UI state (a filter string, a sort mode) may live on `screen` or in upvalues.
2. Give every node a stable identity. A Blizzard frame or data object: `forObject`/`referenced`. Generated rows: a structural key derived from what the row IS ("quest:1234"), never from its position.
3. Never speak. Labels are strings or functions resolved at speak time; the host announces.
4. Adding no nodes closes the screen. Use that for validity checks at the top.

## Nodes and vtables

`builder:addItem(id, vtable)` adds one control. The vtable is a plain table:

- `announcements` — required, at least one part. A part is `{ text = string or function, kind = kind, live = scope }`. The first part is the control's label. Kinds are `graph.kinds.label/role/value/selected/enabled/position`; kinds drive speak order, let a node part override the control type's common part, and key per-kind announcement settings.
- `controlType` — an entry from `graph.controlTypes` (button, toggle, dropdown, group, text; register more with `graph.registerControlType(key, roleWord)`). Supplies the role word and speak order.
- `onActivate` / `onSecondary` — Enter and Backspace handlers for synthetic controls. The host binds them automatically unless the node declares explicit `leftClick`/`rightClick` bindings.
- `onAdjust(sign, large)` — slider adjustment; when present, left/right adjust instead of navigating.
- `stateText` — a function returning the control's state line, spoken immediately after an activation or adjust the user caused. Asynchronous changes ride live parts instead.
- `bindings` — input declarations activated while the node is focused; see Input below.
- `onFocus` / `onUnfocus` — lifecycle hooks (scroll adapters bringing rows into view, edit boxes taking keyboard focus).
- `onExpand` / `onCollapse`, `speaksOwnExpansion`, `speaksOwnPosition` — group and readout overrides, rarely needed.

## Structure: stops, contexts, groups

- `beginStop(key)` starts a tab stop. Arrows never cross stops; tab and shift-tab cycle them, landing on the stop's remembered position (then its selected member, then its first node). One node per stop makes a tab-cycled menu, like the game menu.
- `pushContext(key, label, role)` / `popContext()` push a non-focusable announcement level. The key is required and is the context's whole identity: labels play no part, because every context is distinct even when names repeat (two identical bags). Derive keys from what the context IS, stable across rebuilds. Entering any child from outside reads the context levels outermost-first: "Categories, list, Combat, 9 of 13". Moving between siblings inside reads only the leaf.
- `beginGroup(id, vtable, expanded, defaultExpanded)` / `endGroup()` push a focusable expandable header (a tree section). Children build only while expanded; right expands or descends, left collapses or ascends. Expansion state persists in the screen's `state.expanded`; screens hold none of their own.
- `startRow(rowKey)` / `endRow()` make horizontal rows; rows sharing a non-nil key get column-preserving vertical navigation.
- Positions ("2 of 9") are stamped automatically: multi-item rows within the row; other nodes among siblings sharing their parent context or group (even across stops), or per stop at root level. `pushContext(key, label, role, false)` suppresses them for log-like content.
- Raw mode: `addNode(id, vtable)` plus `connect(fromId, dir, toId, label)` for arbitrary topologies (grids). `dir` includes `"next"`/`"previous"` to hand-wire tab edges; an explicit tab edge overrides stop cycling. A `connect` label speaks only while crossing that edge (a lane change).

## Announcements and live parts

The announcer diffs the old and new focus paths by identity and speaks only what changed. You get this for free; the only authoring decisions are labels, kinds, control types, and context/group structure.

The focused node's readout is inherently live: every part — label, value, selected, expanded state — is watched while its node is focused, and when a part's resolved text changes, just that part is spoken without interrupting. No flags needed for the focused case; `live = false` opts a part out. A part with `live = "always"` is additionally watched while unfocused, anywhere in the render. Watches baseline silently when first seen, and self-caused changes rebaseline through `stateText`, so nothing is spoken twice. Use always-scope sparingly — a few parts per screen (cast progress, quantity counters).

## Input

A node's `bindings` list declares what keys do while it is focused. Each entry names a keymap (the user-rebindable named binding: `leftClick`, `rightClick`, `drag`, `tooltip`, ...) and an action:

```lua
{ binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = someBlizzardButton }
{ binding = "drag", type = "Function", func = function() ... end }
```

Action types (in `core/ui/input/actions.lua`): `Click` (secure click-through to a protected frame, with the emulated mouse button passed through — this is how Enter is a true left click), `Function` (Lua callback with speech-interrupt and TTS-delay handling), `Target`, `Script`. `emulatedKey` may be set per declaration; the keymap's default applies otherwise. Bindings swap only when the focused identity changes, never on mere rebuilds, and everything releases during combat lockdown and re-engages after.

Navigation keys (arrows, tab, ctrl-tab, home/end) are held by the host while any graph screen is open. Escape is never intercepted: the game closes its own frames with its own sounds. Do not override any hotkey the game already handles in the current context without asking the project owner first.

## The host and window stacks

Each open window owns one screen stack; ctrl-tab and ctrl-shift-tab cycle between simultaneously open stacks. `WowVision.graphHost:push(stack, config)` and `pop(stack)` manage child screens within a stack (a covered screen keeps its state and restores exact focus). The host rebuilds and reconciles the focused screen every tick from the UIHost update loop, announces focus changes exactly once no matter their cause, and runs the live watch.

Coexistence caveat: if a graph window and an old-framework window are open at the same time, both navigation systems hold the same keys and the later activation wins. Migrate interacting windows together when this bites.

## Testing

- Headless: `lua tools/headless-tests.lua [-v] [suiteName]` from the repo root runs the graph core suites (no game client) and parse-checks the WoW-bound files. Add new pure-core tests to `core/graph/tests.lua`.
- In game: `/wv test` runs all suites, including the input activator tests.
- Errors: `/wv errors` speaks the most recent Lua error and opens a copyable list; `/wv errors clear` resets.

## Pitfalls

- Unstable ids are the classic bug: a structural key containing a list index breaks focus repair and stop memory the moment the list changes. Key by identity, not position.
- Do not store nodes, renders, or vtables between rebuilds; they are throwaway. Persistent cursor state lives in `screen.state` and is managed by the engine.
- Do not create closures per node for transitions or in hot per-tick paths beyond what labels need; transitions are plain data.
- Context keys are identity: sibling contexts sharing a key read as one level to the announcer, so moving between them never re-announces the second. Keys must be distinct per logical context and stable across rebuilds; derive them from what the context IS (a bag id, a field key), never from its display label.
