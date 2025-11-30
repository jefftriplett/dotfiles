# ----------------------------------------------------------------
# Homebrew and general wrappers - https://brew.sh
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/homebrew.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# clean up old Homebrew packages and cache
[group("maintenance")]
@cleanup DAYS="0":
    brew cleanup --prune={{ DAYS }}

# freeze current Homebrew packages to Brewfile
[group("utils")]
@freeze:
    # touch "$HOME/.homesick/repos/dotfiles/home/Brewfile.$HOST"
    cd "$HOME/.homesick/repos/dotfiles/home" && \
        mv "Brewfile.$HOST" "Brewfile.$HOST.bak" && \
        brew bundle dump --file="Brewfile.$HOST" --no-vscode

# list outdated Homebrew packages
[group("maintenance")]
@outdated:
    brew outdated

# list all Homebrew services
[group("services")]
@services:
    brew services

# restart all running Homebrew services
[group("services")]
@services-restart:
    #!/bin/bash

    # Get the list of started services
    started_services=$(brew services list | awk '$2 == "started" {print $1}')

    # Loop through each service and restart it
    for service in $started_services; do
        # echo "Restarting $service..."
        brew services restart $service
    done

    # echo "All started services have been restarted."

# stop specific Homebrew services (with non-fatal errors)
[group("services")]
@services-stop:
    # -brew services stop yabai
    # -brew services stop spacebar
    # -brew services stop skhd
    -brew services stop ollama

# update Homebrew package database
[group("maintenance")]
@update:
    brew update

# upgrade all outdated Homebrew packages
[group("maintenance")]
@upgrade:
    brew upgrade || true
