# Group Health Monitor

Available on Retail and WoW: Forever.

The Group Health Monitor tells you which of your group members are hurt, and how badly, without reading out percentages. A hurt member is spoken as their number. The pitch tells you how hurt they are: the lower their health, the higher the pitch. Members who are healthy stay silent.

The idea and the numbering come from Sku's health monitor. The monitor is off until you turn it on.

## Turning it on

1. Press Shift+F1 (or type `/wv`) to open the WowVision menu.
2. Go to Group Health Monitor. It sits in the main list, between Errors and Minimap Scanner, so pressing G gets you there quickly.
3. Press Enter on Enabled to turn it on.

All settings of the monitor are on the same screen, see [Settings](#settings) below. Switching Enabled off again silences the monitor completely, and its key does nothing then.

## The numbers

- You are 1.
- Your party members are 2 to 5, in party order.
- In a raid of up to 10 members, the members are numbered 1 to 10 in group order, whatever groups they are in.
- In a raid of 11 or more, a member's number is their group number times five, minus five, plus their place in the group. Group 1 is 1 to 5, group 2 is 6 to 10, and so on up to 40.

These are the same numbers Sku uses for the same members.

In a raid the numbers are only renewed out of combat, so a number never changes in the middle of a fight.

## You need a real Windows voice

The monitor speaks with a voice of its own, which you choose in its settings (Voice). The pitch only works with a real Windows voice. A screen reader bridge voice, such as the NVDA SAPI bridge, speaks the numbers but ignores the pitch. The monitor does not need a screen reader at all.

Every voice sounds a little different, so the pitch steps are tuned per voice. Microsoft Hedda, Zira and Katja are tuned. Any other voice uses Hedda's steps and may sound less even.

## What you hear

Three things speak.

### The repeat

Every member below their role's Repeat Below value is spoken again at the interval of Repeat Every. The members take turns, one number at a time, and a turn only starts while WowVision has nothing else to say, so the monitor never holds back your other speech.

A member above the threshold takes a silent turn. A silent turn is short, about a quarter of a second, so a round through a healthy party of five takes about a second and a half.

Every role has its own values: tanks, healers, damage dealers and members without a role. The defaults are:

| Role | Repeat Below | Repeat Every |
|---|---|---|
| Tanks | 80 percent | 3 seconds |
| Healers | 70 percent | 3 seconds |
| Damage Dealers | 60 percent | 3 seconds |
| No Role | 60 percent | 3 seconds |

Setting Repeat Every to 0 turns the repeat off for that role.

### Deaths

When a member dies, you hear their number and "dead", once. Someone who is already dead when you join the group is not announced.

### The snapshot key

Speak Group Health (default Alt+H, on a controller the right trigger together with the right stick press) says everyone once, in number order, at their current pitch. A member at full health is said as their number and "full", if Announce Full Health is on. Dead members are said as their number and "dead". After the snapshot, the repeat starts afresh.

If there is nobody to watch, you hear "Nobody to watch".

To change the key, open the WowVision menu, go to UI, then Bindings, or type `/wv bind`. See [Keybindings](../basics/keybindings.md).

## Settings

All of these are on the screen of the Group Health Monitor in the WowVision menu. The names are as WowVision speaks them.

| Setting | Default | What it does |
|---|---|---|
| Enabled | Off | Turns the monitor on. Off, it says nothing and its key does nothing |
| Voice | The game's default voice | The monitor's own voice. Pick a real Windows voice |
| Speech Rate | 7 | How fast the numbers are spoken, from -10 to 10. Short numbers are quick, so five hurt members fit in little time |
| Speech Volume | 100 | The volume of the monitor's voice, from 0 to 100 |
| Include Yourself | On | You count as number 1 |
| Watch Party | On | Watch the members of your party |
| Watch Raid | On | Watch the members of your raid |
| Announce Full Health | On | The snapshot says "full" for members at full health |
| Announce Deaths | On | A death is announced |
| Silent Out of Combat | Off | No repeat and no deaths out of combat. The snapshot key still works |
| Repeat Only After a Change | Off | See below |
| Raid Groups | All on | One checkbox per raid group, Group 1 to Group 8. Switch off the groups you do not need, for example to watch only the groups you heal |
| Tanks, Healers, Damage Dealers, No Role | See the table above | Each has Repeat Below (percent), from 0 to 100, and Repeat Every (seconds, 0 is off), from 0 to 300 |

### Repeat Only After a Change

With this setting off, every member takes a turn at the role's interval, and silence means the member is healthy.

With it on, a member only takes a turn when their health changed since their last turn. A member who was hit once is said once and then stays quiet, so the monitor is much quieter. Heals and damage count as changes, but the interval still allows at most one turn per member per interval.

Mind what silence means with this setting on: it means nothing changed, not that everyone is healthy. A member who stays at low health is not said again. Use the snapshot key to check.

## Limits

- The monitor does not follow health changes as they happen and cannot say a percentage or count incoming heals. The repeat and the snapshot are its only voice.
- Every member costs a turn, heard or not, so a large raid takes a while to go round. Watch only the raid groups you heal, or set Repeat Every to 0 for the roles you do not need.
- In battlegrounds and arenas the game does not let addons see your group members. The monitor then says once that it is unavailable ("Group health monitor unavailable here").

## Example

You play a healer in a party of five and want to know who needs you. You turn the monitor on and choose Microsoft Hedda as its voice. In a fight you hear "3" in a high pitch: member 3 is badly hurt. A moment later you hear "2" in a lower pitch: member 2 is only slightly hurt. The tank, number 4, is silent, so that member is above 80 percent. After the fight you press Alt+H and hear all five numbers one after the other, each at its pitch, and "1 full" for yourself.

See also [Monitors](monitors.md) for the monitors that watch your own spells and auras, and [Alerts](../basics/alerts.md) for the general idea of alerts.
