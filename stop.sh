#!/bin/bash
# Claude Code Stop hook → 转交 claude-notify.py
exec python3 "$(dirname "$0")/claude-notify.py" stop
