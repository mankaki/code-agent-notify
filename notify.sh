#!/bin/bash
# Claude Code Notification hook: macOS 原生 banner 通知 + Glass 提示音。
#
# 同一会话内 "waiting for your input" 空闲提醒只响第一次；
# 响应过其他事件后状态重置，下次空闲会再提醒一次。
#
# Dependencies: python3 (macOS 自带), osascript (macOS 自带).

input=$(cat)

IFS=$'\t' read -r SID MSG IS_IDLE <<< "$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    d = {}
msg = (d.get("message") or "Claude needs your attention").replace("\n"," ").replace("\r"," ").replace("\t"," ")
sid = (d.get("session_id") or "default").replace("\t","_")
is_idle = "1" if "waiting for your input" in msg.lower() else "0"
print(f"{sid}\t{msg}\t{is_idle}")
')"

state="/tmp/claude-notify-${SID}.waiting"

if [ "$IS_IDLE" = "1" ]; then
  [ -f "$state" ] && exit 0
  touch "$state"
else
  rm -f "$state"
fi

python3 -c '
import json, sys
print(f"display notification {json.dumps(sys.argv[1])} with title \"Claude Code\" sound name \"Glass\"")
' "$MSG" | osascript 2>/dev/null || true
