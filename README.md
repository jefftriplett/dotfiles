# My Dotfiles

These are my personal dotfiles for macOS development environments. They provide a consistent setup across machines with automated configuration.

The full manual lives in [`docs/`](docs/) and is built with [Zensical](https://zensical.org/).
Run `just docs-serve` to read it locally.

## Key Tools

- [Homebrew][homebrew] for packages, [Homesick][homesick] for the symlinks, [Just](https://github.com/casey/just) for the tasks
- [direnv][direnv] and [Starship][starship] in the shell; [uv][uv] for Python
- [Hammerspoon][hammerspoon] for windows and hotkeys, [Alfred][alfred] for everything else
- tmux and [cmux][cmux] for sessions, with a project registry that spans three Macs

## Installation

1. Install Homesick:
   ```shell
   $ gem install homesick
   ```

2. Clone this repository:
   ```shell
   $ homesick clone jefftriplett/dotfiles
   ```

3. Create the symlinks:
   ```shell
   $ homesick symlink dotfiles
   ```

4. Bootstrap the environment:
   ```shell
   $ just --justfile=./home/justfile bootstrap
   ```

## Manual

| Page | What it covers |
| ---- | -------------- |
| [Overview](docs/index.md) | Key tools, repository layout, inspiration |
| [How the pieces fit together](docs/overview.md) | Which tool owns what, and how a shell, a project, and the Macs connect |
| [Setting up a Mac](docs/setup.md) | The full walk-through for a fresh machine |
| [Daily work](docs/workflows.md) | Task recipes: open, start, list, and kill projects; windows; reloads |
| [Maintenance](docs/maintenance.md) | The update cycle, Brewfiles, lint, the manual, Python and mise upkeep |
| [Troubleshooting](docs/troubleshooting.md) | Symptoms, causes, and fixes |
| [Installation](docs/installation.md) | Install steps and the everyday `just` workflow |
| [Just Recipes](docs/just.md) | Every recipe, generated from the justfiles |
| [Hammerspoon](docs/hammerspoon.md) | Window management, display grid, and application hotkeys |
| [tmux](docs/tmux.md) | Aliases, shell functions, scripts, key bindings, and direnv auto-attach |
| [Project Registry](docs/projects.md) | `workon`, `mkproject`, and `projects` across the Macs |
| [Machine List](docs/machines.md) | The `[machines]` table and how hosts resolve |
| [How workon resolves a project](docs/workon-process.md) | The decision process behind `workon` |
| [cmux Workspaces](docs/cmux.md) | Keeping cmux workspaces and tmux sessions in sync |

```shell
$ just docs-serve    # live preview at http://127.0.0.1:8000/
$ just docs-build    # static site in site/
$ just update-docs   # regenerate the recipe list in docs/just.md
```

## Repository Layout

- `home/`: dotfiles (Brewfile, shell config, app config)
- `home/bin/`: standalone scripts, symlinked onto `$PATH` as `~/bin`
- `home/.justfiles/`: just submodules for task groups
- `docs/`: the manual
- `scripts/`: documentation generation helpers

## Contact / Social Media

Here are a few ways to keep up with me online. If you have a question about this project, please consider opening a GitHub Issue.

[![](https://jefftriplett.com/assets/images/social/github.png)](https://github.com/jefftriplett)
[![](https://jefftriplett.com/assets/images/social/globe.png)](https://jefftriplett.com/)
[![](https://jefftriplett.com/assets/images/social/twitter.png)](https://twitter.com/webology)
[![](https://jefftriplett.com/assets/images/social/docker.png)](https://hub.docker.com/u/jefftriplett/)

[alfred]: https://www.alfredapp.com/
[cmux]: https://github.com/manaflow-ai/cmux
[direnv]: https://direnv.net/
[hammerspoon]: http://www.hammerspoon.org/
[homebrew]: http://brew.sh/
[homesick]: https://github.com/technicalpickles/homesick
[starship]: https://starship.rs/
[uv]: https://github.com/astral-sh/uv
