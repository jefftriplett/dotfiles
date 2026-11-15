# agent-desktop

[agent-desktop](https://agent-browser.dev/desktop) is a desktop automation CLI
for AI agents. It reads a macOS app through the accessibility tree, returns the
controls as JSON with `@ref` IDs, and operates them: click, type, select,
scroll, and so on. It also runs as an MCP server, and it can run inside a local
macOS VM with `agent-desktop sandbox`.

Homebrew installs it. All three Macs have version 1.3.1.

```shell
brew install agent-desktop
agent-desktop version
```

## Permissions

macOS gives permissions to the app that launches `agent-desktop`, not to the
CLI. Each launching app (Ghostty, Herdr, Terminal) needs its own grant, and each
Mac needs its own grants.

| Permission | Needed for |
| ---------- | ---------- |
| Accessibility | every command that reads or operates an app |
| Screen Recording | `screenshot` and session screenshots only |
| Automation | only when a command reports it missing |

```shell
agent-desktop permissions           # show the state, does not prompt
agent-desktop permissions --guide   # open System Settings with a guide
```

The guide opens **System Settings → Privacy & Security → Accessibility** with a
panel that shows which app to add. Drag the launching app into the list and
confirm with Touch ID. The panel then moves to Screen Recording. If System
Settings lists the `agent-desktop` binary as a separate item, turn it on too.

The launching app does not need a restart. The next `agent-desktop` call sees
the new grant.

!!! note

    The guide needs a person at the Mac. It cannot be done over SSH.

## Verify

```shell
agent-desktop status                       # adapter health and permissions
agent-desktop snapshot -i                  # the focused app
agent-desktop snapshot --app Finder -i     # needs an open Finder window
```

Apps that draw their own content, such as Herdr and Ghostty, return only the
window buttons in a snapshot. Use `agent-desktop screenshot` for those. Apps
with standard controls, such as Finder and System Settings, return a full tree.

## Claude Code (MCP)

`agent-desktop mcp` serves every command as an MCP tool over stdio.

```shell
claude mcp add --scope user agent-desktop -- agent-desktop mcp
claude mcp get agent-desktop
```

The user scope makes it available in every project. The entry goes into
`~/.claude.json`, which the repo does not track, so run the command once on each
Mac. The tools load in new Claude Code sessions. To remove it:

```shell
claude mcp remove agent-desktop -s user
```

An agent can also call the CLI directly without the MCP server.

## Guides for agents

The skill docs are compiled into the binary, so they always match the installed
version. An agent reads these first:

```shell
agent-desktop skills list
agent-desktop skills get desktop     # core guide: the snapshot/ref loop
agent-desktop skills get platform    # what differs on macOS
agent-desktop <command> --help       # flags for one command
```

The loop is: take a snapshot, act on a `@ref`, then take a snapshot again to
verify. A return code alone does not prove that an action had an effect.

## Sandbox

`agent-desktop sandbox` runs agent-desktop inside a local macOS VM, so an agent
can operate a desktop that is not the real one. The only provider on macOS is
`macos`.

Requirements:

- An Apple Silicon Mac with macOS 13 or later
- Xcode Command Line Tools for `swiftc` (`xcode-select --install`)

### First setup

```shell
agent-desktop sandbox install          # report each provider, installs nothing
agent-desktop sandbox install macos    # build and sign the VM host and guest agent
agent-desktop sandbox create base --provider macos --set ipsw=latest
agent-desktop sandbox status base      # repeat until setup finishes
agent-desktop sandbox start base       # open the guest in a window
```

`create` downloads and installs macOS in the background. Use
`--set ipsw=<path>` to install from a macOS image that is already on disk. A
failed install reports `broken`, and the reason is in `vm/install.log`.

The first setup needs a person in the guest window:

1. Finish macOS setup and turn on automatic login in
   **System Settings → Users & Groups**.
2. Open Terminal and run `sh "/Volumes/My Shared Files/guest-setup.sh"`.
3. Turn on **agent-desktop-guest** in
   **System Settings → Privacy & Security → Accessibility**. For `screenshot`,
   also turn it on in **Screen & System Audio Recording**.

`agent-desktop sandbox status base` reports `running` when setup is complete.

### Clone and use

Clone the base for real work, so the base stays clean. The source must be
stopped before a clone.

```shell
agent-desktop sandbox stop base
agent-desktop sandbox create work --provider macos --set from=base
agent-desktop sandbox start work
agent-desktop sandbox exec work -- snapshot --app Finder -i
```

`start` runs headless and keeps running until `sandbox stop`. To watch a
sandbox, start it in a window. Closing the window shuts the VM down.

```shell
agent-desktop sandbox start work --window --set title="Review build"
```

### Commands

| Command | What it does |
| ------- | ------------ |
| `sandbox install [provider]` | report what a provider needs, or install it |
| `sandbox create <name> --provider macos` | create a sandbox (`--set ipsw=...` or `--set from=<name>`) |
| `sandbox list` | list every sandbox with its provider and state |
| `sandbox status <name>` | show one sandbox's state and its next command |
| `sandbox start <name>` | start a stopped sandbox, headless by default |
| `sandbox exec <name> -- <args>` | run agent-desktop inside the guest |
| `sandbox stop <name>` | stop a running sandbox |
| `sandbox rm <name>` | remove a stopped sandbox and delete its disk image |

### Recover from needs_setup

`needs_setup` means the guest agent is not answering, Accessibility is off in
the guest, or another process answered in its place. A guest that is slow to
start can report `running` on a later check. Otherwise:

```shell
agent-desktop sandbox stop base
agent-desktop sandbox start base --window
```

Then repeat the three guest steps.

### Limits

- Two macOS VMs can run at once. A third start fails, and `vm/vmhost.log` says
  why.
- `sandbox exec` runs only agent-desktop with the arguments it gets, not a
  shell. It waits at most 300 seconds for one guest command.
- Sandboxes do not isolate the network. All sandboxes on a host share one
  virtual network and can reach the host's network services.
- A sandbox is not a security boundary for untrusted code. Use a separate
  machine for that.
- Creating the first VM from a macOS image is experimental.

### Files and logs

The state root is `~/.agent-desktop/` (`agent-desktop status` shows it). Each
sandbox has its own disk, desktop, and agent-desktop state in
`sandboxes/<name>/`.

| Path | Purpose |
| ---- | ------- |
| `sandboxes/<name>/vm/share/` | the host's build, mounted read-only in the guest |
| `sandboxes/<name>/vm/install.log` | install failures |
| `sandboxes/<name>/vm/vmhost.log` | VM start failures |

## Upgrading

```shell
brew upgrade agent-desktop
```

Repeat on each Mac, or run remotely from another Mac:

```shell
ssh mac-studio-2023 "brew upgrade agent-desktop"
ssh mac-mini-pro-2023 "brew upgrade agent-desktop"
ssh mba-2025 "brew upgrade agent-desktop"
```
