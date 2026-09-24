# skills

My Claude Code skills, one folder each under `skills/`. Install any of them with the [skills](https://skills.sh) CLI:

```sh
npx skills@latest add Abhyuday98/skills --skill claude-video-generator
npx skills@latest add Abhyuday98/skills --skill derebrand-claude-code
```

| Skill | What it does |
| --- | --- |
| [claude-video-generator](skills/claude-video-generator/SKILL.md) | Produces a narrated demo or walkthrough video fully headless: a recorded terminal session, an app tour from a real browser, HTML slides, offline TTS narration, and an assembler where the audio length sets the screen time. |
| [derebrand-claude-code](skills/derebrand-claude-code/SKILL.md) | Renames the Claude Code VS Code extension to a neutral "Assistant" with a plain icon, and re-applies it after an extension update overwrites it. |

## Adding a skill

Make a folder under `skills/` with a `SKILL.md` whose front matter has `name` and `description`, plus any scripts it needs next to it. Commit. It is installable the moment it is pushed.
