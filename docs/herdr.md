# herdr

[herdr][herdr] is a terminal workspace manager for AI coding agents. It keeps
workspaces, tabs, and panes in a persistent server, so a session survives when
the terminal closes. It replaces the [tmux](tmux.md) and
[cmux](cmux.md) setups, which are deprecated.

Homebrew installs it on every Mac (`brew "herdr"` in each Brewfile).

## Configuration

herdr keeps its files in `~/.config/herdr/`. The repo does not track that
directory: it also holds sockets, logs, and session snapshots.
`config.toml` is short:

```toml
onboarding = false

[theme]
name = "dracula"
auto_switch = false

[ui.toast]
delivery = "herdr"
```

After an edit, `herdr server reload-config` applies it to the running server.

Ghostty binds `cmd+c` to copy at all times, because herdr owns the mouse and the
default binding can send a bare `c` into the pane. See
`home/.config/ghostty/config`.

## Common commands

```shell
herdr                       # launch or attach to the persistent session
herdr status                # show the client and the server
herdr session list          # list the named sessions
herdr session attach <name> # attach to a named session
herdr server reload-config  # reload config.toml
herdr update                # install the latest version
```

## Machine to machine

herdr connects the Macs over ssh. Each Mac runs its own herdr server. The other
Macs attach to that server, or send API commands to it. The ssh names are the
same names as in the [Machine List](machines.md), and they resolve through
Tailscale MagicDNS or `~/.ssh/config`.

Each remote Mac is a saved machine. The label is the short key from the
machine list, and the target is the ssh name:

```shell
herdr machine add mac-studio-2023 --label studio
herdr machine add mac-mini-pro-2023 --label mini
herdr machine list
```

`herdr machine add` prepares the herdr server on the remote Mac and saves the
entry. The saved machines then show in the herdr sidebar.

To work on another Mac:

```shell
herdr --remote mac-studio-2023 --session default   # attach to the studio session
herdr --machine studio workspace list              # run an API command on studio
herdr machine status                               # check every saved machine
herdr machine reconnect studio                     # log in again and verify
```

If `herdr machine status` says the remote server is stopped, run the
`herdr --remote` command that it prints. That command starts the server again.

## Moshi

[Moshi](moshi.md) works with herdr. `moshi-hook context` finds the herdr
session of the caller, so an agent in a herdr pane reports the correct
session to Moshi.

[herdr]: https://herdr.dev
