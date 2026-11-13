# Keybinding Reference

This page lists every WowVision keybinding with its default key. You can change any of them in the keybinding window: open the WowVision menu (Shift+F1), go to UI and choose Bindings. How the keybinding window works is explained in [Keybindings](../basics/keybindings.md).

"Unbound" means the binding exists but has no key until you give it one.

## Two kinds of keys

- Window keys only work while a WowVision window is open (bags, a merchant, the WowVision menu and so on). When no window is open, the same keys do whatever you bound them to in the game. Arrow keys, Tab, Enter, Backspace, Escape, Space, Home, End, Page Up, Page Down and the context menu key are window keys. On game windows Escape stays with the game, which closes its own windows; WowVision uses it on its own screens (see [Using the Interface](../basics/interface.md)).
- Global keys work at any time, with or without a window: buffers, navigation, targeting, the loot roll keys, Destroy Cursor Item and the keys that open WowVision windows.

In combat, WowVision hands the window keys back to the game (see [Combat](../world/combat.md)). The global keys keep working.

## Moving around in windows

| Action | Default key | Notes |
|---|---|---|
| Up | Up Arrow | Previous element in a list or column |
| Down | Down Arrow | Next element |
| Left | Left Arrow | Element to the left, or the previous value of a slider or choice |
| Right | Right Arrow | Element to the right, or the next value |
| Next | Tab | Next tab stop: the next section of the window, such as a list or a row of buttons |
| Previous | Shift+Tab | Previous tab stop |
| Jump to Beginning | Home | First element |
| Jump to End | End | Last element |
| Scroll Up | Page Up | Scroll a long list up a page |
| Scroll Down | Page Down | Scroll a long list down a page |
| Next Window | Ctrl+Tab | Switch to the next open window |
| Previous Window | Ctrl+Shift+Tab | Switch to the previous open window |
| Close | Escape | Goes back one level or closes WowVision's own screens and menus. On game windows the game's own Escape closes the window |

## Acting on elements

| Action | Default key | Notes |
|---|---|---|
| Left Click | Enter | Activates the focused element. Works with modifiers: Shift+Enter is a shift click, Ctrl+Enter a ctrl click, and so on |
| Right Click | Backspace | Right click, also with modifiers (Ctrl+Backspace and so on) |
| Drag | \\ or Ctrl+D | Picks up the focused item, spell or action bar slot onto the cursor |
| Read Tooltip | Space | Reads the whole tooltip of the focused element |
| Context Menu | Shift+F10 | Opens the context menu of the focused element, where one exists |
| Destroy Cursor Item | Delete or Alt+Ctrl+\\ | Clears or destroys what is on the cursor (asks first for a real item). Does nothing when the cursor is empty |

## Tooltips

| Action | Default key |
|---|---|
| Previous Tooltip Line | Shift+Up |
| Next Tooltip Line | Shift+Down |
| Read Tooltip Left | Shift+Left |
| Read Tooltip Right | Shift+Right |

See [Tooltips](../basics/tooltips.md).

## Opening WowVision windows

| Action | Default key | Page |
|---|---|---|
| WowVision Menu | Shift+F1 (or type `/wv`) | [The WowVision Menu and Settings](../basics/menu-and-settings.md) |
| Close All Windows | Shift+Escape | Closes every open WowVision window and every window of the game |
| Chat | Shift+F3 | [Chat](../windows/chat.md) |
| Action Bars | Shift+F4 | [Action Bars](../windows/action-bars.md) |
| Scanner | F9 | [Scanner](../world/scanner.md) |
| Navigation | F10 | [Navigation and Routes](../world/navigation.md) |

## Buffers

| Action | Default key |
|---|---|
| Previous Buffer Item | Alt+Up |
| Next Buffer Item | Alt+Down |
| Previous Buffer | Alt+Left |
| Next Buffer | Alt+Right |
| Previous Buffer Group | Alt+Ctrl+Left |
| Next Buffer Group | Alt+Ctrl+Right |

The Invert Item Direction setting in the Buffers module swaps Alt+Up and Alt+Down. See [Buffers](../information/buffers.md).

## Chat

| Action | Default key | Notes |
|---|---|---|
| Previous Link in Message | Ctrl+Left | In the chat window: previous clickable part of a message |
| Next Link in Message | Ctrl+Right | Next clickable part |
| Shift Click | Shift+Enter | Shift click the selected part (puts a link into the chat box) |

See [Chat](../windows/chat.md).

## Navigation and routes

| Action | Default key | Notes |
|---|---|---|
| Turn to Waypoint | I | Faces the current waypoint of your route |
| Next Waypoint | Ctrl+W | Skip ahead to the next waypoint. You hear how many waypoints remain, for example "12 remaining" |
| Previous Waypoint | Ctrl+S | Go back to the previous waypoint, with the same count |
| Start the Route Again From Here | Ctrl+Shift+N | Plans the route to your last destination again, starting from where you stand. You hear "No route to start again" if you have not chosen a destination yet |
| Reverse Route | Ctrl+Shift+R | Turns the running route around: from its destination back to its start, going on at the waypoint the beacon leads to now |
| Cancel Navigation | Shift+F12 | Stops the active route or beacon |
| Cycle Arrival Distance | Alt+P | Changes how close you must come before a waypoint counts as reached |
| Announce Distance | Unbound | Speaks the distance to the waypoint. Alt Gr (or Ctrl+Alt) does the same out of the box |
| Route to Your Target | Unbound | Starts a route to your current target |
| Route to the Nearest Unvisited of the Same Name | Unbound | Routes to the place with the same name you have not visited yet that is the shortest walk away |
| Direct to the Nearest Unvisited of the Same Name | Unbound | The same as a straight beacon instead of a route |
| WowNav Route Status | Unbound | (WoW: Forever) Speaks the state of the WowNav route |
| New WowNav Route Around a Blocked Spot | Unbound | (WoW: Forever) Plans a new route that avoids the spot where you are stuck |

Alt Gr is not a binding: it is read directly, stays silent while you type in an edit box, and can be turned off with the Announce Distance with Alt Gr setting in the Beacon and Routes module (Navigation). See [Navigation and Routes](../world/navigation.md) and [WowNav](../world/wownav.md).

## Minimap

| Action | Default key |
|---|---|
| Scan Minimap | Ctrl+Shift+F |

See [Minimap](../world/minimap.md).

## Targeting

| Action | Default key | Notes |
|---|---|---|
| Soft Target Enemy | Shift+I | Switches soft enemy targeting on or off and says "Soft Target Enemy Enabled" or "Disabled" (with "after combat" when pressed in combat) |
| Soft Target Friend | Shift+P | The same for soft friend targeting |
| Soft Target Interact | Shift+O | The same for soft interact targeting |
| Target of Target | Unbound | Makes your target's target your target, without starting an attack |
| Open Target Menu | Alt+T | Opens the menu of your target, like a right click on its portrait |
| Target Focus 1 to Target Focus 5 | Unbound | Targets one of the five WowVision focus targets |

See [Targeting](../world/targeting.md).

## Loot rolls

| Action | Default key | Notes |
|---|---|---|
| Roll Tooltip | Alt+Ctrl+Y | Reads the whole tooltip of the item up for a roll: name, quality, item level, stats and requirements |
| Roll Need | Alt+Ctrl+U | |
| Roll Greed | Alt+Ctrl+I | |
| Roll Pass | Alt+Ctrl+O | |
| Roll Bonus | Alt+Ctrl+P | Only exists on game versions that have bonus rolls |

The roll keys act on the first roll window on screen. With none open you hear "No loot.".

See [Loot, Trade and Mail](../windows/loot-trade-mail.md).

## Group invitations

| Action | Default key | Notes |
|---|---|---|
| Accept Group Invitation | Unbound | Accepts the group invitation that is shown, also in combat, the same as /wv accept. Without one you hear "No group invitation" |

See [Group Finder](../windows/group-finder.md).

## Monitors

| Action | Default key | Notes |
|---|---|---|
| Toggle All Monitors | Unbound | Mute for monitors: if any monitor is on, turns all off ("Monitors off"); if all are off, turns all on ("Monitors on") |
| Speak Tracked Auras | Unbound | (Retail and WoW: Forever) Reads out every aura of your enabled Cooldown Manager Auras monitors, or says "No tracked auras" |
| Speak Tracked Cooldowns | Unbound | (Retail and WoW: Forever) Reads out every spell of your enabled Spell Cooldowns monitors, or says "No tracked cooldowns" |
| Speak Group Health | Alt+H | (Retail and WoW: Forever) Says every group member once, in number order, with the pitch of their health. On a controller: right trigger + right stick press. Only works while the Group Health Monitor is enabled |

See [Monitors](../information/monitors.md) and [Group Health Monitor](../information/group-health.md).

## Controller

| Action | Default key | Notes |
|---|---|---|
| Close (Controller) | Unbound (no keyboard key) | Gives the controller's close button the game's own Escape on windows where Escape stays with the game |

On Retail and WoW: Forever every binding can also have controller buttons. The defaults are listed in [Controller](../controller.md).

## Keys inside specific windows

These are not extra bindings. They are the window keys from the first sections, doing a job that belongs to one window. Changing the binding changes the key everywhere.

| Where | Key | What it does |
|---|---|---|
| Chat window (Shift+F3), message list | Up, Down, Home, End | Move between messages |
| Chat window, message list | Left, Right | Switch to the previous or next chat tab |
| Chat window, message list | Ctrl+Left, Ctrl+Right | Move between the clickable parts of a message (channel, sender, links) |
| Chat window, message list | Enter, Backspace, Shift+Enter, Space | Left click, right click, shift click and read the tooltip of the selected part |
| Navigation window (F10), Destinations list | Up, Down, Home, End | Walk the long destination list; Enter starts the route |
| Navigation window, Search box | Enter, Tab, Escape | Enter and Tab apply the text, Escape closes the box without changing the search |
| Scanner (F9) | Right, Left, Enter | Open or step into a group, close it or step out, guide you to the entry |
| Scanner | Backspace | Opens the extra text of an entry, such as a quest's objective |
| Scanner | Tab | Jumps between the list and the Refresh button |
| Action bars (Shift+F4), bags and other slot windows | \\ or Ctrl+D, then Delete | Pick up a slot onto the cursor, then clear or destroy it |
| Friends, ignore, who and guild lists (Classic Era, TBC and Mists) | Page Up, Page Down | Scroll the list a page; Home and End do nothing there |
| WowVision menu, context menus, dropdown menus | Letters | Jump to the next entry that starts with the letter. Can be switched off with the Letter Navigation in Menus setting |
| Edit boxes | Enter, Tab, Escape | Enter puts the cursor in a game box and accepts a WowVision box; Tab moves on; Escape cancels a WowVision box |

See [Chat](../windows/chat.md), [Navigation and Routes](../world/navigation.md), [Scanner](../world/scanner.md), [Action Bars](../windows/action-bars.md) and [Using the Interface](../basics/interface.md).

## When Sku is installed

Some WowVision bindings do the same job as keys of Sku, the older accessibility addon. While Sku is loaded, WowVision does not activate these bindings at all and leaves the keys to Sku:

- the four tooltip line keys (Shift+Up, Shift+Down, Shift+Left, Shift+Right)
- the soft targeting switches (Shift+I, Shift+P, Shift+O)
- Target Focus 1 to Target Focus 5 (and the `/focus1` to `/focus5` commands)

WowVision also leaves a list of windows and the commands `/pquit` and `/dquit` to Sku. The decision is made once at login, so switching Sku on or off needs a reload. Keys, windows and commands that are not listed stay with WowVision. More about running both addons together is in [Installation](../getting-started/sku.md).
