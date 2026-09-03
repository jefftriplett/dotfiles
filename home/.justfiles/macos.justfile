# ----------------------------------------------------------------
# macOS recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export

justfile := justfile_directory() + "/.justfiles/macos.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# ----------------------------------------------------------------
# Time Machine recipes
# ----------------------------------------------------------------

# boost Time Machine backup speed by increasing IO priority
@timemachine-boost:
    # bump IO priority to finish more quickly
    # https://apple.stackexchange.com/questions/382772/time-machine-in-the-cleaning-up-state-forever

    sudo sysctl debug.lowpri_throttle_enabled=0

# restore normal IO priority after Time Machine backup completes
@timemachine-boost-complete:
    # once done
    sudo sysctl debug.lowpri_throttle_enabled=1

# delete specific Time Machine backups
@timemachine-delete +ARGS:
    sudo tmutil delete {{ ARGS }}

# list all Time Machine backups
@timemachine-list:
    sudo tmutil listbackups

# ----------------------------------------------------------------
# Xcode
# ----------------------------------------------------------------

# install Xcode command line tools
@xcode-bootstrap:
    sudo xcode-select --install

# upgrade Xcode command line tools by removing and reinstalling
@xcode-upgrade:
    sudo rm -rf /Library/Developer/CommandLineTools
    just --justfile {{ justfile }} xcode-bootstrap

# ----------------------------------------------------------------
# Default applications (duti)
# ----------------------------------------------------------------

# set default applications for file types using duti
@duti-setup:
    brew install duti

    # 3D printing
    duti -s com.bambulab.bambu-studio .stl all
    duti -s com.bambulab.bambu-studio .3mf all

# ----------------------------------------------------------------
# Sublime Text
# ----------------------------------------------------------------

sublime_user := env_var("HOME") + "/Library/Application Support/Sublime Text/Packages/User"
sublime_repo := justfile_directory() + "/.config/sublime-text"

# link the Sublime Text settings from the dotfiles into the Packages/User folder
@sublime-link:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ sublime_user }}"
    for name in "Preferences.sublime-settings" "Package Control.sublime-settings"; do
        src="{{ sublime_repo }}/${name}"
        dst="{{ sublime_user }}/${name}"
        if [[ -L "${dst}" ]]; then
            ln -sfn "${src}" "${dst}"; echo "relinked ${name}"
        elif [[ -e "${dst}" ]]; then
            echo "kept local ${name}; compare with: diff \"${dst}\" \"${src}\""
        else
            ln -s "${src}" "${dst}"; echo "linked ${name}"
        fi
    done

# show how the local Sublime Text settings differ from the dotfiles
@sublime-diff:
    #!/usr/bin/env bash
    for name in "Preferences.sublime-settings" "Package Control.sublime-settings"; do
        echo "== ${name}"
        diff "{{ sublime_user }}/${name}" "{{ sublime_repo }}/${name}" && echo "identical"
    done
