#!/bin/bash
# Toggles Claude's voice on/off and stops anything being spoken right now.
# Bind this to a hotkey (macOS Shortcuts / Quick Action) for a one-key mute.
MUTE_FILE="$HOME/.claude/voice-muted"

if [ -f "$MUTE_FILE" ]; then
  rm "$MUTE_FILE"
  osascript -e 'display notification "Voice is back on" with title "Claude"' >/dev/null 2>&1
else
  touch "$MUTE_FILE"
  pkill -x say 2>/dev/null
  osascript -e 'display notification "Voice muted" with title "Claude"' >/dev/null 2>&1
fi
exit 0
