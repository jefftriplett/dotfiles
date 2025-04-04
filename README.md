# My Dotfiles

These are my personal dotfiles for macOS development environments. They provide a consistent setup across machines with automated configuration.

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
- [pyenv][pyenv]: Simple Python version management
- [uv][uv]: Fast Python package installer and resolver, written in Rust

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
   $ just bootstrap
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
    cleanup DAYS="0"                          # clean up old homebrew packages and casks
    fmt                                       # format and overwrite justfile
    freeze                                    # Updates our lockfiles without installing dependencies [alias: lock]
    git-commit-msg                            # generate a commit message using llm template
    install                                   # create symlinks for dotfiles using homesick
    kill-tabs                                 # Kill all Chrome tabs to improve performance, decrease battery usage, and save memory.
    open-claude-desktop-config                # open Claude desktop configuration file in Sublime Text
    open-docs                                 # open documentation in browser using tailscale/golinks
    open-go                                   # open tailscale/golinks homepage
    open-ha                                   # open Home Assistant interface in browser
    open-syncthing                            # open Syncthing interface in browser
    outdated                                  # list outdated packages from homebrew and pip
    pip-install *ARGS                         # install python packages using uv pip installer
    pip-uninstall *ARGS                       # uninstall python packages using uv pip installer
    postgresql-upgrade                        # upgrade postgresql to latest version and migrate databases
    pyenv-upgrade +ARGS="--skip-existing"     # upgrade python and update pyenv configuration
    pyenv-upgrade-all +ARGS="--skip-existing" # install or upgrade all python versions managed by pyenv
    python-update                             # update python environment and pyenv settings
    restart                                   # restart homebrew services
    stop                                      # stop all homebrew services
    update                                    # updates a project to run at its current version
    upgrade                                   # update and upgrade homebrew packages
    upgrade-all                               # upgrade all tools (pyenv and mise packages)
    uv-python-install *ARGS                   # install python versions using uv installer
    uv-python-reinstall *ARGS                 # reinstall python versions using uv installer
    uv-tool-install *ARGS                     # install common python CLI tools using uv installer
    homebrew ...
    llm ...
    macos ...
    ollama ...
    virtualenv ...
    virtualenvwrapper ...
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
[pyenv]: https://github.com/yyuu/pyenv
[starship]: https://starship.rs/
[uv]: https://github.com/astral-sh/uv

## Contact / Social Media

Here are a few ways to keep up with me online. If you have a question about this project, please consider opening a GitHub Issue.

[![](https://jefftriplett.com/assets/images/social/github.png)](https://github.com/jefftriplett)
[![](https://jefftriplett.com/assets/images/social/globe.png)](https://jefftriplett.com/)
[![](https://jefftriplett.com/assets/images/social/twitter.png)](https://twitter.com/webology)
[![](https://jefftriplett.com/assets/images/social/docker.png)](https://hub.docker.com/u/jefftriplett/)
