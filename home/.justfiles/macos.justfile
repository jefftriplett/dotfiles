# ----------------------------------------------------------------
# macOS recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

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
[group("time machine")]
@timemachine-boost:
    # bump IO priority to finish more quickly
    # https://apple.stackexchange.com/questions/382772/time-machine-in-the-cleaning-up-state-forever

    sudo sysctl debug.lowpri_throttle_enabled=0

# restore normal IO priority after Time Machine backup completes
[group("time machine")]
@timemachine-boost-complete:
    # once done
    sudo sysctl debug.lowpri_throttle_enabled=1

# delete specific Time Machine backups
[group("time machine")]
@timemachine-delete *ARGS:
    sudo tmutil delete {{ ARGS }}

# list all Time Machine backups
[group("time machine")]
@timemachine-list:
    sudo tmutil listbackups

# ----------------------------------------------------------------
# Xcode
# ----------------------------------------------------------------

# install Xcode command line tools
[group("xcode")]
@xcode-bootstrap:
    sudo xcode-select --install

# upgrade Xcode command line tools by removing and reinstalling
[group("xcode")]
@xcode-upgrade:
    sudo rm -rf /Library/Developer/CommandLineTools
    just --justfile {{ justfile }} xcode-bootstrap
