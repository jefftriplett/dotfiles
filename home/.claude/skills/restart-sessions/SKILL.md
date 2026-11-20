---
name: restart-sessions
description: Scan every herdr terminal on this Mac and on all connected machines for Claude Code sessions that show "✔ Update installed · Restart to update" (or "/restart to apply"), run /restart in each one, and report the ones that could not restart. Use when asked to "restart our sessions", "run /restart everywhere", or "scan sessions with the Restart to update status".
---

# Restart outdated Claude Code sessions

The decision comes from the screen, not from a version check. A session gets `/restart` only when its screen shows `✔ Update installed · Restart to update` (older builds show `/restart to apply`). The script does not touch other terminals.

## Run

```bash
~/.claude/skills/restart-sessions/restart.sh --dry-run   # list only, sends no keys
~/.claude/skills/restart-sessions/restart.sh             # send /restart and verify
```

The script looks at two places:

- **hc (herdr-core) terminals:** `hc ls --json` lists this Mac and each connected machine. The script reads every live terminal, also `bash` terminals, because Claude can run inside a shell that hc does not detect.
- **Herdr panes:** `herdr pane list` runs on this Mac and on each reachable machine from `herdr machine status`. The script skips a pane that attaches to an hc terminal, because it shows the same session.

For each terminal with the status, the script does these steps:

1. It skips this session (`$HC_TERMINAL_ID`) and sessions that work (`working` status or `esc to interrupt` on screen).
2. It types `/restart` as keys. Do not use `hc send` for a slash command, because it wraps the text in `<hc from=...>` and the session spends a model turn.
3. It reads the input line back. If the line is not exactly `❯ /restart`, the prompt had a draft. The script deletes the 8 typed characters and skips the session. A dim prompt suggestion is not a draft, because typing replaces it.
4. It presses Enter.

After `WAIT` seconds (default 20), the script reads each terminal again and classifies the text after the last `❯ /restart`.

## Report

The output has one tab-separated line for each session with the status:

- `RESTARTED`: the screen shows `Successfully updated from X to version Y`.
- `FAILED`: the session refused `/restart`. The reason is in the last column.
- `SKIPPED`: the script did not send `/restart`. The reason is in the last column.

Give the user a list of the restarted sessions and a separate table of the sessions that could not restart. Include the reason and the fix for each one:

| Reason | Fix |
|---|---|
| Remote Control connected | Exit, start `claude` again, then `/resume`. |
| wrong directory | Exit, `cd` to the directory in the message, then `claude --resume`. |
| old version: no /restart | Exit and `claude --resume` (2.1.316 and older). |
| this session | Run `/restart` here when the work is done. |
| working | Run the script again when the session is idle. |
| draft text in the prompt | Send or clear the draft, then run the script again. |
| machine not connected / unreachable | `hc machine login <m>` or `herdr machine reconnect <m>`. |
| no result yet | Read the terminal with `hc read <t>` or `herdr --machine <m> pane read <id>`. |

Do not kill a session to force a restart. `/restart` keeps the same PID, so compare the screen text, not PIDs.
