# ----------------------------------------------------------------
# Homebrew and general wrappers - https://brew.sh
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/homebrew.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# @install *ARGS:
#     llm install {{ARGS}} llm-claude
#     # llm install {{ARGS}} llm-ollama
# @upgrade:
#     just --justfile {{ justfile }} install --upgrade

@cleanup DAYS="0":
    brew cleanup --prune={{ DAYS }}

@freeze:
    # touch "$HOME/.homesick/repos/dotfiles/home/Brewfile.$HOST"
    cd "$HOME/.homesick/repos/dotfiles/home" && \
        mv "Brewfile.$HOST" "Brewfile.$HOST.bak" && \
        brew bundle dump --file="Brewfile.$HOST" --no-vscode

@outdated:
    brew outdated

@services:
    brew services

services-restart:
    #!/bin/bash

    # Get the list of started services
    started_services=$(brew services list | awk '$2 == "started" {print $1}')

    # Loop through each service and restart it
    for service in $started_services; do
        # echo "Restarting $service..."
        brew services restart $service
    done

    # echo "All started services have been restarted."

@services-stop:
    # -brew services stop yabai
    # -brew services stop spacebar
    # -brew services stop skhd
    -brew services stop ollama

@update:
    brew update

@upgrade:
    brew upgrade || true
