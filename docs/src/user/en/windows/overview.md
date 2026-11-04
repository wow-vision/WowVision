# Game Windows

Most of World of Warcraft happens in windows: your bags, a merchant, the quest log, the talent tree, the mailbox. A sighted player clicks around in them with the mouse. WowVision reads these windows to you and lets you work them with the keyboard, like a desktop application with a screen reader.

This page explains how that works in general. The pages in this section then go through the windows one by one.

## How it works

You open a game window the usual way: with the game's own key (B for bags, C for the character pane, L for the quest log and so on), by talking to an NPC, or by clicking something. WowVision notices that the window is open and turns it into a WowVision window:

- It says the window's name and the element you are on, for example "Merchant" and then "Linen Cloth, 1 silver, Button".
- The window keys now work: the arrow keys, Tab and Shift+Tab move between elements, Enter is a left click, Backspace a right click, Space reads the tooltip, Shift+F10 opens the context menu. All of this is explained in [Using the Interface](../basics/interface.md).
- Escape closes the window, the same as closing it in the game.

As soon as the game window closes, the WowVision window closes too, and your keys go back to the game. While no WowVision window is open, the arrow keys, Tab, Enter and the other window keys do whatever you bound them to in the game, so they never get in the way of playing.

WowVision does not replace the game's windows; it reads the real ones. Anything you do (buying, equipping, learning a talent) is a real click in the game's window.

## Several windows at once

You can have more than one window open, for example a merchant and your bags. Ctrl+Tab and Ctrl+Shift+Tab switch between them. Each window remembers the element you were on.

A typical case is selling: talk to a merchant, open your bags, find the item and right click it with Backspace to sell it.

## Windows of WowVision itself

Some windows belong to WowVision and have no counterpart in the game:

| Window | Key | Page |
|---|---|---|
| WowVision menu (settings) | Shift+F1 or `/wv` | [The WowVision Menu and Settings](../basics/menu-and-settings.md) |
| Chat window | Shift+F3 | [Chat](chat.md) |
| Action bars window | Shift+F4 | [Action Bars](action-bars.md) |
| Scanner | F9 | [Scanner](../world/scanner.md) |
| Navigation window | F10 | [Navigation and Routes](../world/navigation.md) |

They work with the same keys as the game windows.

## In combat

The game does not let addons take over keys during a fight. When combat starts, WowVision hands its window keys back to the game and stops reading windows; when combat ends, it takes them back and you are where you left off. See [Combat](../world/combat.md).

## Turning a window off

Every supported window is a module under Windows in the WowVision menu. If you prefer to handle a window without WowVision, or another addon reads it for you, switch that module off there. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

## When Sku is loaded

If you run Sku, the older accessibility addon, at the same time, WowVision leaves many windows to Sku and does not read them itself. Which ones is listed in [Using WowVision together with Sku](../getting-started/sku.md).

## Windows that are not read yet

Not every game window is supported on every version. If a window opens and WowVision says nothing, it is probably one of these. [Features by Game Version](../reference/versions.md) has the full table; the pages below mention what is missing in each window.

Windows that every version reads: bags and bank, merchants, NPC dialogs, the quest giver window, flight masters, trainers, trade, the mailbox inbox, books and letters, the game's confirmation popups, ready check and role check, guild invitations, the game menu and options, macros and the color picker. Beyond that, each version has its own set:

| Version | More windows |
|---|---|
| Classic Era | Friends, ignore and who lists, the classic guild windows, the Send Mail tab. Nothing else yet. |
| The Burning Crusade (TBC) | The Classic Era set, plus character pane, spellbook, talents, trade skills, craft window, gem socketing, quest log, pet stable, group finder and auction house. |
| Mists of Pandaria (Mists) | The Classic Era set, plus character pane, spellbook, talents, trade skills, gem socketing, reforging, item upgrade, quest log, quest choice, mount journal and auction house. |
| Retail | Quest log, auction house, chat channels, the Social window, guild and communities, guild control and the cooldown manager window. |
| WoW: Forever | The Retail set, plus character pane, spellbook with talents, professions, collections, Legacy, group finder, the gamepad windows and the WowNav floors list. |

## The pages in this section

- [Action Bars](action-bars.md) — the action bars window, dragging spells and items, gamepad bars
- [Bags and Bank](bags-and-bank.md) — bags, bank, using and moving items, destroying items
- [Talking to NPCs](npcs.md) — dialogs, merchants, trainers, flight masters, books and letters, pet stable
- [Loot, Trade and Mail](loot-trade-mail.md) — loot rolls, trading with players, the mailbox
- [Character](character.md) — equipment, stats, reputation, skills, PvP, equipment sets
- [Spells and Talents](spells-and-talents.md) — spellbook, talents, glyphs, spell search
- [Professions](professions.md) — trade skills, crafting, socketing, reforging, item upgrade
- [Collections](collections.md) — mounts, pets, toys, heirlooms, appearances, Legacy
- [Group Finder](group-finder.md) — group finder, ready check, role check
- [Auction House](auction-house.md) — buying, selling, price scans
- [Chat](chat.md) — chat announcements, the chat window, clicking links
- [Social](social.md) — friends, guild, communities, channels
- [Menus, Options and Dialogs](system.md) — game menu, game options, popups, macros and more
