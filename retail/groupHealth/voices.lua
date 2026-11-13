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

-- Chosen by ear in game 2026-10-03, kept with the pause after the LOW copy
-- (logic.lua, END_PAUSE) after an ear test of offline renders on
-- 2026-11-11: as easy to tell apart as without the pause, a little better
-- in the middle-low levels, and better than measure.py's even scale.
-- Measured with the pause 2026-11-12: the copies stay 5.15 semitones apart
-- and every level still falls a semitone or more.
-- Also used by the OneCore Hedda, which renders the very same sound, and by
-- every voice without a profile. Those get the pause too, on purpose: a
-- number that is not cut off weighs more than a switch between the copies
-- nobody measured for them (a voice like Zira would hear the two copies
-- close together; it needs a profile of its own then).
voices:register({
    key = "hedda",
    match = "hedda",
    fallback = true,
    endPause = true,
    low = { 10, 8, 5, 3, 0, -2, -5, -7, -10 },
    high = { -3, -6, -8, -10 },
    measured = { low = { 3.69, 0.502 }, high = { -1.46, 0.504 } },
})

-- Chosen by ear in game, 2026-10-03; measured again 2026-11-12. Without
-- the pause: with it, her HIGH copy sits only 1.7 semitones below her LOW
-- copy, too close for a scale, so her numbers below 67 percent stay
-- clipped.
voices:register({
    key = "zira",
    match = "zira",
    low = { 10, 7, 5, 2, 0, -3, -6, -8, -10 },
    high = { -2, -5, -7, -10 },
    measured = { low = { 7.53, 0.508 }, high = { 1.94, 0.505 } },
})

-- Measured 2026-11-12 with the pause after the LOW copy. Her HIGH copy sits
-- only about 2.7 semitones below her LOW copy (Hedda 5.15), so the LOW copy
-- carries ten levels and the HIGH copy speaks from 73 percent.
voices:register({
    key = "katja",
    match = "katja",
    endPause = true,
    low = { 10, 7, 5, 3, 1, -1, -3, -5, -7, -9 },
    high = { -6, -8, -10 },
    measured = { low = { 2.21, 0.502 }, high = { -0.45, 0.510 } },
})

-- Measured and left without a profile (they get Hedda's):
-- - Microsoft Stefan: below his middle pitch his voice turns creaky, the
--   pitch jumps from one moment to the next, and steps cannot be heard.
-- - SAPI2SR, the bridge to the screen reader: renders nothing and ignores
--   pitch.
