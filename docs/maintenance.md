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
| `upgrade` | `git pull` the dotfiles, `homesick symlink`, then upgrade Homebrew, mise, the uv Pythons, the uv tools, and the AI CLIs |
| `restart` | restart every Homebrew service that is running |
| `cleanup` | `brew cleanup`; `--days N` prunes the download cache older than N days |

`just upgrade-all` is the smaller variant: it only reinstalls the uv
interpreters and runs `mise install`.

`just outdated` lists what Homebrew would upgrade without doing it.

## Brewfiles

There are three kinds of Brewfile in `home/`:

| File | Purpose |
| ---- | ------- |
| `Brewfile.cog` | Template with cog blocks that dump the current Mac's taps, formulae, casks, and App Store apps |
| `Brewfile` | The generic file `bootstrap` installs from on a fresh Mac |
| `Brewfile.<Hostname>` | What one specific Mac has; one per machine |

`just freeze` (alias `just lock`) is the one to run after you install or
remove something. It overwrites this Mac's file with a fresh dump. Git holds
the previous version, so review the change before you commit:

```shell
just freeze
git diff home/Brewfile.$(hostname -s)
```

`just update-brewfile` regenerates `Brewfile.cog` from this Mac. Use it
rarely: it rewrites the whole template from one machine's state.

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
| `just python::uv-python-install` | Reinstall the interpreter list |
| `just python::uv-tool-install` | Install or, with `--upgrade`, upgrade the tools |

The tool list is in `home/.justfiles/python.justfile`. Add a tool there, not
by hand, so every Mac gets it.

## Languages

`just mise::upgrade` runs `mise install` and `mise reshim`. The versions are
in `home/.config/mise/config.toml`. Python is disabled in mise so it never
competes with uv.

## Leftovers from the Python migration

| Path | Status |
| ---- | ------ |
| `~/.pyenv` | Gone. Removed from all three Macs on 2026-09-03 after uv took over |
| `~/.virtualenvs/` | Kept on purpose. An archive of older environments; `workon` still reads it as a last resort, and two Sublime projects point into it |

Leave `~/.virtualenvs/` alone. Nothing needs to be deleted here any more.
