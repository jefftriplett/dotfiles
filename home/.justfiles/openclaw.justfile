# ----------------------
# Openclaw recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/openclaw.justfile"
package := "openclaw"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# run openclaw doctor to check configuration
@doctor:
    openclaw doctor

# check openclaw health status
@health:
    openclaw health

# install openclaw CLI
@install:
    bun install -g {{ package }}@latest
    # just --justfile {{ justfile }} restart

# uninstall openclaw CLI
@uninstall:
    bun remove -g {{ package }}

# restart openclaw daemon
@restart:
    openclaw daemon restart

# upgrade openclaw to the latest version
@upgrade:
    bun install -g {{ package }}@latest
    -just --justfile {{ justfile }} restart

# display openclaw version
@version:
    openclaw --version
