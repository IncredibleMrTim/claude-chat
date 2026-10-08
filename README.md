# claude-voice

Claude Code speaks its replies aloud on macOS, shuts up the moment you send a message, and has a mute toggle. Fully local (macOS `say`), costs no tokens.

## Install (any Mac)

```bash
claude plugin marketplace add IncredibleMrTim/claude-chat   # private repo: needs GitHub access (gh auth login) on that Mac
claude plugin install claude-voice@claude-voice
```

## One-time setup per machine

These live outside the plugin, because plugins can't set them:

1. **Spoken voice:** System Settings > Accessibility > Spoken Content > System Voice. The plugin uses whatever that is. Override with `CLAUDE_VOICE_NAME="Samantha"` (list: `say -v '?'`).
2. **Talking to Claude (optional):** run `/voice tap` in Claude Code. Needs a claude.ai login, microphone permission for your terminal, and `brew install sox` if the built-in recorder can't start. To auto-send, add `"autoSubmit": true` to the `voice` block in `~/.claude/settings.json`.
3. **Python 3** must be on the path (it ships with macOS developer tools).

## Use

- Replies are spoken automatically. Sending a message stops the voice mid-sentence.
- `/claude-voice:toggle` mutes or unmutes (creates/removes `~/.claude/voice-muted`).
- Tuning via env vars: `CLAUDE_VOICE_RATE` (default 185 wpm), `CLAUDE_VOICE_MAX_CHARS` (default 900).

## What gets read out

Code blocks, file paths, URLs, long snippets, markdown marks and emoji are skipped. Short inline snippets like `/voice tap` are read ("slash voice tap").

## Known gap

The voice doesn't stop when you *tap to start dictating*; Claude Code has no hook for that. Only sending a message stops it.
