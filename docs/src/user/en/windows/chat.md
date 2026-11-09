# Chat

WowVision speaks incoming chat messages as they arrive, keeps a history of every chat tab you have, and lets you read that history, click the names and links in it, and copy lines out of the game. This page covers the announcements, the chat window, the chat settings and what you can and cannot do while the game hides chat text.

Chat works on every game version: Classic Era, The Burning Crusade (TBC), Mists of Pandaria (Mists), Retail and WoW: Forever. The few places where versions differ are marked.

## How WowVision follows your chat tabs

WowVision follows the chat tabs you have in the game. Which messages and channels a tab receives is decided by the game's own chat settings, exactly as for a sighted player. WowVision only decides how each tab is spoken. If you change which messages a tab receives (see [Choosing what a tab receives](#choosing-what-a-tab-receives)), the spoken messages and the history follow.

Every tab keeps up to 5000 lines. The history is saved with your character, so it is still there after a reload or a new login. Closing a tab throws its history away. Each line is stored with its date and time.

## Incoming messages

When a message arrives in a tab that is allowed to speak, you hear the line as the game would show it, for example "[Guild] Xynayya: anyone for Deadmines?". A short sound plays with it by default.

Two things decide whether a tab speaks:

- The tab's own message alert must be enabled (it is by default).
- The tab's Speak Messages choice, explained below.

A message that reaches several speaking tabs is spoken only once, by the first tab that gets it. Messages you hear are also written into the tab's history, whether or not they were spoken.

The game has a text to speech feature of its own for chat (in the game's chat settings, under Text to Speech). Leave it off, or you will hear every message twice.

## Per-tab alerts

Open the WowVision menu (Shift+F1) and go to Chat. The screen lists one entry for every chat tab that is open, named exactly like the tab (for example General or Trade), followed by Whisper Tabs. Press Enter on one to see its settings.

Every tab entry has the same settings:

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | Turns the whole alert for this tab on or off. When off, the tab is silent (its history is still kept). |
| TTS Alert | On | A group with three settings: Enabled (speak the message), Priority Message (interrupts) (when on, the message interrupts whatever is being said instead of waiting its turn; off by default) and Voice (which voice speaks it; by default it follows your speech voice). |
| Sound Alert | On | A group with Enabled and Sound, the sound that plays with each message. The default is a short chat sound. |
| Speak Messages | When the Tab Is Shown | When the tab speaks: see below. |

The Speak Messages choice has two values:

- When the Tab Is Shown: the tab speaks only while you can see it, that is, while it is the selected tab of its dock or a window of its own on screen. This is the behavior you know from a plain chat window.
- Always: the tab speaks everything it receives, whether it is selected or not.

The settings of the first tab (the General tab) carry over from older versions of WowVision, where there was a single chat alert.

Example: get whispers to reach you whatever tab you are reading.

1. In the game, make a new chat tab that receives only whispers (see [Choosing what a tab receives](#choosing-what-a-tab-receives)).
2. Press Shift+F1, go to Chat and press Enter on the new tab's entry.
3. Set Speak Messages to Always.
4. Open Sound Alert, then Sound, and pick a sound of its own, so you can tell a whisper from other messages.

Chat tabs that are not open do not show up. The settings of an alert you configured stay saved for the tab number, so a tab you close and open again keeps its choices.

The pet battle log tab is read, not spoken: it has no alert.

### Whisper tabs

The game can open a new tab for every whisper conversation (in the game's Interface options, New Whispers: in a new tab, or both). Battle.net whispers work the same way. WowVision picks these tabs up the moment the game opens them, so the very first whisper is not lost.

All whisper tabs share one alert, Whisper Tabs, with the same settings as above. It speaks Always by default, because in that mode the game takes the whisper out of every other tab and a tab you are not looking at would otherwise never say it.

Whisper tabs close when you close them or log out. The lines of all whisper tabs are also kept together in one list called Whisper Tabs, which is saved like the other histories (up to 5000 lines) and which you can read in a buffer (see [Chat tab buffers](#chat-tab-buffers)).

Lines that were already in a tab when WowVision picked it up (for example the lines the game copies into a new whisper tab from the tab you were in) are not spoken again.

## The chat window

Press Shift+F3 to open the chat window. Escape closes it. It has two parts, which you reach with Tab and Shift+Tab:

- The message list of the selected tab. It is the first stop.
- The tab strip, a row with one button per visible chat tab, in the order the game shows them (docked tabs left to right, then windows that stand on their own). Whisper tabs are included. The selected tab says "selected".

### Reading messages

The message list is one control that holds all the lines of the selected tab. It opens on the newest message.

| Key | What it does |
|---|---|
| Up and Down | Previous (older) and next (newer) message. |
| Home and End | Jump to the oldest and to the newest message. |
| Left and Right | Switch to the previous or next chat tab. You hear the tab's name and its newest message. At the first or last tab nothing happens. |
| Ctrl+Left and Ctrl+Right | Move between the clickable parts of the message (see below). |
| Enter | Left click on the selected part. |
| Backspace | Right click on the selected part. |
| Shift+Enter | Shift click on the selected part. |
| Space | Read the tooltip of the selected link. |
| Shift+Up, Shift+Down, Shift+Left, Shift+Right | Read the tooltip line by line (see [Tooltips](../basics/tooltips.md)). |
| Shift+F10 | Open the context menu of the message (see below). |

Each message is spoken as the line followed by its date and time, for example "[Guild] Xynayya: anyone for Deadmines? 11/02/26 14:03:22". When the message list gets the focus (the window opens, or you come back from a menu) you also hear your position, for example "340 / 340". Moving with Up, Down, Home and End speaks only the message and its time. Reaching the first or last message again says nothing. A tab with no lines reads "Empty".

Moving between tabs with Left and Right really clicks the neighboring tab, the same as a mouse would, so the game's own selected tab changes too. It makes no difference whether you press Enter on a tab in the tab strip or Left and Right in the message list.

Example: read what you missed in the guild tab.

1. Press Shift+F3.
2. Press Right until you hear the guild tab's name together with its newest message.
3. Press Up to go back through the messages, and End to return to the newest.
4. Press Escape to close the window.

### The tab strip

On a tab button, Enter selects the tab and Backspace opens the game's own tab menu (rename, settings, new window, close, and so on), which WowVision reads like any other dropdown (see [Player and dropdown menus](social.md#player-and-dropdown-menus)). Shift+F10 lists the same clicks.

### Clicking the parts of a message

A sighted player can click pieces of a chat line: the sender's name, the channel name and any linked item, quest or spell. WowVision gives you the same clicks.

Press Ctrl+Left and Ctrl+Right to move between the clickable parts of the current message, in the order they appear in the line. Each part is announced with its kind and name, for example:

- "Player Xynayya"
- "Channel 2. Trade - City"
- "Item Linen Cloth"
- "Quest The Defias Brotherhood"
- "Spell Frostbolt"

Other link kinds announce as Talent, Achievement, Profession, Currency, or simply Link. The first and last part are boundaries: nothing is said when you try to move beyond them.

When you arrive on a message, the first linked item is already selected if there is one, so the tooltip keys can read it right away. If the message has no link, the sender is selected, and otherwise the first part.

On the selected part:

- Enter is a left click. On a player it starts a whisper to them (the chat box opens), on a channel it starts a message to that channel, and on an item, quest, spell or other link it reads the tooltip.
- Backspace is a right click. On a player or a channel it opens the game's own menu (whisper, invite, add friend, ignore, and so on).
- Shift+Enter is a shift click. On a link it puts the link into your chat box (the box opens first if it is closed), so you can send it. On a player it puts the name into an open chat box, or, if no chat box is open, runs a who search for that player. On a channel it opens the chat channels window (Retail and WoW: Forever only). On a Battle.net player the game itself does nothing, so WowVision does nothing either.
- Space and Shift+Arrows read the tooltip of a selected link.

A link that has no tooltip (a Retail talent build, a calendar event) is handled by the game's own click instead of being read.

Example: whisper the player who wrote a message.

1. In the chat window, select the message with Up and Down.
2. Press Ctrl+Left or Ctrl+Right until you hear "Player" and the name.
3. Press Enter. The chat box opens with the whisper already addressed, and a sound plays.
4. Type your message and press Enter to send it. Press Escape if you change your mind.

Example: see what a linked item is.

1. Select the message. If it contains an item, "Item" is already selected; otherwise use Ctrl+Left and Ctrl+Right.
2. Press Enter or Space to hear the tooltip. Use Shift+Down and Shift+Up to go through it line by line.

Example: check a player's level and zone.

1. Select the player part of a message.
2. Press Shift+Enter. The game sends a who search. Its answer arrives as a system message in your chat (on Classic Era, TBC and Mists it may also open the Who list, see [Social](social.md#the-who-list)).

### The message's context menu

Press Shift+F10 on a message to open its context menu. It names what each click does for the selected part, followed by the click that does the same, so you do not need to remember the keys:

- On a player: Whisper (left click), Player Menu for the player (right click), Who (shift click, not for Battle.net players). Each entry names the player and ends with the click it stands for, for example "Whisper Xynayya, Left Click".
- On a channel: Write to the channel (left click), Channel Menu for the channel (right click), and Chat Channels Window (shift click, Retail and WoW: Forever only).
- On any other link: Read Tooltip of it (left click) and Link it in Chat (shift click), for example "Link Linen Cloth in Chat, Shift Click".
- Copy Line is always last.

### Copy Line

Choose Copy Line from the context menu to get the message out of the game, for example a web address or a long text. WowVision says "Copy now" and the message, without colors, link markup and icons, sits selected as plain text in a small edit box. Press Ctrl+C to copy it and Escape to close the box. The line is not read out again.

The player menu has a Copy Character Name row. When the menu was opened from the chat window, WowVision opens the same kind of copy box for the name, so this row works as well.

### Chat during lockdown (Retail and WoW: Forever)

On Retail and WoW: Forever the game hides chat text from all addons during boss encounters, in challenge modes, in PvP matches and on some maps (for example inside dungeons and raids). Chat is still spoken and still written to the history, but WowVision cannot look inside the lines then. That has these effects:

- Ctrl+Left, Ctrl+Right, Enter, Backspace, Shift+Enter and Copy Line answer "Links unavailable here" instead of acting.
- The context menu of the message offers only Copy Line, which also says "Links unavailable here".
- Loot, money, currency, achievement and experience messages are not affected, so their links work as usual.

Outside of lockdown everything works again, and the lockdown messages in the history may not become clickable afterwards.

Classic Era, TBC and Mists have no lockdown.

## Choosing what a tab receives

WowVision does not change what a tab receives. You do that in the game's chat settings window, which WowVision reads.

To open it, go to the tab strip of the chat window, press Backspace on the tab, and choose Settings from the menu. The chat settings window then opens with these parts:

1. Categories: a list of buttons, such as the chat settings, the channel settings and the other message groups. Enter opens one.
2. Chat settings, Channel settings and further groups of check boxes: each group is named by its heading and holds the check boxes of the messages (Say, Yell, Guild, Whisper, Loot, and so on). Enter turns a check box on or off.
3. Channels: the list of global channels (General, Trade and so on), where Enter joins or leaves a channel for this tab.

Which groups you see depends on the category you picked. Escape closes the window.

Example: a whisper-only tab.

1. In the chat window, open the tab strip and press Backspace on any tab. In the game's tab menu, choose the row that creates a new window and give it a name.
2. Open the menu again on the new tab and choose Settings.
3. In the categories pick the chat settings, and turn on only Whispers.
4. Close with Escape. The tab appears under its name in the WowVision Chat menu.

## Chat tab buffers

Every chat tab can also be read through a buffer, so you can check chat with the buffer keys from anywhere without opening the chat window. A Chat Tab Buffer holds the same lines the chat window shows for one tab.

To add one, open the WowVision menu, go to the buffers, add a buffer to a group and pick Chat Tab Buffer as its type. Then choose its Chat Tab: any open chat tab by name, or Whisper Tabs for the lines of all whisper tabs together. Unnamed, the buffer is called after the tab it shows.

A chat tab buffer starts on the newest line and follows new lines as they arrive. Once you move back into older lines it stays where you are until you come back to the end.

See [Buffers](../information/buffers.md) for how buffers, groups and their keys work.

## Sending messages

WowVision reads chat but does not replace the game's chat box. To send a message, press Enter while no WowVision window is open (or whichever key you use in the game), type your message and press Enter again. Typing a slash command such as /w Name works as usual. You can also start a message from the chat window by clicking a player or a channel (see above), which opens the chat box already addressed.

Two sounds tell you where your keys are going: one plays when the chat box takes the keyboard to type, and another when it lets go. This is important because while the chat box is open, every key you press is typed into it and not used by WowVision or the game.

## Settings summary

Everything for chat is in the WowVision menu under Chat.

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | Turns the whole Chat module off or on: no announcements and no history are kept while it is off. |
| One entry per open chat tab, named like the tab | see above | The tab's alert: Enabled, TTS Alert, Sound Alert and Speak Messages (When the Tab Is Shown by default). |
| Whisper Tabs | see above | The shared alert for all whisper tabs, same settings, but Speak Messages is Always by default. |
| Chat Box Opened | On | Sound when the chat box takes the keyboard. Has Enabled and a Sound Alert with Enabled and Sound. |
| Chat Box Closed | On | Sound when the chat box lets go of the keyboard. Same settings. |
| Addon Messages in Chat | Off | Also writes WowVision's messages to your main chat tab, with "WowVision:" in front: for example that a route has started, how far an auction house scan is, or why something does not work. What is read out, such as menus, your target or tooltips, does not appear there, and neither do alerts. These lines are not spoken again. They are in the tab's history like any other line. |

Both chat box sounds work on every chat window, in the classic chat style (where the box stays on screen while idle) as well as in the modern style. They are about the keyboard focus, not about the box being visible.

For how alerts, voices and sounds are configured in general, see [Alerts](../basics/alerts.md) and [Speech](../basics/speech.md).

## Keys at a glance

| Key | Default | Where | What it does |
|---|---|---|---|
| Shift+F3 | Bound | Anywhere | Open the chat window. Can be rebound as Chat. |
| Ctrl+Left | Bound | Message list | Previous Link in Message. |
| Ctrl+Right | Bound | Message list | Next Link in Message. |
| Shift+Enter | Bound | Message list | Shift Click on the selected part. |
| Up, Down, Home, End | Bound | Message list | Move between messages. |
| Left, Right | Bound | Message list | Switch to the previous or next tab. |
| Enter, Backspace, Space | Bound | Message list | Left click, right click, read tooltip. |

The three chat-specific keys (Previous Link in Message, Next Link in Message, Shift Click) and Chat can be changed in the keybinding window (see [Keybindings](../basics/keybindings.md)). They only hold their keys while the message list has the focus.

## Troubleshooting

- Every message is spoken twice. Turn off the game's own chat text to speech in the game's chat settings.
- A whisper tab says nothing. Open Chat in the WowVision menu, go to Whisper Tabs and set Speak Messages to Always.
- A tab you read is silent. Its Speak Messages is probably When the Tab Is Shown and the tab is not the selected one. Set it to Always.
- "Links unavailable here". The game is hiding chat text from addons (see [Chat during lockdown](#chat-during-lockdown-retail-and-wow-forever)).
- Chat window empty after reload. History is kept per tab; a tab you closed has lost its history.
