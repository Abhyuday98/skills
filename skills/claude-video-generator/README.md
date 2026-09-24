# claude-video-generator

A Claude Code skill for producing narrated demo / walkthrough / capability films
fully headless: a real terminal session recorded and time-warped, an app tour from a
real browser, HTML slides and document captures, offline TTS narration, and an
assembler in which narration audio length drives all screen time.

Distilled from a real production: a ~20-minute capability film built end to end
inside a GitHub Codespace (no display, no microphone), reviewed round after round
until it shipped. Every rule in `reference.md` was paid for with a broken cut.

## Install as a skill

```bash
git clone <this repo> ~/.claude/skills/claude-video-generator
```

Claude Code picks it up from `~/.claude/skills/`. Then, in any project:
ask for a narrated demo video and the skill triggers; or start with
`bash ~/.claude/skills/claude-video-generator/scripts/install.sh` to set up the
toolchain (tmux, asciinema, agg, ffmpeg, kokoro-onnx + model files, Playwright).

## Layout

- `SKILL.md` - trigger, stage map, footgun quick reference
- `reference.md` - the full pipeline reference (read once, whole)
- `scripts/` - working templates: recorder driver + babysitter, cast warp + scrub,
  narration-hold generator, tour clip, doc/evidence/annotated cards, deck shooter,
  the assembler, and the toolchain installer
