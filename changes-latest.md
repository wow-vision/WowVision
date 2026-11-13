### All Versions
* Bags: the drag key on a bag slot places the bag you are holding, replacing the one in the slot, as Enter does. Before, it only picked up the bag that was in the slot.

### Modern
* Cooldown Manager Auras monitors: a monitor on Target now hears your own auras while you target yourself. Before, it reported them as Missing, because the cooldown manager labels an aura on you as Player even when you are your own target. In instances, where the game may hide whether you are your own target, the last answer it could read since your target changed holds.
* Cooldown manager (/cdm): the manual explains the game's Lua error when you move an item while a buff the cooldown manager tracks is on you. The change is still saved; make such changes with no tracked buffs on you, and reload before combat, or the next buff in combat brings the same error.
