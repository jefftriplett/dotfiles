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

`moshi-hook install` writes hook configs for supported agent CLIs (Claude Code,
Codex, etc.) so their tool calls route through the local daemon for remote
approval.

## Multi-machine

All three Macs run `moshi-hook` as a Homebrew service. The daemon on each
machine maintains its own WebSocket to Moshi, so approvals for any machine
appear in a single Moshi web session.

To prepare a machine for SSH/Mosh access from Moshi:

```shell
moshi-hook host setup
```

## Useful commands

```shell
moshi-hook serve            # run the daemon in the foreground
moshi-hook logs -f          # tail daemon logs
moshi-hook probe            # check if the daemon is running
moshi-hook context          # print terminal context (tmux/herdr/shell)
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

Repeat on each Mac, or run remotely:

```shell
ssh mac-studio-2023 "brew upgrade moshi-hook && brew services restart moshi-hook"
ssh mba-2025 "brew upgrade moshi-hook && brew services restart moshi-hook"
```
