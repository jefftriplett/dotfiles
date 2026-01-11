# ----------------------
# Clawdbot recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/clawdbot.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# run clawdbot doctor to check configuration
@doctor:
    clawdbot doctor

# check clawdbot health status
@health:
    clawdbot health

# install clawdbot CLI
@install:
    bun install -g clawdbot@latest
    just --justfile {{ justfile }} doctor
    just --justfile {{ justfile }} restart
    just --justfile {{ justfile }} health

# restart clawdbot daemon
@restart:
    clawdbot daemon restart

# upgrade clawdbot to the latest version
@upgrade:
    bun install -g clawdbot@latest
    just --justfile {{ justfile }} doctor
    just --justfile {{ justfile }} restart
    just --justfile {{ justfile }} health

# display clawdbot version
@version:
    clawdbot --version
