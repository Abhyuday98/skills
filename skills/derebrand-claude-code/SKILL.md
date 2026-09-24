---
name: derebrand-claude-code
description: Re-apply the "Assistant" rebrand (neutral name + icon) to the installed Claude Code VSCode extension after a manual update overwrites it. Use when the user says "rebrand the extension", "de-claude", "reapply the rebrand", "I updated the extension", or "/derebrand-claude-code".
---

Run the bundled script and report its output:

```bash
bash ~/.claude/skills/derebrand-claude-code/rebrand.sh
```

- Renames the activity-bar title, view names, and all command-palette entries from "Claude Code" to "Assistant", and swaps the sidebar icon for a neutral chat-bubble glyph, across every installed version folder (`.vscode` and `.vscode-server`).
- Idempotent — safe to run repeatedly; already-patched folders are skipped.
- To use a different name: `bash rebrand.sh MyName`.
- Only touches the extension chrome (package.json + logo SVGs), never the minified webview.

After it runs, tell the user to reload: Command Palette → **Developer: Reload Window** (or restart VSCode) for `package.json` changes to take effect.
