#!/bin/bash
# Queues the opening of Claude's last reply to be spoken aloud using macOS `say`.
# Runs from a Stop hook: Claude Code pipes JSON to stdin. Fully local, costs no tokens.
#
# Replies are spoken one after another (play-queue.sh), never over each other.
# Sending a message, or silence.sh, clears the queue.
#
# Mute:  touch ~/.claude/voice-muted    Unmute: rm ~/.claude/voice-muted
# Voice: empty = macOS System Voice (System Settings > Accessibility > Spoken Content).
#        Override with CLAUDE_VOICE_NAME="Samantha" (list: say -v '?').

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_CHARS="${CLAUDE_VOICE_MAX_CHARS:-900}" # sentences are never cut mid-way
QUEUE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-voice/queue"

[ -f "$HOME/.claude/voice-muted" ] && exit 0

TEXT=$(python3 "$SCRIPT_DIR/speak-reply.py" "$MAX_CHARS")
[ -z "$TEXT" ] && exit 0

# Test mode: print what would be spoken instead of speaking it.
if [ -n "$SPEAK_DRY_RUN" ]; then echo "$TEXT"; exit 0; fi

# Queue the reply. The file name is the time in nanoseconds, so the oldest reply
# plays first. It is written under a dot name and then renamed, so the player never
# picks up a half-written file.
mkdir -p "$QUEUE_DIR"
STAMP="$(python3 -c 'import time; print(time.time_ns())')-$$"
printf '%s' "$TEXT" > "$QUEUE_DIR/.$STAMP.tmp" && mv "$QUEUE_DIR/.$STAMP.tmp" "$QUEUE_DIR/$STAMP.txt"

# Start a player. If one is already speaking, it exits straight away and the
# running player picks this reply up.
nohup bash "$SCRIPT_DIR/play-queue.sh" >/dev/null 2>&1 &
exit 0
