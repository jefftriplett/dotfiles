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
        cleanup [OPTIONS] # clean up old Homebrew packages and cache
        freeze            # freeze current Homebrew packages to Brewfile
        outdated          # list outdated Homebrew packages
        services          # list all Homebrew services
        services-restart  # restart all running Homebrew services
        services-stop     # stop specific Homebrew services (with non-fatal errors)
        update            # update Homebrew package database
        upgrade           # upgrade all outdated Homebrew packages
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
            uninstall         # uninstall pi-coding-agent CLI
            upgrade           # upgrade pi-coding-agent to the latest version
            version           # display pi-coding-agent version
    macos:
        duti-setup                 # set default applications for file types using duti
        timemachine-boost          # boost Time Machine backup speed by increasing IO priority
        timemachine-boost-complete # restore normal IO priority after Time Machine backup completes
        timemachine-delete +ARGS   # delete specific Time Machine backups
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
    cleanup [OPTIONS]  # clean up old Homebrew packages and casks
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
| `tmux-remote-ls` | List tmux sessions across every Mac at once (see also `workon --sessions`) |
| `projects` | Manage the [project registry](#project-registry), including the machine list |

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

Hosts come from the `[machines]` table of [`~/Projects/projects.toml`](#machine-list) and can be overridden per-run
with `--host` or by setting `$TMUX_REMOTE_HOSTS`. The same list drives `cmux-tmux-sync --all`.
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

### Machine List

The Macs live in the `[machines]` table of the project registry, `~/Projects/projects.toml`
— see [Project Registry](#project-registry) below. Every machine gets a short key you type
(`studio`) and an ssh name that has to resolve (`mac-studio-2023`):

```toml
[machines.studio]
host = "mac-studio-2023"

[machines.air]
host = "mba-2025"
hostname = "MacBook-Air-2025"   # only when it differs from the ssh name
```

`hostname` exists because the machine you are sitting at has to be recognized so it is
skipped rather than dialed. The Air answers to `mba-2025` over ssh but reports
`MacBook-Air-2025` as its own hostname, and without the mapping it would try to reach its
own address.

Names must be resolvable by ssh — Tailscale MagicDNS or a `Host` entry in `~/.ssh/config`.
The short key works anywhere a host does, so `tmux-remote-ls --host studio` and
`cmux-tmux-sync --host studio` both do what you would expect.

`projects machines` edits the table for you, keeping entries sorted:

```shell
projects machines                                     # list what is configured
projects machines add test --host mac-test-2026       # add a machine
projects machines add test --host mac-test-2026 --hostname Mac-Test-2026
projects machines add test --host mac-test-2026 --check   # only add if ssh answers
projects machines remove test                         # refuses while projects point at it
```

Hand-editing is still fine — the command uses a format-preserving TOML writer, so comments
and layout survive a round trip either way.

`$TMUX_REMOTE_HOSTS` (space separated) overrides the table for a single run, and `--host`
overrides both:

```shell
TMUX_REMOTE_HOSTS="mac-studio-2023" tmux-remote-ls
```

`tmux-remote-ls`, `cmux-tmux-sync`, and `cmux-doctor` all read the same table. With nothing
configured and no `--host`, they report what to fix rather than falling back to a built-in
list.

#### Migrating from `hosts.toml`

The list used to live in `~/.config/cmux-tmux/hosts.toml` as a flat `hosts = [...]` array
with a separate `[aliases]` table. `projects init` imports it:

```shell
projects init          # reads hosts.toml, writes ~/Projects/projects.toml
projects machines      # rename the keys by hand if you want shorter ones
projects import -n     # then import the projects themselves
```

`hosts.toml` is still read on any machine whose registry has no `[machines]` table, so the
two can coexist while the dotfiles roll out. There is no longer a command to edit `hosts.toml`
— `projects machines` is the one way in, and the fallback exists only so a machine that has
not been migrated yet keeps working.

## Project Registry

`~/Projects/projects.toml` records which machine each project lives on, where it lives there,
and which tmux session holds it. `workon` finds projects by scanning `~/Projects` and `~/Work`,
which structurally cannot see a checkout that lives on another Mac; the registry can.

```toml
[machines.studio]
host = "mac-studio-2023"

[machines.mini]
host = "mac-mini-pro-2023"

[defaults]
tmux = false          # a project gets a session when it asks for one
home_dir = "~/Projects"
work_dir = "~/Work"

[projects.notes]
path = "~/Projects/notes"
# no machine: opens wherever you are, which is true of any synced directory
# nothing has claimed

[projects.django-news]
machine = "studio"    # claimed: a session for it runs on the Studio
path = "~/Work/django-news"
tmux = true
tmux_session = "django-news"

[projects.pghub]
machine = "mini"
path = "~/Projects/pghub"
tmux = true
tmux_path = "~/Projects/pghub/pghub-git"   # optional: where the work happens
tmux_session = "pghub-git"
```

`path` is the project directory; `tmux_path` is the checkout inside it that the tmux session
actually runs in. Both are separate facts because they differ constantly — the project is
`~/Projects/pghub` but the session lives in `~/Projects/pghub/pghub-git`. `tmux_path` is
entirely optional and is written only when the two differ, so a project whose work happens at
its own root carries no `tmux_path` at all. `workon` lands in `tmux_path` when it is
set, and in `path` otherwise.

`machine` is optional too, and most entries do without it. A project names a machine when
something proved one — a session running there — and otherwise carries none, which resolves
as "wherever you are". That is the honest answer for a Syncthing-mirrored directory: it
exists on all three Macs, so its location says nothing about where the work happens, and a
guessed owner would send you across the network to open something already in front of you.

Set `$PROJECTS_TOML` to point somewhere else for a single run.

The registry model is defined with pydantic in `home/bin/_projects.py`. `_cmux.py` stays on
plain dataclasses on purpose: every `cmux-*` and `tmux-remote-*` script imports it, and none of
them should have to grow a dependency to do so. Only `projects` declares pydantic.

### workon and mkproject

Registry-aware companions to `workon` and `mkproject`, defined in `home/.workon.bash`.
They are shell functions rather than scripts because the local case has to change the calling
shell's directory and environment.

| Command | Description |
| ------- | ----------- |
| `workon <project>` | Open a project wherever it lives |
| `workon --local[=<p>]` | Force a local cd + virtualenv activation |
| `workon --remote[=<p>]` | Force a mosh to its registered machine |
| `workon --host=<m> <p>` | Open it on that machine instead, just this once |
| `workon --sessions` | Show the tmux sessions live on every Mac, and what opens each |
| `workon -s --kill <p>` | Kill a session by project key or session name |
| `mkproject <name>` | Create, register, and open a new project |

There is one `workon` and one `mkproject` — no separate remote command to reach for.
`--auto` is the default and is what plain `workon <project>` does: consult the registry,
then cd locally or mosh out.

A project that is *not* in the registry falls back to the original directory scan of
`~/Projects`, `~/Work`, and `~/.virtualenvs`, so nothing that worked before the registry
existed has stopped working.

Opening a project is a cd plus a virtualenv activation. No tmux session is involved unless
something asks for one — `tmux = true` on the entry, `--tmux` on the command, or
`WORKON_TMUX=1` in the environment. A project gets a session because it said so, not
because it failed to say otherwise, and that holds for remote opens too: reaching another
Mac without `tmux = true` gets you a login shell in the right directory.

```shell
workon notes           # cd + activate, wherever it lives
workon notes --tmux    # ...and attach a session after all
workon django-news     # remote: mosh mac-studio-2023, attach (its entry sets tmux = true)
workon                 # no argument: list what is registered
```

Tab completion reads a cache at `~/.cache/workon/names` rather than calling `projects` on
every keypress. `projects` is a `uv run` script and costs ~300ms to start — fine when you
typed it, an eternity to sit through on a TAB. The cache rebuilds when the registry,
`~/Projects`, `~/Work`, or `~/.virtualenvs` is newer than it, which is four `[[ -nt ]]`
builtins and no subprocess in the common case. That takes a TAB from **580ms to
unmeasurable**, and a new project still shows up the moment it exists, whether it arrived
through `projects add` or a bare `mkdir`.

`workon-refresh` rebuilds it by hand, for warming the cache from a profile or when you
want to be sure.

Names are matched loosely: a project registered as `thumb.im` also answers to `thumb-im`,
the slug tmux actually shows you.

### Seeing what is running

`workon --sessions` (`-s`) probes every Mac at once and shows what is live, with the command
that gets you back into each one:

```shell
$ workon --sessions
mini (mac-mini-pro-2023)
  django-news-com                        attached 1w   workon django-news.com
  djangoconus-automation-git             attached 1w   workon djangoconus-automation
  dotfiles                               detached 1w   workon dotfiles
studio (mac-studio-2023)
  toggl-agent-git                        attached 1w   workon agents

12 session(s)
```

The right-hand column is the point. Session names and project keys drift apart constantly —
the session is `django-news-com`, the thing you type is `workon django-news.com`; the session
is `toggl-agent-git`, the project is `agents` — so the listing tells you what to type rather
than leaving you to work it out. A session matches its project by path first (including a
checkout nested inside the project directory, which is the usual case) and by name second,
because a path is where the session actually is while a name is a label.

A session with no registered project behind it is called out rather than hidden — it is real
work the registry does not know about, and usually wants a `projects add`.

Remaining arguments pass through to `projects sessions`:

```shell
workon -s -a                  # only sessions with a client attached
workon -s -m studio           # one Mac
workon -s --names | fzf | xargs workon   # pick a live session and open it
workon -s --kill agents       # kill that session, wherever it is running
workon -s --kill agents --yes # ...without the confirmation
```

`--names` prints bare project names for piping, and lists only registered ones — a name
`workon` cannot open is worse than absent. Unreachable Macs report to stderr, so a sleeping
machine stays visible without corrupting a pipe.

`--kill` (`-k`) takes either spelling the listing shows — the tmux session name or the
project key — so the thing you kill is the thing you would have typed `workon` for, without
looking up its real session name first. `--kill django-news.com` finds the `django-news-com`
session, since both sides are slugified.

It prints what it is about to destroy and asks first; `--yes` (`-y`) skips the prompt. Two
refusals are deliberate: a name matching sessions on more than one Mac is reported rather
than resolved, because guessing which copy you meant is not a guess worth making with
someone's running work, and a Mac that failed to answer is reported too, since the session
you are looking for might be on exactly that one.

```shell
$ workon -s --kill agents
Kill toggl-agent-git on studio (mac-studio-2023)?
  3 window(s), detached, in ~/Projects/agents/toggl-agent-git
Everything running in it goes away [y/N]:
```

This overlaps [`tmux-remote-ls`](#scripts) on purpose: that answers "what is running
where", this answers "what do I type to get back into it".

`mkproject` creates the directory, a `uv` venv, and an `.envrc`, registers the project, and
opens it. Creation always happens here, even when the project is registered to another
machine: `~/Projects` and `~/Work` are Syncthing folders, so the directory and its `.envrc`
travel on their own. The venv does not travel — `.venv/` is in `.stignore` — and does not
need to: the generated `.envrc` is `layout uv`, so direnv builds a native one the first time
you enter the directory over there.

No machine is recorded unless you pass `--machine`. A brand-new project has no history
saying where it is worked on, and the directory will exist on every Mac within the minute,
so naming an owner would be inventing a fact.

```shell
mkproject scratch                 # ~/Projects/scratch, no machine, no session
mkproject client-site --work      # ~/Work/client-site
mkproject api --machine studio --python 3.13
mkproject api --tmux              # wire it up for tmux from the start
mkproject api --session api-git   # name the tmux session something else
mkproject api --no-attach         # create and register, don't open
```

The generated `.envrc` is `layout uv`, plus `use tmux <session>` when the project is a tmux
one, so it picks up the [direnv auto-attach](#direnv-auto-attach) machinery and settles on
the same session name the registry uses. (The pre-registry `mkproject` wrote a bare
`source .venv/bin/activate`, which bypasses `layout uv` and never wires up tmux.)

The two halves have to agree: `--tmux` writes `tmux = true` **and** the `use tmux` line,
and without it neither is written. An `.envrc` that autoattaches a session the registry
disclaims would fight itself. The session name is slugified the same way everywhere, so
`mkproject thumb.im --tmux` writes `use tmux thumb-im` rather than a name tmux would reject.

### Managing the registry

| Command | Description |
| ------- | ----------- |
| `projects` / `projects list` | List project names, one per line; `--long`/`-l` groups by machine |
| `projects add NAME` | Register a project |
| `projects set NAME` | Change one project's details in place |
| `projects remove NAME` | Unregister a project; the directory is untouched |
| `projects create NAME` | Create the directory, venv, and `.envrc`, then register |
| `projects import` | Import `~/Projects` and `~/Work`, deciding machines from evidence |
| `projects resolve NAME` | Show machine, path, session, and the command to get there |
| `projects sessions` | Show live tmux sessions on every Mac, mapped to project names |
| `projects machines` | Add, remove, and list machines |
| `projects init` | Create the registry, importing `hosts.toml` if present |
| `projects edit` | Open the registry in `$EDITOR` |

`projects set` is the one to reach for when an entry needs a fact it does not have — which,
after an import, is most of the interesting ones. `add --force` rewrites the whole entry
from its arguments, so anything you do not repeat is dropped; `set` touches only the fields
you name:

```shell
projects set pghub --tmux                      # this one wants a session
projects set pghub --machine studio            # ...and it lives on the Studio
projects set pghub --session pghub-git         # pin the tmux session name
projects set pghub --tmux-path ~/Projects/pghub/pghub-git   # where the session runs
projects set pghub --clear tmux --clear session   # back to the defaults
```

`--clear` unsets `machine`, `tmux`, `tmux_path`, `session`, or `description`, and is
repeatable. `projects set pghub --clear machine` hands a project back to "wherever you are",
which is how you undo a machine that a session justified once and no longer does. Clearing
`tmux` is not the same as `--no-tmux`: the field is a tri-state, and absent means *follow
`[defaults]`* while `false` pins it off regardless of what the default becomes. Only `path`
cannot be cleared — an entry without one cannot be resolved. Paths are stored as `~/...`
however you type them, so they mean the same thing on every Mac.

### Importing an existing setup

`projects import` brings `~/Projects` and `~/Work` in wholesale. The interesting part is how
it picks a machine, because the roots are Syncthing-mirrored — all three Macs hold
substantially the same ~250 directories, so a directory's *presence* proves nothing about
where you actually work on it.

So the import records a machine from evidence, or records none at all:

| Reason | Signal | Machine |
| ------ | ------ | ------- |
| `session` | a tmux session for it is running there, with a client attached | that machine |
| `session-idle` | ...running there, but detached | that machine |
| `workspace` | the cmux session dump pins it to that machine | that machine |
| `default` | the directory exists under a root, and nothing else is known | none |

Every directory under both roots is registered, keyed by its own name. Most come out as two
lines — a name and a path — because a directory that exists on all three Macs is not evidence
of anything, and an entry with no machine opens wherever you are. Of ~250 directories here,
the handful with a live session are the only ones that name one.

A session then *enriches* the entry it belongs to rather than replacing it: `path` stays the
project directory you imported, and the session contributes the machine, `tmux_path`, and
`tmux_session`.

```
agents  ->  studio:~/Projects/agents
              +tmux_path=~/Projects/agents/toggl-agent-git
              +tmux_session=toggl-agent-git          (session)
```

That matters because the bare directory entry alone would point at `~/Projects/agents` and
start a *second* tmux session next to the one already running. The enriched entry attaches
the one that is actually there.

```shell
projects import --dry-run        # show each assignment and the reason for it
projects import                  # apply; only ever adds
projects import --sessions-only  # register just the evidence-backed projects
projects import --no-sessions    # skip the ssh probe entirely (offline)
projects import --force          # re-assign entries whose evidence has since changed
```

`--force` is how a machine-less entry gets promoted once a session exists to prove where it
belongs: it compares machine, path, *and* session name, so an entry pointing at the project
root moves to the checkout the session is really in.

It only ever promotes. A directory with no evidence behind it never rewrites an entry that
already exists, so running `--force` with `--no-sessions`, or while a Mac happens to be
asleep and unreachable, cannot strip the machine and session off everything that Mac owns.
Removing a machine on purpose is `projects set NAME --clear machine`.

#### Names that exist under both roots

Seven directories here share a name between `~/Projects` and `~/Work` (`revsys-office`,
`revsys.com`, `westerveltco-cms`, ...). Both get registered: the `~/Work` copy takes a `work-`
prefix, so `~/Projects/revsys-office` is `revsys-office` and `~/Work/revsys-office` is
`work-revsys-office`. Only the colliding names are renamed — the other 29 `~/Work` projects
keep the plain name you would actually type.

The prefix is applied everywhere a name is derived, so a tmux session running under
`~/Work/revsys-office` enriches `work-revsys-office` rather than quietly landing on its
`~/Projects` namesake.

One collision the prefix cannot fix is still reported rather than silently merged: a session
outside both roots is keyed by its session name and can shadow a real directory — `dotfiles`
runs in `~/.homesick/repos/dotfiles` while `~/Projects/dotfiles` also exists.

`projects scan` is a deprecated alias that forwards here.

`projects list` is bare by default — one name per line, nothing to strip — so it pipes
straight into `grep`, `fzf`, and `xargs`. With 253 projects registered, the grouped view is
the exception rather than the rule:

```shell
projects list                      # 253 bare names
projects list -m studio            # just the ones on the Studio
projects list | fzf | xargs workon  # pick one and open it
projects list --long               # grouped by machine, with paths and sessions
```

`projects resolve --shell` is the interface `workon` consumes; `--json` is the same data
for anything else:

```shell
$ projects resolve django-news
django-news  (remote via mac-studio-2023)
  machine  studio
  path     ~/Work/django-news
  session  django-news
  command  mosh mac-studio-2023 -- bash -lc 'cd "$HOME"/Work/django-news; tmux new-session -A -s django-news -c "$HOME"/Work/django-news'
```

The `~` in a remote path is deliberately left unexpanded: it has to expand against the remote
home directory, not this machine's.

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
use tmux myproject --host myserver                # SSH to a remote host's tmux session
use tmux myproject --host myserver --path /home/jeff/projects/myproject     # with a remote start path
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

Set `--host` (also accepted: `--machine`, `--profile`) to SSH into a remote host's tmux session instead of the local one. All commands — `tmux-go`, `tmux-ls`, `tmux-kill`, and auto-attach — are routed through `ssh -t` automatically.

```shell
# .envrc
use tmux myproject --host myserver

# With a starting directory on the remote host (only applies when creating a new session)
use tmux myproject --host myserver --path /home/jeff/projects/myproject
```

Requires key-based SSH auth (no password prompt) since the connection is non-interactive.

## cmux Workspaces

Scripts in `home/bin/` that keep [cmux][cmux] workspaces and tmux sessions in sync. They are
[uv][uv] inline-script executables — the dependency headers mean they run straight from
`$PATH` with no virtualenv to manage.

| Script | Description |
| ------ | ----------- |
| `cmux-dump-save` | Save the open workspaces to a dump file |
| `cmux-dump-restore` | Recreate workspaces from a dump file |
| `cmux-dump-edit` | Open the dump file in `$EDITOR` |
| `cmux-tmux-sync` | Give unattached tmux sessions a workspace, once; `--host`/`--all` to cover the other Macs |
| `cmux-tmux-watch` | Same as sync, but polling continuously |
| `_cmux.py` | Shared helpers; imported by the above, not run directly |

The two halves work in opposite directions. `cmux-dump-save` / `cmux-dump-restore` treat a
hand-editable file as the source of truth and rebuild workspaces from it. `cmux-tmux-sync` /
`cmux-tmux-watch` treat the running tmux server as the source of truth, so work left behind in a
detached session gets a window back instead of quietly aging out.

### Dump and Restore

```shell
cmux-dump-save          # save open workspaces to ~/.config/cmux/session-dump.toml
cmux-dump-edit          # edit that file to add host / tmux / session fields
cmux-dump-restore       # recreate any workspace that is not already open
```

The dump defaults to `~/.config/cmux/session-dump.toml`; pass a path to use another file, or
`--json` to write JSON. `cmux-dump-restore` and `cmux-dump-edit` detect the format from the extension
and fall back to `session-dump.json` when no TOML file exists.

cmux cannot report whether a workspace is running mosh or tmux, so `host`, `tmux`, and
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
| `host` | Host to mosh to; treated as local if it matches this machine |
| `tmux` | Attach a tmux session in the workspace |
| `session` | Explicit tmux session name, overriding the title-derived one |

```toml
[[workspaces]]
title = "thumb.im"
cwd = "/Users/jefftriplett/Projects/thumb.im/thumb.im-git"
host = "mac-mini-pro-2023"
tmux = true
```

The last three fields combine to decide where a workspace runs:

| Fields | Result |
| ------ | ------ |
| `host` + `tmux = true` | mosh to the host and attach a tmux session there, started in `cwd` |
| `host` only | plain mosh to the host |
| `tmux = true` only | attach a local tmux session, started in `cwd` |
| neither | plain local workspace |

Restoring is safe to rerun: workspaces whose title already exists are skipped, and tmux
sessions use `new-session -A`, so a restore resumes an existing session rather than
duplicating it. Remote workspaces get a `[mosh] ` label on the cmux title; it is display-only
and never reaches the remote tmux session name.

### Sync and Watch

```shell
cmux-tmux-sync --dry-run              # show which local sessions would get a workspace
cmux-tmux-sync                        # create the missing workspaces
cmux-tmux-sync --host mac-studio-2023 # sync that Mac as mosh workspaces
cmux-tmux-sync --all                  # every host in hosts.toml
cmux-tmux-watch                        # keep syncing local sessions as they appear
```

`cmux-tmux-sync` gives a local session a workspace when nothing is attached to it *and* no open
workspace already maps to it. Attached sessions are left alone so opening the new workspace
does not add a second client to a session you are already using; `--include-attached`
overrides that, which is useful when a session is only attached from outside cmux.

### Syncing Across Macs

`--host` (repeatable) and `--all` extend the same idea to the other Macs, using the same ssh
path as `tmux-remote-ls`. A remote session becomes a workspace that moshes to the host and
attaches there, exactly like a `host` + `tmux = true` entry in the dump file.

The unattached test does not carry over. A session on the mini reads as attached because a
workspace *on the mini* holds it, which says nothing about whether this machine can see it —
so a remote session gets a workspace when none here already points at it, regardless of who
else has it open. Remote workspaces are titled `host:session`, so the same session name on two
Macs stays distinct. A host that cannot be reached prints an error and the remaining hosts
still run.

Because most remote sessions *are* attached on their own machine, opening a synced workspace
adds a second client to a live session. With `window-size latest` (the tmux default, and what
these Macs run) the window resizes to whichever client was most recently active, so the other
Mac's view changes size while you work in it. That is the tradeoff for seeing every session
from one place.

`cmux-tmux-watch` polls on an interval (`--interval`, default 5s) and covers both attached and
detached sessions — its only requirement is that no workspace already covers the session. It is
local-only; use `cmux-tmux-sync --all` for the other Macs. Use `--once` for a single pass.

Workspaces are matched to sessions by the same slug `cmux-dump-restore` feeds to `tmux
new-session`, so a workspace titled `thumb.im` counts as covering the `thumb-im` session and
is not created twice. Sessions are attached by name rather than by directory, which matters
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
