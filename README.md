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

## Project Shell

`project-shell` uses per-project direnv config to attach to the right tmux
session locally or over Mosh:

```shell
$ project-shell
```

Example work-project `.envrc`:

```shell
export PROJECT_REMOTE_HOST=mac-studio
export PROJECT_REMOTE_NAME=mac-studio
export PROJECT_TMUX_SESSION=my-work-project
export PROJECT_REMOTE_MODE=auto
```

Example personal-project `.envrc`:

```shell
export PROJECT_REMOTE_HOST=mac-mini
export PROJECT_REMOTE_NAME=mac-mini
export PROJECT_TMUX_SESSION=my-home-project
export PROJECT_REMOTE_MODE=auto
```

Run `direnv allow` after creating or changing a project `.envrc`. Set
`PROJECT_REMOTE_CONNECT_TIMEOUT` to override the default five-second SSH
connection timeout used by Mosh startup.

Modes are `auto`, `remote`, `local`, and `off`. `auto` uses Mosh when
`PROJECT_REMOTE_HOST` is set, avoids connecting to the current machine, and
falls back to local tmux if no remote is configured. Failed remote attempts ask
whether to use local tmux, retry, or abort.

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
        fmt      # format all AI/LLM justfiles
        outdated # check for outdated AI/LLM tools
        upgrade  # upgrade all AI/LLM tools
        claude:
            config  # open Claude Desktop configuration file in Sublime Text
            install # install Claude Code CLI
            upgrade # update Claude Code CLI to the latest version
            usage   # see Claude Code API/CLI usage
            version # display Claude Code CLI version

        clawdbot:
            doctor    # run clawdbot doctor to check configuration
            health    # check clawdbot health status
            install   # install clawdbot CLI
            restart   # restart clawdbot daemon
            uninstall # uninstall clawdbot CLI
            upgrade   # upgrade clawdbot to the latest version
            version   # display clawdbot version

        clawdhub:
            install   # install clawdhub CLI
            uninstall # uninstall clawdhub CLI
            upgrade   # upgrade clawdhub to the latest version
            version   # display clawdhub version

        codex:
            config    # open Codex configuration file in Sublime Text
            install   # install Codex CLI
            uninstall # uninstall Codex CLI
            upgrade   # update Codex CLI to the latest version
            usage     # see Codex CLI usage
            version   # display Codex CLI version

        copilot:
            config    # open Copilot configuration file in Sublime Text
            outdated  # check for outdated Copilot npm package
            uninstall # uninstall Copilot CLI
            upgrade   # update Copilot CLI to the latest version
            version   # display Copilot CLI version

        glm:
            install   # install ccx CLI
            uninstall # uninstall ccx CLI
            upgrade   # update ccx CLI to the latest version
            usage     # show available ccx model usage
            version   # display ccx CLI version

        happy:
            install   # install happy-coder CLI
            run       # run happy CLI
            uninstall # uninstall happy-coder CLI
            upgrade   # upgrade happy-coder to the latest version
            version   # display happy-coder version

        llm-cli:
            force-reinstall # upgrade all installed LLM plugins with --force-reinstall
            install *ARGS   # install LLM plugins with optional arguments
            path            # open LLM templates directory in Sublime Text
            upgrade         # upgrade all installed LLM plugins

        moltbot:
            doctor    # run moltbot doctor to check configuration
            health    # check moltbot health status
            install   # install moltbot CLI
            restart   # restart moltbot daemon
            uninstall # uninstall moltbot CLI
            upgrade   # upgrade moltbot to the latest version
            version   # display moltbot version

        ollama:
            copy-plist  # copy custom ollama plist file to homebrew directory
            diff-plist  # compare local ollama plist with installed version
            download    # download various ollama models (- prefix makes failures non-fatal)
            getenv      # display ollama environment variables from launchctl
            list        # list all downloaded ollama models
            serve *ARGS # serve ollama in a tandem process with optional arguments
            setenv      # set ollama environment variables in launchctl

        openclaw:
            doctor    # run openclaw doctor to check configuration
            health    # check openclaw health status
            install   # install openclaw CLI
            restart   # restart openclaw daemon
            uninstall # uninstall openclaw CLI
            upgrade   # upgrade openclaw to the latest version
            version   # display openclaw version

        pi-coding-agent:
            help              # display pi CLI help
            install           # install pi-coding-agent CLI
            list-models *ARGS # list available models
            resume            # resume a previous pi session
            uninstall         # uninstall pi-coding-agent CLI
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

### Modifiers

| Name  | Key Combination                                   |
| ----- | ------------------------------------------------- |
| hyper | <kbd>ctrl</kbd> + <kbd>opt</kbd> + <kbd>cmd</kbd> |
| meta  | <kbd>cmd</kbd> + <kbd>shift</kbd>                 |

### Window Management

| Action                    | Key Combination                                                        |
| ------------------------- | ---------------------------------------------------------------------- |
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

### Display Grid (2x2 Monitor Setup)

| Action                     | Key Combination              |
| -------------------------- | ---------------------------- |
| fix 2x2 display grid       | <kbd>hyper</kbd> + <kbd>f</kbd> |
| dump display configuration | <kbd>hyper</kbd> + <kbd>9</kbd> |

### Application Toggle

| Action        | Key Combination              |
| ------------- | ---------------------------- |
| iTerm2        | <kbd>hyper</kbd> + <kbd>i</kbd> |
| Discord       | <kbd>hyper</kbd> + <kbd>d</kbd> |
| Slack         | <kbd>hyper</kbd> + <kbd>s</kbd> |
| Telegram      | <kbd>hyper</kbd> + <kbd>t</kbd> |
| Sublime Text  | <kbd>hyper</kbd> + <kbd>e</kbd> |
| Tower         | <kbd>hyper</kbd> + <kbd>w</kbd> |
| Zed           | <kbd>hyper</kbd> + <kbd>x</kbd> |
| Messages      | <kbd>hyper</kbd> + <kbd>a</kbd> |
| Vivaldi       | <kbd>hyper</kbd> + <kbd>v</kbd> |
| Obsidian      | <kbd>hyper</kbd> + <kbd>o</kbd> |

### Utilities

| Action                       | Key Combination              |
| ---------------------------- | ---------------------------- |
| window hints (current app)   | <kbd>hyper</kbd> + <kbd>.</kbd> |
| battery/screen callbacks     | <kbd>hyper</kbd> + <kbd>,</kbd> |
| display watcher status       | <kbd>hyper</kbd> + <kbd>0</kbd> |

## tmux Setup

Session management and key bindings are defined in `home/.tmux.conf` and `home/.bash_tmux`.

### Shell Aliases

| Alias | Command | Description |
| ----- | ------- | ----------- |
| `t` | `tmux` | Run tmux |
| `ta [name]` | `tmux-go` | Attach to or create a named session |
| `tn [name]` | `tmux-new` | Create a new session (attaches if it already exists) |
| `tk [name]` | `tmux-kill` | Kill a named session |
| `tls` | `tmux-ls` | List sessions (add `--json` for machine-readable output) |

`tmux-resume` and `tmux-attach` are thin wrappers that call `tmux-go`. Neither has a short
alias — `tr` would shadow the `tr` coreutils command.

Tab completion for session names is registered on the function names `tmux-go`,
`tmux-resume`, `tmux-attach`, and `tmux-kill`. Bash does not expand an alias before
completing, so the short forms (`ta`, `tk`) do not complete; type the full name when you
want completion.

### Shell Functions

Defined in `home/.bash_tmux`. All of them respect `TMUX_AUTOATTACH_MACHINE`, so they act on
the remote host's tmux when one is set (see [Remote Sessions](#remote-sessions)).

| Function | Description |
| -------- | ----------- |
| `tmux` | Wrapper that runs tmux through `direnv exec /`, so the project `.envrc` does not leak into the server |
| `tmux-new [name]` | Set the terminal title, then attach to or create the session (`new-session -A`) |
| `tmux-go [name]` | Attach to a session; from inside tmux it uses `switch-client` instead of nesting |
| `tmux-resume [name]` | Wrapper for `tmux-go` |
| `tmux-attach [name]` | Wrapper for `tmux-go` |
| `tmux-ls [--json]` | List sessions on the current machine |
| `tmux-kill [name]` | Kill a session by name |

The session name defaults to `$TMUX_AUTOATTACH`, falling back to the current directory's
basename. `:`, `.`, and spaces are replaced with `-`, since tmux forbids the first two in
session names.

`tmux-ls --json` delegates to `tmux-remote-ls` for the one relevant host, so the schema and
string escaping match the fleet-wide command. It cannot be combined with tmux's own
`list-sessions` flags (such as `-F`), which conflict with the fixed format the JSON is
parsed from.

```shell
tmux-ls --json | jq -r '.[0].sessions[] | select(.attached | not) | .name'
```

### Scripts

Standalone executables in `home/bin/` (symlinked onto `$PATH` as `~/bin`).

| Script | Description |
| ------ | ----------- |
| `tmux-host` | Print the pane's remote host when it is running ssh, else the local short hostname. Used by the status bar |
| `tmux-remote-ls` | List tmux sessions across every Mac at once |

`tmux-remote-ls` is roughly `ssh <host> tmux ls` for each machine, but parsed: sessions are
sorted and annotated with attached/detached state, window count, and path.

```console
$ tmux-remote-ls
mac-mini-pro-2023:
  ags  [attached, 1 window]  /Users/jefftriplett/Projects/ags
  thumb-im  [attached, 1 window]  /Users/jefftriplett/Projects/thumb.im/thumb.im-git
mac-studio-2023:
  default  [detached, 1 window]  /Users/jefftriplett/Vaults/default
```

Hosts are listed in `DEFAULT_HOSTS` at the top of the script — edit it when a machine joins
or leaves — and can be overridden per-run with `--host` or by setting `$TMUX_REMOTE_HOSTS`.
Whichever machine you are sitting at is skipped rather than dialed over ssh; `--include-local`
adds it back, querying tmux directly instead of over the network. Hosts are queried
concurrently, so one unreachable machine costs only its own timeout.

Remote hosts use `ssh` rather than mosh (this is a one-shot non-interactive command, matching
`tmux-ls` and `tmux-kill`) with `BatchMode=yes`, so a host that would prompt fails fast
instead of hanging. The exit status is 1 when any host could not be reached, which
distinguishes "no sessions anywhere" from "never got an answer".

| Option | Description |
| ------ | ----------- |
| `--host`, `-H` | Host to query; repeatable, overrides the defaults |
| `--timeout`, `-t` | ssh connect timeout in seconds (default 5) |
| `--include-local` | Also list this machine, run locally rather than over ssh |
| `--sessions-only`, `-s` | Print bare `host:session` lines with no headers, for piping |
| `--json` | Emit JSON instead of text |

### Key Bindings

Prefix is `Ctrl-b`.

#### Panes

| Action | Key |
| ------ | --- |
| Split horizontally | `prefix + \|` |
| Split vertically | `prefix + -` |
| Navigate left/down/up/right | `prefix + h/j/k/l` |
| Resize left/down/up/right | `prefix + H/J/K/L` (repeatable) |

#### Windows

| Action | Key |
| ------ | --- |
| New window (current directory) | `prefix + c` |

#### Copy Mode

| Action | Key |
| ------ | --- |
| Enter copy mode | `prefix + [` |
| Start selection | `v` |
| Copy selection to clipboard | `y` |
| Mouse drag | auto-copies to clipboard |

#### Misc

| Action | Key |
| ------ | --- |
| Reload config | `prefix + r` |
| Clear screen and scrollback | `prefix + Ctrl-k` |

### direnv Auto-Attach

Add `use tmux` to any project's `.envrc` to automatically attach to (or create) a tmux session when entering that directory:

```shell
# .envrc
use tmux                                          # session name defaults to the directory name
use tmux myproject                                # explicit session name
use tmux myproject --machine myserver             # SSH to a remote host's tmux session
use tmux myproject --machine myserver --path /home/jeff/projects/myproject  # with a remote start path
```

Set `NO_TMUX_AUTOATTACH=1` to skip auto-attach for a shell session.

### Environment Variables

These variables are exported by `use tmux` in `.envrc` and read by the shell functions in `home/.bash_tmux`. They can also be set manually without direnv.

| Variable | Description |
| -------- | ----------- |
| `TMUX_AUTOATTACH` | Session name to attach to or create on shell startup |
| `TMUX_AUTOATTACH_MACHINE` | SSH hostname to route all tmux commands through |
| `TMUX_AUTOATTACH_HOST` | Alias for `TMUX_AUTOATTACH_MACHINE` |
| `TMUX_AUTOATTACH_PATH` | Working directory passed to `tmux new-session -c` (creation only, not re-attach) |
| `NO_TMUX_AUTOATTACH` | Set to `1` to disable auto-attach for a shell session |

### Remote Sessions

Set `--machine` (or `--host` / `--profile`) to SSH into a remote host's tmux session instead of the local one. All commands — `tmux-go`, `tmux-ls`, `tmux-kill`, and auto-attach — are routed through `ssh -t` automatically.

```shell
# .envrc
use tmux myproject --machine myserver

# With a starting directory on the remote host (only applies when creating a new session)
use tmux myproject --machine myserver --path /home/jeff/projects/myproject
```

Requires key-based SSH auth (no password prompt) since the connection is non-interactive.

## cmux Workspaces

Scripts in `home/bin/` that keep [cmux][cmux] workspaces and tmux sessions in sync. They are
[uv][uv] inline-script executables — the dependency headers mean they run straight from
`$PATH` with no virtualenv to manage.

| Script | Description |
| ------ | ----------- |
| `cmux-dump` | Save the open workspaces to a dump file |
| `cmux-restore` | Recreate workspaces from a dump file |
| `cmux-open` | Open the dump file in `$EDITOR` |
| `cmux-adopt` | Give unattached tmux sessions a workspace, once |
| `cmux-watch` | Same as adopt, but polling continuously |
| `_cmux.py` | Shared helpers; imported by the above, not run directly |

The two halves work in opposite directions. `cmux-dump` / `cmux-restore` treat a
hand-editable file as the source of truth and rebuild workspaces from it. `cmux-adopt` /
`cmux-watch` treat the running tmux server as the source of truth, so work left behind in a
detached session gets a window back instead of quietly aging out.

### Dump and Restore

```shell
cmux-dump          # save open workspaces to ~/.config/cmux/session-dump.toml
cmux-open          # edit that file to add machine / tmux / session fields
cmux-restore       # recreate any workspace that is not already open
```

The dump defaults to `~/.config/cmux/session-dump.toml`; pass a path to use another file, or
`--json` to write JSON. `cmux-restore` and `cmux-open` detect the format from the extension
and fall back to `session-dump.json` when no TOML file exists.

cmux cannot report whether a workspace is running mosh or tmux, so `machine`, `tmux`, and
`session` are hand-added. Re-dumping preserves them by matching on title, and keeps annotated
entries whose workspaces have since been closed, so closing a workspace does not lose its
config. Writes are atomic, so an interrupted dump cannot corrupt those hand-edited fields.

| Field | Description |
| ----- | ----------- |
| `title` | Workspace title; also the default tmux session name |
| `cwd` | Working directory |
| `color` | Custom workspace color |
| `pinned` | Whether the workspace is pinned |
| `description` | Workspace description |
| `machine` | Host to mosh to; treated as local if it matches this hostname |
| `tmux` | Attach a tmux session in the workspace |
| `session` | Explicit tmux session name, overriding the title-derived one |

```toml
[[workspaces]]
title = "thumb.im"
cwd = "/Users/jefftriplett/Projects/thumb.im/thumb.im-git"
machine = "mac-mini-pro-2023"
tmux = true
```

The last three fields combine to decide where a workspace runs:

| Fields | Result |
| ------ | ------ |
| `machine` + `tmux = true` | mosh to the host and attach a tmux session there, started in `cwd` |
| `machine` only | plain mosh to the host |
| `tmux = true` only | attach a local tmux session, started in `cwd` |
| neither | plain local workspace |

Restoring is safe to rerun: workspaces whose title already exists are skipped, and tmux
sessions use `new-session -A`, so a restore resumes an existing session rather than
duplicating it. Remote workspaces get a `[mosh] ` label on the cmux title; it is display-only
and never reaches the remote tmux session name.

### Adopt and Watch

```shell
cmux-adopt --dry-run   # show which sessions would get a workspace
cmux-adopt             # adopt them
cmux-watch             # keep adopting as new sessions appear
```

`cmux-adopt` adopts a session when nothing is attached to it *and* no open workspace already
maps to it. Attached sessions are left alone because a second client on one session squeezes
both panes down to the smallest client's size; `--include-attached` overrides that, which is
useful when a session is only attached from outside cmux.

`cmux-watch` polls on an interval (`--interval`, default 5s) and adopts both attached and
detached sessions — its only requirement is that no workspace already covers the session. Use
`--once` for a single pass.

Workspaces are matched to sessions by the same slug `cmux-restore` feeds to `tmux
new-session`, so a workspace titled `thumb.im` counts as covering the `thumb-im` session and
is not adopted twice. Sessions are attached by name rather than by directory, which matters
when two projects share a parent directory.

## Terminal theme

- [Dracula][dracula] Dark theme for iTerm and 294+ apps.

## Repository Layout

- `home/`: dotfiles (Brewfile, shell config, app config)
- `home/bin/`: standalone scripts, symlinked onto `$PATH` as `~/bin`
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
[cmux]: https://github.com/manaflow-ai/cmux
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
