# ssh-clipboard

[ssh-clipboard][ssh-clipboard] makes the three Macs share one clipboard. Copy on one, paste
on another. A small daemon on each Mac watches the system pasteboard and ships every
representation of a change (text, rich text, images, files) to its peers over persistent
ssh connections. There is no relay and no account; it rides on the same Tailscale ssh
path the [tmux](tmux.md) and [cmux](cmux.md) scripts use.

It is installed from npm, not Homebrew, so it is not in the Brewfiles. `home/Brewfile`
installs `node`, which brings `npm`. The recipes live in
`home/.justfiles/ssh-clipboard.justfile`.

```shell
just ssh-clipboard::install   # npm install -g, then the setup TUI
just ssh-clipboard::status    # daemon and peer status
just ssh-clipboard::monitor   # live dashboard of values and peer health
just ssh-clipboard::setup     # add, verify, or repair peers
just ssh-clipboard::upgrade   # install the latest stable release
```

`just upgrade` runs `ssh-clipboard update` as one of its steps. The daemons also gossip
verified versions to each other, so one updated Mac tends to pull the others along.

## Peers

Setup runs a TUI. It lists the online Macs from Tailscale, verifies a passwordless ssh
connection to each one you pick, installs the binary there over ssh if it is missing, and
starts the per-user launchd service on both ends. The peer list is saved in
`~/.config/ssh-clipboard/config.json` on the Mac where you ran setup; that file is
per-machine and not part of the dotfiles.

The Tailscale list uses full tailnet names such as `mac-studio-2023.tail7129b.ts.net`.
The ssh config on each Mac must match that name. See
[Troubleshooting](troubleshooting.md#ssh-clipboard-says-passwordless-ssh-failed) for why
that matters here.

Connections are made from the Mac that added the peer, and the clipboard flows both ways
over that connection. A Mac that was only *added by* another one has an empty peer list of
its own, which is fine for the pair. To give the two desktops a direct link, run
`just ssh-clipboard::setup` on one of them and pick the other.

| Path | What it is |
| ---- | ---------- |
| `~/.local/bin/ssh-clipboard` | The daemon binary setup installs on each peer |
| `/opt/homebrew/bin/ssh-clipboard` | The npm CLI on a Mac where `npm install -g` ran |
| `~/.config/ssh-clipboard/config.json` | Node name, peers, and the `max_bytes` limit |
| `~/Library/LaunchAgents/dev.ssh-clipboard.plist` | The per-user service |

## Limits

- The whole selection, including metadata, must fit `max_bytes` (256 MiB by default). Raise it on both peers and restart their services for larger file copies.
- Transfers are buffered in memory. Large files work; they are not instant.
- With Apple Screen Sharing, turn off *Edit → Use Shared Clipboard*, or the two clipboards fight.
- The daemon needs the ssh connection to answer without a prompt. It never types a password and cannot answer a 1Password or Touch ID prompt.

[ssh-clipboard]: https://github.com/standardagents/ssh-clipboard
