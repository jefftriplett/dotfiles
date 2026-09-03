# How `workon` resolves and opens a project

`workon` (defined in `home/.workon.bash`) takes a project name and figures out
where that project lives, then opens it the right way for wherever that turns
out to be. This documents the decision process, not the CLI flags — see
`workon --help` for those.

## 1. Parse arguments

`workon` reads its argv into three things: a `mode` (`auto`, `local`, or
`remote`; default `auto`), an optional `name`, and an optional `host` override.
`--list` and `--sessions` short-circuit immediately and don't go through
resolution at all. No name means: print usage and the project list, then exit
non-zero.

## 2. Resolve the name

`workon` shells out to `projects resolve <name> --shell [--host <host>]`. That
command looks the name up in the registry (`~/Projects/projects.toml`) and
prints a block of shell variable assignments, which `workon` captures and
`eval`s into local variables (`WORKON_RESOLVED_NAME`, `_KIND`, `_MACHINE`,
`_HOST`, `_PATH`, `_PROJECT_PATH`, `_SESSION`, `_TMUX`, `_ARGV`).

**If the name isn't in the registry**, `projects resolve` fails and `workon`
falls back to the pre-registry behavior (step 3a) — unless `--remote` or
`--host` was explicitly requested, in which case it errors out: an
unregistered project has no machine to reach remotely, so `workon` says so and
suggests `projects add`.

## 3. Open the project

### 3a. Not in the registry — directory scan fallback

Search `WORKON_PROJECT_DIRS` (`~/Projects`, `~/Work`) for a directory matching
the name. Found → `cd` in and activate a virtualenv (step 4). Not found → try
a bare `~/.virtualenvs/<name>` (the pre-registry `mkvirtualenv` convention),
`cd`-ing into its `src/` if one exists. Still not found → error, having
searched the registry, the project dirs, and `~/.virtualenvs`.

### 3b. In the registry — local or remote?

The resolved `WORKON_RESOLVED_KIND` says whether the project belongs to this
machine or another one. A project with `tmux = false` in the registry forces
`want_tmux` off regardless of `--tmux`/`WORKON_TMUX` — it has deliberately
opted out of sessions.

- **`mode=local`** — always opens locally (step 3c), even if the registry
  says the project lives elsewhere.
- **`mode=remote`** — requires the resolved kind to actually be `remote`; if
  it's local instead, `workon` explains why (registered here, or registered
  nowhere) and tells you how to fix it, rather than silently opening local.
- **`mode=auto`** (default) — does whatever the resolved kind says: local
  project → step 3c, remote project → step 3d.

### 3c. Opening locally

Expand the registry's `~`-relative path for this machine, then `cd` into it.
If the directory doesn't exist, error out with the `projects add --force`
fix. Then:

- **`want_tmux=1`**: attach a tmux session via `tmux-go`, in a subshell that
  unsets any inherited `TMUX_AUTOATTACH_HOST`/`_MACHINE` and sets
  `TMUX_AUTOATTACH_PATH` — the registry has already established this project
  is local, so nothing should try to reach it over the network.
- **otherwise**: activate a virtualenv (step 4). This is the default and
  stays fast — a local `workon` has always been a `cd` + activate, not a tmux
  attach.

### 3d. Opening remotely

Title the terminal tab, print which project/machine/host is being opened, and
run the resolver's pre-built `WORKON_RESOLVED_ARGV` (a mosh or ssh command
that attaches the remote tmux session) via `direnv exec /` — stepping outside
the current project's direnv environment so it can't re-trigger a local
autoattach.

## 4. Activate a virtualenv

Try, in order: `.venv`, `venv`, `env` under the project directory, then
`~/.virtualenvs/<name>`. First one with a `bin/activate` wins: deactivate any
currently active venv, source the new one, report what was activated. None
found → say so and leave the shell as-is (still `cd`'d into the project).

## Completion

Tab-completion for project names is served from a cache at
`${XDG_CACHE_HOME:-~/.cache}/workon/names`, rebuilt only when
`projects.toml`, `WORKON_PROJECT_DIRS`, or `~/.virtualenvs` is newer than the
cache (four `stat`s via bash's `-nt`, no subprocess in the common case). A
full rebuild merges the registry (`projects list`), a scan of the project
dirs, and a scan of `~/.virtualenvs`, deduped and sorted. `workon-refresh`
forces this rebuild on demand.

## `mkproject`

`mkproject <name>` delegates directory/venv/`.envrc` creation to
`projects create`, which also registers the project, then calls `workon
<name>` to open it (unless `--no-attach`/`--dry-run`) — so a freshly created
project goes through the exact same resolution and open logic as any other.
