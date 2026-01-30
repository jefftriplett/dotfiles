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
@config:
    command copilot --config

# check for outdated Copilot npm package
@outdated:
    npm outdated @github/copilot

# uninstall Copilot CLI
@uninstall:
    npm uninstall -g @github/copilot

# update Copilot CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g @github/copilot
    just --justfile {{ justfile }} version

# display Copilot CLI version
@version:
    command copilot --version
