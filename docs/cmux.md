# cmux Workspaces

Scripts in `home/bin/` that keep [cmux][cmux] workspaces and tmux sessions in sync. They are
[uv][uv] inline-script executables — the dependency headers mean they run straight from
`$PATH` with no virtualenv to manage.

| Script | Description |
| ------ | ----------- |
| `cmux-dump-save` | Save the open workspaces to a dump file |
| `cmux-dump-restore` | Recreate workspaces from a dump file |
| `cmux-dump-edit` | Open the dump file in `$EDITOR` |
| `cmux-tmux-sync` | Give unattached tmux sessions a workspace, once; `--host`/`--all` to cover the other Macs |
| `cmux-tmux-watch` | Same as sync, but polling continuously |
| `_cmux.py` | Shared helpers; imported by the above, not run directly |

The two halves work in opposite directions. `cmux-dump-save` / `cmux-dump-restore` treat a
hand-editable file as the source of truth and rebuild workspaces from it. `cmux-tmux-sync` /
`cmux-tmux-watch` treat the running tmux server as the source of truth, so work left behind in a
detached session gets a window back instead of quietly aging out.

## Dump and Restore

```shell
cmux-dump-save          # save open workspaces to ~/.config/cmux/session-dump.toml
cmux-dump-edit          # edit that file to add host / tmux / session fields
cmux-dump-restore       # recreate any workspace that is not already open
```

The dump defaults to `~/.config/cmux/session-dump.toml`; pass a path to use another file, or
`--json` to write JSON. `cmux-dump-restore` and `cmux-dump-edit` detect the format from the extension
and fall back to `session-dump.json` when no TOML file exists.

cmux cannot report whether a workspace is running mosh or tmux, so `host`, `tmux`, and
`session` are hand-added. Re-dumping preserves them by matching on title, and keeps annotated
entries whose workspaces have since been closed, so closing a workspace does not lose its
config. Writes are atomic, so an interrupted dump cannot corrupt those hand-edited fields.

| Field | Description |
| ----- | ----------- |
| `title` | Workspace title; also the default tmux session name |
| `cwd` | Working directory |
| `color` | Custom workspace color |
| `pinned` | Whether the workspace is pinned |
| `description` | Workspace description |
| `host` | Host to mosh to; treated as local if it matches this machine |
| `tmux` | Attach a tmux session in the workspace |
| `session` | Explicit tmux session name, overriding the title-derived one |

```toml
[[workspaces]]
title = "thumb.im"
cwd = "/Users/jefftriplett/Projects/thumb.im/thumb.im-git"
host = "mac-mini-pro-2023"
tmux = true
```

The last three fields combine to decide where a workspace runs:

| Fields | Result |
| ------ | ------ |
| `host` + `tmux = true` | mosh to the host and attach a tmux session there, started in `cwd` |
| `host` only | plain mosh to the host |
| `tmux = true` only | attach a local tmux session, started in `cwd` |
| neither | plain local workspace |

Restoring is safe to rerun: workspaces whose title already exists are skipped, and tmux
sessions use `new-session -A`, so a restore resumes an existing session rather than
duplicating it. Remote workspaces get a `[mosh] ` label on the cmux title; it is display-only
and never reaches the remote tmux session name.

## Sync and Watch

```shell
cmux-tmux-sync --dry-run              # show which local sessions would get a workspace
cmux-tmux-sync                        # create the missing workspaces
cmux-tmux-sync --host mac-studio-2023 # sync that Mac as mosh workspaces
cmux-tmux-sync --all                  # every host in hosts.toml
cmux-tmux-watch                        # keep syncing local sessions as they appear
```

`cmux-tmux-sync` gives a local session a workspace when nothing is attached to it *and* no open
workspace already maps to it. Attached sessions are left alone so opening the new workspace
does not add a second client to a session you are already using; `--include-attached`
overrides that, which is useful when a session is only attached from outside cmux.

## Syncing Across Macs

`--host` (repeatable) and `--all` extend the same idea to the other Macs, using the same ssh
path as `tmux-remote-ls`. A remote session becomes a workspace that moshes to the host and
attaches there, exactly like a `host` + `tmux = true` entry in the dump file.

The unattached test does not carry over. A session on the mini reads as attached because a
workspace *on the mini* holds it, which says nothing about whether this machine can see it —
so a remote session gets a workspace when none here already points at it, regardless of who
else has it open. Remote workspaces are titled `host:session`, so the same session name on two
Macs stays distinct. A host that cannot be reached prints an error and the remaining hosts
still run.

Because most remote sessions *are* attached on their own machine, opening a synced workspace
adds a second client to a live session. With `window-size latest` (the tmux default, and what
these Macs run) the window resizes to whichever client was most recently active, so the other
Mac's view changes size while you work in it. That is the tradeoff for seeing every session
from one place.

`cmux-tmux-watch` polls on an interval (`--interval`, default 5s) and covers both attached and
detached sessions — its only requirement is that no workspace already covers the session. It is
local-only; use `cmux-tmux-sync --all` for the other Macs. Use `--once` for a single pass.

Workspaces are matched to sessions by the same slug `cmux-dump-restore` feeds to `tmux
new-session`, so a workspace titled `thumb.im` counts as covering the `thumb-im` session and
is not created twice. Sessions are attached by name rather than by directory, which matters
when two projects share a parent directory.

[cmux]: https://github.com/manaflow-ai/cmux

[uv]: https://github.com/astral-sh/uv
