# Machine List

The Macs live in the `[machines]` table of the project registry, `~/Projects/projects.toml`
— see [Project Registry](projects.md). Every machine gets a short key you type
(`studio`) and an ssh name that has to resolve (`mac-studio-2023`):

```toml
[machines.studio]
host = "mac-studio-2023"

[machines.air]
host = "mba-2025"
hostname = "MacBook-Air-2025"   # only when it differs from the ssh name
```

`hostname` exists because the machine you are sitting at has to be recognized so it is
skipped rather than dialed. The Air answers to `mba-2025` over ssh but reports
`MacBook-Air-2025` as its own hostname, and without the mapping it would try to reach its
own address.

Names must be resolvable by ssh — Tailscale MagicDNS or a `Host` entry in `~/.ssh/config`.
The short key works anywhere a host does, so `tmux-remote-ls --host studio` and
`cmux-tmux-sync --host studio` both do what you would expect.

`projects machines` edits the table for you, keeping entries sorted:

```shell
projects machines                                     # list what is configured
projects machines add test --host mac-test-2026       # add a machine
projects machines add test --host mac-test-2026 --hostname Mac-Test-2026
projects machines add test --host mac-test-2026 --check   # only add if ssh answers
projects machines remove test                         # refuses while projects point at it
```

Hand-editing is still fine — the command uses a format-preserving TOML writer, so comments
and layout survive a round trip either way.

`$TMUX_REMOTE_HOSTS` (space separated) overrides the table for a single run, and `--host`
overrides both:

```shell
TMUX_REMOTE_HOSTS="mac-studio-2023" tmux-remote-ls
```

`tmux-remote-ls`, `cmux-tmux-sync`, and `cmux-doctor` all read the same table. With nothing
configured and no `--host`, they report what to fix rather than falling back to a built-in
list.

## Migrating from `hosts.toml`

The list used to live in `~/.config/cmux-tmux/hosts.toml` as a flat `hosts = [...]` array
with a separate `[aliases]` table. `projects init` imports it:

```shell
projects init          # reads hosts.toml, writes ~/Projects/projects.toml
projects machines      # rename the keys by hand if you want shorter ones
projects import -n     # then import the projects themselves
```

`hosts.toml` is still read on any machine whose registry has no `[machines]` table, so the
two can coexist while the dotfiles roll out. There is no longer a command to edit `hosts.toml`
— `projects machines` is the one way in, and the fallback exists only so a machine that has
not been migrated yet keeps working.
