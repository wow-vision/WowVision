## V0.5.0
this patch introduces significant refactors to the UI code, greatly increasing performance. It also fixes some bugs with gem socketing and adds more alerts for flying, outdoors, swimming, and combat start/end.

* Fixed gem socket colors reading as "color" if you didn't have colorblind mode enabled.
* Fixed tainting issue with gem socketing UI that prevented socket buttons from being clicked.
* Majorly refactored the UI code behind the scenes. This increased performance by ~50%. The changes won't be too noticeable, but bags/etc should feel more responsive.
* Fixed a long-standing bug where certain UI elements would be in an incorrect order if certain screens refreshed.
* Fixed a bug where the gossip window would sometimes be blank.
* Fixed a bug where the text elements when picking up available quests were in a random order.
* The significant performance issues with the character pane are now fixed.
* Fixed the long-standing bug where entering combat with certain UI windows open would cause odd behavior, such as certain windows not closing. Now navigation-related hotkeys are just disabled until combat ends.
* Added the /wv close command. If the UI does glitch out again, this will force any remaining UI contexts to close. Please report any further UI bugs.
* The /dquit command will now properly leave battlegrounds and arenas.
* Updated and added various TTS output alerts:
    * For navigation/compass: direction changed, outdoors/indoors, flying start and end, swimming, and diving
    * For UI/Combat: combat start and end