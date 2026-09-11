# ----------------------------------------------------------------
# ssh-clipboard recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export

justfile := justfile_directory() + "/.justfiles/ssh-clipboard.justfile"
package := "ssh-clipboard"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# install the ssh-clipboard CLI from npm, then run the setup TUI
@install:
    npm install -g {{ package }}
    command ssh-clipboard setup

# watch clipboard values and peer health
@monitor:
    command ssh-clipboard monitor

# check for a newer ssh-clipboard release
@outdated:
    command ssh-clipboard update --check

# restart the per-user background service
@restart:
    command ssh-clipboard service restart

# add, verify, or repair peers
@setup:
    command ssh-clipboard setup

# show daemon and peer status
@status:
    command ssh-clipboard status

# uninstall the ssh-clipboard CLI and stop its service
@uninstall:
    -command ssh-clipboard service stop
    npm uninstall -g {{ package }}

# update ssh-clipboard to the latest stable release
@upgrade:
    command ssh-clipboard update

# display the ssh-clipboard version
@version:
    command ssh-clipboard --version
