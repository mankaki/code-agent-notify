#!/bin/bash
# Claude Code Stop hook: Claude 回复结束时弹通知，并清理 session 的去重状态文件。
set -u

LOG="${TMPDIR:-/tmp}/claude-notify.log"
INPUT=$(cat)

RESULT=$(CLAUDE_HOOK_INPUT="$INPUT" python3 <<'PY'
import json, os, re

try:
    d = json.loads(os.environ.get("CLAUDE_HOOK_INPUT") or "{}")
except Exception:
    d = {}

raw_sid = d.get("session_id") or "default"
sid = re.sub(r"[^A-Za-z0-9_-]", "_", raw_sid)[:64]

tmp = (os.environ.get("TMPDIR") or "/tmp").rstrip("/")
try:
    os.remove(f"{tmp}/claude-notify-{sid}.waiting")
except FileNotFoundError:
    pass

print('display notification "Claude 回复完了" with title "Claude Code" sound name "Funk"')
PY
)

[ -n "$RESULT" ] && echo "$RESULT" | osascript 2>>"$LOG"
exit 0
