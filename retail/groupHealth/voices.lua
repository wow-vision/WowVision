local GroupHealth = WowVision.groupHealth

-- Voice profiles: the pitch levels of the group health monitor per game
-- voice (see logic.lua for why every voice needs its own). Made with
-- tools/voice-profiles, which measures a voice offline and prints the
-- register call to paste here; its README has the procedure. All measured
-- at the monitor's default speech rate 7.
--
-- low, high: the absmiddle of each level of the LOW and the HIGH copy,
--   lowest health (highest pitch) first; 13 levels in all.
-- measured: the voice's peak pitch per copy as a line, { a, b } = a + b *
--   absmiddle semitones; the tests check that every level falls about a
--   semitone or more below the one before.
-- match: part of the game's voice name, lowercase; the longest match wins.
local voices = GroupHealth.voices

-- Chosen by ear in game, 2026-10-03. Also used by the OneCore Hedda, which
-- renders the very same sound, and by every voice without a profile.
voices:register({
    key = "hedda",
    match = "hedda",
    fallback = true,
    low = { 10, 8, 5, 3, 0, -2, -5, -7, -10 },
    high = { -3, -6, -8, -10 },
    measured = { low = { 5.28, 0.497 }, high = { 0.06, 0.506 } },
})

-- Chosen by ear in game, 2026-10-03.
voices:register({
    key = "zira",
    match = "zira",
    low = { 10, 7, 5, 2, 0, -3, -6, -8, -10 },
    high = { -2, -5, -7, -10 },
    measured = { low = { 7.69, 0.51 }, high = { 1.98, 0.506 } },
})

-- Measured 2026-10-03. Her HIGH copy sits only about 3.3 semitones below
-- her LOW copy (Hedda 5.1, Zira 5.7), so the LOW copy carries ten levels
-- and the HIGH copy speaks from 73 percent.
voices:register({
    key = "katja",
    match = "katja",
    low = { 10, 8, 5, 3, 0, -2, -4, -6, -8, -10 },
    high = { -6, -8, -10 },
    measured = { low = { 3.07, 0.506 }, high = { -0.21, 0.507 } },
})

-- Measured and left without a profile (they get Hedda's):
-- - Microsoft Stefan: below his middle pitch his voice turns creaky, the
--   pitch jumps from one moment to the next, and steps cannot be heard.
-- - SAPI2SR, the bridge to the screen reader: renders nothing and ignores
--   pitch.
