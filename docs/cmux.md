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
| `cmux-doctor` | Check the tools, socket, config, and hosts these scripts depend on |
| `_cmux.py` | Shared helpers; imported by the above, not run directly |

They keep their files in `~/.config/cmux-tmux/` (`$XDG_CONFIG_HOME` is honored). That is
deliberately not `~/.config/cmux/`, which belongs to the cmux app itself. Files from the
old locations, `~/.config/cmux/session-dump.*` and `~/.config/tmux/hosts.toml`, are moved
into place automatically the first time any of these scripts runs on a Mac.

The two halves work in opposite directions. `cmux-dump-save` / `cmux-dump-restore` treat a
hand-editable file as the source of truth and rebuild workspaces from it. `cmux-tmux-sync` /
`cmux-tmux-watch` treat the running tmux server as the source of truth, so work left behind in a
detached session gets a window back instead of quietly aging out.

## Dump and Restore

```shell
cmux-dump-save          # save open workspaces to ~/.config/cmux-tmux/session-dump.toml
cmux-dump-edit          # edit that file to add host / tmux / session fields
cmux-dump-restore       # recreate any workspace that is not already open
```

The dump defaults to `~/.config/cmux-tmux/session-dump.toml`. All three take an optional
path argument to use another file; a `.json` extension writes or reads JSON. `cmux-dump-restore`
and `cmux-dump-edit` detect the format from the extension and fall back to `session-dump.json`
when no TOML file exists. None of them has other options.

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
cmux-tmux-sync --all                  # every machine in the registry
cmux-tmux-watch                        # keep syncing local sessions as they appear
```

| `cmux-tmux-sync` option | Description |
| ----------------------- | ----------- |
| `--host`, `-H` | Sync sessions from this host; repeatable |
| `--all` | Sync every host in the machine list |
| `--dry-run`, `-n` | Show what would be created |
| `--include-attached` | Also sync local sessions that have a client; remote is unaffected |
| `--timeout`, `-t` | ssh connect timeout in seconds (default 5) |

| `cmux-tmux-watch` option | Description |
| ------------------------ | ----------- |
| `--interval`, `-i` | Seconds between polls (default 5) |
| `--once` | Run a single sync and exit |
| `--max-failures` | Exit 1 after this many consecutive errors (default 5) |

`cmux-tmux-sync` gives a local session a workspace when nothing is attached to it *and* no open
workspace already maps to it. Attached sessions are left alone so opening the new workspace
does not add a second client to a session you are already using; `--include-attached`
overrides that, which is useful when a session is only attached from outside cmux.

## Syncing Across Macs

`--host` (repeatable) and `--all` extend the same idea to the other Macs, using the same ssh
path as `tmux-remote-ls`. The machine list behind `--all` is the one every `cmux-*` and
`tmux-remote-*` script shares: `$TMUX_REMOTE_HOSTS` (space separated) when set, otherwise
the `[machines]` table of [`~/Projects/projects.toml`](machines.md), otherwise the older
`~/.config/cmux-tmux/hosts.toml`. A remote session becomes a workspace that moshes to the host and
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
When a poll fails, say because cmux is not running, it prints the error, backs off, and
gives up with exit 1 after `--max-failures` consecutive errors, so a dead cmux does not
leave it spinning at the poll rate.

Workspaces are matched to sessions by the same slug `cmux-dump-restore` feeds to `tmux
new-session`, so a workspace titled `thumb.im` counts as covering the `thumb-im` session and
is not created twice. Sessions are attached by name rather than by directory, which matters
when two projects share a parent directory.

## Doctor

`cmux-doctor` is the preflight for everything on this page and on the [tmux](tmux.md) one.
It exits non-zero when a required check fails, so a script can run it first.

```shell
cmux-doctor                 # full run, probes every Mac over ssh
cmux-doctor --skip-hosts    # offline: tools, socket, and config only
cmux-doctor --timeout 10    # slower network
```

| Section | What it checks |
| ------- | -------------- |
| Tools | `tmux`, `cmux`, `mosh`, `ssh`, and the status-bar helpers are on `$PATH`, with versions. A missing required tool fails; an optional one warns |
| Socket | The cmux control socket exists and answers. Honors `$CMUX_SOCKET_PATH`, then the app's `last-socket-path`, then the default under `~/.local/state/cmux/`. A closed socket prints the `cmux.json` setting that opens it |
| Config | `~/.config/cmux-tmux/` and the session dump exist |
| Hosts | The machine list parses, this Mac recognizes itself in it, and each remote host answers over ssh, with its tmux session count |
| Remote tmux rpc | Whether cmux's `remote.tmux.sessions` rpc reports a working directory yet. It does not today, which is why the rpc path prints `(unknown)` in `tmux-remote-ls` |
| Summary | Counts of ok, warn, and fail |

| Option | Description |
| ------ | ----------- |
| `--skip-hosts` | Do not probe remote hosts over ssh |
| `--timeout` | Per-host ssh connect timeout in seconds (default 5) |

[cmux]: https://github.com/manaflow-ai/cmux

[uv]: https://github.com/astral-sh/uv
