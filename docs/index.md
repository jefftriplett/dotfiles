# Dotfiles Manual

These are my personal dotfiles for macOS development environments. They provide a consistent setup across machines with automated configuration.

This manual describes how the pieces fit together: the install and
update tasks, the window manager hotkeys, the tmux and cmux workflow, and
the project registry that ties the three Macs together.

The source lives at [jefftriplett/dotfiles](https://github.com/jefftriplett/dotfiles).

## Start here

| Page | Read it when |
| ---- | ------------ |
| [How the pieces fit together](overview.md) | You want to know which tool owns what |
| [Setting up a Mac](setup.md) | A fresh machine needs the whole setup |
| [Daily work](workflows.md) | You want the command for a task: open, start, list, or kill a project |
| [Maintenance](maintenance.md) | It is time to update, freeze a Brewfile, or lint |
| [Troubleshooting](troubleshooting.md) | Something answers wrong, or not at all |

The Reference section holds the full option lists for each tool.

## Key Tools

### CLI

- [direnv][direnv]: Securely loads or unloads environment variables depending on the current directory
- [Homebrew][homebrew]: Package management for macOS
- [Homesick][homesick]: Manages dotfiles with Git and symlinks
- [Just](https://github.com/casey/just): 🤖 Command runner for project-specific tasks
- [Starship][starship]: Minimal, blazing-fast, and customizable prompt for any shell

### GUI

- [Alfred][alfred]: Productivity tool with [Alfred Powerpack][alfred-powerpack]
- [Hammerspoon][hammerspoon]: macOS automation tool (tiling windows manager)

### Python Environment

- [pip][pip]: PyPA recommended tool for installing Python packages
- [uv][uv]: Fast Python package installer and resolver, written in Rust

## Repository Layout

- `home/`: dotfiles (Brewfile, shell config, app config)
- `home/bin/`: standalone scripts, symlinked onto `$PATH` as `~/bin`
- `home/.justfiles/`: just submodules for task groups
- `scripts/`: README generation helpers

- `docs/`: this manual, built with [Zensical](https://zensical.org/)

## Theme

[Dracula][dracula] is the official theme across every machine. Any app that
offers it gets it. Some of the configuration lives in this repository, the rest
is set inside each app.

| App | Where Dracula is configured |
| --- | --------------------------- |
| tmux | `home/.tmux.conf`, the `dracula/tmux` plugin and the status bar colors |
| Ghostty | `home/.config/ghostty/config` and the `dracula` palette file next to it |
| Starship | Dracula hex colors in `home/.config/starship.toml` |
| Sublime Text | `home/.config/sublime-text/`, color scheme and Package Control entry |
| Zed | `home/.config/zed/themes/dracula.json`; select it in the Zed theme setting |
| Alfred | Theme imported into Alfred preferences |
| cmux | Set in the app, from the [cmux Dracula theme](https://cmuxthemes.com/themes/dracula/) |
| Slack | Set in the app |
| Obsidian | Set per vault in the appearance settings |
| Telegram | Set in the app |
| Vivaldi | Set in the browser |
| This manual | `docs/stylesheets/dracula.css`, selected as the dark scheme in `zensical.toml` |

## Inspiration / Thank you!

- [The Geeky Way: What are dotfiles?](http://www.thegeekyway.com/what-are-dotfiles/)
- https://github.com/epicserve/dotfiles
- https://github.com/geerlingguy/mac-dev-playbook
- https://github.com/JohnColvin/.maid/blob/master/rules.rb
- https://github.com/mathiasbynens/dotfiles/blob/master/.osx
- https://github.com/mitchty/src/blob/master/dotfiles/maid/rules.rb
- http://blog.palcu.ro/2014/06/dotfiles-and-dev-tools-provisioned-by.html

[alfred-powerpack]: https://www.alfredapp.com/powerpack/
[alfred]: https://www.alfredapp.com/
[cmux]: https://github.com/manaflow-ai/cmux
[direnv]: https://direnv.net/
[dracula]: https://draculatheme.com/
[hammerspoon]: http://www.hammerspoon.org/
[homebrew]: http://brew.sh/
[homesick]: https://github.com/technicalpickles/homesick
[pip]: https://pip.pypa.io/en/latest/
[starship]: https://starship.rs/
[uv]: https://github.com/astral-sh/uv
