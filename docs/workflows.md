# Daily work

Task-first recipes. Each one names the page with the full reference.

## Open a project

1. Type `workon <name>`. Names match loosely, so `thumb.im` and `thumb-im` both work.
2. If the project is on this Mac or has no machine recorded, you are now in its directory with the venv active.
3. If it lives on another Mac, `workon` runs `mosh` there and, when the entry has `tmux = true`, attaches its session.

Add `--tmux` to attach a session for a project that normally does not use one.
Add `--local` or `--remote` to override the registry for one run. Details in
[Project Registry](projects.md).

## Start a new project

1. Run `mkproject <name>`. Add `--work` for `~/Work`, `--tmux` for a tmux session, `--machine studio` to record an owner.
2. `mkproject` creates the directory, a uv venv, and an `.envrc` with `layout uv` and, with `--tmux`, `use tmux`.
3. It registers the project and opens it.

The directory reaches the other Macs through Syncthing within a minute. The
venv does not travel; direnv rebuilds it on first entry. Use `--no-attach` to
create without opening, `--dry-run` to see the commands without running them,
and `--path DIR` for a location outside `~/Projects` and `~/Work`.

## See what is running everywhere

1. Run `workon --sessions` (or `workon -s`).
2. Read the right-hand column. It is the exact `workon` command that opens each session.

Filters: `-a` for attached sessions only, `-m studio` for one Mac, `--names`
for bare names to pipe into `fzf`:

```shell
workon -s --names | fzf | xargs workon
```

`tmux-remote-ls` answers the lower-level question of which sessions exist,
with window counts and paths. See [tmux](tmux.md#scripts).

## Kill a session, wherever it is

1. Run `workon -s --kill <name>`. The name can be the project key or the tmux session name.
2. Read the confirmation. It shows the Mac, the window count, and the directory.
3. Answer `y`, or pass `--yes` to skip the prompt.

If the name matches sessions on more than one Mac, the command refuses and
tells you. Pick the Mac with `-m`.

## Work on another Mac

1. Check the machine is registered: `projects machines`.
2. Open the project with `workon <name> --host studio`. That is a `mosh` to `mac-studio-2023` in the project directory.
3. For a session that should stay there, set it in the registry once: `projects set <name> --machine studio --tmux`.

A project with no machine opens wherever you are, which is the right answer
for anything Syncthing mirrors. See [Machine List](machines.md) for how names
resolve.

## Keep cmux workspaces in step with tmux

1. `cmux-tmux-sync --dry-run` shows which detached local sessions have no workspace.
2. `cmux-tmux-sync` creates them. Add `--all` to include the other Macs as mosh workspaces.
3. `cmux-tmux-watch` keeps doing this on a five-second interval.

To save the current layout, `cmux-dump-save` writes
`~/.config/cmux/session-dump.toml`; `cmux-dump-restore` rebuilds it, skipping
workspaces that already exist. See [cmux Workspaces](cmux.md).

## Arrange windows

| Want | Press |
| ---- | ----- |
| Half screen | `hyper + arrow` |
| Quarter screen | `ctrl + opt + shift + arrow` |
| Next or previous monitor | `ctrl + opt + right/left` |
| Maximize, center, snap back | `hyper + m`, `hyper + c`, `hyper + z` |
| Show the grid | `hyper + g` |
| Toggle an app | `hyper + letter`, see the table in [Hammerspoon](hammerspoon.md) |
| Fix the 2x2 monitor layout | `hyper + f` |

`hyper` is `ctrl + opt + cmd`.

## Reload a config after editing it

| Config | How |
| ------ | --- |
| tmux | `prefix + r` inside tmux, or start a new server |
| Hammerspoon | `hyper + r` |
| Shell | open a new shell; the files are symlinks, so there is nothing to copy |
| direnv | `direnv allow` in the project after editing its `.envrc` |
| Registry | nothing; `workon` reads `projects.toml` on every call and the completion cache refreshes itself |

## Copy text out of tmux

Select with the mouse, or `v` then `y` in copy mode. The text goes to the
system clipboard through OSC 52, on every Mac and over ssh. Over mosh it does
not; use the terminal's own modifier-drag there. See
[Troubleshooting](troubleshooting.md#clipboard-over-mosh).
