---
name: claude-video-generator
description: Use when asked to produce a narrated demo, walkthrough, or capability video fully headless (no display, no microphone, no screen recorder) - for example a terminal-session recording, an app tour, slides with voiceover, or all three assembled into one film with subtitles under a duration limit.
---

# Claude video generator

## Overview

Produce a finished, narrated MP4 from inside a headless environment (Codespace, CI
box, remote server). Everything is scripted and reproducible: a real interactive
terminal session recorded and time-warped, an app tour captured from a real browser,
HTML slides and document captures, offline TTS narration, and an assembler in which
**narration audio length drives all screen time**. That last idea is the core design:
a slide or pause can never end before its own voice line does, because the video is
sized from the audio, never the other way round.

**REQUIRED READING: [reference.md](reference.md)** holds the full pipeline and the
footgun list. Do not improvise a stage that reference.md already covers; most of its
rules were paid for with a broken cut.

## The five stages

| Stage | Tooling | Script template |
|---|---|---|
| 1. Terminal act | tmux + asciinema (record), send-keys (drive) | `scripts/drive.sh`, `scripts/babysit.sh` |
| 2. Time warp + scrub | Python over the .cast JSON; agg renders gif | `scripts/castwarp.py`, `scripts/gen_holds.py` |
| 3. App tour + captures | Playwright recordVideo, one browser per scene | `scripts/tourclip.cjs`, `scripts/docshot.cjs`, `scripts/evshot.cjs`, `scripts/evfinding.cjs` |
| 4. Slides | One HTML file, screenshot per slide div | `scripts/deckshoot.cjs` |
| 5. Voice + assembly | kokoro-onnx TTS, ffmpeg concat/amix, SRT | `scripts/assemble.py` |

## Footguns that WILL bite (details in reference.md)

- agg silently caps every pause at 5s (`--idle-time-limit`) - narration holds vanish
  and every downstream anchor drifts; symptom is ffmpeg "durationi out of range".
- Record app tours against a **static build**, never the dev server; **fresh browser
  per scene**; film param routes by clicking through, never direct goto.
- All text scrubbing lives in the warp script's one SCRUB list - one-off edits to the
  warped output are lost on every re-warp.
- Sweep the FULL transcript for leaks with regexes (12-digit account ids, GUIDs,
  domains, names), not just the names you remember.
- A top margin on a card page's first child collapses through body and pushes
  bottom-anchored captions out of frame - use padding-top.
- Repo hooks fire on YOUR driving commands too; `pkill -f` matches its own command
  line (exit 144) - use the `[b]racket` trick.
- Changing the terminal playback speed means re-running holds → warp → agg →
  assemble, in that order.

## Delivery checklist

1. Content clean first, then fit the duration limit (playback speed is the sanctioned
   lever for the terminal act).
2. Audit the FINAL film: extract frames at every boundary and LOOK at them; check the
   audio timeline for overlaps numerically; full-text scan the cast for leaks.
3. Ship mp4 + srt + narration.md + voice track, and keep two or three TTS voice
   samples beside them for the owner to audition.
4. Offer a natural-speed reference cut alongside the duration-capped one.
