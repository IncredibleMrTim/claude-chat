"""Extracts the opening sentences of Claude's last reply, ready to be spoken.

Reads the Stop-hook JSON on stdin (it contains `transcript_path`), prints the
text to speak on stdout, prints nothing if there's nothing worth saying.
Called by speak-reply.sh.
"""
import json
import re
import sys

MAX_CHARS = int(sys.argv[1]) if len(sys.argv) > 1 else 280


def last_assistant_text(transcript_path):
    last_text = ""
    with open(transcript_path) as transcript:
        for line in transcript:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "assistant":
                continue
            parts = entry.get("message", {}).get("content", [])
            if isinstance(parts, str):
                chunk = parts
            else:
                chunk = " ".join(p.get("text", "") for p in parts if p.get("type") == "text")
            if chunk.strip():
                last_text = chunk
    return last_text


def speakable_inline_code(snippet):
    """Keeps short, human-sounding snippets (`Esc`, `/voice tap`, `● REC · tap`)
    and drops anything that would sound like noise: paths, dotted filenames,
    brackets, assignments and long commands."""
    if len(snippet) > 30 or re.search(r"[./\\()\[\]{}=<>]", snippet.lstrip("/")):
        return ""
    spoken = snippet.replace("/", "slash ", 1) if snippet.startswith("/") else snippet
    return re.sub(r"[^\w\s+:-]", " ", spoken)  # decorative symbols like ● and ·


def clean_for_speech(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)       # code blocks
    text = re.sub(r"`([^`]*)`", lambda m: speakable_inline_code(m.group(1)), text)
    text = re.sub(r"(?<!\w)[~.]?/?[\w.-]+(?:/[\w.\[\]-]+)+/?", "", text)  # bare file paths
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)      # links -> label
    text = re.sub(r"https?://\S+", "", text)                  # bare urls
    text = re.sub(r"[*_#>|]+", "", text)                      # markdown marks
    # Emoji and their joiners/modifiers, so `say` doesn't read out their names.
    text = re.sub("[\U0001F000-\U0001FAFF☀-➿⬀-⯿️‍]", "", text)
    text = re.sub(r"^\s*[-+•]\s+", "", text, flags=re.M) # bullets
    return re.sub(r"\s+", " ", text).strip()


def opening_sentences(text, limit):
    spoken = ""
    for sentence in re.split(r"(?<=[.!?])\s+", text):
        if spoken and len(spoken) + len(sentence) > limit:
            break
        spoken = (spoken + " " + sentence).strip()
        if len(spoken) >= limit:
            break
    return spoken[: limit + 60]


def main():
    try:
        payload = json.load(sys.stdin)
        # The transcript can lag behind when the Stop hook fires, which made the
        # voice read the previous reply. Prefer the message handed to the hook.
        reply = payload.get("last_assistant_message")
        if not reply:
            path = payload.get("transcript_path")
            if not path:
                return
            reply = last_assistant_text(path)
        text = clean_for_speech(reply)
    except (ValueError, OSError):
        return
    if text:
        print(opening_sentences(text, MAX_CHARS))


main()
