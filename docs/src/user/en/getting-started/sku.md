# Using WowVision together with Sku

WowVision and Sku can be installed side by side, and many players run both. They do not fight over the same windows: when Sku is loaded, WowVision deliberately steps back from the windows, keys and commands listed below and leaves them to Sku. Everything not on the list is still handled by WowVision.

## How it works

When the game loads WowVision, it checks which addons are already loaded. If Sku is among them, every window, key binding and command marked as "belongs to Sku" is switched off for that session: the window simply never opens in WowVision, the key is not taken over, the command is not registered. The decision is made once at login, so enabling or disabling Sku needs a reload (/reload) or a new login to take effect. Nothing is deleted: your WowVision settings and key bindings for these features stay as they are and come back as soon as Sku is off.

If a window is not read by WowVision and you have Sku loaded, this is almost certainly why. To switch Sku off for a session, disable it in the game's addon list, or type /disableaddon sku (it turns off Sku and its helper addons and reloads the interface; /enableaddon sku turns them back on). These two commands are themselves skipped when the BlindSlash addon is loaded.

## What Sku keeps when both are loaded

Windows on every game version:

- Bags.
- Gossip and other NPC dialogs.
- Merchant.
- Mailbox.
- Popups (the game's confirmation dialogs).
- Quest giver window (accepting and handing in quests).
- Flight master (taxi map).
- Trade window.
- Trainer.
- Ready check and the dungeon ready popup.
- Role poll (the role check popups).
- Guild invitation.

Additional windows on Classic Era, The Burning Crusade (TBC) and Mists of Pandaria (Mists):

- The Friends and Social window, with its Friends, Ignore, Who and Guild pages.
- The guild member card, guild information, guild event log and guild control windows of the classic guild window.

Additional windows on The Burning Crusade (TBC) only:

- Character pane.
- Spellbook.
- Talents.
- Trade skills and the crafting (Craft) window.
- Pet stable.
- Quest log.

Additional windows on Mists of Pandaria (Mists) only:

- Character pane.
- Talents.
- Quest log.
- Item upgrade.
- Reforging.

Additional windows on Retail and WoW: Forever:

- Guild and Communities, with its member card, text editor, event log and news filters.
- Guild control.
- The Social window with its side windows (ignore list, Battle.net broadcast, Battle.net unavailable notice, raid info, Add Friend).
- Cooldown manager window and its alert editors.
- Quest log.
- On WoW: Forever only: Character pane and the gear set popup.

Keys that Sku keeps (WowVision does not take them over while Sku is loaded):

- The tooltip line keys: Previous Tooltip Line and Next Tooltip Line (Shift+Up and Shift+Down), Read Tooltip Left and Read Tooltip Right (Shift+Left and Shift+Right).
- The soft targeting toggles Soft Target Enemy, Soft Target Friend and Soft Target Interact (Shift+I, Shift+P and Shift+O).
- Target Focus 1 to Target Focus 5.

Commands that Sku keeps: /focus1 to /focus5, /pquit (leave party) and /dquit (leave dungeon or battleground group).

## What WowVision still does for you

Everything else works as usual: speech and alerts, the buffers and monitors, targeting announcements, movement and navigation, the minimap scan, the scanner, the chat window and chat announcements, the chat channels window, the action bars window, the loot window, the auction house, the collections and professions windows where Sku has no equivalent, the game menu and options, and the WowVision menu.

