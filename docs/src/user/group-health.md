# Group Health Monitor

Available on WoW: Forever and Retail.

The group health monitor tells you which group member is losing health, and how badly, without reading out percentages. A hurt member is spoken as their number. The pitch tells how hurt they are: the lower their health, the higher the pitch. Healthy members stay silent.

The idea and the numbering come from Sku's health monitor.

## Numbers

- You are 1.
- Your party members are 2 to 5, in party order.
- In a raid of up to 10 members, they are numbered 1 to 10 in group order, whatever groups they are in.
- In a raid of 11 or more, each member's number is their group times five, minus five, plus their place in the group. Group 1 is 1 to 5, group 2 is 6 to 10, up to 40.
- These are the numbers Sku's dial targeting uses for the same members.
- Raid numbers are only renumbered out of combat, so a number never changes during a fight.

## You need a real Windows voice

The monitor speaks with a game voice of its own, chosen in its settings. Pitch only works with a real Windows (SAPI) voice. A screen reader bridge voice, such as the NVDA SAPI bridge, speaks the numbers but ignores the pitch. The monitor does not need a screen reader at all.

Every voice shapes its sentences differently, so the pitch scale is tuned per voice. Microsoft Hedda and Microsoft Zira are measured; any other voice uses Hedda's scale and may sound less even.

## When something is said

The monitor speaks only when a member's health changes. It never reads health on a timer, unless you turn on the repeat.

With **Only When Health Changed Enough** (on by default) a member is spoken only when their health has moved by their role's **Minimum Change** since the last number of theirs you heard, up or down, and their pitch has moved by the role's **Minimum Pitch Steps**. Small changes add up: four small hits of 3 percent each make one announcement for a healer. A member whose health wobbles a little stays silent. This is the rule of Sku's health monitor, with Sku's values: tanks 5 percent, healers 10, damage dealers 20, no role 30; pitch steps healers 1, damage dealers 2, no role 3. Tanks need 1 pitch step here (0 in Sku): their 5 percent is less than one pitch step, so without it a tank could be announced again at the same pitch.

Every role (tanks, healers, damage dealers, no role) has its own settings:

- **Speak Below**: above this health, the member is silent.
- **Minimum Change**: how far health must move since the last announcement (2 to 50 percent).
- **Minimum Pitch Steps**: how many pitch steps the number must move since the last announcement (0 to 7; 0 is off). The two lowest and the two highest of the 15 steps share a pitch and count as one; "full" counts as a step of its own.
- **Urgent Below**: below this health, the member counts as urgent: urgent members are checked first when several wait.
- **Repeat Below** and **Repeat Every**: every member under the repeat threshold is spoken again at this interval, also beside the changes. 0 turns the repeat off.

With **Only When Health Changed Enough** off, the monitor speaks on every health change, as Sku does with a minimum change of 0: each member waits in the queue at most once, and is spoken with their health at the moment their turn comes.

With **Only When Health Changed Enough** on, there is no delay. The number goes out the moment the health changes, and the game itself decides whether it is heard: only when the health is a minimum change and the minimum pitch steps away from the last number you heard. A silent check afterwards (a quarter of a second for "no change", up to about two seconds for a far move) finds out where the health was, so the next number is measured from there. A change above **Speak Below** is silent, so it does not count: the next number is measured from what you last heard. While a member's check is still running, a further change of that member goes out at once if no other check is waiting (it may then repeat the number before); otherwise it waits for the check. The minimum change keeps a member from speaking too often, as in Sku. Someone who joins your group is checked once, silently, to learn where their health is (above **Speak Below** they count as full, as in Sku); from then on their changes count.

If something stops all speech (pressing Ctrl, a target change, a menu key) while a number of a member plays, the next number of that member is said in any case, wherever its lane speaks, so a cut number is never lost (at worst you hear it twice). A check lost to other speech while the number played to its end is read again silently, as long as that member's health has not changed since: the re-check reads the very same health, so the monitor knows whether you heard the number, and nothing is repeated or left out. A death cut by a stop is said again. The snapshot and the repeat are never repeated: stopping them means stop.

A member who comes back to full health is announced as "number full", if **Announce Full Health** is on. A member who dies is announced once as "number dead".

## Other settings

- **Enabled**: the monitor is off until you turn it on. Off, it says nothing and its key does nothing.
- **Voice**, **Speech Rate**, **Speech Volume**: the monitor's own voice.
- **Time Between Numbers**: how far apart two announcements start for the snapshot, the repeat, deaths, and every change with **Only When Health Changed Enough** off. With it on, numbers go out the moment the health changes.
- **Include Yourself**, **Watch Party**, **Watch Raid**.
- **Raid Groups**: which raid groups to watch, for example only the groups you heal.
- **Silent Out of Combat**.

## The snapshot key

**Speak Group Health** (default key: Alt+H) speaks every member once, in number order, at their current pitch; a member at full health as "number full" when **Announce Full Health** is on. Change the key with `/wv bind`.

## The log

`/wv ghlog on` records what the monitor does: every announcement from its queue as it plays (change, dead, repeat or snapshot; how long it waited in the queue), and with **Only When Health Changed Enough** on each number that turned out to be a move (the new reference, whether it was heard or silent above **Speak Below**, how soon after the health event it went out and what it waited for), each check that was lost and why, and each number said again after a stop. In a raid it also notes a health event that came under a second name for the same member (party1 as well as raid3), so a raid test shows whether the game sends both. While the log is on, it also counts who stopped all speech. `/wv ghlog off` stops it, `/wv ghlog show` opens the last 400 lines in a window, `/wv ghlog clear` empties it. The log cannot know which announcements were audible: the game decides that. Its last line counts, from the moment the log was turned on: health events, health checks (samples, readings used, samples thrown away and why), purges, own speech cut by a stop, how much was said again, and how often other speech started. These counts, with how long the log ran, let the offline simulation be set to a real fight. The log is also kept in the saved variables at the next `/reload` (WowVisionDump).

## Limits

- The game keeps group health secret from addons. The monitor never knows anyone's health: it prepares the possible announcements and the game plays the one that matches. That is why incoming heals cannot be counted in.
- **Only When Health Changed Enough** learns how far health moved from how long silent speech plays, through the monitor's own voice. It is tuned to Microsoft voices (Hedda, Katja, Stefan and Zira were measured). Other voices, the NVDA SAPI bridge, and a frame rate below about 20 frames per second can make it fail. It does not work while the game is in the background (after Alt+Tab): the game then gives every utterance the same length. The output device does not matter (speakers and headsets measured the same). The game speaks one utterance after another, about 27 a second for all speech together, and every health event of a watched member costs three of them. Members hit at the same moment are checked together, up to three at a time, and when several wait the most urgent go first: members below their urgent threshold, then tanks, then healers, then the lowest health. In the simulation under steady damage: 5 watched members are followed almost fully (a number about 0.05 seconds after the change), 10 about 88 percent of the time, 20 about 60, 40 about half; under heavy area damage 10 members about a third. Numbers of members hit together may overlap. Watch only the raid groups you heal. When it reads nothing for half a minute, or almost nothing for a while, the monitor says "Group health readings failing" once; turn the setting off, and the monitor speaks on every health change again.
- In battlegrounds and arenas, the game does not let addons read group members at all. The monitor then says once that it is unavailable.
