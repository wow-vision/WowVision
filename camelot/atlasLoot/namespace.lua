-- The loot browser over AtlasLoot (module.lua): the third-party addon AtlasLoot Forever (AtlasLootClassic) or
-- AtlasLootContinued draws a window of its own that the keyboard cannot read; this reads its loot tables and shows them
-- as a WowVision screen. game.lua holds the calls into the game and AtlasLoot, loot.lua the reading of the tables and
-- the filters, screen.lua the screen. None of AtlasLoot's code is copied, and nothing of AtlasLoot is changed.
WowVision.atlasLoot = { L = WowVision:getLocale() }
