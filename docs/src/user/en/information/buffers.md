# Buffers

Buffers let you look up game information whenever you want, without waiting for an announcement. Your health, your mana, your gold, your experience, the buffs on your target and the lines of a chat tab are all kept in buffers that you walk through with a few keys. You can use the buffers that come with WowVision as they are, or build your own.

If you want WowVision to tell you automatically when something changes, for example when a debuff falls off your target, see [Monitors](monitors.md) instead. The two work well together.

## How buffers are organized

Buffers have three levels:

- A group holds buffers. Think of a group as a folder or a topic, such as "General" or "Combat".
- A buffer holds items. A buffer is the list you actually walk through.
- An item is one line of information: your health, your money, one aura.

Groups cannot contain other groups, so there is only one level of groups.

You always have one current group, one current buffer in that group, and one current item in that buffer. WowVision remembers where you were in every buffer for as long as the game session lasts, so when you come back to a buffer later it reads the item you left it on. After a reload or a new login every buffer starts again at its first item (a chat tab buffer at its newest line).

## Keys

| Action | Default key | What you hear |
|---|---|---|
| Next Buffer Item | Alt+Down | The next item of the current buffer |
| Previous Buffer Item | Alt+Up | The previous item of the current buffer |
| Next Buffer | Alt+Right | The next buffer of the current group: its name, then its current item |
| Previous Buffer | Alt+Left | The previous buffer of the current group |
| Next Buffer Group | Alt+Ctrl+Right | The next group: its name, the name of its current buffer, then that buffer's current item |
| Previous Buffer Group | Alt+Ctrl+Left | The previous group |

These keys work anywhere in the game. Each one interrupts whatever WowVision is saying, so you can press them quickly. You can change the keys in the keybinding window, see [Keybindings](../basics/keybindings.md).

### How the keys behave

- The first time you press Alt+Down in a buffer you land on its first item. After that each press moves one item toward the end of the list. If you switch to a buffer with Alt+Left or Alt+Right first, you already hear its first item together with its name, so the next Alt+Down moves on to the second.
- Items do not wrap around. At the last item, Alt+Down just reads that item again. At the first item, Alt+Up reads it again.
- Buffers and groups do wrap around. After the last buffer of a group, Alt+Right goes back to the first one.
- When an item has changed since you last heard it (your health, say), it is read afresh each time, so you always hear the current value.
- An empty buffer (a tracked buffer with nothing in it, for example) stays silent when you press Alt+Up or Alt+Down. Switching to it with Alt+Left or Alt+Right still tells you its name.

Example: you are in the default General buffer.

1. Press Alt+Down. You hear "250 / 500 Health".
2. Press Alt+Down again. You hear "50 / 100 MANA" (your main resource).
3. Press Alt+Up. You are back on health.

### Newest item last, and Invert Item Direction

Items are listed from first to newest, with the newest item last. This matters most for buffers that grow, such as a chat tab: Alt+Down moves toward the newest line and Alt+Up toward the oldest.

Earlier versions of WowVision did it the other way round (Alt+Up moved toward the newest item). If you are used to that, turn on the Invert Item Direction setting: it swaps Alt+Up and Alt+Down for buffers. It does not change anything else. You find it in the WowVision menu under Buffers, see [Settings](#settings).

### Controller

With a gamepad on Retail and WoW: Forever, hold the right stick press and use the D-pad: up and down move between items, left and right between buffers. Hold the left trigger as well (the controller's Shift) with left and right to move between groups. See [Controller](../controller.md).

## The default setup: the General group

Your account starts with one group called General. It holds one buffer, also called General, which is a static buffer with these lines in this order:

| Line | What it tells you | Example |
|---|---|---|
| Health (player) | Your current and maximum health | "250 / 500 Health" |
| Power (player) | Your main resource: mana, rage, energy and so on | "50 / 100 MANA" |
| XP | Experience as a percentage, the numbers, the next level, and your rested experience when you have some | "XP: 45% (12500 of 25000 to level 31), rested 3000" |
| Money | Your gold, silver and copper | "5 Gold 23 Silver 45 Copper" |
| Bags | Free slots in your normal bags (quivers, ammo pouches and profession bags are not counted) | "Free Bag Slots: 12" |
| Durability | The percentage of your most worn item, and how many items are broken | "Durability: lowest item 45%, 1 broken" |
| Mail | Whether unread mail is waiting, and who sent it when the game knows | "Mail from Thrall, Jaina", "New mail" or "Mail: none" |
| Hearthstone | Ready, or the time left on its cooldown, and where it takes you | "Hearthstone: ready, Goldshire" |
| Clock | The game clock, as you set it in the game's clock options (realm or local time, 12 or 24 hours) | "Time: 8:05 PM" |
| PVP (player) | Whether you are flagged for PvP | "PVP: Enabled" |

At the level cap the XP line leaves out the next level and the rested part. When you have no rested experience, the rested part is left out too.

The resource on the Power line is named the way the game names it internally, in capital letters: MANA, RAGE, ENERGY, FOCUS, RUNIC_POWER and so on. Slashes are always spoken with a space on each side ("250 / 500"), because some speech engines trip over a slash that touches the numbers.

If your character was created before the Bags, Durability, Mail, Hearthstone and Clock lines existed, WowVision adds them to your General buffer once, before the PvP line. If you remove one of them afterwards, it stays removed.

You can change or remove any of this, see [Managing buffers](#managing-buffers-in-the-menu).

## Buffer types

When you add a buffer to a group you choose one of four types.

### Static buffer

A static buffer holds a fixed list of items that you choose, in the order you add them. The General buffer is a static buffer. Use it for things you want to check in a fixed place: your health and mana, a cooldown, your money.

Settings of a static buffer: Enabled, Label, and Objects, the list of items (see [Items](#items-and-the-things-they-can-show)).

### Tracked buffer

A tracked buffer fills and empties itself. You describe what to watch (a type of information and, for unit information, which unit), and the buffer adds an item whenever a matching thing appears and removes it when it goes away. You do not manage the items yourself.

Typical uses: every aura on your target, or every spell of yours that is currently on cooldown.

Tracked buffers are not offered on Retail and WoW: Forever, because the game hides nearly everything they could track from addons there. Use an aura buffer for auras, the Spell Cooldowns monitor for cooldowns (see [Monitors](monitors.md)) and a static buffer for everything else. A tracked buffer you made earlier stays in your list.

Settings of a tracked buffer: Enabled, Label, and Source. The source has a Type (what to track) and, for most types, Parameters such as the unit. A newly added tracked buffer has no type yet ("None") and stays empty until you choose one.

Notes:

- Tracked buffers read each item with the type's standard wording. You cannot give their items a custom format.
- For auras, the dedicated aura buffer (below) is the better choice: it also works on Retail in combat and in instances.

### Aura buffer

An aura buffer lists the buffs and debuffs on one or more units, every one the game knows about, not just the ones drawn on screen. The auras follow one another in a single list with no headings in the way.

Settings:

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | The buffer's on/off switch (see [Turn something off for a while](#turn-something-off-for-a-while)) |
| Label | "New Aura Buffer" when added from the menu | The name you hear when you switch to the buffer. If you clear it, the buffer is named after its source (for example "Target Debuffs") or "Auras" when it has several |
| Sources | Player Debuffs, then Player Buffs | The list of sources, in the order they are listed in the buffer |
| Speak Time Remaining | On | Whether an aura says how much time it has left |
| Speak Description | On | Whether an aura says what it does |
| Cast by Me, Castable or Dispellable by Me, Cancelable, Crowd Control, Dispellable by My Group, Dispellable, External Defensive, Big Defensive, Shown on Raid Frames in Combat, Important | Any | One filter each, see below |

Each filter is a choice with up to three values. Any ignores the filter. Only keeps just the auras it describes. Not leaves those auras out. For example, Cast by Me set to Only lists only auras that you cast, and Crowd Control set to Not hides stuns, fears and the like. You can combine several filters; an aura must pass all of them. The filters also work on Retail in combat and in instances.

- Cast by Me: auras that you cast.
- Castable or Dispellable by Me: auras that you could cast or dispel.
- Cancelable: buffs that you can cancel.
- Crowd Control: stuns, fears, polymorphs and the like.
- Dispellable by My Group: auras that someone in your group can dispel.
- Dispellable: auras that can be dispelled.
- External Defensive: defensive effects that others put on you.
- Big Defensive: major defensive effects.
- Shown on Raid Frames in Combat: auras the game shows on raid frames in combat.
- Important: auras the game marks as important.

On Retail and WoW: Forever every filter offers Any, Only and Not. On Classic Era, The Burning Crusade and Mists of Pandaria only Cancelable offers Not; the others offer Any and Only. A game version only offers the filters it knows, so on some versions the list is shorter. The old setting Only My Auras is now Cast by Me; a buffer that had Only My Auras on keeps listing only your own auras until you set Cast by Me.

The available sources are Player Debuffs, Player Buffs, Target Debuffs, Target Buffs, Focus Debuffs, Focus Buffs, Pet Debuffs and Pet Buffs. You can mix them freely, and the order of the Sources list is the order you hear them in.

What you hear for one aura: its name; its stack count when it has stacks; the time remaining when it has a duration; for debuffs, its dispel type (Magic, Curse, Poison, Disease); and last its description, what the aura does. For example: "Moonfire, 12 seconds remaining, Magic, Burns the enemy for 4 Arcane damage every 3 seconds", or with stacks "Rejuvenation, 2 stacks, 9 seconds remaining, Heals 50 damage over 15 seconds". The description comes last, so you can stop the speech with Ctrl once you have heard enough. Speak Time Remaining and Speak Description leave those parts out. The tooltip keys still read them.

When a source has nothing to list, the buffer says so instead of staying silent: "Target Debuffs, none", "Target Debuffs, no target", "Focus Buffs, no focus", "Pet Buffs, no pet", or "unavailable" when the game will not tell. An aura that vanishes while you are on it reads "Gone".

While you are on an aura, the tooltip keys read it line by line: Shift+Down and Shift+Up move through its name, its description and the time left, and Shift+Left and Shift+Right read the left or right part of the current line. This also works in combat, and the time left is current each time you press a key. See [Reading Tooltips](../basics/tooltips.md).

The list updates by itself when auras come and go or when the unit changes (you target something else), and it keeps your position.

On Retail, in combat and in instances, the game closes its aura list to addons. The aura buffer then reads each aura from the game's own tooltip: you still hear the name, for debuffs the dispel type, and then the rest of the tooltip in the game's order: the description, then the time remaining. The two can't be told apart there, so with Speak Description off you hear the tooltip's last line while Speak Time Remaining is on, and with Speak Description on you can still hear the time remaining. The stack count is only read for your own auras, in a buffer with no filters set, and only for auras the game shows on its own buff and debuff bars.

### Chat tab buffer

A chat tab buffer holds the lines of one of your chat tabs, the same lines the chat window shows, so you can read them with the buffer keys without opening anything. See [Chat](../windows/chat.md) for the chat features themselves.

Settings: Enabled, Label, and Chat Tab, a choice among the chat tabs that are open right now (by their names, as set in the game) plus Whisper Tabs, which gathers the lines of all your whisper tabs together. A new chat tab buffer starts on your first chat tab. Which messages a tab receives is decided by the game's own chat settings for that tab.

Each line is read as the message followed by its date and time. The buffer keeps up to 5000 lines. It opens on the newest line and follows new lines as they arrive, like a chat log. Once you move back into older lines with Alt+Up (or Alt+Down with Invert Item Direction on) it stays where you are until you return to the newest line.

If you clear the Label, the buffer is named after its tab.

## Items and the things they can show

An item in a static buffer shows one "thing", which WowVision calls an object type. When you add an item you pick the type from a list. Some types need a little more information, called parameters.

| Type | What it shows | Parameters | Example |
|---|---|---|---|
| Health | Current and maximum health of a unit | Unit | "250 / 500 Health" |
| Power | One resource of a unit | Unit, Power Type | "50 / 100 energy" |
| PVP | Whether a unit is flagged for PvP | Unit | "PVP: Enabled" |
| XP | Your experience, next level and rested experience | None | "XP: 45% (12500 of 25000 to level 31)" |
| Money | Your money | None | "5 Gold 23 Silver 45 Copper" |
| Bags | Free slots in normal bags | None | "Free Bag Slots: 12" |
| Durability | Most worn item and number of broken items | None | "Durability: lowest item 87%" or "Durability: 100%" |
| Mail | Unread mail and the first senders | None | "Mail from Thrall, Jaina" or "Mail: none" |
| Hearthstone | Cooldown and bind location | None | "Hearthstone: 20 minutes 5 seconds, Goldshire" |
| Clock | The game clock | None | "Time: 8:05 PM" |
| Cooldown | The cooldown of one spell | Spell ID, On Cooldown | "Barkskin: Ready" or "Barkskin: 12.3s" |
| Aura | One aura on a unit | Unit | "Rejuvenation stacks 0 12 seconds" |

The list you pick from shows these names. Types without parameters never ask for anything more. The names of the type, the unit and so on also form the item's name in the item list, for example "Power (player, mana)".

The wording of an aura item is fixed: its name, the word "stacks" and the stack count (0 for an aura that does not stack), then the time left when it has one.

### Parameters

- Unit: any unit the game knows by name, typed as text. The common ones are `player`, `target`, `focus`, `pet`, `mouseover`, `targettarget`, `party1` to `party4` and `raid1` and up.
- Power Type: which resource to read, for example mana, rage, energy, focus, runic power, combo points, soul shards, holy power, chi, insanity, maelstrom, fury, pain, essence, runes. The list holds every power type your game version knows, starting with mana, so choose one that your class actually uses. When you change the Type of an item or a tracked buffer to Power, Power Type starts on mana; open Parameters if you want another one. A tracked Power buffer lists every resource the unit has, and picks up a resource that appears later, such as combo points once you start building them.
- Spell ID (Cooldown): the spell to watch. You can type its name or its number, or pick it from the list of spells this character has cast (or met as auras). See [Picking a spell](monitors.md#picking-a-spell) on the Monitors page.
- On Cooldown (Cooldown): a yes/no filter used by tracked buffers. On means "only spells that are currently on cooldown". Off, once you have switched it on and back off, means "only spells that are ready". Left untouched there is no filter.

### Things to know about each type

- Aura items are meant for tracked buffers. A static buffer needs an item that points at exactly one thing, and an aura is only identified by an internal number that changes each time it is applied, so the menu will not let you save an Aura parameter set in a static buffer. Use a tracked buffer or an aura buffer.
- Power in a static buffer needs a Power Type; without one the menu refuses to save it ("Parameters must identify a single object"). The Power line in the default General buffer is the exception: it has no power type and simply reads your main resource, whatever it is.
- Cooldown needs a Spell ID in a static buffer. In a tracked buffer, you can leave the spell out and set only On Cooldown: the buffer then collects the spells you cast that have a real cooldown (the global cooldown never counts) and shows only those on cooldown. Spells appear after you have cast them once in this session. A tracked Cooldown buffer needs at least a Spell ID or On Cooldown to be saved, otherwise you hear "Invalid parameters".
- Cooldown items work through the game's normal cooldown functions. On Retail the game hides cooldown numbers from addons in combat and in instances, so use the Spell Cooldowns monitor and its Speak Tracked Cooldowns key there, see [Monitors](monitors.md).
- Health and Power of other units can be unreadable on Retail in combat; WowVision speaks what the game allows.
- Hearthstone shares one cooldown for all hearthstones, so it reports the right time whichever hearthstone you carry. When the game hides the cooldown, you only hear the bind location.
- With no target, a Health item for `target` has nothing real to read. Where you have tracked buffers, one is the cleaner choice for the target, since it is simply empty when you have no target.

### Custom formats

Every item in a static buffer has a Template setting that controls the wording. By default it reads Default, which is the type's standard wording (the examples above).

For types that have a registered wording (Health, Power, PVP, Clock, Bags, Cooldown) the list offers Default and Custom. For the others (XP, Money, Durability, Mail, Hearthstone) only Custom is offered. Choosing Custom opens a text field named Format. Type your own wording and press Enter. Leaving it empty and confirming puts the item back to its standard wording.

One difference: for a Cooldown item, the standard wording (when the Template has never been set) reads "Barkskin: Ready" or "Barkskin: 12.3s", while picking Default in the list gives "Barkskin: 12 seconds" (and "Barkskin: 0 seconds" when ready).

A format is plain text with two kinds of placeholders:

- `{name}` is replaced by a value. For example `{current}` is the current health.
- `[word]` is replaced by that word in your language, for words WowVision knows, such as `[Health]`, `[of]`, `[ready]`. If WowVision does not know the word, the text in brackets is spoken as typed.
- To write a literal brace or bracket, double it: `{{`, `}}`, `[[`, `]]`.
- A slash in your own text is spoken with a space on each side, as in the standard wordings.

Example: for a Health item, the format `{current} of {maximum}` reads "250 of 500". Another: `[Health] {current}` reads "Health 250".

Use only text and number values in a format. Yes/no values (such as ready or unread) cannot be put into a format; they are left out of the list below, and using one would make that line fail with an error instead of speaking.

The values you can use, by type:

| Type | Values |
|---|---|
| Health | `current`, `maximum`, `minimum` |
| Power | `current`, `maximum`, `minimum`, `label` (the power's name) |
| PVP | `status` ("Enabled" or "Disabled") |
| XP | `current`, `maximum`, `percent`, `nextLevel`, `rested` |
| Money | `current` (in copper), `formatted` (gold, silver and copper in words) |
| Bags | `free` |
| Durability | `lowest` (percent of the most worn item), `broken` (number of broken items) |
| Mail | `senders` (up to three names) |
| Hearthstone | `remaining` (time left, empty when ready), `location` |
| Clock | `time` |
| Cooldown | `name`, `remaining` (time left in words), `charges`, `maxCharges`, `duration`, `startTime`, `spellId` |

A value that has nothing to say, such as `rested` when you have no rested experience, simply adds nothing. Time values are spoken in words ("1 minute 5 seconds").

Example: to make the Money line say "I have 5 Gold 23 Silver 45 Copper", set its template to Custom with the format `I have {formatted}`.

## Managing buffers in the menu

All buffer setup happens in the WowVision menu. The menu is the same keyboard-driven list used everywhere else in WowVision, see [The WowVision menu and settings](../basics/menu-and-settings.md) and [Using WowVision windows](../basics/interface.md).

### Opening the buffer settings

1. Press Shift+F1 (or type `/wv`) to open the WowVision menu.
2. Move to Buffers and press Enter. The screen shows an Enabled toggle, a button named Buffers followed by the number of groups, for example "Buffers (1)", and the Invert Item Direction setting, in that order.
3. Press Enter on Buffers (1). You see your groups, one button each, followed by an Add button.

Pressing Escape goes back one screen.

### The levels of the menu

- On the groups list, Enter on a group opens that group. It has Enabled, Label, a Buffers button with the number of buffers in the group, and Remove.
- Enter on the Buffers button shows the group's buffers and an Add button. Enter on a buffer opens it. A buffer has Enabled, Label, its type-specific settings, and Remove.
- For a static buffer the type-specific setting is the Objects button (with the item count), which lists the items and an Add button. Enter on an item opens it: Object, Template, and Remove.

### Add a group

1. In the groups list, go to Add and press Enter.
2. The Select Type screen has one entry, Buffer Group. Press Enter.
3. The new group opens, named "New Buffer Group". Change Label to a name you like (press Enter on it, type, Enter again).

### Add a buffer to a group

1. Open the group, press Enter on Buffers, then on Add.
2. Choose the type: Static Buffer, Tracked Buffer (not on Retail and WoW: Forever), Aura Buffer or Chat Tab Buffer.
3. The new buffer opens, named "New Static Buffer" (and so on). Set Label to a name that tells you what it is. This is the name you hear when you switch to it.
4. Fill in the type-specific settings (the Objects list, the Source, the Sources, or the Chat Tab).

### Add an item to a static buffer

1. Open the buffer, go to Objects, and press Enter.
2. Press Enter on Add. The Select Type list shows the object types (Aura, Health, Power, PVP, XP, Money, Bags, Durability, Mail, Hearthstone, Clock, Cooldown).
3. Pick one. The new item opens.
4. If the type has parameters, press Enter on Object. The screen has a Type choice (you can still change the type here) and, for types with parameters, a Parameters button. Press Enter on Parameters, fill in Unit, Power Type or Spell ID, then go to Save and press Enter. WowVision checks the parameters and tells you "Invalid parameters" or "Parameters must identify a single object" if something is missing.

Always set the unit explicitly for Health, Power and PVP items, even when you want `player`: an item you have just added has no unit yet. The Unit box shows "player", but Save only knows what you typed into it, so saving with the box untouched says "Invalid parameters". (Changing the Type of an item or of a tracked buffer to a unit type does fill in `player` for you.)

Items are added at the end of the list.

### Change or rename something

Open the group, buffer or item and change its settings. Changes apply immediately; there is no Save button except in the parameters screen. To rename a group or buffer, change its Label. Items have no label of their own; their name comes from their type and parameters.

### Remove something

Open the group, buffer or item and press Enter on Remove. There is no confirmation and no undo. Removing a group removes all its buffers; removing a buffer removes all its items. If you remove the default General group by mistake, you have to build it again by hand.

### Put things in a different order

The menu has no move up or move down. Groups, buffers and items appear in the order they were added. To change the order, remove the things after the one you want to move and add them again in the order you like.

### Turn something off for a while

Groups and buffers have an Enabled toggle. A group or buffer that is switched off keeps its settings, but Alt+Left, Alt+Right, Alt+Ctrl+Left and Alt+Ctrl+Right skip over it. Switch it on again and it is back in its place. If every other buffer in a group is off, Alt+Left and Alt+Right stay where you are. The Enabled toggle on the Buffers screen itself does switch the whole buffer feature off.

### Account-wide or per character

WowVision stores settings in two places: once for your whole account ("Global") and once for each character.

- Groups are stored account-wide by default, so every character sees them and a change on one character is there on all of them. That includes the default General group.
- When a character first logs in after buffers became account-wide, its groups join the account's. A group joins the account's group of the same name, which takes only the buffers it does not have yet, so a changed buffer sits beside the account's. Any other group moves as it is.
- To change where a group lives, go to the groups list, move to the group, and press Shift+F10 (the context menu). Choose Scope, then Global (all characters) or your character's name (this character only). The buffers and items inside a group travel with it and have no scope choice of their own.
- To change everything at once, open the WowVision menu, move to Buffers, press Shift+F10, choose Scope, and pick Global or your character.
- The Invert Item Direction setting can also be given a scope with Shift+F10 on it. It is account-wide by default.

Nothing is deleted when you switch a scope: choosing your character copies the current setup to this character, and choosing Global adopts the account version.

## Examples

### Hear your target's health

The simplest way is a tracked buffer, because it is empty when you have no target and refills on every new target. On Retail and WoW: Forever, use the static buffer at the end of this example.

1. Open the WowVision menu with Shift+F1 and go to Buffers, then Buffers (1), then General, then Buffers.
2. Press Add, choose Tracked Buffer.
3. Set Label to "Target Health".
4. Press Enter on Source. Set Type to Health.
5. Press Enter on Parameters. Set Unit to `target`, then Save.
6. Close the menu. Target something, then press Alt+Right until you hear "Target Health", followed by the health of your target, for example "Target Health 8200 / 12000 Health". Press Alt+Down to read it again.

If you prefer a static buffer: add a Static Buffer, open Objects, Add, Health, then set the item's Parameters with Unit `target`. With no target it has nothing to read, see above.

### Hear the debuffs on your target

1. In the group's Buffers list press Add and choose Aura Buffer.
2. Set Label to "Target Debuffs".
3. Press Enter on Sources (2). You see two rows, "Player Debuffs" and "Player Buffs", each with a choice and a Remove button, and an Add button at the end. Change the first row to Target Debuffs and press Remove on the second row, so that only one source is left. (Add appends a new row that starts as "Player Debuffs"; change it to any source you like.)
4. Set Cast by Me to Only if you only care about your own debuffs.
5. In the game, target an enemy and press Alt+Right until you hear "Target Debuffs". Then press Alt+Down to walk through the debuffs: "Moonfire, 12 seconds remaining, Magic, Burns the enemy for 4 Arcane damage every 3 seconds".

### Watch a power other than your main one

1. Add a Static Buffer named "Resources".
2. Objects, Add, Power.
3. Open the item, Object, Parameters. Set Unit to `player` and Power Type to the one you want, for example combo points. Save.
4. In the game, Alt+Right to "Resources", then Alt+Down: "3 / 5 combo points".

### See every spell currently on cooldown

On Retail and WoW: Forever, use the Spell Cooldowns monitor and its Speak Tracked Cooldowns key instead, see [Monitors](monitors.md).

1. Add a Tracked Buffer named "Cooldowns".
2. Open Source, set Type to Cooldown, open Parameters, switch On Cooldown on, and Save.
3. Cast some spells. Whenever one is on cooldown it shows up in the buffer. Walk through them with Alt+Down: "Barkskin: 12.3s".

### Read chat without opening it

1. Add a Chat Tab Buffer. Set Label to "Whispers".
2. Set Chat Tab to Whisper Tabs.
3. Press Alt+Right to switch to it: you hear the name and the newest whisper. Alt+Up moves back into older lines.

## Settings

The Buffers screen of the WowVision menu has:

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | Turns the buffer feature on or off (the Alt keys stop working while it is off) |
| Buffers | one group | The list of groups |
| Invert Item Direction | Off | Swaps Alt+Up and Alt+Down so that Alt+Up moves toward the newest item |

Settings of the things you add (group, buffer, item) are described in the sections above. There are no alerts for buffers; nothing is spoken until you press a key.

## Availability

| Feature | Classic Era | The Burning Crusade | Mists of Pandaria | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Groups, Static and Chat Tab buffers | Yes | Yes | Yes | Yes | Yes |
| Tracked buffer | Yes | Yes | Yes | No | No |
| Aura buffer | Yes | Yes | Yes | Yes | Yes |
| Aura buffer filters with Any and Only | Yes | Yes | Yes | Yes | Yes |
| Aura buffer filters with Not | Cancelable only | Cancelable only | Cancelable only | All filters | All filters |
| Reading an aura's tooltip with the tooltip keys | Yes | Yes | Yes | Yes | Yes |
| Every object type listed above | Yes | Yes | Yes | Yes | Yes |
| Choosing a Power Type | Yes | Yes | Yes | Yes | Yes |

See [Versions](../reference/versions.md) for the full feature matrix.

## Tips

- Keep the General buffer short and put your own things in buffers of their own. Switching buffers with Alt+Left and Alt+Right is quicker than walking a long list.
- Name buffers by what you will say to yourself: "Target Debuffs", "Cooldowns", "Whispers". The name is the first thing you hear.
- Use an aura buffer for buffs and debuffs, a static buffer for fixed facts, and, where you have one, a tracked buffer for "whatever matches right now".
- If Alt+Up and Alt+Down feel backwards, you are probably used to the older behaviour: turn on Invert Item Direction.
- Buffers show information on demand. To be told when something happens, set up a [monitor](monitors.md).
- If the keys do nothing, see [Troubleshooting](../getting-started/troubleshooting.md).
