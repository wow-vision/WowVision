# Features by Game Version

WowVision runs on five game versions. The game itself picks the matching part of WowVision when it starts, so you never choose anything: everything listed for your version is simply there. This page shows which features and windows exist on which version.

The versions:

- Classic Era — the original game (Vanilla), on the Classic Era realms
- TBC — The Burning Crusade, on the anniversary realms
- Mists — Mists of Pandaria Classic
- Retail — the current expansion of World of Warcraft
- WoW: Forever — the WoW: Forever client

The Burning Crusade and Mists of Pandaria are the versions worked on most; WoW: Forever is changing quickly. Classic Era and Retail get everything that is shared by all versions, but fewer game windows of their own.

## Shared by all versions

These work the same everywhere (small differences are explained on each page):

- Moving through WowVision windows, clicks, context menus, tooltips: [Using the Interface](../basics/interface.md), [Tooltips](../basics/tooltips.md)
- Speech settings, alerts, the WowVision menu, keybindings: [Basics](../basics/index.md)
- Buffers: [Buffers](../information/buffers.md)
- Targeting, soft targeting, focus targets, the target menu: [Targeting](../world/targeting.md)
- Combat alerts, enemy count, game error messages: [Combat](../world/combat.md)
- Compass, zone and movement alerts, falling and wall detection, follow, corpse run, pitch lock: [Movement and Orientation](../world/movement.md)
- The navigation window and routes (F10), wherever map data exists: [Navigation and Routes](../world/navigation.md)
- The scanner (F9): [Scanner](../world/scanner.md)
- Chat, the chat window and chat tab buffers: [Chat](../windows/chat.md)
- Action bars window (Shift+F4): [Action Bars](../windows/action-bars.md)
- NPC dialogs, merchants, trainers, flight masters, books and letters: [Talking to NPCs](../windows/npcs.md)
- Quest giver windows: [Quests](../world/quests.md)
- Mailbox inbox, trade window, loot roll keys: [Loot, Trade and Mail](../windows/loot-trade-mail.md)
- Game menu, game options, popups, macros, color picker: [Menus, Options and Dialogs](../windows/system.md)
- Ready check and role check popups, guild invitation: [Group Finder](../windows/group-finder.md), [Social](../windows/social.md)

## Differences by version

"Yes" means WowVision reads or offers this on that version. "No" means it is not available there yet (the game's own window then stays unread, or the feature does not exist in that game version).

### Monitors

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Aura monitor | Yes | Yes | Yes | No | No |
| Cooldown monitor | Yes | Yes | Yes | No | No |
| Cooldown Manager Auras monitor | No | No | No | Yes | Yes |
| Spell Cooldowns monitor (with proc rules) | No | No | No | Yes | Yes |
| Group Health Monitor (speaks your group's health as pitched numbers, off by default) | No | No | No | Yes | Yes |
| Cooldown manager window (`/cdm`) | No | No | No | Yes | Yes |

On Retail and WoW: Forever the game hides aura and cooldown data from addons in combat and in instances, which is why those versions have their own monitor types. See [Monitors](../information/monitors.md).

### Navigation

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Map data shipped with WowVision (WowVision_MapData_TBC) | Yes | Yes | No | No | Yes |
| WowNav route planner | No | No | No | No | Yes |
| Minimap scan (Ctrl+Shift+F) | No | No | No | Yes | Yes |

Routes need map data: without it the navigation window has nothing to route along, though the scanner can still point you straight at things. The minimap scan works on Retail and WoW: Forever. The Classic clients lack a minimap function it needs, so on Classic Era, TBC and Mists the key answers "Minimap scanner not available on this client". See [Minimap](../world/minimap.md).

### Bags, bank, mail and social windows

| Window | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Bags and bank | Yes | Yes | Yes | Yes | Yes |
| Mailbox: send mail tab | Yes | Yes | Yes | No | No |
| Friends, ignore and who list (classic friends window) | Yes | Yes | Yes | No | No |
| Social window (friends, Battle.net friends, who) | No | No | No | Yes | Yes |
| Guild window (classic guild tab and its dialogs) | Yes | Yes | No | No | No |
| Guild and communities window, guild control | No | No | No | Yes | Yes |
| Chat channels window | No | No | No | Yes | Yes |

See [Social](../windows/social.md).

### Character, spells and professions

| Window | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Character pane | No | Yes | Yes | No | Yes |
| Spellbook | No | Yes | Yes | No | Yes |
| Talents | No | Yes | Yes | No | Yes |
| Glyphs | No | No | Announces "Glyphs not yet implemented" | No | No |
| Spell search | No | No | No | No | Yes |
| Trade skills / professions | No | Yes | Yes | No | Yes |
| Craft window (enchanting) | No | Yes | No | No | No |
| Gem socketing | No | Yes | Yes | No | No |
| Reforging and item upgrade | No | No | Yes | No | No |
| Quest log window | No | Yes | Yes | Yes | Yes |
| Quest choice dialog | No | No | Yes | No | No |
| Questie support | Yes | Yes | Yes | No | Yes |

Quest log details per version are on the [Quests](../world/quests.md) page. See also [Character](../windows/character.md), [Spells and Talents](../windows/spells-and-talents.md) and [Professions](../windows/professions.md).

### Collections, group finder, auction house

| Window | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Mount journal | No | No | Yes | No | Yes |
| Pets, toys, heirlooms, appearances | No | No | No | No | Yes |
| Legacy (reward track, challenges, trees) | No | No | No | No | Yes |
| Group finder | No | Yes | No | Yes (Dungeon Finder; other tabs not yet) | Yes |
| Pet stable | No | Yes | No | No | No |
| Auction house | No | Yes (with price database and full scan) | Yes | Yes (with price database and full scan) | Yes (with price database and full scan) |

See [Collections](../windows/collections.md), [Group Finder](../windows/group-finder.md) and [Auction House](../windows/auction-house.md).

### Movement and combat

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Pitch lock also holds while flying | Yes | Yes | Yes | No | No |
| Target Crowd Control alert (sound when your target is stunned, feared and the like) | No | No | Yes | Yes | Yes |
| Game hides values from addons in combat and instances (health, power, auras and so on) | No | No | No | Yes | Yes |

On Retail and WoW: Forever the pitch lock holds only while swimming, because skyriding steers by pitch. The Target Crowd Control alert needs a crowd control filter in the game's aura system. The Classic Era and TBC clients do not have it, so the alert is missing there. See [Targeting](../world/targeting.md), [Movement and Orientation](../world/movement.md) and [Combat](../world/combat.md).

### Controller

| Feature | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Gamepad support (controller buttons in WowVision windows and the world, shortcut layer) | No | No | No | Yes | Yes |
| Gamepad main menu and gamepad action bars | No | No | No | No | Yes |

The Classic clients have no gamepad interface. See [Controller](../controller.md).

## When a window is not read

If a game window from the table is not read on your version although it should be, check two things first:

- Is Sku loaded? While Sku runs, WowVision leaves many windows to Sku. See [Using WowVision together with Sku](../getting-started/sku.md).
- Is the window module enabled? Every window has an Enabled setting under Windows in the WowVision menu. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

More help is in [Troubleshooting](../getting-started/troubleshooting.md).
