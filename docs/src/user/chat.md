# Chat

WowVision gives you access to your chat history and announces incoming messages automatically.

## Incoming Messages

By default, WowVision speaks new chat messages as they arrive and plays a notification sound. You can configure or disable these alerts from the WowVision menu (`/wv`).

## Chat Tabs

WowVision follows the chat tabs you have in the game. Which messages and channels a tab receives is set in the game's own chat settings (right click a tab, or Backspace on it in the chat window, then Settings), exactly as for a sighted player. WowVision only decides how each tab is spoken.

In the Chat module of `/wv`, every open tab has its own message alert, named like the tab. Each alert has a speech and a sound output, and a **Speak Messages** choice:

- **When the Tab Is Shown** (the default): the tab speaks while it is the selected tab, or a window of its own on screen.
- **Always**: the tab speaks everything it receives, selected or not.

For example, make a tab in the game that receives only whispers, set its alert to Always, and give it a sound of its own: whispers then reach you whatever tab you are reading.

A message that reaches several speaking tabs is spoken once.

### Whisper Tabs

When the game's whisper mode opens a new tab per conversation (Interface options, "New Whispers": in a new tab, or both), WowVision picks those tabs up, Battle.net whispers included, as soon as they open: the first whisper is not lost. All whisper tabs share one alert, **Whisper Tabs**, which speaks always by default, because in that mode a whisper is not shown in any other tab.

Whisper tabs close when you close them or log out. Their lines are kept in one list, Whisper Tabs, which you can add to a buffer group (see Buffers).

The game's own text to speech (chat settings, Text to Speech) speaks chat on its own; leave it off, or messages are spoken twice.

## The Chat Window

Press **Shift+F3** to open the chat window. The window has two sections: your message history and your chat tabs.
Use **Up** and **Down** to scroll through messages in the current tab. Each message is announced with its text and timestamp. **Home** and **End** jump to the oldest or most recent message.

**Left** and **Right** switch to the previous or next chat tab, in the order the game shows them, and read the tab's name and its newest message. At the first or last tab nothing happens.

**Tab** moves to the row of chat tabs, where the arrow keys move between tabs and **Enter** selects one. **Backspace** on a tab opens the game's tab menu (settings, rename, new window, close). Each tab corresponds to one of your WoW chat frames, so whatever tab setup you have in-game carries over.

## Clicking Parts of a Message

A sighted player can click pieces of a chat line: the sender's name, the channel name, and any linked item, quest, or spell. WowVision gives you the same clicks.

Within a message, **Ctrl+Left** and **Ctrl+Right** move between its clickable parts, in the order they appear in the line. Each is announced, for example "Player Xynayya" or "Item Linen Cloth". When you arrive on a message, the first linked item is selected if there is one; otherwise the sender is.

On the selected part:

- **Enter** is a left click. On a player it starts a whisper, on a channel it starts a message to that channel, and on an item, quest, or spell it reads the tooltip.
- **Backspace** is a right click. On a player or channel this opens the game's own menu (whisper, invite, add friend, ignore, and so on), which WowVision reads like any other dropdown.
- **Shift+Enter** is a shift click. On a link it puts the link into your chat box, opening it if needed. On a player it puts the name into an open chat box, or runs a who query if none is open.
- **Space** and the **Shift+Arrow** tooltip keys read the tooltip of a selected link line by line.

**Shift+F10** opens the context menu, which lists these clicks and adds **Copy Line**: WowVision says "Copy now" and the message sits selected as plain text in an edit box, where Ctrl+C copies it and Escape closes the box. Use this for web addresses or anything else you want outside the game.

On Retail and WoW: Forever, the game hides chat text from addons during boss encounters and in some instances. Messages are still spoken, but their parts cannot be clicked there, and WowVision says "Links unavailable here". Loot messages are not affected.

## Sending Messages

WowVision reads chat but doesn't replace WoW's chat input. To send a message, use WoW's normal chat system — press Enter (when no WowVision window is open), type your message, and send it as usual.

A sound plays when the game's chat box opens for typing and another when it closes, so you always know whether your keys go to the chat box or to the game. Both sounds can be changed or turned off in the Chat module's settings ("Chat Box Opened" and "Chat Box Closed").
