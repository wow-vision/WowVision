# Voice profiles for the group health monitor

The group health monitor (`retail/groupHealth`) says each member's health
as a number whose pitch rises as health falls. Every SAPI voice has its own
melody on top of the pitch the monitor asks for, so each voice needs its
own scale: a profile, one `voices:register({...})` call in
`retail/groupHealth/voices.lua`. A voice without a profile uses the
fallback profile (Hedda's).

These tools make a profile for a new voice on Windows, offline, without
the game. Everything runs from a terminal and prints plain text.

## What you need

- Windows with the voice installed. Both kinds work:
  - SAPI voices (the ones WoW lists, for example Microsoft Hedda Desktop).
  - OneCore voices (Windows' Narrator voices, added in Settings, Time and
    Language, Speech). They do not need to be in WoW's voice list to be
    measured.
- Python 3 (on Windows the launcher `py`).

One-time setup, from this folder:

```
py -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
```

## Making a profile

1. List the voices on this PC:

   ```
   powershell -ExecutionPolicy Bypass -File render.ps1 -List
   ```

2. Render the voice. Give a part of its name that matches exactly one
   voice; lowercased, it becomes the profile's `match`: the monitor uses
   the profile when it is part of the voice's name in game (the longest
   match wins). Pick one that does not also match other voices ("katja",
   not "microsoft"). Rendering Hedda Desktop alongside checks
   the setup: its numbers should match the "Check" section below.

   ```
   powershell -ExecutionPolicy Bypass -File render.ps1 -Voice "Katja,Hedda Desktop"
   ```

   This writes 63 short WAV files per voice into `render\` (the number 3
   at 21 pitches, three ways) and `render\voices.json`.

3. Measure and design:

   ```
   .venv\Scripts\python measure.py katja
   ```

   For each voice it prints the measured lines, then either a
   `voices:register({...})` call or REJECTED with the reason. Katja's:

   ```
   voices:register({
       key = "katja",
       match = "katja",
       low = { 10, 8, 5, 3, 0, -2, -4, -6, -8, -10 },
       high = { -6, -8, -10 },
       measured = { low = { 3.07, 0.506 }, high = { -0.21, 0.507 } },
   })
   ```

   `low` and `high` are the pitch levels (SAPI absmiddle) of the two copies,
   lowest health first, 13 in all; `measured` keeps the measured lines so
   the tests can check the steps.

4. Paste the call into `retail/groupHealth/voices.lua`, with a comment line
   above it (when measured, anything worth knowing about the voice). Add
   the voice's name to the test "voices: the game's voices get their
   profiles" in `retail/groupHealth/tests.lua`, and run the offline tests
   from the repository root:

   ```
   luajit tools/headless-tests.lua GroupHealth
   ```

   Registration refuses a malformed profile with a message; the tests
   check that every level falls at least 0.95 semitones below the one
   before.

5. Listen in game: choose the voice in the monitor's Voice setting and
   lose health slowly (or press the snapshot key at different health).
   Every step down in health should sound one step higher, including the
   switch from the LOW to the HIGH copy (the percentage measure.py
   prints). Only an ear decides: a profile counts as done once heard.

## What measure.py does

The whole method is in the docstring at the top of `measure.py`. In short:

- Each announcement carries the number twice behind volume gates: the
  LOW copy (spoken first, rising melody, the urgent part of the scale) and
  the HIGH copy (spoken last, falling melody, the healthy part). Both are
  measured at every pitch from -10 to 10.
- Pitch is taken on the loud vowel, at its peak, and a robust straight
  line is fitted per copy.
- A voice whose pitch is not steady is rejected (Microsoft Stefan turns
  creaky below his middle pitch; steps there cannot be heard), and so is a
  voice that renders no sound (SAPI2SR, a bridge to the screen reader,
  which ignores pitch anyway).
- When two scales are equally good, which one comes out can depend on a
  hundredth of a semitone; either is fine, the ear decides.
- The scale spreads 13 levels as evenly as possible, with the LOW copy
  keeping at least 9 of them.

## Check

Hedda Desktop rendered on 2026-10-03 measured: LOW copy about
+5.1 + 0.50 x absmiddle, HIGH copy about -0.25 + 0.50 x absmiddle (5.3
semitones apart), no points off the line. Values within a few tenths of
these mean the setup works. Its published profile was chosen by ear and
differs slightly from what measure.py designs; both have the same switch
and the same smallest step. The same holds for Zira (LOW about
+7.5 + 0.51 x absmiddle, HIGH about +1.9 + 0.51 x absmiddle).

## Measured voices

- Microsoft Hedda Desktop (the fallback), Microsoft Zira Desktop: profiles chosen by ear
  in game on 2026-10-03 (the method was built on them).
- Microsoft Hedda (OneCore): the same sound as Hedda Desktop, byte for
  byte; uses Hedda's profile by name.
- Microsoft Katja (OneCore): profile from measure.py, 2026-10-03.
- Microsoft Stefan (OneCore): rejected, creaky low pitch.
- SAPI2SR (Nunosoft's screen reader bridge): rejected, renders no sound.

## When the monitor changes

`render.ps1` renders exactly the monitor's markup (`GroupHealth.segment`)
at the monitor's default rate 7. If the markup, the sentence shape or the
default rate changes, change `render.ps1` to match and measure every
voice again.
