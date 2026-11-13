# Monitors

Monitors watch the game for you and speak or play a sound when something changes: a debuff you applied is about to run out, a cooldown is ready again, a proc lights up. While [Buffers](buffers.md) answer the question when you ask it, monitors tell you without being asked.

Which monitors you have depends on your game version. Classic Era, The Burning Crusade and Mists of Pandaria have an Aura monitor and a Cooldown monitor. Retail and WoW: Forever have Cooldown Manager Auras and Spell Cooldowns, because the game hides aura and cooldown numbers from addons there during combat. Cooldown Manager Auras reads Blizzard's cooldown manager. Spell Cooldowns uses the few facts the game still gives out, and only borrows the cooldown manager for its list of spells to pick from.

## How monitors work

A monitor has one or more rules. A rule watches one thing, usually one spell, and moves through states such as Applied, Pandemic, Expiring and Missing. Every state has its own alert, and every alert has two outputs: a sound and a spoken message. You decide which states should make noise and how.

In short:

- The monitor says what kind of thing to watch and on which unit (for example auras on your target).
- Each rule inside it names a spell.
- Each state of a rule has an alert with a Sound Alert and a TTS Alert output.

Nothing is spoken until you turn an output on. All outputs are off when you create a rule.

### What triggers an alert

A rule speaks when its state changes, not continuously. The first state a rule sees after it starts is established silently, so logging in while Moonfire is already running does not produce an announcement. After that, each change to another state fires the outputs of the new state.

What happens when you change the setup differs by monitor type:

- Aura and Cooldown monitors (Classic Era, TBC, Mists) start over whenever you change what they track: a rule's Spell (or Applied by Player), the monitor's Unit, or when you add or remove a rule. Starting over resets every rule of that monitor, and each rule then announces the state it finds once, if the output for that state is on. For example, after you add a second rule, the first rule can announce "Moonfire Applied" or "Moonfire Missing" again.
- Spell Cooldowns (Retail, WoW: Forever) starts over silently: after a change, every rule just takes in the current state without speaking.
- Cooldown Manager Auras (Retail, WoW: Forever) does not start over. A rule you change speaks only if the state it now finds differs from the state it had before.

Turning an output on while its rule is already in that state also makes it speak (or play) at once, as soon as the rule next checks. Don't be surprised when you switch on the Applied sound while Moonfire is up and hear it straight away.

### Fallback between states

Some states are "worse versions" of another one. For auras, Pandemic falls back to Applied, and Expiring falls back to Pandemic. The rule is: if a state has no output of its own turned on, the output of the state it falls back to is used instead, and an output that does not change from one state to the next is not repeated.

Practical consequences:

- If you only turn on a sound for Applied, you hear it once when the aura appears. You do not hear it again when the aura enters its pandemic window or starts expiring.
- If you turn on a different sound for Expiring, you hear Applied's sound when the aura goes on and Expiring's sound when it is about to fall off.
- Missing has no fallback: it only fires when its own output is on.

Cooldown states (Ready, Charging, On Cooldown) have no fallbacks; each plays only its own outputs.

## Setting up a monitor

1. Press Shift+F1 (or type `/wv`) to open the WowVision menu, move to Monitors and press Enter.
2. The screen shows Enabled, and a button named Monitors with the number of monitors, for example "Monitors (0)". Press Enter on it.
3. Press Enter on Add. The Select Type screen lists the monitor types for your game version. Choose one.
4. The new monitor opens, named "New" plus its type, for example "New Aura" (or "New Spell Cooldowns"). Set Label to something meaningful like "Target DoTs".
5. Set the monitor's own settings (the unit, and so on). They come after the Rules button in the monitor's screen.
6. Press Enter on the Rules button ("Rules (0)"), then Add, and choose the rule type.
7. The new rule opens. Set the Spell, then the thresholds if the rule has any.
8. Open the state you care about (Applied, Missing, Ready, and so on), then open Sound Alert or TTS Alert and turn it on. See [Alerts](#state-alerts-and-their-outputs) below.

Escape goes back one screen. To remove a monitor or a rule, open it and press Enter on Remove at the bottom. There is no confirmation.

The menu is described in [The WowVision menu and settings](../basics/menu-and-settings.md). The general idea of alerts is in [Alerts](../basics/alerts.md).

### Account-wide or per character

Monitors you add are stored account-wide by default, so all your characters share them. That is not always what you want: a Druid's Moonfire monitor means nothing on a Warrior.

- To keep a monitor on one character, go to the monitors list, move to the monitor, press Shift+F10 (the context menu), choose Scope, and then your character's name. Choose Global to share it again.
- To switch every monitor at once, open the WowVision menu, move to Monitors, press Shift+F10, choose Scope, and pick Global or your character's name.

Nothing is deleted when you change scope.

### Copying a monitor or a rule

To build a second monitor like one you already have, move to it in the monitors list, press Shift+F10 and choose Copy. You hear the new name, for example "Moonfire Copy 1"; the copy sits right after the original, with the same settings, alerts and rules, in the same scope. Rename it and change what differs. Copy works the same on a rule inside a monitor.

### Settings that every monitor and rule has

| Setting | Default | What it does |
|---|---|---|
| Enabled (monitor) | On | A disabled monitor does nothing |
| Label (monitor) | "New ..." plus the type | The name shown in the monitor list. If you clear it, the list shows the type, for example "Aura Monitor (target)" |
| Rules | none | The list of rules (the menu shows the count) |
| Enabled (rule) | On | A disabled rule is ignored |
| Label (rule) | "New ..." plus the rule type | The name shown in the rule list. It keeps saying "New ..." after you set the spell, so rename it; if you clear it, the list shows the spell, for example "Moonfire (8921)" |

### State alerts and their outputs

Each state of a rule appears in the rule's screen as a button named after the state, for example Applied. Pressing Enter on it opens the alert of that state. It contains:

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | The state's own switch. See the note below the table |
| Sound Alert | Off | Plays a sound. Opens its own screen |
| TTS Alert | Off | Speaks a message. Opens its own screen |

Turn on the output you want, and leave the state's own Enabled on. At the moment that switch does nothing for the states of any rule: only the Enabled switch of the Sound Alert or TTS Alert inside decides whether something plays. The only alerts that obey the state's own Enabled are Charge Gained and Charge Lost of the Cooldown rule.

The Sound Alert screen has:

| Setting | Default | What it does |
|---|---|---|
| Enabled | Off | Turns the sound on |
| Sound | none chosen | Opens a browser of sounds. Move through the list to hear each sound as a preview, press Enter to choose one. No sound plays until you choose one |

The TTS Alert screen has:

| Setting | Default | What it does |
|---|---|---|
| Enabled | Off | Turns speech on |
| Priority Message (interrupts) | Off | When on, the message cuts off whatever is being spoken instead of waiting its turn |
| Voice | Follows your Speech Voice setting | Speaks this alert with a different voice. See [Speech](../basics/speech.md) |
| Message | empty | The words to speak. When empty, WowVision speaks its standard message |

The standard message is the spell's name and the state, on every monitor: "Moonfire Applied", "Moonfire Expiring", "Rebirth On Cooldown", "Rebirth Charge Gained", "Barkskin Ready", "Starsurge Proc". A rule without a spell uses its Label instead. Type your own Message, such as "Moonfire down", to replace that whole sentence.

## Aura monitor

(Classic Era, The Burning Crusade, Mists of Pandaria)

Watches buffs and debuffs on one unit.

| Setting | Default | What it does |
|---|---|---|
| Unit | target | Which unit to watch, typed as text: `target`, `player`, `focus`, `pet`, `mouseover`, `party1` and so on |
| Announce on Target Change | Only Changes | What the rules say when you change target (or the unit changes). Only Changes: a rule speaks only when the new target's state differs from what it had. Always: every rule announces the state it finds on the new unit, including Missing. Never: the rules take the new target's state in silence; later changes on that target speak as usual |

Rule type: Aura State Rule. It follows one spell through its life on the unit.

| Setting | Default | What it does |
|---|---|---|
| Spell | none | The aura to watch. See [Picking a spell](#picking-a-spell) |
| Applied by Player | On | Only count the aura when you (or your pet) applied it |
| Pandemic Window (%) | 30 | The aura enters the Pandemic state when this percentage of its total duration, or less, is left |
| Expiry Threshold (seconds) | 5 | The aura enters the Expiring state when, inside the pandemic window, this many seconds or fewer are left |

States and when they fire:

| State | When |
|---|---|
| Applied | The aura is on the unit and has plenty of time left (or has no duration) |
| Pandemic | The aura is inside the pandemic window: time to refresh it for the best result |
| Expiring | The aura is inside the pandemic window and at or under the expiry threshold |
| Missing | The aura was on the unit and is gone |

Details worth knowing:

- Expiring needs both conditions: inside the pandemic window and under the expiry threshold. For a short aura (say 6 seconds) the pandemic window is so small that the aura goes straight from Applied to Expiring.
- Auras with no duration stay at Applied.
- If more than one matching aura is present (when Applied by Player is off and several people applied it), the rule reports the healthiest one.
- Missing is spoken when an aura that was being tracked disappears. When the monitor starts (at login, say) and the aura was never there, Missing is not spoken. Set Announce on Target Change to Always if you want to hear "Moonfire Missing" or "Moonfire Applied" every time you target something new.
- With Announce on Target Change at Only Changes (the default), changing target still speaks when the new target's state differs from what the rule had (for example from Applied to Missing). Set it to Never to hear nothing at a target change, only the changes that follow on the new target.
- Applied by Player must be turned off for effects with no caster, such as many trinket procs.
- A rule matches the aura by its own spell number. When the spell you cast and the aura it puts on the target have different numbers (on the classic versions this can depend on the spell rank), choose the aura from the quick picks instead of typing the name. The aura appears there once your monitor has seen it on the unit.

## Cooldown monitor

(Classic Era, The Burning Crusade, Mists of Pandaria)

Watches the cooldowns of your own spells. It has no settings beyond the common ones; the spells are named in its rules.

Rule type: Cooldown State Rule.

| Setting | Default | What it does |
|---|---|---|
| Spell | none | The spell whose cooldown to watch |

States:

| State | When |
|---|---|
| Ready | The spell is off cooldown. For a spell with charges, all charges are available |
| Charging | The spell has charges, at least one is available, but not all |
| On Cooldown | The spell is on cooldown. For a spell with charges, no charge is available |

Two more alerts fire independently of the state, for spells with charges:

| Alert | When |
|---|---|
| Charge Gained | A charge came back |
| Charge Lost | A charge was used |

The global cooldown never counts as a cooldown. The first state a rule sees (at login, say) is silent.

## Cooldown Manager Auras

(Retail and WoW: Forever)

On Retail the game hides aura information from addons in combat and in instances, so the ordinary aura functions cannot see your debuffs there. Blizzard's own cooldown manager can, and this monitor reads what it shows. It tells you, for each aura in the cooldown manager's Tracked Buffs and Tracked Bars, whether the aura is up on the unit and whether it is in its pandemic window.

Before you can use it, the aura must be one of the cooldown manager's tracked buffs or bars:

- Only auras in the Tracked Buffs and Tracked Bars categories can be watched. The Essential and Utility categories hold spells, not auras.
- Only two units can be watched: Target and Player, the two the cooldown manager follows. While you target yourself, a Target monitor hears the auras on you. In instances the game may hide whether you are your own target; WowVision then goes by the last answer it could read since your target changed, so your aura is not reported Missing while you still target yourself.
- The cooldown manager must be showing the aura. A cooldown manager row that you have hidden, or set to appear only in combat, reads as empty while it is hidden, and your rule will report Missing. If an alert plays at the wrong time, check that the rows are shown.

You arrange the cooldown manager in its settings window, which WowVision makes accessible. Open it with `/cdm`. The window has the Spells, Auras and Group Buffs tabs, a Search box, a Settings menu, each category with its items, the Layout dropdown and a Revert Changes button. Press Enter on an item to pick it up and Enter on another item, or on the empty slot of a category, to drop it there. Press Backspace on an item for its menu (alerts, move to another category). Changes made with the keyboard take effect after the interface reloads, because the game rebuilds its on-screen cooldown data from them. The window tells you so the first time and offers a Reload Interface button at its end (or type `/reload`); when you close the window after such changes it reminds you again. Make these changes with no buffs on you, at least none that the cooldown manager tracks. If such a buff is active while you move an item or pick something in its menu, the game shows a Lua error. The error does not stop you: the change is still saved and works after the reload. It comes from the game's own code, which refuses to rebuild the on-screen buffs for a change that did not come from a real mouse click. Reload before you go into combat: until the reload, the on-screen buffs still carry the keyboard change, and the next buff in combat brings the same Lua error, whether or not a buff was on you while you made the change. The items are read with their name, "Unlearned" for spells you have not learned, and the number of alerts they have (for example "1 alert"). Categories can be collapsed and expanded with Enter on their heading. On the Group Buffs tab the buffs sit in a Shown and a Hidden section: Enter picks a buff up, and Enter on a buff in the other section moves it there. Choosing an alert in the item's menu (Add New Alert, or editing an existing one) opens the game's alert editor as a window of its own, called Alert Editor: the spell, one dropdown for each choice, and the button that adds or saves the alert, then Close.

You rarely need the game's alerts, though: WowVision's monitors do everything they do, and do it better. Each state of a rule has its own sound and its own spoken message, in your own speech settings, and you can change both at any time. Spell Cooldowns also works for any spell, not only those in the cooldown manager. The game's alert editor is there if you want it, but start with a monitor.

### Monitor settings

| Setting | Default | What it does |
|---|---|---|
| Unit | Target | Target or Player |
| Announce on Target Change | Only Changes | What the rules say when you change target (only for Target): Only Changes speaks a state that differs from the old target's, Always announces every rule's current state, Never stays silent and speaks only later changes on the new target |
| One Decimal Timer | Off | The countdown drawn on the tracked icons shows tenths of a second ("8.7") below ten minutes. It changes what sighted players see on the screen, which is why it is off by default. It is also what Speak Tracked Auras reads |

### Rule type: Cooldown Manager Aura Rule

| Setting | Default | What it does |
|---|---|---|
| Spell | none | The aura to watch |

The Spell picker lists the auras that are in your Tracked Buffs and Tracked Bars (or says "No tracked buffs or bars"). You can still type any spell name or number, but only auras that are in those two categories will ever be seen. The rule matches by the spell's name, so a cast spell like Moonfire matches its debuff.

States:

| State | When |
|---|---|
| Applied | The aura is up on the unit |
| Pandemic | The cooldown manager marks the aura as inside its refresh window. Pandemic falls back to Applied |
| Missing | The aura is not on the unit |

On WoW: Forever there is no pandemic window, so the Pandemic state does not exist there and does not show in the menu.

When a tracked aura runs out while inside its pandemic window, the rule goes straight from Pandemic to Missing, with no spurious Applied between them.

After you change target, the rule waits a moment (a couple of ticks) for the game to refresh its icons before reading them, so a target change does not sound like the aura dropped and came back.

### Speak Tracked Auras

The Speak Tracked Auras key reads every tracked aura of every enabled Cooldown Manager Auras monitor, as the game shows it: the aura's name, the time left, the stacks, and "Pandemic" when it applies, or "Missing". Example: "Moonfire, 8.7, 3 stacks, Pandemic. Rake, Missing". When nothing is tracked you hear "No tracked auras".

The key is unbound by default. You find it under Monitors in the keybinding window, see [Keybindings](../basics/keybindings.md).

### Diagnostic command: /wv cdmlog

If an alert fires at the wrong moment, `/wv cdmlog` shows a log of what each rule saw on the cooldown manager frames around every change, newest last, in a window you can copy from, and speaks the newest line. Include it when you report a bug.

- `/wv cdmlog clear` empties the log.
- `/wv cdmlog spells` lists every entry in Tracked Buffs and Tracked Bars with its spell ids.
- `/wv cdmlog cooldowns` lists the Essential and Utility entries.

## Spell Cooldowns

(Retail and WoW: Forever)

Cooldown information is secret in combat and in instances on Retail, but the game leaves a few plain facts: whether a cooldown is running, whether it is only the global cooldown, and whether a charge is recharging. This monitor builds its states from those facts alone, so it works anywhere and for any spell. The cooldown manager is needed only to offer you a list of spells to pick from; you can type any spell instead. The time left comes from the game's own formatting, in plain words, and can be spoken even in combat.

It has no settings of its own beyond the common ones. It has two rule types.

### Rule type: Spell Cooldown Rule

| Setting | Default | What it does |
|---|---|---|
| Spell | none | The spell to watch |

The Spell picker offers the spells of your cooldown manager's Essential and Utility categories that the game says have a cooldown to alert on (an instant like Sunfire, which has none, is not offered; or it says "No spells with cooldowns"). An entry that stands for several spells, like Eclipse for Lunar and Solar, is offered as each of those spells. You can still type any spell name or number.

States:

| State | When |
|---|---|
| Ready | The spell is off cooldown and has a charge to use |
| Charging | A charge is recharging while at least one charge is still available |
| On Cooldown | The spell is on a real cooldown, with no charge left |

The global cooldown never counts. While the spell is on cooldown or charging, the rule checks it about ten times a second, because the game sends no event when a cooldown ends.

### Rule type: Spell Proc Rule

A proc rule follows the glow the game draws around a spell when it procs.

| Setting | Default | What it does |
|---|---|---|
| Spell | none | The spell whose glow to watch |

The picker lists the same cooldown manager spells without filtering, since a proc can be on any spell (or says "No essential or utility spells"). States, each with its own alert:

| State | When |
|---|---|
| Proc | The glow appeared |
| Proc Ended | The glow ended |

### Speak Tracked Cooldowns

The Speak Tracked Cooldowns key reads the state of every rule of every enabled Spell Cooldowns monitor. Example: "Barkskin, On Cooldown, 49 seconds. Fire Blast, Charging, 1 charges, 8 seconds. Starsurge, Proc. Wild Growth, Ready". A proc rule reads "No proc" when the glow is off. When no rules exist you hear "No tracked cooldowns".

The key is unbound by default. You find it under Monitors in the keybinding window.

## Availability

| Feature | Classic Era | The Burning Crusade | Mists of Pandaria | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Aura monitor | Yes | Yes | Yes | No | No |
| Cooldown monitor | Yes | Yes | Yes | No | No |
| Cooldown Manager Auras | No | No | No | Yes | Yes |
| Spell Cooldowns (cooldown and proc rules) | No | No | No | Yes | Yes |
| Pandemic state of Cooldown Manager Auras | No | No | No | Yes | No |
| Toggle All Monitors | Yes | Yes | Yes | Yes | Yes |
| Speak Tracked Auras, Speak Tracked Cooldowns, `/wv cdmlog` | No | No | No | Yes | Yes |

See [Versions](../reference/versions.md) for the full feature matrix.

## Keys

| Action | Default key | What it does |
|---|---|---|
| Toggle All Monitors | unbound | If any monitor is on, turns all monitors off and says "Monitors off". If all are off, turns them all on and says "Monitors on" |
| Speak Tracked Auras | unbound | Reads all tracked auras (Retail and WoW: Forever) |
| Speak Tracked Cooldowns | unbound | Reads all tracked spell cooldowns and procs (Retail and WoW: Forever) |

Bind them in the keybinding window, see [Keybindings](../basics/keybindings.md). Toggle All Monitors works as a mute: press it once to silence all monitors and again to turn them all back on. Monitors you had switched off one by one are turned on as well.

## Picking a spell

Every rule has a Spell setting. Press Enter on it to open a small screen:

- Spell Name opens a text field. Type the spell's name or its number and press Enter. If WowVision cannot find the spell you hear "Not Found". On the classic versions the name usually has to be a spell you know; for anything else, use the spell's number.
- Below it is a list of quick picks, each read as "Spell name (number)". Choose one with Enter. For the Aura, Cooldown and Spell Cooldowns rules the list is the spells you have cast, or met as auras, on this character. The Cooldown Manager Auras and Spell Cooldowns rules offer the cooldown manager's own entries instead, as described above.

When a spell is set, the Spell setting reads like "Moonfire (8921)".

## Examples

### Moonfire on your target (Classic Era, TBC, Mists)

You want to hear when your Moonfire is about to fall off the target, and when it is gone.

1. Open the WowVision menu (Shift+F1), then Monitors, then Monitors (0), then Add, and choose Aura.
2. Set Label to "Moonfire". Leave Unit at `target`.
3. Open Rules, press Add and choose Aura State Rule.
4. Set Spell: press Enter, choose Spell Name, type `Moonfire`, Enter. You hear the spell with its number.
5. Leave Applied by Player on.
6. Open Expiring, then TTS Alert. Turn Enabled on. Set Message to "Moonfire expiring".
7. Go back and open Missing, then TTS Alert. Turn Enabled on. Set Message to "Moonfire gone".
8. Optionally open Applied, then Sound Alert, turn it on and choose a short sound with Sound, for a click each time you apply it.

Now apply Moonfire to a target. Applied plays your click. The Pandemic state stays quiet: it has no output of its own, so it falls back to Applied and nothing new plays. When the aura is about to expire you hear "Moonfire expiring", and when it falls off you hear "Moonfire gone". If you then switch to a target that has no Moonfire, you also hear "Moonfire gone", because the rule changed from Applied to Missing.

### A cooldown ready alert (Classic Era, TBC, Mists)

1. Monitors, Monitors (0), Add, Cooldown. Label it "Cooldowns".
2. Rules, Add, Cooldown State Rule. Set Spell to `Starfire` (or any spell with a cooldown).
3. Open Ready, then TTS Alert, turn it on and set Message to "Starfire ready".

Cast the spell. When the cooldown ends you hear "Starfire ready". Nothing is said at login, when the spell is simply ready.

### A cooldown ready alert (Retail and WoW: Forever)

1. Monitors, Monitors (0), Add, Spell Cooldowns.
2. Rules, Add, Spell Cooldown Rule. Open Spell: the quick picks list the Essential and Utility spells of your cooldown manager that have a cooldown. Choose Barkskin.
3. Open Ready, TTS Alert, turn on Enabled.

When Barkskin comes back you hear "Barkskin Ready", also in combat. Add the On Cooldown TTS alert if you also want "Barkskin On Cooldown" when you use it. Bind Speak Tracked Cooldowns to hear the state and the time left on demand.

### A debuff in combat on Retail

1. In the cooldown manager settings (`/cdm`), make sure the aura you want is in Tracked Buffs or Tracked Bars.
2. Monitors, Add, Cooldown Manager Auras. Keep Unit at Target.
3. Rules, Add, Cooldown Manager Aura Rule. Open Spell: the quick picks list your tracked auras. Choose the debuff.
4. Turn on the TTS Alert of Missing and Pandemic.

You hear "Moonfire Pandemic" when the cooldown manager marks the debuff as ready to refresh and "Moonfire Missing" when it falls off.

## Tips

- Start with one monitor and one rule and make sure it works before adding more.
- Turn on only the alerts you will need. A sound on Applied and a spoken message on Missing is a good start.
- Use Applied by Player for auras in group play so that other players' copies do not count. Turn it off for effects that have no caster, such as many trinket procs.
- Give monitors and rules clear labels; the lists show nothing else.
- Monitors and buffers complement each other: let a monitor tell you when Moonfire falls off, and read your other timers on demand with a [buffer](buffers.md) or the Speak keys.
- If an alert never fires, check in this order: the monitor is Enabled; the rule is Enabled; the Spell is set; the state's Sound Alert or TTS Alert is Enabled (they are off by default); and for the sound, a Sound has been chosen.
- If an alert fires at an odd moment on Retail, use `/wv cdmlog`, see [Reporting problems](../getting-started/troubleshooting.md).
