# One file that knows where all my projects live

*Draft — not published yet.*

I work across three Macs — a Studio, a Mini, and a MacBook Air — and for a long
time the answer to "where is that project running?" was "let me go look."

My `workon` function finds projects by scanning `~/Projects` and `~/Work`. That
works great, right up until the project you want is a tmux session on a
different machine. A directory scan structurally cannot see that. So I'd end up
running `tmux-remote-ls`, reading the output, and then hand-typing a `mosh`
command with the right session name.

So I built a registry: `~/Projects/projects.toml`.

## The file

```toml
[machines.studio]
host = "mac-studio-2023"

[machines.mini]
host = "mac-mini-pro-2023"

[machines.air]
host = "mba-2025"
hostname = "MacBook-Air-2025"   # only when it differs from the ssh name

[defaults]
tmux = false
home_dir = "~/Projects"
work_dir = "~/Work"

[projects.notes]
path = "~/Projects/notes"

[projects.pghub]
machine = "mini"
path = "~/Projects/pghub"
tmux = true
tmux_path = "~/Projects/pghub/pghub-git"   # optional
tmux_session = "pghub-git"
```

Each machine gets a short key I actually want to type (`studio`) plus the ssh
name that has to resolve (`mac-studio-2023`). That `hostname` field exists for
one annoying reason: the Air answers to `mba-2025` over ssh but reports
`MacBook-Air-2025` as its own hostname. Without the mapping, the Air doesn't
recognize itself and cheerfully tries to mosh into its own address.

`path` is the project directory. `tmux_path` is the checkout *inside* it where
the work actually happens. I kept those as two fields because on my machine
they differ constantly — the project is `~/Projects/pghub`, but the session
lives in `~/Projects/pghub/pghub-git`. `tmux_path` is optional and only written
when the two differ.

Notice how little the `notes` entry says. `machine` is optional, and leaving it
out means the project opens wherever I am — which is the truth about a
Syncthing-mirrored directory nothing has claimed. I went back and forth on this
and landed hard: an entry states facts I know, not defaults I've inferred. Most
of mine are two lines.

## Using it

Two commands, both shell functions:

```shell
workon notes           # unclaimed: cd in, activate, right here
workon pghub           # claimed by the Mini: mosh over, attach there
workon                 # no args: list everything registered
```

`projects list` is bare by default — one name per line, nothing to strip — which
makes the obvious thing work:

```shell
projects list | fzf | xargs workon
```

With 253 projects registered, the pretty grouped view is the exception, so it
lives behind `--long` rather than being what you have to pipe through `cut`.

That's the whole point. One command, same muscle memory, and I stopped caring
which machine a thing is on.

Names match loosely, too. A project registered as `thumb.im` also answers to
`thumb-im`, because that's the slug tmux actually shows you and it's what my
fingers type.

New projects:

```shell
mkproject scratch                  # ~/Projects/scratch, unclaimed, no session
mkproject client-site --work       # ~/Work/client-site
mkproject api --machine studio --tmux --python 3.13
```

This creates the directory, a `uv` venv, and an `.envrc`, registers the project,
and opens it.

Creation always happens on the machine I'm sitting at, even when the project is
registered to another one. I built an ssh path for this at first and then
deleted it, because `~/Projects` and `~/Work` are Syncthing folders — the
directory and its `.envrc` show up on the other Macs by themselves. The venv
doesn't travel, since `.venv/` is in my `.stignore`, and it doesn't need to:
`layout uv` builds a native one the first time direnv sees the directory over
there. `--machine` says which machine *owns* the project, which is what `workon`
routes on. It was never a statement about where the `mkdir` runs.

It's also not recorded unless I ask for it. An early version defaulted the
machine from which root the directory landed under — `~/Work` implied the
Studio — and that's the same mistake as the import made, dressed up as a rule
instead of a guess. A brand-new project has no history saying where I'll work
on it, and Syncthing will have put it on all three Macs before I've finished
typing. So it starts unclaimed, and earns a machine later if it earns one at
all.

The generated `.envrc` is one line, or two for a tmux project:

```shell
layout uv
use tmux api    # only with --tmux
```

Which is a small fix to an old bug of mine. My previous `mkproject` wrote a bare
`source .venv/bin/activate`, which bypassed the `layout uv` I'd defined in my
direnvrc and never wired the project into tmux at all. New projects were born
outside all the machinery I'd built for them.

## Not everything wants a tmux session

Most projects are a directory I poke at for ten minutes. Starting a persistent
tmux session for those is noise, and it clutters `tmux-remote-ls` on every
machine forever.

My first version had `tmux = true` in `[defaults]`, which meant every one of
253 imported projects was a session waiting to happen. I flipped it. A project
gets a tmux session because it asked for one, not because it failed to object —
and opening a project is a cd and a virtualenv activation until something says
otherwise.

There are three places to say otherwise, depending on how permanent the answer
is. Just this once, at the point of use:

```shell
workon notes --tmux      # attach a session after all
workon notes --no-tmux   # never mind
```

At creation, when I already know:

```shell
mkproject api --tmux
```

And after the fact, which is the one I actually use, because I'm usually wrong
about which projects deserve a session until I've lived with them:

```shell
projects set notes --tmux       # on
projects set notes --no-tmux    # off, and pinned off
projects set notes --clear tmux # back to whatever [defaults] says
```

That third form matters more than it looks. `tmux` is a tri-state — `true`,
`false`, or absent — and absent means *follow the default*, not *off*. Clearing
it hands the project back to `[defaults] tmux`, so if I ever flip that global
again, the project flips with it. `--no-tmux` pins it against the default
regardless. Those are different intentions and the file records which one I
meant.

The subtle part is that `--tmux` at creation has to change **two** things. The
registry entry gets `tmux = true`, and the generated `.envrc` gains its
`use tmux` line. Without the flag, neither is written:

```shell
layout uv
```

Get that pair out of step and direnv cheerfully autoattaches a session the
moment I `cd` into the directory — a session the registry just finished saying
the project doesn't want. Two systems, one opinion, and I'd have shipped it
disagreeing with itself if I hadn't gone looking.

## Importing 253 projects

The interesting part was the import, and it's where my first attempt was
straightforwardly wrong.

My initial version assigned machines by which root a directory sat under:
everything in `~/Projects` goes to the Mini, everything in `~/Work` goes to the
Studio. Reasonable-sounding. Completely useless in practice, because my project
directories are Syncthing-mirrored. All three Macs hold substantially the same
253 directories. A directory's *presence* on a machine tells you nothing at all
about where you work on it.

What does tell you? A running tmux session. That's not a guess — that's a
process, with a working directory, that exists because I sat down and started
working.

So `projects import` records a machine from evidence, or records none at all:

| Reason | Signal | Machine |
| ------ | ------ | ------- |
| `session` | a tmux session is running there, with a client attached | that one |
| `session-idle` | ...running there, but detached | that one |
| `workspace` | my cmux session dump pins it to that machine | that one |
| `default` | the directory exists, and that's all I know | none |

```shell
projects import --dry-run        # every assignment, with the reason for it
projects import                  # apply it
projects import --sessions-only  # only the ones with real evidence
projects import --no-sessions    # offline; just register the directories
```

That last row started out as `home_machine`/`work_machine` — the same
root-implies-machine rule I'd already talked myself out of, quietly reinstated
as the fallback. Writing it down as a table is what made it obvious. I'd built
an evidence ranking and then put a guess at the bottom of it, which meant 241
of my entries were confident assertions about where I work, most of them wrong,
each one an invitation to mosh across the network to open a directory that was
already sitting in front of me.

Now they just don't have a machine. On my setup: **253 projects, 12 that name a
machine, 241 that open wherever I am.** Those 12 are every project I've touched
in weeks. The other 241 are repos I cloned once to read, and "wherever you are"
is exactly right for them.

## Enrich, don't replace

My second wrong turn was letting the session *overwrite* the path. If a session
was running in `~/Projects/agents/toggl-agent-git`, that became the project's
path — and the `~/Projects/agents` directory I'd actually asked to import
disappeared from the registry.

Now the session enriches the entry instead:

```
would  agents -> studio:~/Projects/agents
                   +tmux_path=~/Projects/agents/toggl-agent-git
                   +tmux_session=toggl-agent-git          (session)
```

`path` stays the thing I imported. The session contributes the machine,
`tmux_path`, and `tmux_session` on top. Both facts survive, and `workon` lands
in `tmux_path` when there is one.

That last bit is most of the value, and it's subtle: without it, `workon
agents` would `cd` to `~/Projects/agents` and start a **second** tmux session
next to the one already running in the checkout. With it, I attach the session
that's actually there.

Since the import now leaves most entries unclaimed, `projects set` is how one
earns its details later — a field at a time, without disturbing the rest:

```shell
projects set pghub --machine studio
projects set pghub --tmux-path ~/Projects/pghub/pghub-git
projects set pghub --session pghub-git
projects set pghub --clear machine    # ...and back to unclaimed
```

Same command as the `--tmux` toggling above, and for the same reason: the entry
is a set of independent facts, and I want to add or correct one of them without
restating the others. `--clear machine` is there because unowned is a real
state, not an error — it's how I undo a machine that a session justified once
and doesn't any more.

I wanted this the first time I tried to fix a guess with `add --force` and
silently dropped the `tmux_path` I wasn't repeating. `--force` rewrites the
whole entry from its arguments; `set` touches only what you name. `--clear`
unsets a field outright — `machine`, `tmux`, `tmux_path`, `session`,
`description`. Only `path` is exempt, because an entry without one can't be
resolved at all.

Making "unclaimed" the normal state had one consequence I nearly shipped. The
import's `--force` mode re-assigns entries whose evidence has changed, and now
that a bare directory carries *no* machine, a `--force` run with the Studio
asleep — or with `--no-sessions` — would have "re-assigned" every project on it
to nothing. Dressed up as an update. So `--force` only promotes: a candidate
with no evidence behind it never rewrites an entry that already exists. Erasing
is a thing you have to ask for by name.

## Two names, one key

Seven of my directories exist under *both* `~/Projects` and `~/Work` —
`revsys-office`, `revsys.com`, `westerveltco-cms`, and friends. I have no idea
how long that's been true.

My first import just dropped one of each pair, which is the sort of quiet data
loss that makes a tool untrustworthy. Now both get registered, and the `~/Work`
copy takes a `work-` prefix:

```toml
[projects.revsys-office]        # ~/Projects/revsys-office
[projects.work-revsys-office]   # ~/Work/revsys-office
```

Only the colliding names get renamed. The other 29 Work projects keep the plain
name I'd actually type. And the prefix is applied everywhere a name gets
derived — directory listings, tmux session paths, cmux dump paths — so a session
running under `~/Work/revsys-office` enriches `work-revsys-office` and not its
`~/Projects` namesake.

## What else it found

Turning a pile of directories into a registry is a great way to discover your
directories were lying to you.

`~/Projects/dotfiles` and `~/.homesick/repos/dotfiles` are two different
directories with the same name. My dotfiles session runs in the second one. The
`work-` prefix can't help here, so the import reports the collision instead of
silently picking one — it's my mess to clean up, not the tool's to hide.

And a subtler one: the `cwd` recorded in my cmux session dump is deliberately
the *local* home directory for remote workspaces — a trick so the pane doesn't
trigger a local tmux autoattach before the mosh command runs. My first import
took that field literally and registered five projects pointing at `~`. It now
treats those entries as machine-only hints and matches them to real directories
by slugifying and dropping a trailing `-git`, so `djangotv-com-git` finds
`djangotv.com`.

## Implementation notes

`projects` is a `uv run --script` with inline dependencies (pydantic, rich,
tomlkit, typer), same as the rest of my `~/bin`. The registry model is pydantic:

```python
class Project(BaseModel):
    key: str
    machine: str | None = None
    path: str = ""
    tmux: bool | None = None
    session: str | None = None
    tmux_path: str | None = None
    description: str | None = None
```

The shared `_cmux.py` that all my `cmux-*` and `tmux-remote-*` scripts import
deliberately stays on plain dataclasses. Those scripts each declare their own
dependencies, and none of them should have to grow a pydantic dep just to
import a helper. Keeping pydantic on the one script that needs it costs nothing
and keeps the others lean.

Note how many of those fields are `| None`. That's the whole design in one
class: `machine` unset means "wherever you are", `tmux` unset means "follow the
default", and neither is the same as a value that happens to be falsy. Getting
tri-states right in the model is what let me stop writing guesses to disk.

Output goes through rich, with a theme keyed to *meaning* rather than colour —
strong evidence is green, an entry with nothing behind it is dim — so a
253-line import scan tells you at a glance which handful of assignments are
real.

The one thing to be careful about: `--shell` and `--json` output must bypass
rich entirely and use builtin `print`. `--shell` gets `eval`'d by the shell
function, and rich would hard-wrap the long `mosh ... bash -lc '...'` argv at
the terminal width and corrupt the command. Rich also parses `[...]` as markup,
which ate a literal `[defaults]` in one of my warning messages before I turned
markup off for those.

`workon` and `mkproject` are shell functions rather than scripts,
because the local case has to change the calling shell's directory and
environment. They shell out to `projects resolve --shell`, which emits
shell-quoted assignments to `eval`. Everything gets quoted on the Python side,
so a path with a space in it survives the round trip.

## Was it worth it

The registry replaced four separate places that used to hold overlapping
fragments of the same fact: a `hosts.toml` machine list, per-project `.envrc`
variables in two different naming schemes, and a hardcoded directory list in my
shell functions. Those could disagree with each other, and did.

Mostly, though, I just type `workon pghub` now and end up in the right
place on the right machine. That's the feature.
