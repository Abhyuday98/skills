#!/usr/bin/env bash
# Driver for the recorded demo session living in tmux session "demo".
# Subcommands:
#   type "text"   send literal text (no Enter)
#   enter         send Enter
#   key <keys>    send raw tmux key names (e.g. BTab, Escape, Down)
#   say "text"    type + enter
#   cap           print the visible pane
#   wait [secs]   poll until pane content is stable for 3 consecutive 2s polls
#                 (max wait default 600s); prints the final pane
set -u
S=demo
case "${1:?cmd}" in
  type) tmux send-keys -t $S -l "$2" ;;
  enter) tmux send-keys -t $S Enter ;;
  key) shift; tmux send-keys -t $S "$@" ;;
  say) tmux send-keys -t $S -l "$2"; sleep 0.6; tmux send-keys -t $S Enter ;;
  cap) tmux capture-pane -pt $S ;;
  wait)
    max=${2:-600}; stable=0; last=""; t=0
    while [ $t -lt $max ]; do
      sleep 2; t=$((t+2))
      cur=$(tmux capture-pane -pt $S)
      if [ "$cur" = "$last" ]; then stable=$((stable+1)); else stable=0; fi
      last="$cur"
      # consider idle only if stable AND no spinner/interrupt hint visible
      if [ $stable -ge 3 ] && ! printf '%s' "$cur" | grep -q "esc to interrupt"; then
        break
      fi
    done
    printf '%s\n' "$last"
    ;;
  *) echo "unknown cmd" >&2; exit 2 ;;
esac
