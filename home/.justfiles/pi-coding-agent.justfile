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

# install pi-coding-agent CLI
@install:
    bun install -g @mariozechner/pi-coding-agent

# upgrade pi-coding-agent to the latest version
@upgrade:
    bun install -g @mariozechner/pi-coding-agent

# display pi-coding-agent version
@version:
    pi-coding-agent --version
