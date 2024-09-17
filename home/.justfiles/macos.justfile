# ----------------------------------------------------------------
# macOS recipes
# ----------------------------------------------------------------

justfile := justfile_directory() + "/.justfiles/macos.justfile"

[private]
@default:
    just --list --justfile {{ justfile }}

[private]
@fmt:
    just --fmt --justfile {{ justfile }}

# ----------------------------------------------------------------
# Time Machine recipes
# ----------------------------------------------------------------

@timemachine-boost:
    # bump IO priority to finish more quickly
    # https://apple.stackexchange.com/questions/382772/time-machine-in-the-cleaning-up-state-forever

    sudo sysctl debug.lowpri_throttle_enabled=0

@timemachine-boost-complete:
    # once done
    sudo sysctl debug.lowpri_throttle_enabled=1

@timemachine-delete *ARGS:
    sudo tmutil delete {{ ARGS }}

@timemachine-list:
    sudo tmutil listbackups

# ----------------------------------------------------------------
# Xcode
# ----------------------------------------------------------------

@xcode-bootstrap:
    sudo xcode-select --install

@xcode-upgrade:
    sudo rm -rf /Library/Developer/CommandLineTools
    just --justfile {{ justfile }} xcode-bootstrap
