# Group Health Monitor

Available on WoW: Forever and Retail.

The group health monitor tells you which group members are hurt, and how badly, without reading out percentages. A hurt member is spoken as their number. The pitch tells how hurt they are: the lower their health, the higher the pitch. Healthy members stay silent.

The idea and the numbering come from Sku's health monitor. The monitor is off until you turn it on in its settings.

## Numbers

- You are 1.
- Your party members are 2 to 5, in party order.
- In a raid of up to 10 members, they are numbered 1 to 10 in group order, whatever groups they are in.
- In a raid of 11 or more, each member's number is their group times five, minus five, plus their place in the group. Group 1 is 1 to 5, group 2 is 6 to 10, up to 40.
- These are the numbers Sku's dial targeting uses for the same members.
- Raid numbers are only renumbered out of combat, so a number never changes during a fight.

## You need a real Windows voice

The monitor speaks with a game voice of its own, chosen in its settings. Pitch only works with a real Windows (SAPI) voice. A screen reader bridge voice, such as the NVDA SAPI bridge, speaks the numbers but ignores the pitch. The monitor does not need a screen reader at all.

Every voice shapes its sentences differently, so the pitch scale is tuned per voice. Microsoft Hedda, Zira and Katja are measured; any other voice uses Hedda's scale and may sound less even.

## What is said

The game keeps group health secret from addons on these clients, so the monitor never knows anyone's health and cannot speak on changes. Instead it prepares every announcement with its possible forms, and the game plays the one that matches the member's health. Three things speak:

- **The repeat.** Every member below their role's **Repeat Below** is spoken again every **Repeat Every** seconds. The members take turns, one announcement at a time, and a turn only starts while WowVision has nothing else queued or playing, so the monitor never holds back what WowVision says. A member above the threshold takes a silent turn (it lasts as long as a spoken one), so a round through a party of five takes a few seconds whatever the fight does.
- **"number dead"**, once, when a member dies. Someone already dead when you join is not announced.
- **The snapshot key**, **Speak Group Health** (default Alt+H; on a controller the right trigger with the right stick press): everyone once, in number order, at their current pitch; a member at full health as "number full" when **Announce Full Health** is on; dead members as "number dead". The repeat starts afresh after it. Change the key with `/wv bind`.

Every role (tanks, healers, damage dealers, no role) has its own **Repeat Below** (tanks 80, healers 70, damage dealers and no role 60 percent) and **Repeat Every** (3 seconds; 0 turns the repeat off for that role).

## Other settings

- **Enabled**: the monitor is off until you turn it on. Off, it says nothing and its key does nothing.
- **Voice**, **Speech Rate**, **Speech Volume**: the monitor's own voice. The pitch scales were measured at rate 7.
- **Include Yourself**, **Watch Party**, **Watch Raid**.
- **Raid Groups**: which raid groups to watch, for example only the groups you heal.
- **Announce Full Health**, **Announce Deaths**.
- **Silent Out of Combat**: no repeat and no deaths out of combat; the snapshot key still works.

## Limits

- The monitor never knows anyone's health: it cannot speak on changes, count incoming heals or say a percentage. The repeat and the snapshot are its only voice.
- A silent turn costs the same time as a spoken one, so a large raid takes long to go round. Watch only the raid groups you heal, or set the roles you do not need to 0.
- In battlegrounds and arenas, the game does not let addons read group members at all. The monitor then says once that it is unavailable.
