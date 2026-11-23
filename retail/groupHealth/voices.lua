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
-- Measured with the pause (the pron pause since 2026-11-22): the copies are
-- 5.17 semitones apart and every level still falls a semitone or more.
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
    measured = { low = { 4.72, 0.547 }, high = { -0.45, 0.504 } },
})

-- From measure.py with the pron pause, 2026-11-22 (her copies 3.21
-- semitones apart). Before, she went without a pause, as the <silence>
-- pause brought her copies within 1.7 semitones: her numbers below 67
-- percent were cut at the end. Now they end whole, the LOW copy carries
-- ten levels and the HIGH copy speaks from 73 percent. Not heard yet.
voices:register({
    key = "zira",
    match = "zira",
    endPause = true,
    low = { 10, 7, 5, 2, 0, -2, -4, -6, -8, -10 },
    high = { -6, -8, -10 },
    measured = { low = { 5.13, 0.501 }, high = { 1.92, 0.506 } },
})

-- Measured with the pause after the LOW copy (the pron pause 2026-11-22;
-- measure.py gives the same scale as with the <silence> pause before). Her
-- HIGH copy sits only about 2.8 semitones below her LOW copy (Hedda 5.17),
-- so the LOW copy carries ten levels and the HIGH copy speaks from 73
-- percent.
voices:register({
    key = "katja",
    match = "katja",
    endPause = true,
    low = { 10, 7, 5, 3, 1, -1, -3, -5, -7, -9 },
    high = { -6, -8, -10 },
    measured = { low = { 4.44, 0.505 }, high = { 1.63, 0.516 } },
})

-- Measured and left without a profile (they get Hedda's):
-- - Microsoft Stefan: below his middle pitch his voice turns creaky, the
--   pitch jumps from one moment to the next, and steps cannot be heard.
-- - SAPI2SR, the bridge to the screen reader: renders nothing and ignores
--   pitch.
