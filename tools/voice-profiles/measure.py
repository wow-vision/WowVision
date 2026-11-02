"""Measures rendered voices and designs their group health pitch profiles.

See README.md in this folder for the whole procedure.

    python measure.py              every voice in render/voices.json
    python measure.py katja zira   only these profile keys

Per voice, from the files render.ps1 made:

1. Pitch of each file: Praat's pitch track, only the frames within 6 dB of
   the file's loudest moment (the vowel; a HIGH copy opens with a short,
   quieter onset still at the LOW pitch, and the ear follows the vowel),
   frames more than 5 semitones off the file's median dropped (octave
   errors), the 90th percentile taken (the PEAK: the ear follows where a
   rising or falling number reaches; judged by the average, Zira's switch
   to the HIGH copy sounded like a step the wrong way). Semitones against
   the plain number at absmiddle 0.
2. A robust straight line (Theil-Sen) through the 21 points of the LOW
   copy and of the HIGH copy.
3. Quality: a voice is REJECTED when more than 4 of the 21 points of
   either copy sit over a semitone off its line, or a line's slope is not
   near the half semitone per unit every measured voice has. Microsoft
   Stefan is the example: below his middle pitch his voice turns creaky,
   the pitch jumps from one moment to the next, and steps cannot be heard
   reliably there. A rejected voice gets no profile; the monitor gives it
   Hedda's scale.
4. The scale: 13 levels (the two lowest and the two highest 7 percent
   steps share a level), first the LOW copy from absmiddle 10 down, then
   the HIGH copy down to absmiddle -10. The LOW copy is spoken first, so it
   keeps the urgent part: at least 9 levels (the switch to the HIGH copy at
   67 percent or later). Among those, the one whose smallest fall is the
   largest, then the one whose largest fall is the smallest. The monitor's
   tests demand every fall to be at least 0.95 semitones. This rule
   reproduces the scales chosen by ear for Hedda and Zira (same switch,
   same smallest fall).

Prints the register call to paste into retail/groupHealth/voices.lua and
writes render/profiles.json.
"""

import json
import math
import re
import sys
from pathlib import Path

import numpy as np
import parselmouth
from scipy.stats import theilslopes

HERE = Path(__file__).resolve().parent
RENDER = HERE / "render"
PITCHES = list(range(-10, 11))
LEVELS = 13
MIN_LOW_LEVELS = 9
MIN_FALL = 0.95
MAX_OFF_LINE = 4
SLOPE_RANGE = (0.4, 0.65)


def pitch_floor(ref_hz):
    return 50 if ref_hz < 130 else 75


def vowel_pitches(path, floor):
    sound = parselmouth.Sound(str(path))
    pitch = sound.to_pitch_ac(
        time_step=0.005, pitch_floor=floor, pitch_ceiling=500, voicing_threshold=0.2, very_accurate=True
    )
    intensity = sound.to_intensity(minimum_pitch=floor, time_step=0.005)
    top = intensity.values.max()
    values = []
    for t, hz in zip(pitch.xs(), pitch.selected_array["frequency"]):
        db = intensity.get_value(t)
        if hz > 0 and db == db and db >= top - 6:
            values.append(hz)
    values = np.array(values)
    if len(values) == 0:
        return values
    median = np.median(values)
    return values[np.abs(12 * np.log2(values / median)) <= 5]


class NoSound(Exception):
    pass


def measure(file):
    # A voice that bridges to a screen reader (SAPI2SR) renders empty
    # files: its speech goes to the screen reader, which ignores pitch.
    try:
        probe = vowel_pitches(RENDER / f"{file}_plain0.wav", 50)
    except parselmouth.PraatError:
        raise NoSound("renders no sound (a screen reader bridge? those ignore pitch)")
    if len(probe) == 0:
        raise NoSound("renders no voiced sound")
    # A first pass with a low floor finds the voice's register.
    floor = pitch_floor(float(np.median(probe)))
    ref = float(np.median(vowel_pitches(RENDER / f"{file}_plain0.wav", floor)))
    lines = {}
    for kind in ("low", "high"):
        points = []
        for p in PITCHES:
            values = vowel_pitches(RENDER / f"{file}_{kind}{p}.wav", floor)
            points.append(12 * math.log2(np.percentile(values, 90) / ref) if len(values) else float("nan"))
        known = [(p, y) for p, y in zip(PITCHES, points) if y == y]
        ps = np.array([p for p, _ in known])
        ys = np.array([y for _, y in known])
        slope, intercept, _, _ = theilslopes(ys, ps)
        off = int((np.abs(ys - (intercept + slope * ps)) > 1.0).sum()) + (len(PITCHES) - len(known))
        lines[kind] = dict(a=float(intercept), b=float(slope), off=off, points=points)
    return ref, lines


def problems(lines):
    found = []
    for kind, line in lines.items():
        if line["off"] > MAX_OFF_LINE:
            found.append(f"{line['off']} of 21 {kind.upper()} points over a semitone off the line")
        if not SLOPE_RANGE[0] <= line["b"] <= SLOPE_RANGE[1]:
            found.append(f"{kind.upper()} slope {line['b']:.2f} semitones per unit")
    return found


def design(low, high):
    """Max-min fall over 13 levels, LOW copy first; see the module docstring."""
    value = {("L", p): low["a"] + low["b"] * p for p in PITCHES}
    value.update({("H", p): high["a"] + high["b"] * p for p in PITCHES})

    def run(min_fall):
        current = {("L", 10): (float("inf"), [("L", 10)])}
        for step in range(LEVELS - 1):
            following = {}
            for a, (score, path) in current.items():
                for b in value:
                    if a[0] == "H" and b[0] == "L":
                        continue
                    if a[0] == b[0] and b[1] >= a[1]:
                        continue
                    if b[0] == "H" and step + 1 < MIN_LOW_LEVELS:
                        continue
                    fall = value[a] - value[b]
                    if fall <= 0:
                        continue
                    if min_fall is None:
                        new = min(score, fall)
                    elif fall < min_fall - 1e-9:
                        continue
                    else:
                        new = min(score, -fall)
                    if b not in following or new > following[b][0]:
                        following[b] = (new, path + [b])
            current = following
        return current.get(("H", -10))

    first = run(None)
    if first is None:
        return None
    best = run(first[0])
    path = best[1]
    lows = [p for copy, p in path if copy == "L"]
    highs = [p for copy, p in path if copy == "H"]
    heard = [value[n] for n in path]
    falls = [heard[i] - heard[i + 1] for i in range(len(heard) - 1)]
    return dict(
        low=lows,
        high=highs,
        switch=round((len(lows) + 1) / 15 * 100),
        heard=[round(h, 2) for h in heard],
        falls=[round(f, 2) for f in falls],
    )


def lua_list(values):
    return "{ " + ", ".join(str(v) for v in values) + " }"


def lua_key(match):
    return re.sub(r"[^a-z0-9]+", "_", match).strip("_")


def main(keys):
    manifest = json.loads((RENDER / "voices.json").read_text(encoding="utf-8-sig"))
    keys = keys or list(manifest)
    results = {}
    for key in keys:
        entry = manifest[key]
        print(f"== {entry['name']}  (key \"{key}\", rate {entry['rate']}, rendered {entry['date']})")
        try:
            ref, lines = measure(entry["file"])
        except NoSound as reason:
            print(f"   REJECTED, no profile: {reason}")
            print()
            results[key] = dict(voice=entry["name"], rate=entry["rate"], rejected=[str(reason)])
            continue
        low, high = lines["low"], lines["high"]
        print(f"   plain number at absmiddle 0: {ref:.0f} Hz")
        for kind, line in lines.items():
            print(f"   {kind.upper():4s} copy peak: {line['a']:+.2f} {line['b']:+.3f} x absmiddle semitones, {line['off']} of 21 points over a semitone off")
        print(f"   HIGH copy below LOW copy by {low['a'] - high['a']:.2f} semitones")
        found = problems(lines)
        result = dict(voice=entry["name"], rate=entry["rate"], ref_hz=round(ref, 1), lines=lines)
        if found:
            print("   REJECTED, no profile: " + "; ".join(found))
            print("   (the pitch is not steady enough for steps to be heard; the monitor gives this voice Hedda's scale)")
            result["rejected"] = found
        else:
            profile = design(low, high)
            if profile is None or min(profile["falls"]) < MIN_FALL:
                smallest = "none possible" if profile is None else f"{min(profile['falls']):.2f}"
                print(f"   REJECTED, no profile: no scale with every fall {MIN_FALL} semitones or more (smallest {smallest})")
                result["rejected"] = ["range too small"]
            else:
                print(f"   scale falls {min(profile['falls']):.2f} to {max(profile['falls']):.2f} semitones, "
                      f"{profile['heard'][0] - profile['heard'][-1]:.1f} in all, HIGH copy from {profile['switch']} percent")
                print("   For retail/groupHealth/voices.lua:")
                print("voices:register({")
                print(f'    key = "{lua_key(key)}",')
                print(f'    match = "{key}",')
                print(f"    low = {lua_list(profile['low'])},")
                print(f"    high = {lua_list(profile['high'])},")
                print(f"    measured = {{ low = {{ {low['a']:.2f}, {low['b']:.3f} }}, high = {{ {high['a']:.2f}, {high['b']:.3f} }} }},")
                print("})")
                result["profile"] = profile
        results[key] = result
        print()
    (RENDER / "profiles.json").write_text(json.dumps(results, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1:])
