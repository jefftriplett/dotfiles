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
   $ just --justfile=./home/justfile bootstrap
   ```

## Project Workflow (Just)

Most tasks in this repo run via `just` recipes defined in `home/justfile` and
its submodules in `home/.justfiles`. Use `just --justfile=./home/justfile` when
running commands from the repo root.

Common commands:

```shell
$ just --justfile=./home/justfile install
$ just --justfile=./home/justfile bootstrap
$ just --justfile=./home/justfile update
$ just --justfile=./home/justfile update-readme-docs
```

## Justfile Usage

<!-- [[[cog
from scripts.run_command import run
run("just --justfile=./home/justfile --list --list-submodules", with_console=True)
]]] -->

```shell
$ just --justfile=./home/justfile --list --list-submodules

Available recipes:
    homebrew:
        cleanup DAYS="0" # clean up old Homebrew packages and cache
        freeze           # freeze current Homebrew packages to Brewfile
        outdated         # list outdated Homebrew packages
        services         # list all Homebrew services
        services-restart # restart all running Homebrew services
        services-stop    # stop specific Homebrew services (with non-fatal errors)
        update           # update Homebrew package database
        upgrade          # upgrade all outdated Homebrew packages
    llm:
        fmt     # format all AI/LLM justfiles
        upgrade # upgrade all AI/LLM tools
        claude:
            config  # open Claude Desktop configuration file in Sublime Text
            install # install Claude Code CLI
            upgrade # update Claude Code CLI to the latest version
            usage   # see Claude Code API/CLI usage
            version # display Claude Code CLI version

        clawdbot:
            doctor  # run clawdbot doctor to check configuration
            health  # check clawdbot health status
            install # install clawdbot CLI
            restart # restart clawdbot daemon
            upgrade # upgrade clawdbot to the latest version
            version # display clawdbot version

        clawdhub:
            install # install clawdhub CLI
            upgrade # upgrade clawdhub to the latest version
            version # display clawdhub version

        codex:
            config   # open Codex configuration file in Sublime Text
            outdated # check for outdated Codex npm package
            upgrade  # update Codex CLI to the latest version
            usage    # see Codex CLI usage
            version  # display Codex CLI version

        copilot:
            config   # open Copilot configuration file in Sublime Text
            outdated # check for outdated Copilot npm package
            upgrade  # update Copilot CLI to the latest version
            version  # display Copilot CLI version

        glm:
            install # install ccx CLI
            upgrade # update ccx CLI to the latest version
            usage   # show available ccx model usage
            version # display ccx CLI version

        llm-cli:
            force-reinstall # upgrade all installed LLM plugins with --force-reinstall
            install *ARGS   # install LLM plugins with optional arguments
            path            # open LLM templates directory in Sublime Text
            upgrade         # upgrade all installed LLM plugins

        ollama:
            copy-plist  # copy custom ollama plist file to homebrew directory
            diff-plist  # compare local ollama plist with installed version
            download    # download various ollama models (- prefix makes failures non-fatal)
            getenv      # display ollama environment variables from launchctl
            list        # list all downloaded ollama models
            serve *ARGS # serve ollama in a tandem process with optional arguments
            setenv      # set ollama environment variables in launchctl

        pi-coding-agent:
            help              # display pi CLI help
            install           # install pi-coding-agent CLI
            list-models *ARGS # list available models
            resume            # resume a previous pi session
            upgrade           # upgrade pi-coding-agent to the latest version
            version           # display pi-coding-agent version
    macos:
        timemachine-boost          # boost Time Machine backup speed by increasing IO priority
        timemachine-boost-complete # restore normal IO priority after Time Machine backup completes
        timemachine-delete *ARGS   # delete specific Time Machine backups
        timemachine-list           # list all Time Machine backups
        xcode-bootstrap            # install Xcode command line tools
        xcode-upgrade              # upgrade Xcode command line tools by removing and reinstalling
    mise:
        bootstrap # bootstrap mise by installing configured language versions
        upgrade   # install latest language versions and refresh shims
    pyenv:
        upgrade +ARGS="--skip-existing"     # upgrade all python versions managed by pyenv
        upgrade-all +ARGS="--skip-existing" # install or upgrade all python versions managed by pyenv
    python:
        bootstrap                 # bootstrap python environment with essential packages
        outdated                  # list outdated Python packages
        upgrade                   # update python environment
        uv-pip-install *ARGS      # install python packages using uv pip installer
        uv-pip-uninstall *ARGS    # uninstall python packages using uv pip installer
        uv-pip-upgrade *ARGS      # update python versions using uv installer
        uv-python-install *ARGS   # install python versions using uv installer
        uv-python-reinstall *ARGS # reinstall python versions using uv installer
        uv-tool-install *ARGS     # install common python CLI tools using uv installer
        uv-tool-upgrade           # upgrade common python CLI tools using uv installer
    virtualenv:
        scan    # scan virtualenvs and display their python versions
        upgrade # upgrade pip in all virtualenvs
        workon  # list all virtualenvs with their python and pip versions
    virtualenvwrapper:
        get_env_details  # virtualenvwrapper hook for getting environment details
        initialize       # virtualenvwrapper hook for environment initialization
        postactivate     # virtualenvwrapper hook that runs after environment activation
        postdeactivate   # virtualenvwrapper hook that runs after environment deactivation
        postmkproject    # virtualenvwrapper hook that runs after creating a project
        postmkvirtualenv # virtualenvwrapper hook that runs after creating a virtualenv
        postrmproject    # virtualenvwrapper hook that runs after removing a project
        postrmvirtualenv # virtualenvwrapper hook that runs after removing a virtualenv
        preactivate      # virtualenvwrapper hook that runs before environment activation
        predeactivate    # virtualenvwrapper hook that runs before environment deactivation
        premkproject     # virtualenvwrapper hook that runs before creating a project
        premkvirtualenv  # virtualenvwrapper hook that runs before creating a virtualenv
        prermproject     # virtualenvwrapper hook that runs before removing a project
        prermvirtualenv  # virtualenvwrapper hook that runs before removing a virtualenv

    [database]
    postgresql-upgrade # upgrade PostgreSQL to latest version and migrate databases

    [maintenance]
    cleanup DAYS="0"   # clean up old Homebrew packages and casks
    outdated           # list outdated packages from Homebrew and pip
    update             # update project to run at its current version
    upgrade            # update and upgrade Homebrew packages
    upgrade-all        # upgrade all tools (pyenv and mise packages)

    [services]
    restart            # restart Homebrew services
    stop               # stop all Homebrew services

    [setup]
    bootstrap          # install and update all dependencies
    install            # create symlinks for dotfiles using homesick

    [shortcuts]
    open-docs          # open documentation in browser using Tailscale/golinks
    open-go            # open Tailscale/golinks homepage
    open-ha            # open Home Assistant interface in browser
    open-syncthing     # open Syncthing interface in browser

    [utils]
    fmt                # format and overwrite justfile
    freeze             # update lockfiles without installing dependencies [alias: lock]
    lint               # run shellcheck on bash configuration files
    test               # run validation checks
    update-brewfile    # update Brewfile from cog template
    update-readme-docs # update README.md docs using cog
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

## Repository Layout

- `home/`: dotfiles (Brewfile, shell config, app config)
- `home/.justfiles/`: just submodules for task groups
- `configs/`: editor/application configs (Sublime Text)
- `scripts/`: README generation helpers

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
