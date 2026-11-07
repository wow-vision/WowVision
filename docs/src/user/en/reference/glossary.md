# Glossary and FAQ

## Glossary

Account-wide setting — A setting shared by all your characters on the account. Most WowVision settings are account-wide unless you switch them to per character. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

Alert — An automatic announcement of something that happened, such as a target change, a zone change or a chat message. An alert has one or more outputs. See [Alerts](../basics/alerts.md).

Alt Gr — The right Alt key on many European keyboards. WowVision uses it to speak the distance to the next waypoint. Windows reports it as Ctrl and Alt held together, so Ctrl+Alt does the same.

Arrival distance — How close you must come to a waypoint before it counts as reached and the route moves on. Changed with Alt+P. See [Navigation and Routes](../world/navigation.md).

Beacon — A sound placed in the game world at a waypoint or destination. You hear where it is from its direction and pitch and walk towards it. See [Navigation and Routes](../world/navigation.md).

Binding — An action that can be put on a key, such as Next Buffer Item. A binding can have several keys and, on Retail and WoW: Forever, controller buttons. See [Keybindings](../basics/keybindings.md).

Buffer — A list of information you can read at any time with Alt and the arrow keys, for example your health, gold or the auras on your target. Buffers are organized into buffer groups. See [Buffers](../information/buffers.md).

Classic routes — The route system of The Burning Crusade and Classic Era, which WoW: Forever can use in place of WowNav. See [Navigation and Routes](../world/navigation.md#classic-routes).

Context menu — A list of extra actions for the element you are on, opened with Shift+F10.

Cooldown manager — A Blizzard window on Retail and WoW: Forever (`/cdm`) that tracks chosen spells and auras. WowVision's Cooldown Manager Auras monitor reads it. See [Monitors](../information/monitors.md).

Cursor — What a sighted player sees attached to the mouse pointer after picking something up: an item from your bags, a spell from an action bar. Placing it somewhere is a left click on the target slot. See [Using the Interface](../basics/interface.md).

Element — One thing in a window you can land on: a button, a check box, a list entry, an item slot, a text field.

Focus target (virtual focus) — One of five targets WowVision stores by name (/focus1 to /focus5) that you can target again with a key. Independent of the game's own focus. See [Targeting](../world/targeting.md).

Group Health Monitor — A monitor for Retail and WoW: Forever that speaks the number of each hurt group member, with a higher pitch the lower their health. See [Group Health Monitor](../information/group-health.md).

Hard target — Your normal target, chosen by clicking, Tab-targeting or a macro. Opposed to the soft target.

Map data — The network of waypoints routes follow. WowVision ships map data for The Burning Crusade and WoW: Forever. See [Navigation and Routes](../world/navigation.md).

Module — One part of WowVision with its own entry in the WowVision menu, for example Buffers, Chat or Targeting. Every module can be switched off.

Monitor — Something that watches the game for you and fires alerts when a state changes, for example a debuff falling off your target. Made of rules. See [Monitors](../information/monitors.md).

Output — How an alert is delivered: TTS Alert (spoken by text to speech), Sound Alert (a sound file), Voice Alert (a recording from a voice pack). See [Alerts](../basics/alerts.md).

Pandemic window — The last part of a damage-over-time effect's duration in which refreshing it does not lose any time. Monitors can alert when an aura enters this window.

Pitch lock — Keeps your character level while swimming or flying, so turning does not make you slowly dive. See [Movement and Orientation](../world/movement.md).

Rule — One part of a monitor: which spell or aura to watch, and which alerts to fire in each state. See [Monitors](../information/monitors.md).

Scanner — WowVision's list of things around you (quest givers, quests, objectives, your corpse and more), opened with F9. See [Scanner](../world/scanner.md).

Scope — Whether a setting is stored per character or account-wide. Changed through the context menu (Shift+F10) in the WowVision menu. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

Soft target — A unit the game picks for you without a real target: the enemy, friend or interactive object in front of you. Switched on and off with Shift+I, Shift+P and Shift+O. See [Targeting](../world/targeting.md).

Sku — The older accessibility addon for blind WoW players. WowVision can run beside it. See [Using WowVision together with Sku](../getting-started/sku.md).

Tab stop — A section of a window that Tab and Shift+Tab jump to, such as a list, a row of buttons or a search box. Inside a tab stop you move with the arrow keys. See [Using the Interface](../basics/interface.md).

TTS — Text to speech: the synthetic voice that reads WowVision's announcements. WowVision uses the game's text to speech, which uses the voices installed in Windows.

Unbound — A binding that exists but has no key until you give it one in the keybinding window. See [Keybinding Reference](keybindings.md).

Voice pack — A set of recorded words and numbers WowVision can play instead of text to speech, for example for compass directions or the enemy count. See [Speech and Sound](../basics/speech.md).

Waypoint — A point on a route. WowVision leads you from one waypoint to the next. See [Navigation and Routes](../world/navigation.md).

Window keys — The keys WowVision uses while one of its windows is open: arrows, Tab, Enter, Backspace, Space, Escape, Home, End and so on. They go back to the game when no window is open and during combat.

WowNav — The route planner for WoW: Forever, with its own map data, boats, zeppelins, trams and portals. See [WowNav](../world/wownav.md).

## Frequently asked questions

### Do I need a screen reader like NVDA or JAWS?

No. WowVision speaks through the game's own text to speech. Some players route that speech through NVDA with a SAPI bridge voice; see [Speech and Sound](../basics/speech.md) and [Troubleshooting](../getting-started/troubleshooting.md).

### How do I get through the login and character selection screens?

No addon can read them: the game only loads addons once a character enters the world. Use the Sku login tool, or ask sighted help the first time. See [Logging In with the Sku Login Tool](../getting-started/sku-login.md).

### My arrow keys move me in the game but not in WowVision windows, or the other way round.

WowVision only takes the arrow keys while one of its windows is open, and gives them back in combat. If a window is stuck open, type `/wv close`. See [Troubleshooting](../getting-started/troubleshooting.md#my-keys-do-nothing).

### Can I use WowVision and Sku together?

Yes. WowVision then leaves a number of windows and keys to Sku. See [Using WowVision together with Sku](../getting-started/sku.md).

### Are my settings saved per character?

Most settings are shared by all characters on the account. You can switch any module, buffer or monitor to per-character storage through its context menu. See [The WowVision Menu and Settings](../basics/menu-and-settings.md).

### How do I hear my own health and mana?

Press Alt+Down with no window open: the first two lines of the General buffer are your health and your main resource. WowVision does not announce them by itself. See [Your own health and resources](../world/combat.md#your-own-health-and-resources).

### How do I make WowVision talk faster?

Open the WowVision menu (Shift+F1), go to Speech and raise Speech Rate, or type `/wv speech` followed by voice, rate and volume. See [Speech and Sound](../basics/speech.md).

### I hear chat messages twice.

The game's own text to speech for chat is switched on as well. Turn it off in the game's chat settings (Text to Speech). See [Chat](../windows/chat.md).

### Something is announced that I do not want to hear.

Almost every announcement is an alert you can turn off or change to a sound. Find it in the module's entry in the WowVision menu. Game error messages can be muted one by one in Errors, Per-Error Filter. See [Alerts](../basics/alerts.md) and [Combat](../world/combat.md).

### I am stuck on a route. What can I do?

Jump, step aside, skip the waypoint with Ctrl+W, go back one with Ctrl+S, or change the arrival distance with Alt+P. If the NPC you are looking for stands behind a counter, talk to them directly. See [Troubleshooting](../getting-started/troubleshooting.md#i-am-stuck-on-a-route).

### Where can I see every key?

In the [Keybinding Reference](../reference/keybindings.md), and in the game in the keybinding window: WowVision menu, UI, Bindings.

### How do I report a bug?

See [Troubleshooting](../getting-started/troubleshooting.md#reporting-a-bug).
