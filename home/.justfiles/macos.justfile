# ----------------------------------------------------------------
# macOS recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/macos.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

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
@timemachine-delete *ARGS:
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
