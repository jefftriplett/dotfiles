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
    copilot --config

# check for outdated Copilot npm package
@outdated:
    npm outdated @github/copilot

# update Copilot CLI to the latest version
@upgrade:
    npm install -g @github/copilot

# display Copilot CLI version
@version:
    copilot --version
