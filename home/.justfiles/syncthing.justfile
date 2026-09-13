# ----------------------------------------------------------------
# Syncthing recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export

justfile := justfile_directory() + "/.justfiles/syncthing.justfile"
label := "com.jefftriplett.syncthing"
plist := justfile_directory() + "/Library/LaunchAgents/com.jefftriplett.syncthing.plist"
agent := env_var("HOME") + "/Library/LaunchAgents/com.jefftriplett.syncthing.plist"
log := env_var("HOME") + "/.local/log/syncthing.log"
brew_log := "/opt/homebrew/var/log/syncthing.log"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# run Syncthing from our LaunchAgent with a rotated log, in place of the Homebrew service
service-install:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$(dirname "{{ log }}")" "$(dirname "{{ agent }}")"
    if brew services list | grep -q "^syncthing.*started"; then
        echo "stopping the Homebrew service"
        brew services stop syncthing
    fi
    # a copy, not a link: launchd refuses to bootstrap a symlinked plist
    cp "{{ plist }}" "{{ agent }}"
    launchctl bootout "gui/$(id -u)/{{ label }}" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "{{ agent }}"
    # the old Homebrew log never rotated; keep the tail, drop the rest
    if [[ -s "{{ brew_log }}" ]]; then
        tail -c 3000000 "{{ brew_log }}" > "{{ brew_log }}.tail" && : > "{{ brew_log }}"
        echo "truncated {{ brew_log }} (tail kept in {{ brew_log }}.tail)"
    fi
    tmutil addexclusion "{{ brew_log }}" 2>/dev/null || true
    echo "syncthing now runs as {{ label }}, log in {{ log }}"

# go back to the Homebrew service
service-uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    launchctl bootout "gui/$(id -u)/{{ label }}" 2>/dev/null || true
    rm -f "{{ agent }}"
    brew services start syncthing

# restart the Syncthing LaunchAgent
@restart:
    launchctl kickstart -k "gui/$(id -u)/{{ label }}"

# stop the Syncthing LaunchAgent until the next login
@stop:
    launchctl bootout "gui/$(id -u)/{{ label }}"

# start the Syncthing LaunchAgent
@start:
    launchctl bootstrap "gui/$(id -u)" "{{ agent }}"

# show the LaunchAgent state and the log sizes
@status:
    launchctl print "gui/$(id -u)/{{ label }}" 2>/dev/null | grep -E "state|pid" | head -3 || echo "{{ label }} is not loaded"
    ls -lh "{{ log }}"* 2>/dev/null || echo "no log yet at {{ log }}"

# follow the Syncthing log
@log:
    tail -f "{{ log }}"
