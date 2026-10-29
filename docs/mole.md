# Mole

[Mole](https://github.com/tw93/Mole) cleans and inspects a Mac from the
terminal. It finds caches, logs, old project build files, and installer
downloads, and shows what is using disk space. The command is `mo` (`mole` also
works).

## Install

Every Mac gets the formula from its Brewfile:

| Mac | Brewfile lines |
| --- | -------------- |
| Mac Studio | `brew "mole"` |
| Mac Mini | `brew "mole"` |
| MacBook Air | `brew "mole"` and `cask "mole-app"` (the menu bar app) |

`just mole::update` runs `brew upgrade mole`. Mole has its own `mo update` as
well, but let Homebrew own the upgrade so the Brewfile stays true.

## Recipes

The recipes are in the `mole` module, `home/.justfiles/mole.justfile`:

| Recipe | What it does |
| ------ | ------------ |
| `just mole::preview` | Runs `clean` and `purge` with `--dry-run`; changes nothing |
| `just mole::clean-preview` | `mo clean --dry-run` |
| `just mole::clean` | Removes caches, logs, and leftovers from apps that are gone |
| `just mole::purge-preview` | `mo purge --dry-run` |
| `just mole::purge` | Removes old project build files |
| `just mole::installers` | Lists `.dmg`, `.pkg`, and `.zip` installers to pick and remove |
| `just mole::analyze [path]` | Disk usage explorer; the default is `~`, use `/Volumes` for external drives |
| `just mole::status` | System health |
| `just mole::history` | Past cleanups |
| `just mole::update` | `brew upgrade mole` |

Always run the preview first, and read it, before the real command.

## What each command touches

### clean

Caches, logs, and temporary files under `~/Library`, plus files left behind by
apps that are no longer installed. Apps rebuild caches, so the main cost is a
slower first launch.

It also empties the Trash and clears the package caches for uv, pip, npm,
pnpm, bun, Go, mise, and Homebrew. Those refill on the next install, so the
next `uv sync` or `brew install` downloads more.

The scan is slow. On the Studio, `mo clean --dry-run` took more than five
minutes. Run it in a terminal you can leave open.

The first dry run on the Studio (2026-10-29) estimated 24 GB or more. The
largest items were Vivaldi service worker caches (about 2.7 GB), the Xcode
Simulator cache (3.3 GB), and Xcode DerivedData (1 GB). The full list goes to
`~/.config/mole/clean-list.txt`.

Mole only reports the biggest space users; it does not remove them:

| Item | Size | Where to deal with it |
| ---- | ---- | --------------------- |
| OrbStack data | 259 GB | `docker system df`, then prune images and volumes |
| Hugging Face cache | 50 GB | `hf cache scan` / `hf cache delete` |
| mise Rust installs | 10 GB | `mise prune`, or drop old versions from the config |
| Simulator devices | 10 GB | `xcrun simctl delete unavailable` |

To keep a cache, add it with `mo clean --whitelist`.

### purge

Build files inside project folders: `.venv`, `__pycache__`, `.ruff_cache`,
`dist`, `target`, and similar. The first dry run on the Studio (2026-10-29)
found 343 items and about 22 GB, most of it under `~/Projects`.

!!! warning "Purge removes `.venv` folders"
    A project whose `.venv` is removed needs `uv sync` before it runs again.
    Read the preview for projects you are working on, and skip them in the
    picker. `mo purge --paths` sets which folders it scans.

### installer

An interactive picker for installer files, mostly in `~/Downloads`. On the
Studio it found 69, including several copies of the same Bambu Studio `.dmg`.
Nothing is selected until you select it. `--dry-run` opens the same picker.

### analyze

A disk usage browser. `mo analyze /Volumes` looks only at external drives.

## Leave alone

- **Time Machine.** Mole does not manage backups. Old backups and local
  snapshots are Time Machine's job, and it removes the oldest backups itself
  when a drive fills.
- **`mo touchid`, `mo slim`, `mo optimize`.** These change system settings or
  app bundles. Run them only with `--dry-run` unless you mean to.
- **`mo remove`.** It uninstalls Mole. Use `brew uninstall mole` instead.
