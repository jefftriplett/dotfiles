# ----------------------
# Codex recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/codex.justfile"
package := "@openai/codex"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# open Codex configuration file in Sublime Text
@config:
    command codex --config

# install Codex CLI
@install:
    bun install -g {{ package }}

# uninstall Codex CLI
@uninstall:
    bun remove -g {{ package }}

# update Codex CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    bun install -g {{ package }}
    just --justfile {{ justfile }} version

# see Codex CLI usage
@usage:
    bunx @ccusage/codex@latest

# display Codex CLI version
@version:
    command codex --version
