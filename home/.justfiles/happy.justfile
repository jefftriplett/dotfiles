# ----------------------
# Happy (Claude Code Mobile Client) recipes
# https://happy.engineering
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/happy.justfile"
package := "happy-coder"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# install happy-coder CLI
@install:
    bun install -g {{ package }}
    just --justfile {{ justfile }} version

# run happy CLI
@run:
    happy

# uninstall happy-coder CLI
@uninstall:
    bun remove -g {{ package }}

# upgrade happy-coder to the latest version
@upgrade:
    bun install -g {{ package }}
    just --justfile {{ justfile }} version

# display happy-coder version
@version:
    happy --version
