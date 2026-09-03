# tmux

Session management and key bindings are defined in `home/.tmux.conf` and `home/.bash_tmux`.

## Shell Aliases

| Alias | Command | Description |
| ----- | ------- | ----------- |
| `t` | `tmux` | Run tmux |
| `ta [name]` | `tmux-go` | Attach to or create a named session |
| `tn [name]` | `tmux-new` | Create a new session (attaches if it already exists) |
| `tk [name]` | `tmux-kill` | Kill a named session |
| `tls` | `tmux-ls` | List sessions (add `--json` for machine-readable output) |

`tmux-resume` and `tmux-attach` are thin wrappers that call `tmux-go`. Neither has a short
alias — `tr` would shadow the `tr` coreutils command.

Tab completion for session names is registered on the function names `tmux-go`,
`tmux-resume`, `tmux-attach`, and `tmux-kill`. Bash does not expand an alias before
completing, so the short forms (`ta`, `tk`) do not complete; type the full name when you
want completion.

## Shell Functions

Defined in `home/.bash_tmux`. All of them respect `TMUX_AUTOATTACH_MACHINE`, so they act on
the remote host's tmux when one is set (see [Remote Sessions](#remote-sessions)).

| Function | Description |
| -------- | ----------- |
| `tmux` | Wrapper that runs tmux through `direnv exec /`, so the project `.envrc` does not leak into the server |
| `tmux-new [name]` | Set the terminal title, then attach to or create the session (`new-session -A`) |
| `tmux-go [name]` | Attach to a session; from inside tmux it uses `switch-client` instead of nesting |
| `tmux-resume [name]` | Wrapper for `tmux-go` |
| `tmux-attach [name]` | Wrapper for `tmux-go` |
| `tmux-ls [--json]` | List sessions on the current machine |
| `tmux-kill [name]` | Kill a session by name |

The session name defaults to `$TMUX_AUTOATTACH`, falling back to the current directory's
basename. `:`, `.`, and spaces are replaced with `-`, since tmux forbids the first two in
session names.

`tmux-ls --json` delegates to `tmux-remote-ls` for the one relevant host, so the schema and
string escaping match the fleet-wide command. It cannot be combined with tmux's own
`list-sessions` flags (such as `-F`), which conflict with the fixed format the JSON is
parsed from.

```shell
tmux-ls --json | jq -r '.[0].sessions[] | select(.attached | not) | .name'
```

## Scripts

Standalone executables in `home/bin/` (symlinked onto `$PATH` as `~/bin`).

| Script | Description |
| ------ | ----------- |
| `tmux-host` | Print the pane's remote host when it is running ssh, else the local short hostname. Used by the status bar |
| `tmux-remote-ls` | List tmux sessions across every Mac at once (see also `workon --sessions`) |
| `projects` | Manage the [project registry](projects.md), including the machine list |

`tmux-remote-ls` is roughly `ssh <host> tmux ls` for each machine, but parsed: sessions are
sorted and annotated with attached/detached state, window count, and path.

```console
$ tmux-remote-ls
mac-mini-pro-2023:
  ags  [attached, 1 window]  (unknown)
  thumb-im  [attached, 1 window]  (unknown)
mac-studio-2023:
  default  [detached, 1 window]  (unknown)
```

Hosts come from the `[machines]` table of [`~/Projects/projects.toml`](machines.md) and can be overridden per-run
with `--host` or by setting `$TMUX_REMOTE_HOSTS`. The same list drives `cmux-tmux-sync --all`.
Whichever machine you are sitting at is skipped rather than dialed; `--include-local`
adds it back, querying tmux directly instead of over the network. Hosts are queried
concurrently, so one unreachable machine costs only its own timeout.

Each remote host is queried through cmux's `remote.tmux.sessions` rpc first — one Unix-socket
round trip to the local cmux app, no `ssh` process of our own — falling back to `ssh` when that
fails (cmux not running, host unreachable, or the "Remote tmux" beta setting off for this
account). The `ssh` fallback is a one-shot non-interactive command, matching `tmux-ls` and
`tmux-kill`, with `BatchMode=yes` so a host that would prompt fails fast instead of hanging.
The exit status is 1 when any host could not be reached, which distinguishes "no sessions
anywhere" from "never got an answer".

The rpc path does not report a session's working directory, so its path column prints
`(unknown)`; a session answered by the `ssh` fallback shows the real path instead.
`cmux-doctor` has a "Remote tmux rpc" check that rechecks this gap on every run, in case a
future cmux update fills it in.

| Option | Description |
| ------ | ----------- |
| `--host`, `-H` | Host to query; repeatable, overrides the defaults |
| `--timeout`, `-t` | ssh connect timeout in seconds (default 5) |
| `--include-local` | Also list this machine, run locally rather than over ssh |
| `--sessions-only`, `-s` | Print bare `host:session` lines with no headers, for piping |
| `--json` | Emit JSON instead of text; adds `source` (`local`/`rpc`/`ssh`) and `rpc_fallback_reason` per host |

## Key Bindings

Prefix is `Ctrl-b`.

### Panes

| Action | Key |
| ------ | --- |
| Split horizontally | `prefix + \|` |
| Split vertically | `prefix + -` |
| Navigate left/down/up/right | `prefix + h/j/k/l` |
| Resize left/down/up/right | `prefix + H/J/K/L` (repeatable) |

### Windows

| Action | Key |
| ------ | --- |
| New window (current directory) | `prefix + c` |

### Copy Mode

| Action | Key |
| ------ | --- |
| Enter copy mode | `prefix + [` |
| Start selection | `v` |
| Copy selection to clipboard | `y` |
| Mouse drag | auto-copies to clipboard |

### Misc

| Action | Key |
| ------ | --- |
| Reload config | `prefix + r` |
| Clear screen and scrollback | `prefix + Ctrl-k` |

## direnv Auto-Attach

Add `use tmux` to any project's `.envrc` to automatically attach to (or create) a tmux session when entering that directory:

```shell
# .envrc
use tmux                                          # session name defaults to the directory name
use tmux myproject                                # explicit session name
use tmux myproject --host myserver                # SSH to a remote host's tmux session
use tmux myproject --host myserver --path /home/jeff/projects/myproject     # with a remote start path
```

Set `NO_TMUX_AUTOATTACH=1` to skip auto-attach for a shell session.

## Environment Variables

These variables are exported by `use tmux` in `.envrc` and read by the shell functions in `home/.bash_tmux`. They can also be set manually without direnv.

| Variable | Description |
| -------- | ----------- |
| `TMUX_AUTOATTACH` | Session name to attach to or create on shell startup |
| `TMUX_AUTOATTACH_MACHINE` | SSH hostname to route all tmux commands through |
| `TMUX_AUTOATTACH_HOST` | Alias for `TMUX_AUTOATTACH_MACHINE` |
| `TMUX_AUTOATTACH_PATH` | Working directory passed to `tmux new-session -c` (creation only, not re-attach) |
| `NO_TMUX_AUTOATTACH` | Set to `1` to disable auto-attach for a shell session |

## Remote Sessions

Set `--host` (also accepted: `--machine`, `--profile`) to SSH into a remote host's tmux session instead of the local one. All commands — `tmux-go`, `tmux-ls`, `tmux-kill`, and auto-attach — are routed through `ssh -t` automatically.

```shell
# .envrc
use tmux myproject --host myserver

# With a starting directory on the remote host (only applies when creating a new session)
use tmux myproject --host myserver --path /home/jeff/projects/myproject
```

Requires key-based SSH auth (no password prompt) since the connection is non-interactive.
