# Installation

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

See [Just Recipes](just.md) for the full list of recipes.
