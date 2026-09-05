# Setting up a Mac

This is the order for a fresh machine. Each step depends on the one before it.
The short version in [Installation](installation.md) covers steps 3 to 5.

## 1. Xcode command line tools

Homebrew and git need them.

```shell
xcode-select --install
```

`just macos::xcode-bootstrap` runs the same command once `just` exists.

## 2. Homebrew

Install Homebrew from [brew.sh](https://brew.sh/). On Apple silicon it lands
in `/opt/homebrew`, which the shell config already puts on the PATH.

Install the two tools the next steps need:

```shell
brew install just
gem install homesick
```

## 3. Clone and link the dotfiles

```shell
homesick clone jefftriplett/dotfiles
homesick symlink dotfiles
```

`homesick symlink` links every entry under `home/` into `~`. Folders listed in
`.homesick_subdir`, such as `.config` and `Library/Application Support`, are
not linked whole; their children are linked one by one, so other apps can keep
writing their own files next to yours.

Open a new shell after this step. The prompt and the shell functions come from
the linked files.

### Configure Git identity

Git's shared settings are linked to `~/.config/git/config`. Identity and
signing values are intentionally kept outside this repository in
`~/.config/git-private/config`. On a new machine, create the private file from
the value-free example:

```shell
mkdir -p ~/.config/git-private
cp ~/.config/git/private.example ~/.config/git-private/config
chmod 600 ~/.config/git-private/config
${EDITOR:-nano} ~/.config/git-private/config
```

Confirm that Git sees the private values before making a commit:

```shell
git config --show-origin --name-only --get-regexp '^(user|github)\.'
git var GIT_AUTHOR_IDENT
```

## 4. Bootstrap

```shell
just --justfile=./home/justfile bootstrap
```

From then on `~/justfile` is linked, so plain `just <recipe>` works from any
directory. The recipe does this, in order:

| Step | What it runs | Result |
| ---- | ------------ | ------ |
| homesick | `gem install homesick`, `homesick symlink` | Links refreshed |
| Homebrew | `brew bundle install` from `Brewfile.<Hostname>` when it exists, else the generic `Brewfile` | Formulae, casks, and App Store apps |
| Xcode | `just macos::xcode-bootstrap` | Command line tools, if still missing |
| mise | `mise install` for go, node, ruby, rust, then `mise reshim` | Language runtimes |
| Python | `just python::bootstrap` | See below |

`python::bootstrap` installs the uv-managed interpreters (3.10 to 3.14), runs
`uv python install --default 3.14` so `python` and `python3` exist in
`~/.local/bin`, and installs the CLI tools with `uv tool install`.

!!! note
    The generic `home/Brewfile` is only the starting point for a Mac that has
    no per-host file yet. The per-host files, `home/Brewfile.<Hostname>`, are
    what each Mac really has, and `bootstrap` prefers them. Step 9 creates
    this Mac's own file.

## 5. Tailscale and ssh names

Every other Mac must be reachable by name. Install Tailscale, sign in, and
confirm MagicDNS resolves the others:

```shell
ssh -o BatchMode=yes mac-studio-2023 hostname
```

If a name does not resolve, add a `Host` entry in `~/.ssh/config`. Key-based
auth is required. The scripts never type a password.

## 6. Register the machine

The registry lives in `~/Projects/projects.toml`. If this Mac does not have it
yet, Syncthing brings it over in step 7, so do this step after Syncthing has
finished its first sync. Then add the machine:

```shell
projects machines add air --host mba-2025 --hostname MacBook-Air-2025 --check
```

`--hostname` is needed only when the machine's own `hostname` differs from its
ssh name. Without it, the machine would try to ssh to itself. `--check`
refuses to add a host that does not answer. See [Machine List](machines.md).

## 7. Syncthing

Install Syncthing from the Brewfile, then share `~/Projects` and `~/Work` with
the other Macs. `home/.stignore` is linked into `~` and holds the global ignore
patterns; each project can add its own `.stignore`. Virtualenvs are ignored,
which is why a project's `.venv` is rebuilt on each Mac the first time you
enter the directory.

## 8. tmux plugins

The plugin manager is not in the repository. Clone it, then install the
plugins from inside tmux:

```shell
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start tmux and press `prefix + I` (capital i). That installs tmux-sensible and
the Dracula theme named in `~/.tmux.conf`.

## 9. Freeze this Mac's Brewfile

After the apps you want are installed:

```shell
just freeze
```

This writes `home/Brewfile.<Hostname>`. Commit it. See [Maintenance](maintenance.md) for the caveat about tap
formulae.

## 10. Hammerspoon

Open Hammerspoon once. macOS asks for Accessibility permission; grant it in
System Settings, otherwise no hotkey can move a window. The config is already
linked at `~/.hammerspoon`. Press `hyper + r` to reload it after changes. The
hotkeys are listed in [Hammerspoon](hammerspoon.md).

If this Mac drives the 2x2 monitor grid, press `hyper + 9` to dump the screen
UUIDs to the console and copy them into `display_grid.lua`.

## 11. Optional: default apps

`just macos::duti-setup` installs `duti` and sets the default app for a list
of file types.

## 12. Screenshots

`just macos::screenshots-setup` points macOS at `~/Screenshots` for new
screenshots. The Desktop is one iCloud folder shared by every Mac, so a
screenshot saved there shows up on all of them; `~/Screenshots` is local to
each machine. `just macos::screenshots-sweep` moves any screenshots that
still landed on the Desktop into `~/Screenshots` without overwriting.

## 13. Optional: Sublime Text settings

The preferences and the Package Control package list live in
`home/.config/sublime-text/`. `just macos::sublime-link` symlinks them into
`~/Library/Application Support/Sublime Text/Packages/User/`. The recipe never
overwrites a real file that is already there; `just macos::sublime-diff`
shows what differs, so you can merge by hand and rerun the link.

For a machine that needs different values, add
`Preferences.<Hostname>.sublime-settings` next to the shared file with only
the keys that differ, such as a font size. The recipe then writes a generated
preferences file for that machine instead of a link, with the overlay applied.

## Verify

```shell
python --version            # 3.14.x from ~/.local/bin
mise ls                     # go, node, ruby, rust present
just --list                 # recipes resolve
tmux-remote-ls              # the other Macs answer
workon                      # lists registered projects
just lint                   # every hook passes
```

If `workon` lists nothing, the registry has not synced yet or the machine is
not in it. `projects machines` shows what the registry knows.
