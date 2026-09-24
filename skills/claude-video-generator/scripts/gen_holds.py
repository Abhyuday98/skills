#!/usr/bin/env python3
"""Size a narration hold for each terminal anchor from its cue's wav duration.

hold = max(0, (vo_seconds - GRACE) * TS)

TS is the terminal playback speed factor used in assembly (setpts=PTS/TS): the hold
is inserted into the 1x cast, so pre-scaling by TS makes the played-back pause cover
the narration. GRACE seconds of narration may spill into moving footage.

After ANY change to TS or a cue's text: re-run this, then castwarp, then agg, then
assemble - in that order.

Usage: gen_holds.py <vo-wav-dir> <out anchor-holds.json> [TS]
"""
import json, os, sys, wave

VO_DIR, OUT = sys.argv[1], sys.argv[2]
TS = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
GRACE = 4.5

# EDIT ME: literal TYPED strings (input arrives as one cast event; output fragments,
# so never anchor on output text) -> the narration cue key spoken over that moment.
ANCHOR = {
    # 'the first thing you typed': 'term-intro',
    # 'the second thing you typed': 'term-plan',
    # 'Run the full verification block': 'term-verify',
}

def dur(key):
    w = os.path.join(VO_DIR, key + '.wav')
    if not os.path.exists(w):
        return 0.0
    with wave.open(w) as f:
        return f.getnframes() / f.getframerate()

holds = {}
for text, key in ANCHOR.items():
    h = max(0.0, (dur(key) - GRACE) * TS)
    if h > 0:
        holds[text] = round(h, 1)
json.dump(holds, open(OUT, 'w'), indent=1)
print({k[:28]: v for k, v in holds.items()})
