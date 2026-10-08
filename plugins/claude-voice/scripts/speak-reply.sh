#!/bin/bash
# Speaks the opening of Claude's last reply aloud using macOS `say`.
# Runs from a Stop hook: Claude Code pipes JSON to stdin. Fully local, costs no tokens.
#
# Mute:  touch ~/.claude/voice-muted    Unmute: rm ~/.claude/voice-muted
# Voice: empty = macOS System Voice (System Settings > Accessibility > Spoken Content).
#        Override with CLAUDE_VOICE_NAME="Samantha" (list: say -v '?').

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VOICE="${CLAUDE_VOICE_NAME:-}"
RATE="${CLAUDE_VOICE_RATE:-185}"           # words per minute
MAX_CHARS="${CLAUDE_VOICE_MAX_CHARS:-900}" # sentences are never cut mid-way

[ -f "$HOME/.claude/voice-muted" ] && exit 0

TEXT=$(python3 "$SCRIPT_DIR/speak-reply.py" "$MAX_CHARS")
[ -z "$TEXT" ] && exit 0

# Test mode: print what would be spoken instead of speaking it.
if [ -n "$SPEAK_DRY_RUN" ]; then echo "$TEXT"; exit 0; fi

# Stop any earlier speech so replies never pile up, then speak in the background.
pkill -x say 2>/dev/null
if [ -n "$VOICE" ]; then
  nohup say -v "$VOICE" -r "$RATE" "$TEXT" >/dev/null 2>&1 &
else
  nohup say -r "$RATE" "$TEXT" >/dev/null 2>&1 &
fi
exit 0
