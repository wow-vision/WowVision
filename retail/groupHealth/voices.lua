local GroupHealth = WowVision.groupHealth

-- Voice profiles: the pitch levels of the group health monitor per game
-- voice (see logic.lua for why every voice needs its own). Each voice was
-- rendered offline through SAPI with the monitor's own markup at its
-- default speech rate 7, and its peak pitch per absmiddle measured; the
-- levels were then chosen so that each is heard about a semitone or more
-- below the one before (the tests check that against `measured`).
--
-- low, high: the absmiddle of each level of the LOW and the HIGH copy,
--   lowest health (highest pitch) first; 13 levels in all.
-- measured: the voice's peak pitch per copy as a line, { a, b } = a + b *
--   absmiddle semitones.
-- match: part of the game's voice name, lowercase; the longest match wins.
local voices = GroupHealth.voices

-- Measured 2026-11-10 with the pause after the LOW copy (logic.lua,
-- END_PAUSE); before it, chosen by ear in game 2026-10-03 without the pause.
-- Also used by the OneCore Hedda, which renders the very same sound, and by
-- every voice without a profile.
voices:register({
    key = "hedda",
    match = "hedda",
    fallback = true,
    endPause = true,
    low = { 10, 8, 6, 4, 2, 0, -2, -4, -6 },
    high = { -1, -4, -7, -10 },
    measured = { low = { 3.69, 0.502 }, high = { -0.33, 0.502 } },
})

-- Chosen by ear in game, 2026-10-03. Without the pause: with it, her HIGH
-- copy sits only 1.3 semitones below her LOW copy, too close for a scale
-- (measured 2026-11-10), so her numbers below 67 percent stay clipped.
voices:register({
    key = "zira",
    match = "zira",
    low = { 10, 7, 5, 2, 0, -3, -6, -8, -10 },
    high = { -2, -5, -7, -10 },
    measured = { low = { 7.69, 0.51 }, high = { 1.98, 0.506 } },
})

-- Measured 2026-11-10 with the pause after the LOW copy. Her HIGH copy sits
-- only about 2.5 semitones below her LOW copy (Hedda 4.0), so the LOW copy
-- carries eleven levels and the HIGH copy speaks from 80 percent.
voices:register({
    key = "katja",
    match = "katja",
    endPause = true,
    low = { 10, 8, 6, 4, 2, 0, -2, -4, -6, -8, -10 },
    high = { -8, -10 },
    measured = { low = { 2.21, 0.502 }, high = { -0.25, 0.502 } },
})

-- Measured and left without a profile (they get Hedda's):
-- - Microsoft Stefan: below his middle pitch his voice turns creaky, the
--   pitch jumps from one moment to the next, and steps cannot be heard.
-- - SAPI2SR, the bridge to the screen reader: renders nothing and ignores
--   pitch.
