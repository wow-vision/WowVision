local _, addon = ...

-- Retail and WoW: Forever have a Gameplay Sound Effects slider (Blizzard's
-- cooldown alerts play on "Gameplay SFX"); WowVision's sounds play there by
-- default, a volume apart from the general sound effects
-- (core/audio/channels.lua).
addon.consts = {
    UI_DELAY = 0,
    SOUND_CHANNELS = { { label = GAMEPLAY_SFX_VOLUME, value = "Gameplay SFX" } },
    DEFAULT_SOUND_CHANNEL = "Gameplay SFX",
}
