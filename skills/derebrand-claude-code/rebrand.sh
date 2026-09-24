#!/usr/bin/env bash
# Re-apply the "Assistant" rebrand to every installed Claude Code VSCode extension.
# Idempotent: skips folders already done. Globs all versions, so it catches new
# ones after a manual update without any editing. Keeps .bak of first change.
set -euo pipefail

NAME="${1:-Assistant}"   # pass a different name as arg 1 if you want
GLYPH='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9l-5 4v-4H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/></svg>'

shopt -s nullglob
dirs=( "$HOME"/.vscode/extensions/anthropic.claude-code-*/ "$HOME"/.vscode-server/extensions/anthropic.claude-code-*/ )
[ ${#dirs[@]} -gt 0 ] || { echo "No Claude Code extension folders found."; exit 0; }

for D in "${dirs[@]}"; do
  pj="$D/package.json"
  [ -f "$pj" ] || continue
  if grep -q 'Claude Code' "$pj"; then
    [ -f "$pj.bak" ] || cp "$pj" "$pj.bak"
    sed -i "s/Claude Code/$NAME/g" "$pj"
    python3 -c "import json;json.load(open('$pj'))"   # fail loud on bad JSON
    echo "patched  $(basename "$D")"
  else
    echo "skip     $(basename "$D") (already done)"
  fi
  for f in claude-logo.svg claude-logo-done.svg claude-logo-pending.svg; do
    r="$D/resources/$f"
    [ -f "$r" ] || continue
    grep -q 'M4 4h16' "$r" 2>/dev/null && continue   # already the glyph
    cp "$r" "$r.bak"
    printf '%s' "$GLYPH" > "$r"
  done
  # Wordmark logo (welcome-art-*.svg): the serif "Claude Code" is vector letter
  # paths, not text, so replace the whole asset with a neutral wordmark. Same
  # viewBox keeps sizing. Marker makes it idempotent.
  for wf in welcome-art-dark.svg welcome-art-light.svg; do
    r="$D/resources/$wf"
    [ -f "$r" ] || continue
    grep -q 'derebrand-wordmark' "$r" 2>/dev/null && continue
    cp "$r" "$r.bak"
    printf '%s' "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 440 189\" fill=\"currentColor\"><!--derebrand-wordmark--><text x=\"220\" y=\"108\" text-anchor=\"middle\" font-family=\"Georgia,'Times New Roman',serif\" font-size=\"46\">$NAME</text></svg>" > "$r"
  done
  # Empty-state "Clawd" robot mascot -> blank (keep viewBox so layout is stable).
  cr="$D/resources/clawd.svg"
  if [ -f "$cr" ] && ! grep -q 'derebrand-robot' "$cr" 2>/dev/null; then
    cp "$cr" "$cr.bak"
    printf '%s' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 47 38"><!--derebrand-robot--></svg>' > "$cr"
  fi
  # Webview panel: kill the product name and brand color (safe substrings only).
  # "Claude Code" never appears in an identifier or the `claude` binary name, so
  # it can't break logic. Bare "Claude" is left alone (shared protocol keys).
  for w in index.js index.css; do
    wf="$D/webview/$w"
    [ -f "$wf" ] || continue
    # Brand oranges -> neutral gray. Keep semantic colors: #e5a54b/#eab308
    # (warning amber/yellow), #ef4444/#c74e39-as-error (red). c74e39 here is the
    # clay SEND button (background), neutralized on purpose.
    ORANGE='d97757|c6613f|f37726|f97316|eda38a|c74e39|f38518|f5a66a'
    if grep -qE 'Claude Code' "$wf" || grep -qiE "#($ORANGE)" "$wf"; then
      [ -f "$wf.bak" ] || cp "$wf" "$wf.bak"
      sed -i 's/Claude Code/'"$NAME"'/g' "$wf"
      for h in d97757 c6613f f37726 f97316 eda38a c74e39 f38518 f5a66a; do
        sed -i "s/#$h/#808080/gi" "$wf"
      done
    fi
    # Inline React robot mascot (minified as j("svg",..), viewBox 47x38 / 32x26):
    # blank its blocky SVG path so the empty-state icon disappears.
    if grep -q 'd:"M5\.08191 10\.0769' "$wf" || grep -q 'd:"M3\.88775 7\.44482' "$wf"; then
      [ -f "$wf.bak" ] || cp "$wf" "$wf.bak"
      sed -i 's/d:"M5\.08191 10\.0769[^"]*"/d:""/g; s/d:"M3\.88775 7\.44482[^"]*"/d:""/g' "$wf"
    fi
    # Curated visible prose (full phrases only -> never identifiers/IPC keys).
    if grep -qF "unfocus Claude" "$wf"; then
      sed -i "s/focus or unfocus Claude/focus or unfocus $NAME/g; s/Tell Claude what to do/Tell $NAME what to do/g; s/Claude is waiting/$NAME is waiting/g; s/watch Claude edit/watch $NAME edit/g; s/Ask Claude/Ask $NAME/g; s/Send to Claude/Send to $NAME/g" "$wf"
    fi
  done
  # Neutralize the red input focus ring (it uses --vscode-errorForeground via
  # --app-error-foreground). Root override with !important beats VSCode's inline
  # value; scoped to the webview so real editor error colors are untouched.
  cf="$D/webview/index.css"
  if [ -f "$cf" ] && ! grep -q 'derebrand-error-ring' "$cf"; then
    printf '\n/* derebrand-error-ring */:root{--vscode-errorForeground:#808080 !important;--app-error-foreground:#808080 !important}\n' >> "$cf"
  fi
done
echo "Done. Reload VSCode: Developer: Reload Window (or restart)."
