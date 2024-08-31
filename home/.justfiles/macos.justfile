# ----------------------------------------------------------------
# macOS recipes
# ----------------------------------------------------------------

# ----------------------------------------------------------------
# Time Machine recipes
# ----------------------------------------------------------------

@macos-timemachine-boost:
    # bump IO priority to finish more quickly
    # https://apple.stackexchange.com/questions/382772/time-machine-in-the-cleaning-up-state-forever

    sudo sysctl debug.lowpri_throttle_enabled=0

@macos-timemachine-boost-complete:
    # once done
    sudo sysctl debug.lowpri_throttle_enabled=1

@macos-timemachine-delete *ARGS:
    sudo tmutil delete {{ ARGS }}

@macos-timemachine-list:
    sudo tmutil listbackups

# ----------------------------------------------------------------
# Xcode
# ----------------------------------------------------------------

@_macos-xcode-bootstrap:
    sudo xcode-select --install

@macos-xcode-upgrade:
    sudo rm -rf /Library/Developer/CommandLineTools
    just _xcode-bootstrap
