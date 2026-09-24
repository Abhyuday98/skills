#!/usr/bin/env python3
"""Time-warp + scrub an asciinema .cast. THE single owner of all text rewriting.

Usage: castwarp.py take.cast take-warped.cast [anchor-holds.json]

- Quiet events (no newline: spinner/cursor/typing echo) are capped per RUN.
- Content events keep at most CONTENT_CAP seconds of delta.
- SCRUB rewrites payload text, most-specific pairs FIRST (plain substitution;
  lengths need not match). Never edit the warped file directly: it is regenerated.
- anchor-holds.json ({"literal typed string": seconds}) inserts a narration-length
  pause at the FIRST event containing each anchor string (see gen_holds.py).
"""
import json, re, sys

SRC, DST = sys.argv[1], sys.argv[2]
HOLDS_FILE = sys.argv[3] if len(sys.argv) > 3 else None

SCRUB = [
    # EDIT ME - most specific first. Examples of the classes that must be covered:
    # ('<the harness status line as recorded>', '<how it should read on camera>'),      # status bars carry account details
    # ('client-prod-account-name (123456789012)', 'the-production-account'),        # account name AND number
    # ('clientname.com', 'example-group.example'),
    # ('ClientCo', 'the client'), ('clientco', 'the client'),
    # ('demo/branch-name', 'neutral-branch-name'),
    # ('for a recording', 'for an external demonstration'),                          # fourth-wall phrases
]

QUIET_RUN_CAP = 0.9   # max seconds a spinner-only stretch may occupy
CONTENT_CAP = 0.42    # max delta a content event keeps

lines = open(SRC).read().strip().split('\n')
header = json.loads(lines[0])
events = [json.loads(l) for l in lines[1:]]
HOLDS = list(json.load(open(HOLDS_FILE)).items()) if HOLDS_FILE else []

def scrub(t):
    for a, b in SCRUB:
        t = t.replace(a, b)
    return t

out, t_new, t_prev, quiet_budget, seen = [], 0.0, 0.0, 0.0, set()
for ts, kind, data in events:
    delta = ts - t_prev
    t_prev = ts
    if '\n' in data or '\r\n' in data:
        d = min(delta, CONTENT_CAP); quiet_budget = 0.0
    else:
        d = 0.016 if quiet_budget >= QUIET_RUN_CAP else min(delta, 0.20)
        quiet_budget += d
    t_new += d
    for m, h in HOLDS:
        if m in data and h > 0 and m not in seen:
            seen.add(m); t_new += h
    out.append([round(t_new, 3), kind, scrub(data)])

header['idle_time_limit'] = None
with open(DST, 'w') as f:
    f.write(json.dumps(header) + '\n')
    for e in out:
        f.write(json.dumps(e) + '\n')

print('warped duration: %.1f min (%d events)' % (out[-1][0] / 60, len(out)))

# Leak sweep - regexes, not memory. Extend for your engagement.
joined = ''.join(e[2] for e in out)
for label, pat in [
    ('12-digit account id', r'(?<!\d)\d{12}(?!\d)'),
    ('guid', r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'),
    ('arn', r'arn:aws'),
]:
    hits = re.findall(pat, joined)
    if hits:
        print('LEAK CHECK', label, len(hits), sorted(set(hits))[:3])
for a, _ in SCRUB:
    if a in joined:
        print('LEFTOVER (scrub failed, chunk-split?):', a[:40])
