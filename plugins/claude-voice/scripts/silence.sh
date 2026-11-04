#!/bin/bash
# Instantly stops Claude's voice mid-sentence and drops every reply waiting to be
# spoken. Safe to run any time.
# Used by the UserPromptSubmit hook (so sending a message hushes me) and
# by the hotkey you can bind in macOS (see voice-toggle.sh for mute/unmute).
BASE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-voice"

# Empty the queue first, so the player has nothing left to pick up.
rm -f "$BASE_DIR/queue"/*.txt 2>/dev/null

# Ask the player to stop; it silences its own `say` and removes its lock.
PLAYER_PID=$(cat "$BASE_DIR/player.lock/pid" 2>/dev/null)
[ -n "$PLAYER_PID" ] && kill -TERM "$PLAYER_PID" 2>/dev/null

# Belt and braces for a `say` that outlived its player.
pkill -x say 2>/dev/null
pkill -x space-stop 2>/dev/null
exit 0
