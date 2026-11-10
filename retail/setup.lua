local _, addon = ...

-- Retail and WoW: Forever have a Gameplay Sound Effects slider (Blizzard's
-- cooldown alerts play on "Gameplay SFX"), offered as one more channel for
-- WowVision's sounds (core/audio/channels.lua). The default stays Sound
-- Effects, as on every version: moving existing players to another slider
-- could silence WowVision for anyone who keeps that one low or off.
addon.consts = {
    UI_DELAY = 0,
    SOUND_CHANNELS = { { label = GAMEPLAY_SFX_VOLUME, value = "Gameplay SFX" } },
}
