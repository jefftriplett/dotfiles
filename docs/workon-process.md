# How `workon` resolves and opens a project

`workon` takes a project name, works out where that project lives, and opens
it the right way for wherever that turns out to be. This documents the decision
process, not the CLI flags — see `workon --help` for those.

## Where the logic lives

`workon` and `mkproject` are shell functions in `home/.bashrc.d/61-workon.bash`,
but they make no decisions. Each is four lines: run the Rust `projects` binary
(`projects workon` or `projects mkproject`), and `eval` the shell code it
prints.

```bash
workon() {
    local code
    code="$(command projects workon "$@")" || return $?
    eval "$code"
}
```

They have to be functions because the local case changes the calling shell —
a `cd` and a virtualenv activation — which no child process can do. So the
binary does everything else and hands back only the lines that act on its
answer: a `cd`, a `source .venv/bin/activate`, a `tmux-go`, or a `mosh`
command.

When the binary fails it prints the error to stderr, exits non-zero, and
prints no shell code at all, so a failed lookup never evals half an answer.
Anything meant for the terminal, such as `--help` or `--list`, comes back as a
`printf` so it prints when eval'd.

On a Mac where `projects` has not been built yet (`just projects-install`),
`61-workon.bash` falls back to the archived bash versions, `workon-archive` and
`mkproject-archive` in `60-workon-archive.bash`, so `workon` never goes
missing.

## 1. Parse arguments

`projects workon` reads its argv into four things: a `mode` (`auto`, `local`,
or `remote`; default `auto`), an optional `name`, an optional `host` override
(`--host` or its alias `--machine`, with or without `=`), and a `want_tmux`
flag that starts from `$WORKON_TMUX` and is set by `--tmux` or cleared by
`--no-tmux`. `--help`, `--list`, and `--sessions` short-circuit immediately
and don't go through resolution at all; `--sessions` hands every argument
after it to `projects sessions`. A second bare word, an unknown flag, or a
`--host` with nothing after it is a usage error, exit code 2. No name means:
print usage and the project list, then return 1.

## 2. Resolve the name

The binary loads the registry (`~/Projects/projects.toml`) and looks the name
up directly: an exact key first, then a loose match, so `thumb-im` finds a
project registered as `thumb.im`.

Only one outcome means "not found":

| Outcome | What `workon` does |
| ------- | ------------------ |
| The name is registered | Plan the open (step 3b) |
| The name is not registered | Fall back to the directory scan (step 3a) |
| The registry cannot be loaded | Print the error and stop with exit code 2 |

The third row is deliberate. A registry that fails to parse, or an entry that
fails validation, must not look like "not registered" and fall through to a
same-named directory under `~/Projects`. Those errors stay visible.

**If the name isn't in the registry** and `--remote` or `--host` was
explicitly requested, `workon` errors out instead of scanning: an unregistered
project has no machine to reach remotely, so `workon` says so and suggests
`projects add`.

`--host` is a one-off: it plans the open as if the project lived on that
machine, without writing anything back to the registry.

## 3. Open the project

### 3a. Not in the registry — directory scan fallback

Search `~/Projects` and `~/Work` for a directory matching the name. Found →
`cd` in and activate a virtualenv (step 4). Not found → try a bare
`~/.virtualenvs/<name>` (the pre-registry `mkvirtualenv` convention),
`cd`-ing into its `src/` if one exists. Still not found → error, having
searched the registry, the project dirs, and `~/.virtualenvs`.

### 3b. In the registry — local or remote?

The plan says whether the project belongs to this machine or another one. A
project with `tmux = false` in the registry forces `want_tmux` off regardless
of `--tmux`/`WORKON_TMUX` — it has deliberately opted out of sessions.

- **`mode=local`** — always opens locally (step 3c), even if the registry
  says the project lives elsewhere.
- **`mode=remote`** — requires the project to actually be remote; if it's
  local instead, `workon` explains why (registered here, or registered
  nowhere) and tells you how to fix it, rather than silently opening local.
- **`mode=auto`** (default) — does whatever the plan says: local project →
  step 3c, remote project → step 3d.

### 3c. Opening locally

Expand the registry's `~`-relative path for this machine and check that the
directory exists. If it doesn't, error out with the `projects add --force`
fix. Otherwise the emitted code `cd`s into it, then:

- **`want_tmux`**: attach a tmux session via `tmux-go`, in a subshell that
  unsets any inherited `TMUX_AUTOATTACH_HOST`/`_MACHINE` and sets
  `TMUX_AUTOATTACH_PATH` — the registry has already established this project
  is local, so nothing should try to reach it over the network.
- **otherwise**: activate a virtualenv (step 4). This is the default and
  stays fast — a local `workon` is a `cd` + activate, not a tmux attach.

### 3d. Opening remotely

Title the terminal tab, print which project/machine/host is being opened, and
run the planned command — `mosh <host> -- bash -lc '...'`, or `ssh -t` when
mosh is not installed — via `direnv exec /`, stepping outside the current
project's direnv environment so it can't re-trigger a local autoattach. The
command lands in the project directory on the far side and attaches its tmux
session when the entry has `tmux = true`, or starts a login shell there when
it doesn't.

## 4. Activate a virtualenv

Try, in order: `.venv`, `venv`, `env` under the project directory, then
`~/.virtualenvs/<name>`. First one with a `bin/activate` wins: deactivate any
currently active venv, source the new one, report what was activated. None
found → say so and leave the shell as-is (still `cd`'d into the project).

## Completion

Tab completion calls `projects names` on every TAB: registered projects, then
any directory under `~/Projects` and `~/Work`, then `~/.virtualenvs` entries
with a `bin/activate`, deduped and sorted. It takes a few milliseconds, so
there is no cache to go stale and nothing to refresh by hand. `workon --list`
prints the same list.

Completion is context-aware: after `--host` or `--machine` it offers machine
keys from `projects machines`; on a partial `--local=`, `--remote=`, or
`--auto=` it completes the name after the `=`; on a bare `-` it offers the
flags.

## `mkproject`

`mkproject <name>` works the same way: `projects mkproject` parses the
arguments and prints `projects create <name> ...`, followed by
`workon <name>` unless `--no-attach` or `--dry-run` was given. So a freshly
created project goes through the exact same resolution and open logic as any
other, and if `projects create` fails, `mkproject` returns its exit code and
never calls `workon`.

The argument pass is minimal on purpose. The first bare word is the name.
`--host KEY` (either spelling) is rewritten to `--machine KEY`, so the flag
matches `workon`. `--no-attach` is consumed and never reaches `projects
create`; `--dry-run`/`-n` is both consumed (no attach) and forwarded (print
only). Every other argument, flag or not, is forwarded verbatim, which is why
the option list in [Project Registry](projects.md#workon-and-mkproject) is
really the option list of `projects create`.
