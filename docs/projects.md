# Project Registry

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

## workon and mkproject

Registry-aware companions to `workon` and `mkproject`, defined in `home/.bashrc.d/60-workon.bash`.
They are shell functions rather than scripts because the local case has to change the calling
shell's directory and environment.

| Command | Description |
| ------- | ----------- |
| `workon <project>` | Open a project wherever it lives |
| `workon --auto[=<p>]` | The default: consult the registry, then cd locally or mosh out |
| `workon --local[=<p>]` | Force a local cd + virtualenv activation |
| `workon --remote[=<p>]` | Force a mosh to its registered machine |
| `workon --host=<m> <p>` | Open it on that machine instead, just this once; `--machine` is the same flag |
| `workon --tmux <p>` | Attach a tmux session for a local open too |
| `workon --no-tmux <p>` | Plain cd + activate, even when `WORKON_TMUX=1` is set |
| `workon --list` (`-l`) | Print every name completion knows, one per line |
| `workon --sessions` (`-s`) | Show the tmux sessions live on every Mac, and what opens each |
| `workon -s --kill <p>` | Kill a session by project key or session name |
| `workon --help` (`-h`) | Usage |
| `workon-refresh` | Rebuild the completion cache now |
| `mkproject <name>` | Create, register, and open a new project |

There is one `workon` and one `mkproject` — no separate remote command to reach for.
`--auto` is the default and is what plain `workon <project>` does: consult the registry,
then cd locally or mosh out. `--local`, `--remote`, and `--auto` take the name either as
`--local foo` or `--local=foo`; `--host` takes it as `--host studio` or `--host=studio`.
Flags and the name can come in any order. A second bare argument, an unknown flag, or a
`--host` with no machine after it is a usage error with exit code 2.

Two environment variables shape it. `WORKON_TMUX=1` makes every local open attach a
session, as if `--tmux` were passed; `--no-tmux` overrides it for one call.
`WORKON_PROJECT_DIRS` is the list of roots the unregistered fallback and the completion
cache scan, `~/Projects` and `~/Work` by default.

`workon` trusts `projects resolve` and its exit code. Only exit code 3, the resolver's
"not in the registry" answer, sends `workon` to the directory scan. Any other failure —
a registry that does not parse, an entry that fails validation, a `projects` script that
is missing from `$PATH` — is printed and `workon` stops with that exit code, rather than
silently opening a same-named local directory that may not be the project you meant.

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

## Seeing what is running

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

This overlaps [`tmux-remote-ls`](tmux.md#scripts) on purpose: that answers "what is running
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
mkproject api --path ~/Code/api   # somewhere other than home_dir or work_dir
mkproject api --no-attach         # create and register, don't open
mkproject api --dry-run           # print what would be created; nothing runs
```

| Option | Description |
| ------ | ----------- |
| `--machine KEY`, `--host KEY` | Record an owner. `--host` is accepted for symmetry with `workon` and is passed on as `--machine` |
| `--path DIR` | Create the project here instead of `<home_dir>/<name>` |
| `--work` | Create under `work_dir` instead of `home_dir` |
| `--session NAME` | tmux session name when the project key is not what tmux should show |
| `--tmux` / `--no-tmux` | Register `tmux = true` and write `use tmux`, or pin `tmux = false` and leave it out |
| `--python VERSION` | Python for the uv venv; default `3` |
| `--no-attach` | Create and register, but do not `workon` it afterwards |
| `--dry-run` (`-n`) | Print the commands `projects create` would run. Implies `--no-attach` |
| `--help` (`-h`) | Usage |

`mkproject` is a thin wrapper: the first bare word is the name, `--host` is rewritten
to `--machine`, `--no-attach` and `--dry-run` are noted, and everything else goes to
`projects create` untouched. So any option `projects create --help` lists works here, and
an option it rejects is rejected there, with its error message. Tab completion offers the
machine keys after `--machine` or `--host` and a short list of Python versions after
`--python`.

The generated `.envrc` is `layout uv`, plus `use tmux <session>` when the project is a tmux
one, so it picks up the [direnv auto-attach](tmux.md#direnv-auto-attach) machinery and settles on
the same session name the registry uses. (The pre-registry `mkproject` wrote a bare
`source .venv/bin/activate`, which bypasses `layout uv` and never wires up tmux.)

The two halves have to agree: `--tmux` writes `tmux = true` **and** the `use tmux` line,
and without it neither is written. An `.envrc` that autoattaches a session the registry
disclaims would fight itself. The session name is slugified the same way everywhere, so
`mkproject thumb.im --tmux` writes `use tmux thumb-im` rather than a name tmux would reject.

## Managing the registry

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

## Importing an existing setup

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

### Names that exist under both roots

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
