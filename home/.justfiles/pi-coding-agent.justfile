# ----------------------
# Pi Coding Agent recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/pi-coding-agent.justfile"
package := "@earendil-works/pi-coding-agent"
legacy_package := "@mariozechner/pi-coding-agent"

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
    bun remove -g {{ legacy_package }} || true
    bun install -g {{ package }}
    pi --version

# list available models
@list-models *ARGS:
    pi --list-models {{ ARGS }}

# resume a previous pi session
@resume:
    pi --resume

# uninstall pi-coding-agent CLI
@uninstall:
    bun remove -g {{ package }}
    bun remove -g {{ legacy_package }} || true

# upgrade pi-coding-agent to the latest version
@upgrade:
    bun remove -g {{ legacy_package }} || true
    bun install -g {{ package }}
    pi --version

# display pi-coding-agent version
@version:
    pi --version
