# claude-code-notify

Claude Code 在需要你操作或回复完毕时，通过 macOS 系统通知 + 提示音提醒你，防止晾着终端错过。

## 特性

- 权限/选择/空闲等事件 → 右上角 banner + Glass 音
- Claude 回复结束 → banner + Funk 音（Stop hook）
- 同一会话内「waiting for your input」空闲提醒只响**第一次**，不会每 60 秒骚扰；响应其他事件后自动重置

## 依赖

- macOS（`osascript`）
- `python3`（macOS 自带，或 `brew install python`）

## 安装

```bash
# 1. 克隆
git clone https://github.com/mankaki/claude-code-notify.git
cd claude-code-notify

# 2. 放到 ~/.claude/
cp notify.sh stop.sh ~/.claude/
chmod +x ~/.claude/notify.sh ~/.claude/stop.sh

# 3. 合并 hooks 到 ~/.claude/settings.json
#    —— 文件不存在就直接复制 settings.json
#    —— 已有内容（env、model 等）只合并 "hooks" 字段，别整个覆盖
```

合并后大概长这样：

```json
{
  "env": { "...": "..." },
  "model": "opus[1m]",
  "hooks": {
    "Notification": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/notify.sh" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/stop.sh" }] }
    ]
  }
}
```

## 生效

改完 `~/.claude/settings.json` 后**重启 Claude Code CLI**。打开 `/hooks` 菜单只是查看，不会重载磁盘配置。

## 调试

- osascript 的错误写在 `${TMPDIR:-/tmp}/claude-notify.log`
- `claude --debug` 能看到 hook 执行日志
- 去重状态文件：`${TMPDIR:-/tmp}/claude-notify-<session_id>.waiting`，脚本启动时会自动清理 7 天前的

## 调整

- **换提示音**：改 `notify.sh` / `stop.sh` 里的 `Glass` / `Funk`，可选 Basso / Blow / Bottle / Frog / Funk / Glass / Hero / Morse / Ping / Pop / Purr / Sosumi / Submarine / Tink
- **自定义去重**：`notify.sh` 里判断 `waiting for your input` 的那段

## 参考

- [Hooks Guide](https://code.claude.com/docs/zh-CN/hooks-guide)
