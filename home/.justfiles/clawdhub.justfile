# ----------------------
# Clawdhub recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/clawdhub.justfile"

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
    bun add -g clawdhub

# uninstall clawdhub CLI
@uninstall:
    bun remove -g clawdhub

# upgrade clawdhub to the latest version
@upgrade:
    bun add -g clawdhub

# display clawdhub version
@version:
    clawdhub | grep ClawdHub
