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

# display Copilot CLI version
@version:
    copilot --version
