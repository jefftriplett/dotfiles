# ----------------------------------------------------------------
# Mole recipes (https://github.com/tw93/Mole)
# ----------------------------------------------------------------

set dotenv-load := false
set export

justfile := justfile_directory() + "/.justfiles/mole.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# preview what clean and purge would remove; changes nothing
@preview:
    mo clean --dry-run
    mo purge --dry-run

# remove caches, logs, and leftovers from uninstalled apps
@clean:
    mo clean

# preview clean; changes nothing
@clean-preview:
    mo clean --dry-run

# remove old project build artifacts (.venv, __pycache__, dist, target)
@purge:
    mo purge

# preview purge; changes nothing
@purge-preview:
    mo purge --dry-run

# pick installer files (.dmg, .pkg, .zip) to remove from Downloads
@installers:
    mo installer

# explore disk usage, defaulting to the home folder
@analyze path="~":
    mo analyze {{ path }}

# show system health
@status:
    mo status

# list past Mole cleanups
@history:
    mo history

# update Mole itself
@update:
    brew upgrade mole
