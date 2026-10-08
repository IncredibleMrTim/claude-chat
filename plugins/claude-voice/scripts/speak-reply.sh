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
pkill -x space-stop 2>/dev/null
if [ -n "$VOICE" ]; then
  nohup say -v "$VOICE" -r "$RATE" "$TEXT" >/dev/null 2>&1 &
else
  nohup say -r "$RATE" "$TEXT" >/dev/null 2>&1 &
fi
SAY_PID=$!

# Tapping the space bar cuts speech off. Compiled on first use (and when the source
# changes) so the plugin stays portable; set CLAUDE_VOICE_SPACE_STOP=0 to skip.
if [ "${CLAUDE_VOICE_SPACE_STOP:-1}" = "1" ]; then
  BIN_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-voice"
  BIN="$BIN_DIR/space-stop"
  if [ ! -x "$BIN" ] || [ "$SCRIPT_DIR/space-stop.swift" -nt "$BIN" ]; then
    mkdir -p "$BIN_DIR" && swiftc -O "$SCRIPT_DIR/space-stop.swift" -o "$BIN" 2>/dev/null
  fi
  [ -x "$BIN" ] && nohup "$BIN" "$SAY_PID" >/dev/null 2>&1 &
fi
exit 0
