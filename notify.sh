#!/bin/bash
# Claude Code Notification hook → 转交 claude-notify.py
exec python3 "$(dirname "$0")/claude-notify.py" notification
