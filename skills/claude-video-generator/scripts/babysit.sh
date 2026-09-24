#!/usr/bin/env bash
# Approve permission dialogs (Enter on default Yes) until the session goes idle.
# Usage: babysit.sh [max_seconds]
set -u
max=${1:-300}; t=0
while [ $t -lt $max ]; do
  pane=$(tmux capture-pane -pt demo)
  if printf '%s' "$pane" | grep -q "Do you want to proceed\|Do you want to make this edit\|Do you want to create"; then
    tmux send-keys -t demo Enter
    sleep 3; t=$((t+3)); continue
  fi
  if printf '%s' "$pane" | grep -q "esc to interrupt"; then
    sleep 4; t=$((t+4)); continue
  fi
  # idle check: stable pane for 3 polls, no dialog, no spinner
  sleep 3; t=$((t+3))
  pane2=$(tmux capture-pane -pt demo)
  if [ "$pane" = "$pane2" ] && ! printf '%s' "$pane2" | grep -q "esc to interrupt\|Do you want"; then
    break
  fi
done
tmux capture-pane -pt demo | grep -v "^$" | tail -16
