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

@outdated:
    npm outdated @openai/codex

# update Codex CLI to the latest version
@upgrade:
    npm install -g @openai/codex

# see Codex CLI usage
@usage:
    bunx @ccusage/codex@latest

# display Codex CLI version
@version:
    codex --version
