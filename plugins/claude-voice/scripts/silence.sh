#!/bin/bash
# Instantly stops Claude's voice mid-sentence. Safe to run any time.
# Used by the UserPromptSubmit hook (so sending a message hushes me) and
# by the hotkey you can bind in macOS (see voice-toggle.sh for mute/unmute).
pkill -x say 2>/dev/null
pkill -x space-stop 2>/dev/null
exit 0
