## V0.5.1
This patch fixes a few bugs and introduces virtual focus (allowing you to quickly set multiple focus targets.)

* Fixed a bug where trying to access bindings from the /wv UI menu would cause 
errors.
* Added virtual focus. This works as the Sku feature does; you can use the /focus1 through /focus5 commands to set the corresponding virtual focus to either your target or to a specified unit name. Using the corresponding hotkey will /targetexact that unit name. Note that virtual foci cannot be changed while in combat due to Blizzard restrictions.
    * For example I could set my focus1, focus2, and focus3 to each of the bosses in a given raid encounter. Then I could map my focus hotkeys (let's say to alt 1, alt 2, and alt 3). Pressing alt 1 would target the first boss, alt 2 the second, and alt 3 the third.
