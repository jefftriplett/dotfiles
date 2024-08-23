# My Dotfiles

There are my personal dotfiles. They are managed using:

## CLI

- [direnv][direnv]: Securely loads or unloads environment variables depending on the current directory.
- [Homebrew][homebrew] for macOS package management.
- [Homesick][homesick] for managing dotfiles.
- [Just](https://github.com/casey/just) 🤖 Just a command runner.
- [Starship][starship] The minimal, blazing-fast, and infinitely customizable prompt for any shell.

## GUI

- [Alfred][alfred]: Productivity tool and [Alfred Powerpack][alfred-powerpack].
- [Hammerspoon][hammerspoon]: An macOS automation tool (tiling windows manager)

## Python

- [pip][pip]: The PyPA recommended tool for installing and managing Python packages.
- [pipx][pipx]: execute binaries from Python packages in isolated environments.
- [pyenv][pyenv]: Simple Python version management.
- [uv]: An extremely fast Python package installer and resolver, written in Rust.

## Installation

1. Bootstrap our environment (install ansible via pipx)

```shell
$ make bootstrap
```

2. Let ansible do its thing

```shell
$ make install
```

# Justfile Usage

<!-- [[[cog
from scripts.run_command import run
run("just --justfile=./home/justfile", with_console=True)
]]] -->

```shell
$ just --justfile=./home/justfile

Available recipes:
    bootstrap                                 # installs/updates all dependencies
    cleanup DAYS="0"
    fmt                                       # format and overwrite justfile
    freeze                                    # Updates our lockfiles without installing dependencies
    lock                                      # alias for `freeze`
    homebrew-services
    install
    kill-tabs                                 # Kill all Chrome tabs to improve performance, decrease battery usage, and save memory.
    macos-timemachine-boost
    macos-timemachine-boost-complete
    macos-timemachine-delete *ARGS
    macos-timemachine-list
    macos-xcode-upgrade
    ollama-copy-plist
    ollama-diff-plist
    ollama-download
    ollama-getenv
    ollama-list
    ollama-serve *ARGS
    ollama-setenv
    open-docs
    open-go
    open-ha
    open-syncthing
    outdated
    pip-install *ARGS
    pip-uninstall *ARGS
    pipx-upgrade-all
    postgresql-upgrade
    pyenv-upgrade +ARGS="--skip-existing"
    pyenv-upgrade-all +ARGS="--skip-existing"
    python-update
    restart
    stop
    update                                    # updates a project to run at its current version
    upgrade
    upgrade-all
    virtualenv-scan
    virtualenv-upgrade
    virtualenv-workon
```

<!-- [[[end]]] -->

## Hammerspoon Keyboard Shortcuts

| Action                    | Key Combination                                                        |
| ------------------------- | ---------------------------------------------------------------------- |
| hyper                     | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>cmd</kbd>                      |
| meta                      | <kbd>cmd</kbd> + <kbd>shift</kbd>                                      |
| reload config             | <kbd>hyper</kbd> + <kbd>r</kbd>                                        |
| show grid                 | <kbd>hyper</kbd> + <kbd>g</kbd>                                        |
| make full screen          | <kbd>hyper</kbd> + <kbd>m</kbd>                                        |
| center and 60%            | <kbd>hyper</kbd> + <kbd>c</kbd>                                        |
| move to left half         | <kbd>hyper</kbd> + <kbd>left</kbd>                                     |
| move to right half        | <kbd>hyper</kbd> + <kbd>right</kbd>                                    |
| move to top half          | <kbd>hyper</kbd> + <kbd>up</kbd>                                       |
| move to lower half        | <kbd>hyper</kbd> + <kbd>down</kbd>                                     |
| move to upper left (25%)  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>left</kbd>  |
| move to upper right (25%) | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>up</kbd>    |
| move to lower left (25%)  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>down</kbd>  |
| move to lower right (25%) | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>shift</kbd> + <kbd>right</kbd> |
| move to next monitor      | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>right</kbd>                    |
| move to previous monitor  | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>left</kbd>                     |

## Terminal theme

- [Dracula][dracula] Dark theme for iTerm and 294+ apps.

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
[direnv]: https://direnv.net/
[dracula]: https://draculatheme.com/iterm
[espanso]: https://espanso.org/
[hammerspoon]: http://www.hammerspoon.org/
[homebrew]: http://brew.sh/
[homesick]: https://github.com/technicalpickles/homesick
[modd]: https://github.com/cortesi/modd
[pip]: https://pip.pypa.io/en/latest/
[pipenv]: http://docs.pipenv.org/en/latest/
[pipx]: https://pipxproject.github.io/pipx/
[pyenv]: https://github.com/yyuu/pyenv
[starship]: https://starship.rs/
[uv]: https://github.com/astral-sh/uv

## Contact / Social Media

Here are a few ways to keep up with me online. If you have a question about this project, please consider opening a GitHub Issue.

[![](https://jefftriplett.com/assets/images/social/github.png)](https://github.com/jefftriplett)
[![](https://jefftriplett.com/assets/images/social/globe.png)](https://jefftriplett.com/)
[![](https://jefftriplett.com/assets/images/social/twitter.png)](https://twitter.com/webology)
[![](https://jefftriplett.com/assets/images/social/docker.png)](https://hub.docker.com/u/jefftriplett/)
