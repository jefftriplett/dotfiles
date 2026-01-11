# ----------------------
# Pi Coding Agent recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/pi-coding-agent.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# display pi CLI help
@help:
    pi --help

# install pi-coding-agent CLI
@install:
    bun install -g @mariozechner/pi-coding-agent
    just --justfile {{ justfile }} version

# list available models
@list-models *ARGS:
    pi --list-models {{ ARGS }}

# resume a previous pi session
@resume:
    pi --resume

# upgrade pi-coding-agent to the latest version
@upgrade:
    bun install -g @mariozechner/pi-coding-agent
    just --justfile {{ justfile }} version

# display pi-coding-agent version
@version:
    pi --version
