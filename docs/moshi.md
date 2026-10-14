# Moshi

[Moshi](https://moshi.sh/) is the remote approval and hook system that lets you
monitor and approve AI agent actions from a phone or another device. It pairs
with `moshi-hook`, a local daemon that bridges agent CLIs (Claude Code, Codex,
etc.) to Moshi's web interface via a WebSocket.

## Components

| Binary | Installed via | Purpose |
| ------ | ------------- | ------- |
| `moshi` | `brew install rjyo/moshi/moshi-hook` | Opens the local web client; `moshi .` opens/attaches a tmux session |
| `moshi-hook` | same formula | Daemon + CLI for hook installation, pairing, and the local socket bridge |

Both binaries come from the same Homebrew formula (`rjyo/moshi/moshi-hook`).

## Setup

Pair each Mac once, then install hooks and start the daemon:

```shell
moshi-hook pair --token <PAIRING_TOKEN>
moshi-hook install
brew services start moshi-hook
```

Get the `<PAIRING_TOKEN>` from the Moshi iPhone app under
**Settings → Integrations**. The token is reusable (account-level), so the same
one pairs every Mac. Pairing stores a host secret; the host ID lands in a plain
`host.json` beside it so SSH sessions can read it.

`moshi-hook install` writes hook configs for every supported agent CLI it finds
(Claude Code, Codex, OpenCode, Gemini, Antigravity, Cursor, Copilot, Goose, and
others) so their tool calls route through the local daemon for remote approval.
Agents that were already running when hooks change must be restarted, since each
reads its hook config only at startup.

### Pairing on a headless / SSH session

The secret defaults to the macOS Keychain, which a non-interactive SSH shell
cannot unlock (`User interaction is not allowed`). Pair with the file store
instead when running over SSH:

```shell
moshi-hook pair --token <PAIRING_TOKEN> --name <HOSTNAME> --store file
```

All three Macs are paired with `--store file`. To move a pairing back into the
Keychain, re-run `moshi-hook pair` from an interactive Terminal on that Mac
(without `--store file`).

## Multi-machine

All three Macs run `moshi-hook` as a Homebrew service. The daemon on each
machine maintains its own WebSocket to Moshi, so approvals for any machine
appear in a single Moshi web session.

To prepare a machine for SSH/Mosh access from Moshi:

```shell
moshi-hook host setup
```

## Diagnostics

`moshi-hook doctor` checks a host feature by feature and says what to fix. It
reports the daemon and gateway, the multiplexers (tmux/herdr), per-agent hook
status, pairing, and a table of what works (agent inbox, Chat View, Workspaces,
session picker, diff viewer, browser preview, usage).

```shell
moshi-hook doctor          # full report with fix suggestions
moshi-hook doctor --json   # machine-readable, no prompts
moshi-hook doctor --yes    # apply the suggested fixes without asking
```

### Codex shared background server

Codex 0.157+ runs every session inside one shared background server
(`daemon_auto_start`), so Moshi cannot tell Codex sessions apart and
Chat View, replies, and approvals can land on the wrong terminal. `doctor`
detects this; `moshi-hook doctor --yes` sets `daemon_auto_start = false` in
`~/.codex/config.toml` and stops the background server. Restart any Codex
sessions that were using it afterward.

## Useful commands

```shell
moshi-hook serve            # run the daemon in the foreground
moshi-hook doctor           # check the host feature by feature
moshi-hook logs -f          # tail daemon logs
moshi-hook probe            # check if the daemon is running
moshi-hook context          # print terminal context (tmux/herdr/zellij/shell)
moshi-hook cwd-list         # list recent agent working directories
moshi-hook diff             # open a local Git diff viewer
moshi-hook servers          # probe local HTTP servers (SSH preflight)
brew services restart moshi-hook   # restart after an upgrade
```

## Upgrading

```shell
brew trust rjyo/moshi       # needed once after the tap's trust policy changed
brew upgrade moshi-hook     # upgrades both moshi and moshi-hook
brew services restart moshi-hook
```

Repeat on each Mac, or run remotely from another Mac:

```shell
ssh mac-studio-2023 "brew upgrade moshi-hook && brew services restart moshi-hook"
ssh mac-mini-pro-2023 "brew upgrade moshi-hook && brew services restart moshi-hook"
ssh mba-2025 "brew upgrade moshi-hook && brew services restart moshi-hook"
```

After a large version jump, re-run `moshi-hook install` to refresh agent hooks
and `moshi-hook doctor` to confirm the host is healthy.
