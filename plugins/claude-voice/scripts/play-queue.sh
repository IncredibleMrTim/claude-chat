#!/bin/bash
# Speaks queued replies one after another, oldest first, so a new reply waits for
# the one being spoken instead of cutting it off (two `say` processes at once
# sound like slurred, unintelligible speech). speak-reply.sh queues each reply and
# then starts this script; if a player is already running this one exits at once,
# and the running player picks the new reply up.
#
# Stop everything (the current speech and every waiting reply): run silence.sh,
# or send this script a TERM, which is what the space bar helper does.

BASE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-voice"
QUEUE_DIR="$BASE_DIR/queue"
LOCK_DIR="$BASE_DIR/player.lock"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VOICE="${CLAUDE_VOICE_NAME:-}"
RATE="${CLAUDE_VOICE_RATE:-185}"           # words per minute

SAY_PID=""

# mkdir is atomic, so only one player can hold the lock. A lock left behind by a
# player that died (crash, reboot) is stale and gets taken over. A lock with no
# pid yet is treated as held, because its owner is between mkdir and writing it.
take_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then echo $$ > "$LOCK_DIR/pid"; return 0; fi
  local holder
  holder=$(cat "$LOCK_DIR/pid" 2>/dev/null)
  if [ -z "$holder" ]; then
    # Only a lock that has sat without a pid for over a minute can be stale.
    [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1 2>/dev/null)" ] || return 1
  elif kill -0 "$holder" 2>/dev/null && ps -p "$holder" -o command= | grep -q "play-queue"; then
    return 1
  fi
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR" 2>/dev/null && echo $$ > "$LOCK_DIR/pid"
}

# Hush: drop every waiting reply, stop the current one and give the lock back.
stop_all() {
  trap '' TERM INT
  rm -f "$QUEUE_DIR"/*.txt
  [ -n "$SAY_PID" ] && kill "$SAY_PID" 2>/dev/null
  rm -rf "$LOCK_DIR"
  exit 0
}
trap stop_all TERM INT

oldest_reply() {
  local file
  for file in "$QUEUE_DIR"/*.txt; do
    [ -e "$file" ] && { echo "$file"; return 0; }
  done
  return 1
}

# Tapping the space bar cuts speech off. Compiled on first use (and when the source
# changes) so the plugin stays portable; set CLAUDE_VOICE_SPACE_STOP=0 to skip.
# It is given this player's pid and signals it, so one tap clears the whole queue.
start_space_stop() {
  [ "${CLAUDE_VOICE_SPACE_STOP:-1}" = "1" ] || return 0
  local bin="$BASE_DIR/space-stop"
  if [ ! -x "$bin" ] || [ "$SCRIPT_DIR/space-stop.swift" -nt "$bin" ]; then
    swiftc -O "$SCRIPT_DIR/space-stop.swift" -o "$bin" 2>/dev/null
  fi
  [ -x "$bin" ] && nohup "$bin" "$$" >/dev/null 2>&1 &
}

mkdir -p "$QUEUE_DIR"
SPACE_STOP_STARTED=0

while take_lock; do
  if [ "$SPACE_STOP_STARTED" = "0" ]; then
    start_space_stop
    SPACE_STOP_STARTED=1
  fi

  while REPLY_FILE=$(oldest_reply); do
    TEXT=$(cat "$REPLY_FILE")
    rm -f "$REPLY_FILE"
    [ -z "$TEXT" ] && continue
    # Run in the background and `wait`, so a TERM is handled straight away
    # instead of after the sentence finishes.
    if [ -n "$VOICE" ]; then
      say -v "$VOICE" -r "$RATE" "$TEXT" >/dev/null 2>&1 &
    else
      say -r "$RATE" "$TEXT" >/dev/null 2>&1 &
    fi
    SAY_PID=$!
    wait "$SAY_PID"
    SAY_PID=""
  done

  # Give the lock back, then look once more: a reply queued while this player was
  # finishing would otherwise wait for the next reply to start a player.
  rm -rf "$LOCK_DIR"
  oldest_reply >/dev/null || break
done
exit 0
