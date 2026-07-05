# UI Framework Rewrite Plan

Status: draft for review. Written July 2026.

This document proposes replacing WowVision's current virtual-DOM UI framework with a port of the graph-based UI framework from wotr-access (WrathAccess), which itself descends from FactorioAccess's key-graph design. The wotr-access version is the blueprint because it already solves the three things the original FactorioAccess framework lacked and WowVision needs: nested container announcements, live announcement parts, and a per-tick rebuild model.

## 1. Why replace the current framework

The current framework has two structural problems that cause most of its bugs and maintenance cost.

First, it maintains two retained trees that must stay synchronized: the element tree (virtual DOM reconciled against real elements) and the Navigator tree (focus and announcements). Every known focus bug traces back to this duality. Focus recovery after list changes is hand-rolled and duplicated across three navigator node classes. Containers need a one-shot latch to stop focus snapping back when dynamic lists regenerate. SyncedContainer resets its own index to bypass its own equality guard. Generator.lua patches "explicitly ensure realElement is set" in three separate places.

Second, it re-renders every frame and then layers caching on top to make that affordable: two overlapping subtree-skip mechanisms and five different regeneration inputs (events, frameFields, framePredicates, dynamicValues, alwaysRun), plus legacy signature branching. A contributor or agent adding a screen has to understand all of this to reason about why a screen updates or fails to.

The result is that adding a screen requires knowing the element type vocabulary, prop schemas, window type selection, reconciliation semantics, and XML load order, with no scaffolding. The new model reduces a screen to one render function plus a small registration.

## 2. The new model at a glance

A screen is a pure render function that builds a flat graph of nodes each update tick. Nodes are keyed by stable identity, connected by directional edges (up, down, left, right, plus tab and shift-tab). Movement always follows an edge; interaction always happens at a node. The graph is rebuilt from live game state every tick and thrown away; there is no retained widget tree and no dirty tracking. Focus is a node identity, re-validated against the fresh graph on every rebuild, with deterministic repair when the focused node disappears. The framework composes and speaks all announcements; screen code only writes labels and handlers, never calls speech directly.

Hierarchy (containers within containers) is not a tree of container objects. The graph stays flat. Hierarchy is overlaid as metadata in two ways:

1. Parent pointers on nodes form the announcement hierarchy. A parent can be a non-focusable pure structural level (a labeled context like "categories, list") or a focusable expandable group header.
2. Tab stops partition the graph into sections. Arrows never cross a stop. Tab and shift-tab are edge directions on nodes, exactly like the arrows: the builder wires them between stops, and each stop remembers its last position so a tab edge lands on the remembered node (falling back to the selected member, then the first).

The source frameworks also have a third overlay, regions, for jump navigation within a stop; that is specific to Pathfinder's screens and is dropped from this port.

This design removes the entire class of tree-synchronization bugs: there is only one structure, rebuilt from truth every tick, and focus stability comes from identity reconciliation rather than from keeping retained state consistent.

## 3. Core concepts and types

Names below follow the wotr-access implementation and can be adjusted during the port.

**Node.** One focusable position. Carries: an identity (ControlId), a vtable (announcement parts, handlers such as onClick, onSecondary, onAdjust, onExpand, lifecycle hooks onFocus and onUnfocus, and input binding declarations, see section 7), transitions in up to six directions (the four arrows plus tab and shift-tab), a parent pointer, a stop key, and an auto-stamped position index and count among its siblings.

**ControlId.** Two-tier identity. The reference tier is a Lua object (a Blizzard frame, a data object such as a quest or item); the structural tier is a string key (for generated content such as "option:combat"). Focus reconciliation prefers reference identity, so focus follows an object even when it moves position in a list.

**Render.** The product of one rebuild: the node table plus a start key. Built per tick, discarded. Live state never lives on a render.

**GraphState.** The only persistent UI state, held per screen: current focus key, previous key order, per-stop remembered positions, the set of expanded group ids, and a one-shot suggested move. Plain data, safe to keep across rebuilds and across screens being covered and revealed.

**Builder.** Screens do not construct nodes by hand. A builder provides menu-mode auto-wiring (add items in order; vertical edges are wired automatically, rows give horizontal edges), plus:

- pushContext(label, role) and popContext() add a non-focusable announcement level. Everything added between them gets that level on its parent chain. This is what produces readings like "categories, list" when entering a section.
- beginGroup(id, vtable) and endGroup() add a focusable, expandable level. Children are only built while the group is expanded; collapsed subtrees cost nothing.
- Position stamping. After build, siblings sharing a parent and stop get position index and count stamped automatically, producing "9 of 13" with no screen code.

**Key order.** A total order over nodes computed from the down-right traversal rule (down and right edges must reach every node; up and left are unconstrained). This order powers nearest-survivor focus repair, home/end and edge jumps, and later type-ahead search.

## 4. The announcement system

**Parts.** A node's announcement is a list of parts. Each part has a kind (label, role, value, selected, enabled, position), a text function resolved lazily only when spoken, and a live scope (see section 5). Parts come from two sources merged per node: the control type's common parts (for example, the role word "button") and the node's own parts, with node parts overriding common parts of the same kind. The merged list is sorted by the control type's speak order and filtered by user settings.

**Control type registry.** Control types (button, toggle, slider, list item, group, and so on) are registry values, not classes. Each owns its role word, its part speak order, and its settings key. This gives users one settings surface to say, for example, "never read role words on buttons" or "skip positions in lists," and the filter applies to both readouts and the live watch. This meshes naturally with InfoClass for generating that settings UI.

**Path-diff composition.** When focus moves, the announcer builds the old and new focus paths (root to leaf, from parent pointers), finds the common prefix by identity, and speaks only the newly entered suffix. Consequences:

- Tabbing into the options category list from elsewhere diverges at the context level, so it reads the context label, the context role, the focused item, and its position: "categories, list, combat, 9 of 13."
- Arrowing within the list shares the whole prefix, so it reads only "wizard, 10 of 13."
- Ascending out of a level reads only the newly focused node.
- Descending from a group header onto its first child reads only the child, because the header is already in the common prefix.

A duplicate-suppression rule skips a level whose label merely repeats the next level down. Wording (position phrasing, expanded and collapsed words) comes from pluggable localized functions, not hardcoded strings.

**Announce exactly once.** The host remembers the last spoken focus identity. Whatever caused focus to change (a keypress, a rebuild that removed the focused node, the game closing a frame), one announcement results.

## 5. Live parts

A part can be marked live. Live parts are watched and their changes are spoken; this is the replacement for the current liveFields mechanism, at finer granularity (per part, not per element).

Live scope has two values:

- **focus** — watched only while the node is focused. Each tick, the watcher resolves the focused node's live parts, compares each against a cached baseline string, and speaks just the changed part, non-interrupting. This covers things like a control graying out under the cursor or a cast bar value.
- **always** — watched even while unfocused. This is a WowVision extension; wotr-access only watches the focused node. Mechanism: during build, nodes carrying always-scoped parts are collected into a watch list. Each tick the watcher diffs their resolved texts against a cache keyed by node identity and part index, and speaks changes non-interrupting. Because screens rebuild every tick anyway, collecting the list is free; cost scales only with the number of always parts on the open screens, which should stay small by convention.

Alerts and monitors are a separate mechanism and are deliberately not involved here. Live UI parts just speak their changes.

Two rules prevent double-speaking, both proven in wotr-access:

1. Silent baseline. When focus lands on a new node (or an always-watched node first appears), its live values are recorded without speaking; the focus announcement or initial context already covered the current state.
2. Rebaseline after self-caused changes. When the user activates or adjusts a control, synchronous feedback is spoken through a separate immediate path (an interrupting state line on the vtable, which also handles key-repeat on sliders cleanly), and the live cache is rebaselined so the same change is not spoken again by the watcher.

## 6. Rebuild model and focus reconciliation

The graph rebuilds every update tick (from the existing OnUpdate loop) and additionally at the start of every navigation operation, so operations always act on current state. There is no dirty tracking of any kind. This stays cheap because:

- Building is immediate mode: plain table construction, no diffing, no bookkeeping.
- All announcement text is lazy functions; building the graph never resolves labels. Only spoken text and the live watch resolve anything.
- Collapsed group subtrees are not built at all.

When the focused node's identity is not present in the fresh graph, focus is repaired in tiers:

1. Reference match: a node backed by the same Lua object exists under a different structural key (the object moved). Focus follows it.
2. Structural match: a node with the same structural key exists (the backing object was rebuilt). Focus stays put.
3. Nearest survivor: walk backward through the previous key order to the closest node that still exists. This is the "delete an item, land on the one above it" behavior, implemented once in the framework.
4. First render or nothing matched: land on the start stop, preferring its selected member (the checked radio button or active tab, not the top of the list).

One Lua-specific note: rebuilding tables every tick creates garbage collector churn that Factorio and Mono tolerate more gracefully than WoW's Lua 5.1. The wotr-access discipline already addresses the main risk: transitions and node metadata are plain data, not per-edge closures. Label closures are unavoidable and fine. If profiling shows pressure, node table pooling is a contained optimization to add later; it should not be built preemptively.

## 7. WoW-specific layers

These parts of WowVision are kept, because they solve problems the source frameworks never had.

**Input.** WoW cannot intercept individual keys without SetOverrideBinding on secure frames, so the input layer's mechanism is kept in full: the pool of SecureActionButtonTemplate frames, SetOverrideBindingClick per input on activation, release and ClearOverrideBindings on deactivation, and the named user-rebindable bindings with persisted key inputs. Nothing in the graph core touches secure frames.

The layer's internal structure is simplified at the same time, because the current design fuses three concepts into one class hierarchy (the Flexible binding type exists only as a workaround for that fusion). The restructure separates them:

- **Keymaps** are pure persisted data: name, label, category, the user's inputs, the emulated key, and flags such as vital and conflictingAddons. This is the only persisted piece, and the saved format stays key to inputs, so existing user rebinds carry over without migration.
- **Actions** are a small registry of strategies, each just a configure and clear function pair over a secure frame: secure click on a target frame, Lua function call (with speech interrupt and delay handling), host method call (today's Virtual type), secure target change, and macro script. An action declaration carries whatever SecureActionButtonTemplate attributes it needs, including the emulated key — a node binding looks like { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = someFrame }, and the click action passes that button attribute through to the protected frame. When a declaration omits the emulated key, the keymap's default applies (leftClick defaults to LeftButton, rightClick to RightButton), matching today's behavior, but nodes are free to emulate any button or key the secure template supports.
- **The activator** resolves a request of keymap name plus action, acquires pooled frames, applies the action, and returns a release handle.

Two activation scopes replace today's navigator-plus-element split:

1. The navigation set (arrows, tab and shift-tab as edge moves, ctrl-tab and ctrl-shift-tab for window stack switching, home and end, expand and collapse) is active while at least one screen stack is open, routed through the host's onBindingPressed into graph operations. With no UI open, the keys pass through to the game. Escape is never intercepted: the game closes its own frames and plays its own sounds, and hotkeys the game already handles are not overridden — a screen that needs a close key (a child screen the game doesn't know about) opts in explicitly.
2. Per-node bindings. Node vtables declare keymap-plus-action pairs as data: a proxy node declares leftClick as a secure click onto its protected frame, a synthetic node declares leftClick as a function action invoking its onClick, draggable nodes declare drag, and so on. When reconciled focus lands on a node the host activates its declarations; when focus leaves, it releases them — replicating the current per-element focus activation. Because the graph rebuilds every tick while focus identity persists, activation is keyed to the focused ControlId, never to node table instances: bindings swap only when the focused identity or its declaration set actually changes, not on a mere rebuild.

The onFocus and onUnfocus lifecycle hooks run alongside the binding swap, covering hover sounds, scroll adapters bringing the real row into view, and edit boxes taking keyboard focus. Edit nodes keep the current EditBox escape hatch of routing tab presses back into the host while typing captures keys natively.

Combat lockdown stays exactly as today: override bindings cannot change in combat, so entering combat deactivates input while preserving focus state, reactivation happens one frame after combat ends, and the per-node binding swap defers during combat.

During coexistence the old framework's elements still call the Binding and ActivationSet surface; those become thin wrappers over the new keymap registry and activator, and the wrappers are deleted with the old framework.

**Windows and screen stacks.** WindowManager keeps its job of detecting Blizzard frames opening and closing (FrameWindow polling, event windows, interaction windows). What changes is what it feeds: each open window owns its own screen stack, and a window closing removes its whole stack. Multiple stacks can be open simultaneously, and ctrl-tab cycles focus between them — this preserves today's ctrl-tab-between-windows behavior and lives in the host, not in node edges. Within a stack, child screens push on top (text input through a hidden EditBox, confirmations, choosers) and return results to their parent following the wotr-access child-result pattern; covered screens keep their GraphState and restore exact focus when revealed.

**Proxy nodes.** The current Proxy element classes become a library of node factories. A proxy button node's identity is the Blizzard frame itself (reference tier), its label part reads from the frame, and its onClick clicks it. The current requiresFrameShown behavior becomes simply not emitting the node while the frame is hidden, which the per-tick rebuild makes trivial.

**Scroll frames.** Blizzard's virtualized scroll widgets (ScrollBox, FauxScrollFrame, HybridScrollFrame) only instantiate visible rows. The graph should present the full logical list whenever a data API allows reading items that are scrolled out of view, with an adapter that scrolls the real frame as focus moves so the focused row's real button exists when the user activates it. Each widget family needs its own small adapter. This is the one area with genuine new design work and it replaces today's SyncedContainer family and six proxy scroll classes.

**Speech.** A small message builder accumulates fragments during an operation; the host speaks the result through the existing speech layer after the operation resolves. The existing TTS timing workaround (the UI delay re-dispatch) stays in the host, in one place, rather than threaded through multiple files as today.

**Tooltips.** The tooltip reader stays exactly as it works today, driven by shift plus arrows on the focused element. WoW tooltips are too complex for inline readout, so nodes carry no tooltip announcement parts and tooltips stay entirely outside the part system.

## 8. Settings UI generated from InfoClass

Settings screens remain fully generated, which is one of the current framework's genuine strengths. A new generator walks a module's InfoManager fields and emits builder calls: Bool fields become toggle nodes, Number becomes slider or edit nodes, Choice becomes dropdown nodes, String becomes edit nodes, Category and child modules become groups, and arrays become groups with add and remove actions. The dataBinding layer (Field, Property, Method, Function bindings) is kept unchanged as the value get and set behind those node factories. This replaces InfoFrame's generator and ModulePanel. Because every settings screen flows through this one generator, migrating it migrates all settings screens at once.

## 9. What is kept and what is eventually deleted

Kept, unchanged or lightly adapted: core/ui/tooltip/, core/dataBinding/, core/info/ (Field and InfoManager), the speech layer, WindowManager's detection machinery, and the module system. The input layer's mechanism (frame pool, override bindings, named rebindable keymaps, saved rebind data) is kept but restructured as described in section 7; the Binding class hierarchy, the Flexible type, BindingSet, and ActivationSet survive only as thin compatibility wrappers until the old framework is deleted.

Replaced and eventually deleted: Generator.lua, Navigator.lua and WindowedNavigator.lua, the context classes, UIContainer and the container and widget element classes, the SyncedContainer and Proxy scroll family, GeneratorPanel, InfoFrame's generator and ModulePanel, and MenuManager (context menus become ordinary child screens).

## 10. Migration strategy

The two frameworks coexist during migration. The window registry decides per screen which framework owns it; both share the input entry point and the window stack. Old and new windows can be open simultaneously since both ultimately hang off the same host.

Phase 1: port the core. KeyGraph (graph, reconciliation, key order, movement), the types, the builder (contexts, groups, position stamping), the announcer (path diff, parts, control type registry), the navigator host (per-tick rebuild, announce-once, live watch including the always scope), the screen stacks, and the input restructure. For input, the action registry and activator are built new, but during coexistence they read keymap data (inputs, default emulated key, conflicting addons) from the existing named binding instances, which already carry persistence and user rebinding — one source of truth, no changes to old-framework code. The data-only keymap collapse and deletion of the Binding class hierarchy happen in phase 4. Write unit tests alongside, following the existing core/ui/tests.lua pattern; the graph core is pure Lua and highly testable.

Phase 2: write the developer documentation for the new framework before porting screens (the FactorioAccess experience shows the doc is a large part of why the framework is easy to extend, especially for agents). Port two pilot screens: the game menu (the escape menu, currently core/windows/GameMenu.lua — a flat list of proxied Blizzard buttons with frame-based window detection, and trivially easy to reach in game) as the simple case, and either the quest window or the settings generator as the hard case, to validate proxy nodes, window detection, and nested announcements against real Blizzard frames.

Phase 3: port the settings generator (covers all settings screens at once), then migrate the remaining windows screen by screen, roughly forty registered windows and three hundred element definitions across sixty-four files. Buffers and chat views migrate onto the sheet idiom (tables built from plain graph primitives with edge labels as column headers).

Phase 4: delete the old framework, update the developer docs, and remove the coexistence shims.

## 11. Open questions for review

1. Naming and layout. Suggest core/graph/ for the new core so it can live alongside core/ui/ until deletion. Class names as in this doc, or renamed to taste.
2. Scroll adapters. Which Blizzard scroll widgets do we commit to supporting with full logical lists versus visible-rows-only in the first pass?
3. Type-ahead search. wotr-access has it (scoped to the focused stop, matching label text). Port it in phase 1 while the core is fresh, or defer?
4. Part-filter settings. How much of the per-control-type, per-part announcement settings UI should be exposed to users initially, versus shipping sensible defaults first?
5. The always live scope. Proposed convention: reserve it for a small number of parts per screen (cast progress, quantity counters). Agree, or does anything need broader always coverage?
