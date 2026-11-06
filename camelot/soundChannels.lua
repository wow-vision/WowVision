-- Forever's sound options have a gameplay sound effects slider the classic
-- clients lack (Blizzard's cooldown alerts play on "Gameplay SFX"), and
-- WowVision's sounds play there by default: its own volume, apart from the
-- general sound effects. The ping and combat warning sliders have no channel
-- name an addon can play on (tested 2026-11-06: every name played).
local L = WowVision:getLocale()
tinsert(WowVision.audio.channels, { label = L["Gameplay Sound Effects"], value = "Gameplay SFX" })
WowVision.audio.defaultChannel = "Gameplay SFX"
