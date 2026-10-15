# Settings & the WowVision Menu

Type `/wv` in chat to open the WowVision menu. This is the central place to configure the addon.

## Menu Structure

The menu is organized by module. Each entry opens that module's settings, and modules with submodules let you drill deeper. The main sections are:

- **Buffers** — configure your buffer groups and tracked objects
- **Chat** — chat alert settings
- **Navigation** — compass, follow, and map settings
- **Speech** — voice selection, speech rate, and volume
- **Targeting** — target announcements and soft targeting (see below)
- **UI** — settings for combat, cursor, and tooltip behavior
- **Windows** — settings for individual game windows (merchants, mail, loot, bags, etc.)

Settings are presented as standard controls — checkboxes, dropdowns, and text fields — and are navigated the same way as any other WowVision window.

## What to Adjust First

If you're just getting started, the most useful thing to configure is **Speech**. The default voice and rate will work, but most users prefer to increase the speech rate. You'll find voice selection, rate, and volume controls under the Speech section.

After that, browse at your own pace. Each module's settings are self-explanatory, and you can always come back to adjust things as you get more familiar with the addon.

## Soft Targeting

Soft targeting picks what is in front of you without a hard target: an enemy, a friend, or something to interact with (the interact key acts on it). Shift+I, Shift+P and Shift+O switch the three on and off; the Targeting settings hold their arc and range.

**Soft Targeting With a Hard Target** decides what happens while you have a target locked:

- **Game Default** (default) — WowVision leaves the game's own behaviour alone.
- **Only Without an Attackable Hard Target** — with a living enemy targeted, soft targeting stays out of the way, so the interact key acts on that enemy instead of a corpse or a chair next to it. With a corpse, an NPC, or a player you follow targeted, soft targeting keeps working. This switches with every target change and when your target dies, in combat too.
- **Only Without a Hard Target** — any locked target turns soft targeting off.
- **Always** — soft targeting works whatever you have targeted.

**Make Soft Target the Hard Target** lets your hard target follow the soft enemy or friend; by default the game's own setting stays. The arc and range settings default to the game's values too: a range of 0 means the game's own range.

The game locks the on/off switches and that last setting in combat. Changed in a fight, they apply when combat ends, and WowVision says "after combat". `/wv soft` reads every soft targeting value, including anything still waiting for combat to end.

## Enemy Count

In a fight WowVision says how many enemies are in it whenever the number changes: "1", "3", "2", and "0" when the last one is gone. The settings are under UI, Combat:

- **Enemy Count Alert** — on by default, spoken by text to speech; a voice pack output plays the numbers instead if you turn it on.
- **Count Enemies** — **Attacking You or Your Group** (default) counts every enemy that you, your pet or anyone in your group is fighting; **Attacking You** counts only the enemies whose aggro you hold.
- **Count Elite Enemies Only** — leaves normal mobs out (elites, rare elites and world bosses still count).

The count comes from enemy nameplates, so it needs them: turn on **Enemy Units** in the game's Nameplates options (off by default in some game versions; WowVision says so once if you enter combat without them). Turning on **Minor** and **Minions** below it counts small trash mobs and enemy pets too. An enemy counts once it is within nameplate range (45 yards on WoW: Forever).
