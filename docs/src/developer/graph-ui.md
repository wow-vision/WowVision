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
local ControlId = graph.ControlId

local function render(builder, screen)
    local frame = GameMenuFrame
    if frame == nil or not frame:IsShown() then
        return -- adding no nodes closes the screen
    end
    local buttons = {}
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:GetObjectType() == "Button" and child:IsShown() then
            tinsert(buttons, child)
        end
    end
    table.sort(buttons, function(a, b)
        return a:GetTop() > b:GetTop()
    end)

    builder:pushContext(L["Menu"])
    for _, button in ipairs(buttons) do
        builder:beginStop()
        builder:addItem(ControlId.forObject(button), {
            controlType = graph.controlTypes.button,
            announcements = { { text = buttonLabel(button), kind = graph.kinds.label } },
            bindings = {
                { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = button },
            },
        })
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GameMenuFrame",
    frameName = "GameMenuFrame",
    graphScreen = { render = render },
})
```

That is everything: a render function and a window registration carrying `graphScreen`. Window detection (FrameWindow polling, event windows, interaction windows) works exactly as before; a `graphScreen` window opens a graph screen stack instead of the old element context.

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
- `pushContext(label, role)` / `popContext()` push a non-focusable announcement level. Entering any child from outside reads the context levels outermost-first: "Categories, list, Combat, 9 of 13". Moving between siblings inside reads only the leaf.
- `beginGroup(id, vtable, expanded, defaultExpanded)` / `endGroup()` push a focusable expandable header (a tree section). Children build only while expanded; right expands or descends, left collapses or ascends. Expansion state persists in the screen's `state.expanded`; screens hold none of their own.
- `startRow(rowKey)` / `endRow()` make horizontal rows; rows sharing a non-nil key get column-preserving vertical navigation.
- Positions ("2 of 9") are stamped automatically: multi-item rows within the row; other nodes among siblings sharing their parent context or group (even across stops), or per stop at root level. `pushContext(label, role, false)` suppresses them for log-like content.
- Raw mode: `addNode(id, vtable)` plus `connect(fromId, dir, toId, label)` for arbitrary topologies (grids). `dir` includes `"next"`/`"previous"` to hand-wire tab edges; an explicit tab edge overrides stop cycling. A `connect` label speaks only while crossing that edge (a lane change).

## Announcements and live parts

The announcer diffs the old and new focus paths by identity and speaks only what changed. You get this for free; the only authoring decisions are labels, kinds, control types, and context/group structure.

A part with `live = "focus"` (or `true`) is watched while its node is focused: when its resolved text changes, just that part is spoken, without interrupting. A part with `live = "always"` is watched even while unfocused, anywhere in the render. Both baseline silently when first seen, and self-caused changes rebaseline through `stateText`, so nothing is spoken twice. Use always-scope sparingly — a few parts per screen (cast progress, quantity counters).

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
- A context's synthetic id derives from its label; two sibling contexts with the same label under the same parent will collide. Vary the label or nest differently.
