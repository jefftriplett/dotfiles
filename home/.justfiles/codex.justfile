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
    codex --config

# update Codex CLI to the latest version
@upgrade:
    npm install -g @openai/codex
