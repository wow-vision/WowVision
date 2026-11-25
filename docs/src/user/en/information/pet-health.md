# Pet Health

Available on Retail and WoW: Forever.

WowVision tells you how much health your pet has left, for a hunter's pet, a warlock's demon or any other pet. A key says it whenever you want, and WowVision can say it by itself during a fight. The [Group Health Monitor](group-health.md) watches players only, so your pet is not part of it.

## The key

Speak Pet Health (default Alt+Shift+H) says the pet's health, for example "Pet 45 percent". Without a pet you hear "No pet", and for a dead pet "Pet dead".

The percentage is rounded up to a multiple of 5, so "Pet 45 percent" means more than 40 and at most 45. A pet with any health left is never said as 0. You can choose another step in the settings.

To change the key, open the WowVision menu, go to UI, then Bindings, or type `/wv bind`. See [Keybindings](../basics/keybindings.md).

## Saying it by itself

This is off until you turn on Announce Health Changes in the settings of Pet Health (Shift+F1, or `/wv`, then Pet Health).

- During a fight, a change of your pet's health is said at most every 3 seconds, and only while WowVision has nothing else to say. A change that has to wait is said as soon as WowVision is quiet, with the health the pet has then.
- When the fight ends, a change that was not said yet is said once.
- When your pet dies you hear "Pet dead" at once.

## Settings

| Setting | Default | What it does |
|---|---|---|
| Enabled | On | Off, the module says nothing and its key does nothing |
| Announce Health Changes | Off | Says the pet's health by itself when it changes, see above |
| Also Out of Combat | Off | With the announcements on, also says changes outside a fight, for example while the pet heals up |
| At Most Every (seconds) | 3 | The shortest time between two announcements, from 1 to 30 |
| Round Up To | 5 percent | The step the percentage is rounded up to: 1, 5, 10, 20 or 25 percent |

## Limits

- The game hides your pet's health from addons. WowVision can have it spoken but cannot know it: it cannot warn you below a value of your choice, and it says a change even when the rounded percentage is the same as before.
- If the game refuses to give the health, the key says "Pet health unavailable here".
