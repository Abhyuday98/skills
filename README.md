# skills

Everything I have written for Claude Code, in one place. Two kinds of thing live here:

- **Skills**: a folder with a `SKILL.md` and its scripts. Install one with the [skills](https://skills.sh) CLI, which works across Claude Code, Codex, Cursor and the rest.
- **Plugins**: skills plus commands, hooks or setup scripts, packaged for Claude Code's plugin system. This repo is also a Claude Code marketplace.

## Install

```sh
# a skill, into any agent the skills CLI supports
npx skills@latest add Abhyuday98/skills --skill claude-video-generator

# a plugin, into Claude Code
/plugin marketplace add Abhyuday98/skills
/plugin install cowork@abhyuday-skills
/plugin install derebrand-claude-code@abhyuday-skills
```

## What is here

| Name | Kind | What it does |
| --- | --- | --- |
| [claude-video-generator](skills/claude-video-generator/SKILL.md) | skill | Produces a narrated demo or walkthrough video fully headless: a recorded terminal session, an app tour from a real browser, HTML slides, offline TTS narration, and an assembler where the audio length sets the screen time. |
| [cowork](plugins/cowork/skills/cowork/SKILL.md) | plugin | Cowork mode: hand over a goal, get back a verified file. Research first, the right document skill second, and it opens the result to check it before reporting. |
| [derebrand-claude-code](plugins/derebrand-claude-code/skills/derebrand-claude-code/SKILL.md) | plugin | Renames the Claude Code VS Code extension to a neutral "Assistant" with a plain icon and no orange, and re-applies it after an extension update overwrites it. |

The standalone repos ([claude-video-generator](https://github.com/Abhyuday98/claude-video-generator), [claude-code-cowork](https://github.com/Abhyuday98/claude-code-cowork), [derebrand-claude-code](https://github.com/Abhyuday98/derebrand-claude-code)) are where these started; this repo is where they are maintained now.

## Adding one

A skill: make `skills/<name>/SKILL.md` with `name` and `description` in the front matter, scripts next to it. A plugin: make `plugins/<name>/` with a `.claude-plugin/plugin.json` and add an entry to `.claude-plugin/marketplace.json`. Push, and it is installable.
