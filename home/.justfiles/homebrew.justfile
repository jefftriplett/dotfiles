# ----------------------------------------------------------------
# Homebrew and general wrappers - https://brew.sh
# ----------------------------------------------------------------

set dotenv-load := false
set export

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
[arg("DAYS", long="days", pattern='\d+|all', help="prune cache older than DAYS, or 'all'")]
@cleanup DAYS="0":
    brew cleanup --prune={{ DAYS }}

# freeze current Homebrew packages to Brewfile
@freeze:
    cd "$HOME/.homesick/repos/dotfiles/home" && \
        { [ -f "Brewfile.$HOST" ] && mv "Brewfile.$HOST" "Brewfile.$HOST.bak" || true; } && \
        brew bundle dump --file="Brewfile.$HOST" --no-vscode

# list outdated Homebrew packages
@outdated:
    brew outdated

# list all Homebrew services
@services:
    brew services

# restart all running Homebrew services
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
@services-stop:
    # -brew services stop yabai
    # -brew services stop spacebar
    # -brew services stop skhd
    -brew services stop ollama

# update Homebrew package database
@update:
    brew update

# upgrade all outdated Homebrew packages
@upgrade:
    brew upgrade --yes || true
