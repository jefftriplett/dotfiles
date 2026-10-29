# Maintenance

The upkeep is a small number of `just` recipes. This page says what each one
touches, so you can run the right one.

## The update cycle

```shell
just update
```

`update` runs three recipes in order:

| Recipe | What it does |
| ------ | ------------ |
| `upgrade` | `git pull` the dotfiles, `homesick symlink`, then upgrade Homebrew, mise, the uv Pythons, the uv tools, the AI CLIs, ssh-clipboard, and the tmux plugins; finally `just freeze` |
| `restart` | restart every Homebrew service that is running; Syncthing is not one of them, use `just syncthing::restart` |
| `cleanup` | `brew cleanup`; `--days N` prunes the download cache older than N days |

`just upgrade-all` is the smaller variant: it only reinstalls the uv
interpreters and runs `mise install`.

`just outdated` lists what Homebrew would upgrade without doing it.

To free disk space, preview with `just mole::preview` first. See [Mole](mole.md).

## Brewfiles

There are two kinds of Brewfile in `home/`:

| File | Purpose |
| ---- | ------- |
| `Brewfile` | The generic file `bootstrap` installs from on a fresh Mac |
| `Brewfile.<Hostname>` | What one specific Mac has; one per machine |

`just freeze` (alias `just lock`) is the one to run after you install or
remove something; `just upgrade` also runs it at the end. It overwrites this Mac's file with a fresh dump. Git holds
the previous version, so review the change before you commit:

```shell
just freeze
git diff home/Brewfile.$(hostname -s)
```

!!! warning "Dump omits tap formulae"
    Homebrew 6 `brew bundle dump` can leave out formulae that come from
    third-party taps. A formula such as `oven-sh/bun/bun` disappears from the
    file while it stays installed. Before you treat a missing line as a
    removal, check `brew list --full-name --formula`.

## Lint

```shell
just lint
```

This runs every hook in `.pre-commit-config.yaml` through prek: whitespace and
end-of-file fixes, YAML, TOML, and JSON syntax, executable bits, shellcheck on
the bash files, ruff on the Python scripts, and `just --fmt --check` on every
justfile. The CI workflow runs the same command on every push, so a failure
there is a failure you can reproduce locally.

To run the hooks on every commit as well, run `uvx prek install` once in the
repository.

`just fmt` formats the justfiles in place. Run it before `just lint` when the
format check fails.

## The manual

| Recipe | What it does |
| ------ | ------------ |
| `just docs-serve` | Live preview at `http://127.0.0.1:8000/` |
| `just docs-build` | Static site into `site/`, which git ignores |
| `just update-docs` | Regenerate the recipe list in `docs/just.md` with cog |

The Docs workflow builds and deploys the site on every push to `main`. It
publishes through a GitHub Pages artifact, not a branch. The repository's
Pages source must stay on "GitHub Actions"; if it flips to the branch build,
GitHub renders the README instead. See
[Troubleshooting](troubleshooting.md#pages-shows-the-readme).

Run `just update-docs` after you add or rename a recipe, and commit the
result. Zensical's config is `zensical.toml` at the repository root; it has to
stay there, because Zensical treats the config's folder as the project root.

## Python

uv owns Python. The recipes are in the `python` module:

| Recipe | What it does |
| ------ | ------------ |
| `just python::bootstrap` | Install the interpreters, set 3.14 as `python`, install the CLI tools |
| `just python::upgrade` | Upgrade the interpreters in place and the CLI tools |
| `just python::uv-python-install` | Install 3.11 to 3.15; a version already installed is skipped |
| `just python::uv-tool-install` | Install or, with `--upgrade`, upgrade the tools |

The tool list is in `home/.justfiles/python.justfile`. Add a tool there, not
by hand, so every Mac gets it.

### Python versions

Every Mac keeps one uv install of each version: the newest patch release. On
2026-10-12 all three Macs had the same set:

| Version | Patch | Command in `~/.local/bin` | Installed by |
| ------- | ----- | ------------------------- | ------------ |
| 3.15 | 3.15.0 | `python3.15` | `uv-python-install` |
| 3.14 | 3.14.8 | `python3.14`, `python` | `uv-python-install`; `bootstrap` makes it the default |
| 3.13 | 3.13.16 | `python3.13` | `uv-python-install` |
| 3.12 | 3.12.15 | `python3.12` | `uv-python-install` |
| 3.11 | 3.11.17 | `python3.11` | `uv-python-install` |
| 3.15 free-threaded | 3.15.0 | `python3.15t` | by hand: `uv python install 3.15t` |
| 3.14 free-threaded | 3.14.8 | `python3.14t` | by hand: `uv python install 3.14t` |

3.10 and older are gone. Do not install them again.

Homebrew also installs Python 3.12 to 3.14 in `/opt/homebrew/bin`, because
other formulae need them. `~/.local/bin` comes last on the PATH, so `python3`
and `python3.14` find the Homebrew copy first. Only `python` always finds the
uv copy.

To see what is installed:

```shell
uv python list --only-installed --managed-python
uv python dir      # where uv keeps them
```

To move to new patch releases and drop the old ones:

1. Run `just python::uv-pip-upgrade`. It runs `uv python upgrade`, which
   installs the newest patch of each version and moves the links.
2. `uv python upgrade` skips the free-threaded builds. Install those by full
   version, for example `uv python install 3.14.8+freethreaded`.
3. Remove each old patch by its key, for example
   `uv python uninstall cpython-3.14.7-macos-aarch64-none`.
4. Do the same on each Mac.

A project `.venv` points to the exact patch release that made it. When that
release is removed, the `.venv` stops working. Run `uv sync` in the project to
make a new one. For a uv tool, run `uv tool install --reinstall <tool>`.

## Languages

`just mise::upgrade` runs `mise install`, then `mise prune` to drop versions the config no longer names, then `mise reshim`. The versions are
in `home/.config/mise/config.toml`. Python is disabled in mise so it never
competes with uv.

## Leftovers from the Python migration

| Path | Status |
| ---- | ------ |
| `~/.pyenv` | Gone. Removed from all three Macs on 2026-09-03 after uv took over |
| `~/.virtualenvs/` | Kept on purpose. An archive of older environments; `workon` still reads it as a last resort, and two Sublime projects point into it |

Leave `~/.virtualenvs/` alone. Nothing needs to be deleted here any more.
