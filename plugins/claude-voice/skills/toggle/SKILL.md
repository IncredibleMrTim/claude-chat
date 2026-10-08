---
name: toggle
description: Mute or unmute Claude's spoken replies
disable-model-invocation: true
---

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/voice-toggle.sh"`, then tell the user in one short line whether the voice is now on or muted (check whether `~/.claude/voice-muted` exists: present = muted).
