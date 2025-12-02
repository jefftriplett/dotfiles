# ----------------------
# Codex recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/codex.justfile"

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

# check for outdated Codex npm package
@outdated:
    npm outdated @openai/codex

# update Codex CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g @openai/codex
    just --justfile {{ justfile }} version

# see Codex CLI usage
@usage:
    bunx @ccusage/codex@latest

# display Codex CLI version
@version:
    command codex --version
