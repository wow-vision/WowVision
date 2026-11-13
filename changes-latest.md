### All Versions
* Bags: the drag key on a bag slot places the bag you are holding, replacing the one in the slot, as Enter does. Before, it only picked up the bag that was in the slot.
* Errors: one part of WowVision that fails no longer stops the rest. Before, an error that repeated every frame (for example a range check in a dungeon) left menus and windows dead until a reload; now the error is still reported, once instead of every frame, and everything else keeps working. The spoken Lua error alert says each error at most once every 5 seconds, also when two errors take turns.
* Range checks: WowVision's copy of LibRangeCheck is now the current upstream version with our fixes, and it is used by every addon that embeds the library. Another addon's older copy can no longer throw errors every frame in dungeons. In dungeons a new target no longer gets the old target's range for a moment.

### Modern
* Dungeons: a menu entry or target name the game keeps hidden no longer causes an error; it is spoken as the game gives it. Typing letters in a list skips such entries. Target names read quest objectives in dungeons too. There the game hides whether an objective is finished, so each objective is read and its count says how far it is.
