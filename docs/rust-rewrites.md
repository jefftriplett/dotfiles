# Rust Rewrites

Some of the bash and Python tools in this repo now have Rust versions. The
Rust code lives in one Cargo workspace, `rust/`, with a single `Cargo.lock`
and `target/` directory. The old versions stay in the repo, so you can
compare the output of the two.

## What changed

| Old version | Language | Rust version | Status |
| ----------- | -------- | ------------ | ------ |
| `home/bin/projects-archive` and `home/bin/_projects.py` | Python (uv script) | `projects`, from `rust/projects/` | In use on all three Macs |
| `workon` and `mkproject` in `home/.bashrc.d/60-workon-archive.bash` | bash | `projects workon` and `projects mkproject`, called from `home/.bashrc.d/61-workon.bash` | In use on all three Macs |
| `homesick` (the Ruby gem) | Ruby | `homesick-new`, from `rust/homesick-new/` | Installed on all three Macs; the setup still uses the gem |

`homesick-new` replaces a Ruby gem, not bash or Python. It is in this list
because it is in the same workspace.

## projects

`projects` is a port of `projects-archive`. It manages the project registry in
`~/Projects/projects.toml`. The file format did not change, so the Rust
`projects` and the Python `projects-archive` can both read and write the same
registry. See [Project Registry](projects.md).

The main gain is the start time. The Python `projects list` took about 500 ms
to start, and the Rust version takes a few milliseconds. Because of this,
`workon` tab completion no longer needs a cache.

## workon and mkproject

`workon` and `mkproject` must change the shell that calls them: they run `cd`
and activate a virtualenv. A child process cannot do that. Thus the hidden
`projects workon` and `projects mkproject` subcommands print shell code, and
the two functions in `61-workon.bash` run `eval` on that output.

`projects workon` exits with a non-zero status and prints nothing to stdout
when it fails. Thus a failed lookup never runs part of an answer.

On a Mac that does not have the `projects` binary, `61-workon.bash` falls back
to the old bash versions. See
[How workon resolves a project](workon-process.md).

## homesick-new

`homesick-new` copies the symlink behavior of homesick, without castles. The
repo can live anywhere. `homesick-new` finds it in this order:

1. `--dir PATH`
2. `$HOMESICK_DIR`
3. `$HOMESICK_REPO`
4. `dir` in `~/.config/homesick/config.toml`
5. `~/.homesick/repos/dotfiles`

`homesick-new` does not have castle commands (`clone`, `list`, `generate`,
`destroy`, `exec_all`) or `rc`. It keeps the git commands that homesick
wraps: `status`, `diff`, `pull`, `push` and `commit`.

`just homesick-new-install` puts it in `~/.local/bin` on each Mac. The setup
still uses the Ruby gem. See [Setting up a Mac](setup.md).

## The old versions

The old versions stay in the repo for comparison:

```shell
workon-archive <name>       # the old bash workon
mkproject-archive <name>    # the old bash mkproject
projects-archive list       # the old Python projects
```

## Build and install

```shell
just rust-check     # cargo fmt, clippy, and tests for the workspace
just rust-build     # release build of every tool
just rust-install   # install every tool to ~/.local/bin
just projects-install
just homesick-new-install
```

The release profile uses LTO and strips the binaries. A new tool goes in
`members` in `rust/Cargo.toml`. Shared dependency versions go in
`[workspace.dependencies]`.
