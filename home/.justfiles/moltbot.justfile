# ----------------------
# Moltbot recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/moltbot.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# run moltbot doctor to check configuration
@doctor:
    moltbot doctor

# check moltbot health status
@health:
    moltbot health

# install moltbot CLI
@install:
    bun install -g moltbot@latest
    # just --justfile {{ justfile }} restart

# uninstall moltbot CLI
@uninstall:
    bun remove -g moltbot

# restart moltbot daemon
@restart:
    moltbot daemon restart

# upgrade moltbot to the latest version
@upgrade:
    bun install -g moltbot@latest
    -just --justfile {{ justfile }} restart

# display moltbot version
@version:
    moltbot --version
