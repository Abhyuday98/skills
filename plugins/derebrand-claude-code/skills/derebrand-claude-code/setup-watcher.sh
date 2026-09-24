#!/usr/bin/env bash
# Set up automatic re-application of the de-brand after each extension update.
# Picks the best mechanism the environment supports:
#   1. systemd user path unit  (desktop Linux: event-driven, survives reboot)
#   2. shell-rc hook           (codespaces/containers: idempotent run on shell start)
# Idempotent: safe to run repeatedly. Run once per machine/codespace.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/rebrand.sh"
[ -f "$SCRIPT" ] || { echo "rebrand.sh not found next to this script"; exit 1; }

# Run it once now so the current install is patched immediately.
bash "$SCRIPT" || true

# --- 1. systemd user (best, if available) -----------------------------------
if command -v systemctl >/dev/null && systemctl --user is-system-running >/dev/null 2>&1; then
  U="$HOME/.config/systemd/user"; mkdir -p "$U"
  cat > "$U/derebrand-claude-code.service" <<EOF
[Unit]
Description=Re-apply Claude Code extension de-branding after an update
[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 8
ExecStart=$SCRIPT
EOF
  {
    echo "[Unit]"
    echo "Description=Watch VS Code extensions dirs for Claude Code updates"
    echo "[Path]"
    for d in "$HOME/.vscode/extensions" "$HOME/.vscode-server/extensions" "$HOME/.vscode-remote/extensions"; do
      [ -d "$d" ] && echo "PathModified=$d"
    done
    echo "[Install]"
    echo "WantedBy=default.target"
  } > "$U/derebrand-claude-code.path"
  systemctl --user daemon-reload
  systemctl --user enable --now derebrand-claude-code.path
  echo "Installed systemd path watcher (event-driven)."
  exit 0
fi

# --- 2. shell-rc hook (portable, zero deps) ---------------------------------
# Runs the idempotent script in the background on each shell start. Extension
# updates are rare and you open terminals often, so this re-patches promptly.
MARK="# derebrand-claude-code watcher"
LINE="$MARK"$'\n'"[ -f \"$SCRIPT\" ] && (bash \"$SCRIPT\" >/dev/null 2>&1 &)"
added=0
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -e "$rc" ] || [ "$(basename "$rc")" = ".bashrc" ] || continue
  if ! grep -qF "$MARK" "$rc" 2>/dev/null; then
    printf '\n%s\n' "$LINE" >> "$rc"; echo "Added shell hook to $rc"; added=1
  else
    echo "Shell hook already present in $rc"; added=1
  fi
done
[ "$added" = 1 ] || { printf '\n%s\n' "$LINE" >> "$HOME/.bashrc"; echo "Added shell hook to ~/.bashrc"; }
echo "Done. New terminals will re-apply the de-brand automatically."
