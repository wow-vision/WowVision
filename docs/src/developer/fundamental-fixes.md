# Known Issues and Fundamental Fixes

Status: a collection of known issues whose real fix is a framework change, not a small patch. Each entry records what happens, why, what it costs the player today, and the fix idea. Nothing in the fix ideas is built or verified in game yet.

## Finding taint problems

WowVision records every blocked or forbidden protected call itself (`core/taintWatch.lua`):

- It listens for `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN`, `MACRO_ACTION_BLOCKED` and `MACRO_ACTION_FORBIDDEN` from load on.
- On each one it says "Blocked: <function>". Some blocks show no popup, so this is the only signal.
- It keeps the last 30 in the `WowVisionDump.taint` saved variable: time, event, addon, function, the full stack, and the focused graph screen, node, row template and setting name.
- The events fire synchronously, so the stack shows the exact code path that made the call.

Workflow: reproduce, `/reload`, then read `WTF\Account\<account>\SavedVariables\WowVision.lua` (key `["taint"]`), or use `/wv taint` in game. `/wv taint clear` empties the list.

`Logs\taint.log` (`/console taintLog 1`) additionally names the first tainted read, but it is harder to use: a `/reload` starts the file fresh, at level 1 it only reaches disk on `/quit`, and on WoW: Forever the setting does not survive a restart unless `SET taintLog "1"` is in `WTF\Config.wtf`. Level 2 adds only noise: a line for every global read by addon code.

## Scrolling a ScrollBox from addon code taints its rows

### Symptom

WoW: Forever (and presumably Retail), game options: moving through the settings list, usually in the Social category or search results near the Discord entry, produces a one-time "Diese Funktion ist der Blizzard-UI vorbehalten" (`ADDON_ACTION_FORBIDDEN`, `C_Discord.IsUserOAuthed()`). It is triggered by a nearby row, not the Discord row itself. It returns when the row scrolls out and back in, or when the options are reopened.

### Cause

When a row gets focus, the ScrollBox adapter scrolls it into view so the row frame exists for hover and secure clicks: `core/graph/scrollBox.lua`, the `onFocus` that calls `scrollBox:ScrollToElementDataIndex(capturedIndex)`.

That call runs in WowVision's insecure stack, so Blizzard's whole list update runs tainted, including the `Init` of every row frame that scrolls into view. The Discord sign-in row (`Blizzard_SettingsDefinitions_Frame/Social.lua`) calls `C_Discord.IsUserOAuthed` in its `Init`, for the caption (`GetAuthButtonName`), and in `EvaluateState`, through its modify predicate. That function only runs untainted.

Recorded stack, shortened: `Host:_syncNodeFocus` → `scrollBox.lua:135` → `ScrollBox:ScrollToElementDataIndex` → `ScrollBox:Update` → `InvokeInitializers` → `SettingsButtonControlMixin:Init` → `IsUserOAuthed`.

This is not specific to Discord. Any Blizzard row whose `Init` makes a protected call breaks the same way under any ScrollBox that WowVision scrolls, including rows Blizzard adds in future patches.

### Cost today

Only the popup. The blocked call returns nothing and `Init` carries on, so at worst the Discord button shows a stale caption or enabled state until Blizzard refreshes it (`DISCORD_LINK_UPDATE`). WowVision's own reading of that row is already safe: it takes the sign-in state from the caption on the button (`core/windows/options/ui.lua`, `discordSignedIn`).

Rejected workaround: suppressing the popup (for example by unregistering `ADDON_ACTION_FORBIDDEN` from `UIParent`). It would also hide every future real block.

### Fix idea: scroll as the player's own input

Stop calling scroll methods from addon code. Let the key press itself scroll through Blizzard's own scroll bar steppers, so the list update runs in a secure stack and rows initialize untainted.

WowVision already does this for HybridScroll lists: `core/graph/hybridScroll.lua`, secure mode, introduced for "Copy Character Name blocked after scrolling the friends list":

- Up or down at the visible edge: one secure click of the real arrow button. Focus moves on the same key press via `postClick`.
- Page up or down: a macrotext of enough arrow clicks to cover one viewport, then focus snaps to the nearest newly visible row.
- Home and End are eaten: a secure jump of arbitrary distance does not fit one key press.

Porting this to `core/graph/scrollBox.lua` would cover the options list and every other ScrollBox list.

Open questions to settle in game before building:

1. **Mouse-down steppers.** ScrollBox scroll bars (`MinimalScrollBar`, also `WowTrimScrollBar`) have `Back` and `Forward` steppers that scroll in `OnMouseDown` (`MinimalScrollBarStepperScripts`), not `OnClick`. A secure click (`/click`, or a `clickbutton` attribute) fires `OnClick`. Test whether `/click <name> LeftButton 1` (down = true) reaches `OnMouseDown`. If it does not, the stepper route is closed and another secure scroll trigger is needed.
2. **Names.** The steppers are `parentKey` children without global names, and `/click` needs a name. A WowVision secure button with `type = "click"` and `clickbutton = <stepper>` set out of combat, clicked by name, could bridge that.
3. **Step size.** A stepper moves by a fixed step, not to an element index. Focus has to follow whichever rows became visible, like hybrid secure mode's page up and down.
4. **Initial position.** Opening a category or search result can leave the focused row off screen. Only Blizzard's own code or a secure scroll may move the list there.
5. **Scope.** Most ScrollBox lists have no protected calls in their rows. Secure mode could be opt-in per list (the options list first), as it is for HybridScroll.
