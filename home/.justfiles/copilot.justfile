# ----------------------
# Copilot recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/copilot.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# open Copilot configuration file in Sublime Text
[group("config")]
@config:
    command copilot --config

# check for outdated Copilot npm package
[group("maintenance")]
@outdated:
    npm outdated @github/copilot

# update Copilot CLI to the latest version
[group("maintenance")]
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g @github/copilot
    just --justfile {{ justfile }} version

# display Copilot CLI version
[group("utils")]
@version:
    command copilot --version
