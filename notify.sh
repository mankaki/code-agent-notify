#!/bin/bash
# Claude Code Notification hook: macOS notification + sound.
# Permission-style messages additionally pop an AppleScript dialog that
# force-focuses the terminal (click-to-focus on the notification itself
# is broken on macOS 26 because NSUserNotification is deprecated).
#
# Dedup logic: within the same session, the "waiting for your input"
# idle reminder only notifies the first time; subsequent triggers
# (Claude Code re-fires it every ~60s) are silenced. Any other
# notification resets the state so the next idle reminder will notify
# again.
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

case "$TERM_PROGRAM" in
  vscode)          APP_NAME="Visual Studio Code"; APP_BUNDLE="com.microsoft.VSCode" ;;
  cursor)          APP_NAME="Cursor"; APP_BUNDLE="com.todesktop.230313mzl4w4u92" ;;
  iTerm.app)       APP_NAME="iTerm"; APP_BUNDLE="com.googlecode.iterm2" ;;
  WezTerm)         APP_NAME="WezTerm"; APP_BUNDLE="com.github.wez.wezterm" ;;
  ghostty)         APP_NAME="Ghostty"; APP_BUNDLE="com.mitchellh.ghostty" ;;
  Apple_Terminal)  APP_NAME="Terminal"; APP_BUNDLE="com.apple.Terminal" ;;
  *)               APP_NAME="Terminal"; APP_BUNDLE="com.apple.Terminal" ;;
esac

# 图标路径：~/.claude/icon.png 存在就用，否则 dialog 用系统默认
ICON_PATH="$HOME/.claude/icon.png"
if [ -f "$ICON_PATH" ]; then
  ICON_CLAUSE="with icon (POSIX file \"$ICON_PATH\")"
else
  ICON_CLAUSE="with icon note"
fi

# 判断是不是需要人做决定的消息（权限/选择/确认）
NEEDS_DECISION=0
if printf '%s' "$MSG" | grep -qiE "permission|approve|confirm|choose|select|允许|拒绝|确认|选择"; then
  NEEDS_DECISION=1
fi

if [ "$NEEDS_DECISION" = "1" ]; then
  # 后台弹 dialog（不抢焦点），点「去终端处理」后通过 bundle id 激活终端。
  ( osascript <<APPLESCRIPT 2>/dev/null
tell application "System Events"
  set theResult to display dialog $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MSG") with title "Claude Code" $ICON_CLAUSE buttons {"去终端处理"} default button 1 giving up after 120
end tell
if gave up of theResult is false then
  tell application id "$APP_BUNDLE"
    activate
  end tell
end if
APPLESCRIPT
  ) &
else
  # 普通通知：声音 + banner，点击无效但至少有提示音
  python3 -c '
import json, sys
print(f"display notification {json.dumps(sys.argv[1])} with title \"Claude Code\" sound name \"Glass\"")
' "$MSG" | osascript 2>/dev/null || true
fi
