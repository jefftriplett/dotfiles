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
[group("config")]
@config:
    command codex --config

# check for outdated Codex npm package
[group("maintenance")]
@outdated:
    npm outdated @openai/codex

# update Codex CLI to the latest version
[group("maintenance")]
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g @openai/codex
    just --justfile {{ justfile }} version

# see Codex CLI usage
[group("tools")]
@usage:
    bunx @ccusage/codex@latest

# display Codex CLI version
[group("utils")]
@version:
    command codex --version
