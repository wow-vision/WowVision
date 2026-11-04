# Social: Friends, Guild, Communities and Channels

This page covers the windows where you deal with other players: the friends list, ignore list and who list, Battle.net friends, the raid tab, the guild windows, the chat channels window, the guild invitation, and the player menus that open from names all over the game. For reading and sending chat messages, see [Chat](chat.md).

All of these windows open the way a sighted player opens them: with the game's own keys and buttons. WowVision notices when the game opens the window and reads it. You move around with the usual WowVision keys (see [Interface](../basics/interface.md)): Tab and Shift+Tab between sections, Up, Down, Left and Right inside a section, Enter for a left click, Backspace for a right click, Space to read a tooltip, Shift+F10 for the context menu of the focused control, and Escape to close.

## What exists on which game version

| Window | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Friends window: friends list, ignore list, who list | Yes | Yes | Yes | No (see Social window) | No (see Social window) |
| Social window: Battle.net bar, friends, requests, recent allies, quick join, raid | No | No | No | Yes, where the game uses it | Yes |
| Guild tab of the friends window (classic guild window) | Yes | Yes | No: Mists has its own guild window, which is not read yet | No | No |
| Guild and Communities window | No | No | No | Yes | Yes |
| Guild control | classic version | classic version | No | Yes | Yes |
| Chat channels window | No | No | No | Yes | Yes |
| Guild invitation window | popup | popup | window if the client has it, else popup | Yes | Yes |
| Raid tab | not read yet | not read yet | not read yet | Yes | Yes |

If the Sku addon is loaded, the friends, guild, communities and social windows are left to Sku and WowVision does not read them (see [Using WowVision together with Sku](../getting-started/sku.md)). The chat window and the chat channels window are not affected.

## The friends window (Classic Era, TBC, Mists)

Open it with the game's social key (O by default) or the Friends button of the game's menu.

The window is read in these parts, in this order, which you reach with Tab:

1. The page itself: the friends list, the ignore list, the who list or the guild page, depending on the tab.
2. Page controls (called Controls): the buttons under the page.
3. On the Friends tab, a strip of sub-tabs (Friends and Ignore) where the game has it.
4. The strip of main tabs at the end (Friends, Who, Guild and Raid; on older versions also Ignore). The selected tab says "selected". Enter switches tab.

The Raid tab is not read yet: it says "This tab is not supported yet".

### Friends list

The list holds your friends in the order the game uses: Battle.net friend requests first (under a Friend Requests header), then friends who are online (character friends, then Battle.net friends), then those offline. Up and Down move through the list, Page Up and Page Down scroll it. Home and End do not work in this list (nor in the ignore list, the who list or the guild roster of this window).

Each friend is announced in one go:

- A character friend: the name and, when online, "Level 60 Mage"; then the status (Offline, Away, Busy), then the zone and the note ("Note ..."). If you have the friend selected, "selected" is added.
- A Battle.net friend: the account name, the character they play and, when they are not in WoW, the game they are in; then the status (offline friends say when they were last online), the zone, the note and their status message.

Keys on a friend:

- Enter selects the friend (a left click).
- Backspace opens the game's friend menu: whisper, invite to group, set a note, remove friend and so on. See [Player and dropdown menus](#player-and-dropdown-menus).
- Shift+F10 lists the same two clicks.

The Controls section after the list has:

- Send Message: whisper the selected friend.
- Add Friend: opens the game's Add Friend dialog, where you type a character name or BattleTag (see [Popups](system.md)).
- Status: a dropdown for your own status (available, away, busy).

Friend requests: the Friend Requests (N) header folds the requests when you press Enter. Every request reads "Friend request" and the sender's name. When a request has the focus, Tab reaches Accept, and Tab again reaches Decline, a dropdown with decline, block and report. Both press the game's own buttons.

Example: whisper a friend.

1. Press O to open the friends window. You land on the friends list.
2. Use Up and Down until you hear the friend's name.
3. Press Backspace for the friend menu and choose Whisper. The chat box opens, addressed to the friend, with a sound.
4. Type your message and press Enter to send.

Or, instead of steps 3 and 4: press Enter to select the friend, Tab to Controls and press Enter on Send Message.

Example: invite a friend to your group.

1. Open the friends window and select the friend.
2. Press Backspace and choose Invite.

Example: add a note to a friend.

1. Press Backspace on the friend and choose Set Note.
2. The game opens a small edit box (a popup). Type the note and press Enter.

### Ignore list

The ignore list is its own tab or sub-tab. It has a heading Ignore List with the players you ignore, and below it, when you have any, a heading for blocked Battle.net invitations. Enter selects a name and Backspace is a right click.

The Controls hold the game's button for ignoring a player (it asks for a name, or takes your target) and the button for stopping ignoring the selected name.

Example: stop ignoring someone.

1. Switch to the ignore list (Tab to the tab strip, then Enter on Ignore).
2. Move to the name and press Enter to select it.
3. Tab to Controls and press Enter on the button that stops ignoring.

### The Who list

Open the Who tab to search for players. It has:

- Search: an edit box. Type a search such as a name, a level range ("60"), a class ("c-Mage"), a zone ("z-Orgrimmar"), a guild ("g-Name"), then press Enter, as in the game.
- List: the results, one line each: "Name, Level 60 Mage, Race, Zone, Guild". Enter selects a result and Backspace opens its player menu.
- Controls: the total ("12 players"), the search button, Add Friend, Group Invite and a Column dropdown that chooses which extra column the game shows (zone, guild or race).

Like the friends list, this list scrolls with Page Up and Page Down; Home and End do not work in it.

Example: find players in a zone and invite one.

1. Open the friends window and switch to the Who tab.
2. In Search, type "z-Elwynn Forest 10-20" and press Enter.
3. Tab to the list and move to a name. Press Enter to select it.
4. Tab to Controls and press Enter on Group Invite.

The Who list is available on Classic Era, TBC and Mists. On Retail there is no who tab in the Social window; a who search (from a chat name with Shift+Enter, or the /who command) shows its answer the way the game does. On WoW: Forever the Who tab is part of the group finder window (see [Group finder](./group-finder.md#who-tab-wow-forever)).

### The guild tab of the friends window

On Classic Era and TBC the Guild tab of the friends window is the guild window. Mists has a separate guild window, which WowVision does not read yet. It is described in [The guild window (Classic Era, TBC)](#the-guild-window-classic-era-tbc).

## The Social window (Retail, WoW: Forever)

Where the game uses the Social window (WoW: Forever does, and turns the older friends list off), the game's social key (O by default) opens it instead of the friends window. Retail uses the same window.

The window is read from top to bottom:

1. Battle.net, a row with: your BattleTag, Copy BattleTag (puts it on the clipboard), a notice button when Battle.net is down (Enter opens a small notice window that reads its heading and text), Status (a dropdown, read together with your current status) and a Menu dropdown (broadcast, ignore list and more).
2. The page of the selected tab.
3. Tabs, a row: Friends, Recent Allies, Quick Join, Friend Requests, Recruit a Friend and Raid. A tab says "selected" if it is the shown one, and "Disabled" together with its reason if it cannot be used. A tab can also announce a count (for example the number of Quick Join groups).

The Recruit a Friend page is not read yet: it says "This tab is not supported yet".

### List pages

Friends, Recent Allies, Quick Join and Friend Requests share one layout:

- Search and Filter: a search edit box and a filter dropdown, in one section.
- A notice line where there is one ("Loading", Battle.net unavailable).
- On Friend Requests, a one-time warning about Real ID requests with a continue button.
- The list, in groups under collapsible headers such as "Friends (3/10)". Enter on a header folds or opens it; it says Collapsed or Expanded.
- An action button: Add Friend or Join.

A card announces the name, Favorite where it applies, the status (online, away, busy, offline, in game and so on), then what the card shows (character, level, class, where, last seen), and "selected" if it is the selected card. A Quick Join entry reads the names of the friends in the group, then what they are queued for, and "Disabled" if you cannot join.

On a card:

- Enter selects it (a left click).
- Backspace opens the game's menu for it.
- Shift+F10 opens the context menu, which lists the card's own buttons as entries: Invite (friends, recent allies), Summon (Recruit a Friend), Accept and Decline (friend requests; decline opens a menu), then the left and right click.

Example: invite a friend to your group from the Social window.

1. Press O and make sure the Friends tab is selected (check the tab row with Tab).
2. Move through the list to the friend. Optionally use Search to type the name first.
3. Press Shift+F10 and choose Invite.

Example: accept a friend request.

1. Open the Social window and Tab to the tab row, then press Enter on Friend Requests.
2. Move to the request and press Shift+F10, then choose Accept.

Example: whisper a friend.

1. Open the Friends tab and move to the friend.
2. Press Backspace for the game's menu and choose Whisper; the chat box opens with a sound. Type and press Enter.

### The Add Friend window

Add Friend opens a window of its own. The first time you use it, an information page comes first (with an Okay button). Then: an edit box "Enter character name or BattleTag", then any error or information line, Send Request and Cancel, and after them the explanations of what each kind of name adds.

### The Raid tab

When you are in a raid: the role counts ("Tank 2, Healer 3, Damage 5"), then each group ("Group 1" and so on) with its members. A member reads "Name, Level 80 Warrior, Raid Leader, Main Tank, Offline or Dead, Zone". Enter targets the member and Backspace opens the player menu; Shift+F10 lists both. Moving members between groups is drag and drop and is not read.

When you are not in a raid, the game's description appears instead of the groups. The Controls section holds the Everyone is Assistant check box, Convert to Raid (only when you are not in a raid) and Raid Info.

### Raid Info

Raid Info opens a window listing saved instances and world bosses: "Name, Difficulty, time to reset", plus "Extended" where you extended the lockout. A lockout that has run out reads the game's "expired" text instead of a time. Enter selects an entry, Extend extends the selected lockout, Close closes the window.

### Ignore list (Social window)

The ignore list opens from the Battle.net Menu. It lists ignored players and blocked invitations under their headings; Enter selects a name. Two buttons below: one to ignore a player (your target or a typed name) and one to remove the selected name.

### Broadcast

Choose the broadcast entry of the Battle.net Menu to set the message your Battle.net friends see under your name. The window has the edit box, Update and Cancel.

## The guild window (Classic Era, TBC)

Open the guild tab with the game's guild key (J by default), or by choosing the Guild tab in the friends window. The guild tab is read from top to bottom:

1. Guild name: a heading with the member total and online total, and the message of the day. If you may change the message of the day, it is a button: Enter opens the game's edit box.
2. Members: the roster. A member reads "Name, Level 60 Mage, Zone, Rank, Note". A member who is offline says when they were last online instead of the zone. Away and busy members say so.
3. Controls: the Looking for Guild check box where it applies, a button that switches between the two column sets (Player Status: level, class, zone; Guild Status: rank, note, online), the sort headers (Sort), and the buttons Add Member, Guild Control, Guild Information, and, where shown, the button to replace an inactive guild master.

On a member: Enter selects them and opens the member card; Backspace opens the game's member menu (whisper, invite, promote, demote, remove).

### The member card

The member card opens as a window of its own beside the friends window. It reads: the name, "Level 60 Mage", zone, rank, last online or online, the Promote and Demote buttons (for officers who may use them), the personal note and, for officers, the officer note, then Remove, Group Invite and Close.

A note you may edit is a button: Enter on it opens the game's note box where you type and press Enter.

Example: invite a guild member to your group.

1. Open the guild tab with J and move to the member in the roster.
2. Press Enter. The member card opens.
3. Move to Group Invite and press Enter. Close the card with Escape.

(Or press Backspace on the member and choose Invite in the menu.)

Example: set an officer note.

1. Select the member (Enter), so the member card opens.
2. Tab or arrow to the Officer Note button. It says the note's current text.
3. Press Enter, type the new note into the game's box and press Enter to save.

Example: set the message of the day.

1. On the guild tab, move to the message of the day, which is a button when you have the right to change it.
2. Press Enter, type the message and press Enter.

### Guild information, event log and guild control

- Guild Information: a window with the text of the guild information. When you may edit it, it is an edit box, followed by Save, Cancel, Event Log and Close.
- Guild event log: one line per event (who invited, joined, was promoted and so on), newest first, then Close.
- Guild Control (guild master and officers): the rank dropdown, the rank name box, Add Rank and Remove Rank; the permission check boxes of the selected rank and the gold it may withdraw per day; and, where the guild bank is on, a row of bank tabs with, for the selected tab, the check boxes View, Deposit and Update Text and the number of withdrawals per day; Accept and Cancel at the end.

## The Guild and Communities window (Retail, WoW: Forever)

Open it with the game's guild key (J by default). It has these parts, which you reach with Tab in this order:

1. A banner when the guild must be renamed (guild leaders only).
2. Guild and Communities, the list on the left: your guild, your communities, invitations and the finder entries (guild finder, find a community, join a community). Enter selects one. Backspace opens the game's menu for it. Each entry says its name, "Guild" for a guild, Favorite, "selected", and "Disabled" for finders you cannot use. When the window is minimized, this list is a dropdown instead.
3. The page, chosen with the tabs.
4. Controls, the buttons along the bottom, which depend on the page and your rank: Invite, Community Settings, Guild Recruitment, Guild Control, View Log, and Maximize or Minimize.
5. Tabs, a row: Chat, Roster, Guild Benefits, Guild Info and, for communities, Preferred Play. The selected tab says "selected". The chat tab can be locked (chat muted or turned off) and then says "Disabled" and the reason.

An invitation to a community shows as a page of its own: the invitation text, the community's name, type, member count, leader and description, then Accept and Decline.

The finders (guild finder, find a community), the lists of applicants and the Preferred Play settings are not read yet; they say "This tab is not supported yet".

### Chat page

- The channel dropdown, Add to Chat and the calendar button.
- Messages: the latest fifty messages, oldest first. Focus starts on the newest. Each message is read with links reduced to their text. Jump to Unread follows when there is one.
- Chat: the game's own chat box. Type and press Enter to send.
- The short member list: the member count, Show Offline and the members. A member reads "Name, Leader or Moderator, Away or Busy or Offline".

### Roster page

- The column dropdown (a guild and a community each have their own) to choose an extra column, such as achievement points or dungeon score.
- The member count and the Show Offline check box.
- Sort By: a row of column header buttons. Enter sorts by that column.
- Members: every member, for example "Name, Level 80 Hunter, Zone, Rank, Note". An offline member reads when they were last online. A pending invitation reads the invitee's name, and Cancel is in its context menu.

Enter on a guild member opens the member card. Backspace opens the player menu. For a community member, Enter does what a left click does in the game for that row (for example showing a profession's recipes under a profession heading).

### Guild Info page

- Challenges, where the guild has them, each with its progress.
- Message of the Day with its text and an edit button. Enter on the edit button opens a small window with an edit box, Accept and Close. In the message box, Enter accepts; in the guild information box, Enter starts a new line.
- Guild Information: the text and its edit button.
- The news: a Set Filters button (a window with one check box per kind of news and Close), the button to replace an inactive guild master where the game offers it, and the news list. Dates are headings; each line reads like "Xynayya earned the achievement ...". With no news you hear the game's "no news" text.

### Guild Benefits page

The perks, the rewards ("Item name, cost, requirement") and the guild's achievement points and reputation.

### The member card

A guild member's card is a window of its own, the same as on Classic: the name, level and class, zone, rank, last online, the notes, Remove, Group Invite and Close. Where you may promote or demote, the rank is a dropdown. A note you may edit is a button; Enter opens the game's note box.

### The event log

View Log (among the Controls) opens the guild event log: one line per event ("A invited B", "A promoted B to Officer", and so on) with its time, newest first, then Close.

Examples for this window:

Invite a guild member to your group.

1. Press J. Tab to Tabs and choose Roster with Enter.
2. Tab back to the members and move to the player.
3. Press Backspace and choose Invite. Or press Enter for the member card and use Group Invite.

Set an officer note.

1. Open the Roster page and press Enter on the member.
2. In the member card, go to Officer Note, press Enter, type and press Enter.

Read what the guild said.

1. Open the Chat page. Focus lands on the newest message; Up goes back.
2. Press Tab to reach Chat to type a reply.

## Guild control (Retail, WoW: Forever)

The Guild Control button (guild master and officers) opens a window of rank management. A dropdown at the top picks the page:

- Guild Ranks: a row per rank, each with the rank name box (the game saves a new name when you leave the box), and buttons to move the rank up, move it down and delete it; right arrow reaches the buttons. Then New Rank below the list.
- Rank Permissions: the rank dropdown ("Select Rank" and the rank shown), the officer check box with its explanation, the permission check boxes, the guild bank permissions with the gold the rank may withdraw per day (reads "Disabled" when greyed out), and the authenticator check box (can be greyed out for the last rank and a rank in use).
- Guild Bank Tab Permissions: the rank dropdown, then each guild bank tab with its View and Deposit check boxes and its item withdrawals per day, and, for a tab you can still buy, its cost and the button to buy it.
- Discord: the Discord link page, read as its texts and controls.

Close closes the window.

Example: set the permissions of a rank.

1. In the guild window press Guild Control.
2. Choose Rank Permissions in the page dropdown.
3. Pick the rank with the rank dropdown.
4. Move through the check boxes and press Enter on each to turn it on or off.

## The chat channels window (Retail, WoW: Forever)

The window of the game's channels. Open it with the channel button of the chat window, the game's Toggle Chat Tab key, or by pressing Shift+Enter on a channel name in the chat window.

It has:

- Channels: the channel list under headers (group, global, custom, communities). Enter on a header folds it; it says Collapsed or Expanded. Enter on a channel selects it; the channel says "selected", and "Disabled" when you left it. Backspace opens the channel menu (leave, join, set a password, invite).
- Members: the members of the selected channel, named after it ("Members, Trade"). Each reads "Name, Owner or Moderator, Offline". Backspace opens the player menu.
- The buttons Add and Settings (voice chat).

Add opens the new channel box: a name and a password edit box (it opens in the name box, so you can type at once), a voice chat check box where the game has it, OK and Cancel. Enter in either box creates the channel.

The voice chat parts (the headset button on a channel, mute and deafen on members) are not read yet.

Example: join a custom channel.

1. Open the chat channels window and Tab to Add. Press Enter.
2. Type the channel name, and the password if it has one, and press Enter.

## The guild invitation

When a player invites you into a guild, WowVision opens the invitation window (Retail, WoW: Forever, and wherever the game uses it): the inviter, the invitation text, the guild's name, its achievement points where the game shows them, and a warning about guild reputation when you would lose some. Tab reaches Join Guild and Decline.

Closing the invitation declines it, as in the game: Escape declines. The game also declines on its own after one minute.

On Classic Era and TBC the invitation is an ordinary popup and reads like every other popup (see [Popups](system.md)).

## Player and dropdown menus

Almost every name you can select in the game has a menu, and WowVision reads all of them the same way. They appear when you press Backspace (right click) on a player in the friends list, who list, roster, raid list, channel members or chat message, when you press Alt+T for your target, and from a tab or card.

A menu opens as its own section. Each menu level is a separate stop: the main menu first, and a submenu is another level that opens when you press Enter on a row with a submenu (it says "dropdown"). Escape closes the level you are in. In a menu that you can type in, pressing a letter jumps to the next row that starts with it.

The menu's own headings (the player's name, Interact, Other Options) are read once when you cross into their section, and you do not land on them. Each row says its text and, where it applies, Checked or Unchecked, and Disabled if you cannot use it. A row that carries small buttons (like play or delete) is a row: Right reaches them.

A player's menu has the game's usual rows, for example Whisper, Invite, Add Friend, Ignore, Inspect, Target, Focus, Report, Set Note and Copy Character Name. Which rows you see depends on the player and the game version.

Copy Character Name: on a menu you opened from the chat window, WowVision opens its own box for this row (the same as Copy Line in chat): it says "Copy now", the name is selected, Ctrl+C copies and Escape closes. In other menus the row is the game's own and copies the name straight to the clipboard.

### The target menu (Alt+T)

Alt+T opens the menu of your current target, the one a right click on the target's portrait opens: whisper, invite and the rest. With yourself targeted it offers Reset All Instances, loot and dungeon difficulty. With no target nothing opens. It is bound by default and can be changed in the keybinding window. It is described with the other targeting keys in [Targeting](../world/targeting.md).

Example: invite the player you targeted.

1. Target the player.
2. Press Alt+T, move to Invite and press Enter.

See [Interface](../basics/interface.md) for the general rules of dropdowns and context menus.

## Keys at a glance

| Key | Where | What it does |
|---|---|---|
| Enter | Lists | Select (left click). |
| Backspace | Lists | Right click: open the game's menu. |
| Shift+F10 | Any control | Context menu of the control (clicks, card buttons). |
| Space | Any control | Read the tooltip. |
| Tab, Shift+Tab | Window | Next and previous section. |
| Alt+T | Anywhere | Menu of your target. |
| Escape | Window or menu | Close. Declines a guild invitation. |

The game's own keys open the windows (social key, guild key, and so on); WowVision adds no keys of its own for them.
