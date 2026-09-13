# Troubleshooting

Symptoms first, then the cause and the fix.

## A Mac does not answer

`tmux-remote-ls` or `workon --sessions` prints an error for one host and exits
with status 1. The other hosts still report.

1. Check the name resolves: `ssh -o BatchMode=yes <host> hostname`.
2. If ssh asks for a password, the scripts cannot use it. They run with `BatchMode=yes` on purpose, so a host that would prompt fails fast. Fix the key.
3. If the host is asleep, Tailscale cannot wake it. The exit status of 1 is deliberate: it separates "no sessions" from "no answer".
4. Raise the connect timeout with `--timeout` if the network is slow.

Running the command from the machine itself never dials it; that is why
`hostname` must be set in the registry when it differs from the ssh name. See
[Machine List](machines.md).

## ssh-clipboard says passwordless ssh failed

The setup TUI reports that a machine is not reachable without a password,
while `ssh mac-studio-2023` works every day.

The TUI takes machines from Tailscale and dials the full tailnet name, such
as `mac-studio-2023.tail7129b.ts.net`, or the Tailscale IP. A `Host` entry
that only names `mac-studio-2023` does not match, so ssh falls back to the
local user name. That matters here: the Studio's account is not the same as
the account on the other two Macs, and the login fails.

1. Reproduce with the tool's own options: `ssh -T -o BatchMode=yes -o PasswordAuthentication=no <tailnet-name> true`.
2. Add the tailnet name and the IP to the existing `Host` line in `~/.ssh/config` on each Mac, so the `User` line applies to every spelling.
3. Re-run `just ssh-clipboard::setup`.

`~/.ssh/config` is per-machine and is not in the dotfiles. It holds account
names and addresses, and the repository is public.

## Syncthing's log fills the disk

`/opt/homebrew/var/log/syncthing.log` is hundreds of gigabytes, Time Machine
copies it on every run, and the Mac is slow.

The Homebrew service captures Syncthing's stdout into that file with no
rotation, and a folder that fails to sync logs one warning per file per
retry, every hour. `just syncthing::service-install` moves Syncthing to our
LaunchAgent with a rotated log under `~/.local/log/`, truncates the old file,
and excludes it from Time Machine. If a folder still logs thousands of
"no connected device has the required version" warnings, its index holds
stale entries; pause the folder in the Syncthing GUI and reset it from
Actions → Advanced, which rebuilds the index without touching files.

## Tab completion does not show a new project

`workon` completes from a cache at `~/.cache/workon/names`, because starting
`projects` costs about 300 ms and a TAB should not. The cache rebuilds when
the registry, `~/Projects`, `~/Work`, or `~/.virtualenvs` is newer than it.

If a name is still missing, run `workon-refresh`.

## A formula vanished from the Brewfile after `just freeze`

Homebrew's `brew bundle dump` can omit formulae from third-party taps. The
package is still installed.

1. Confirm with `brew list --full-name --formula | grep <name>`.
2. Put the line back in `home/Brewfile.<Hostname>` by hand.


## Pages shows the README

The manual's address serves a rendered README instead of the site.

The repository's Pages source flipped from "GitHub Actions" to the branch
build. In that mode GitHub runs its own Jekyll build on every push, and the
later deployment wins.

1. Open the repository settings, Pages, and set Source to "GitHub Actions".
2. Rerun the Docs workflow: `gh workflow run Docs`.
3. Check: `gh api repos/jefftriplett/dotfiles/pages --jq .build_type` prints `workflow`.

## A Hammerspoon app toggle brings the app forward but never hides it

`toggle_application` looks the app up with `hs.application.find` by name, and
falls back to `launchOrFocus` when nothing is found. Hammerspoon matches on
the name inside the app bundle, which can differ from the folder name in
`/Applications`. Telegram is the known case: the folder is
`Telegram Desktop.app`, the bundle name is `Telegram`.

Test in the Hammerspoon console:

```lua
hs.application.find("Telegram Desktop")   -- nil
hs.application.find("Telegram")           -- hs.application: Telegram
```

Use the bundle name, or the bundle ID from `Info.plist`, to get the full
toggle. Using the folder name gives launch-or-focus only, which may be all you
want.

## `python: command not found`

pyenv used to provide the bare `python` command. Now uv does:

```shell
uv python install --default 3.14
```

That writes `python` and `python3` links into `~/.local/bin`. Open a new shell.
An old shell that still has `~/.pyenv/shims` on its PATH keeps failing until
you do; the shims point at a pyenv that is gone.

## Shift+Enter or Ctrl+Shift+key does nothing inside tmux

tmux drops modifier combinations unless extended keys are on. The config sets:

```tmux
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
```

A tmux server started before that change still has the old value. Reload with
`prefix + r`, or start a new server.

## Clipboard over mosh

Copying in tmux uses OSC 52, which mosh 1.4.0 does not forward. Inside a mosh
session, select with the terminal's own modifier-drag instead. Over plain ssh,
OSC 52 works.

## shellcheck fails in CI but passes locally

CI and `just lint` run the same prek hooks, so a difference means the local
run was skipped or the config changed. Two things to check:

1. `SC1091` ("not following") is excluded in `.pre-commit-config.yaml`. The
   argument is `"--exclude=SC1090,SC1091"` in quotes, because a YAML flow list
   splits at commas without them.
2. A `# shellcheck source=` directive that names a file outside the repository
   makes shellcheck exit 2. Point it at `/dev/null` for files that are
   generated per machine.

## `hs -c 'hs.reload()'` hangs

The `hs` command talks to Hammerspoon over an IPC socket. A reload tears that
socket down mid-call, so the client waits forever. Press `hyper + r` instead,
or wrap the call in `timeout`:

```shell
timeout 5 hs -c 'hs.reload()' || true
```

The reload still happens.

## A Hammerspoon test through `hs -c` shows stale window state

`hs.timer.usleep` inside one `hs -c` call blocks Hammerspoon's run loop, so
window and focus events do not process until the call returns. Issue one
action per `hs -c` call and sleep in the shell between them.
