# ----------------------
# Clawdhub recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/clawdhub.justfile"
package := "clawdhub"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# install clawdhub CLI
@install:
    bun add -g {{ package }}

# uninstall clawdhub CLI
@uninstall:
    bun remove -g {{ package }}

# upgrade clawdhub to the latest version
@upgrade:
    bun add -g {{ package }}

# display clawdhub version
@version:
    clawdhub | grep ClawdHub
