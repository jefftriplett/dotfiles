# ----------------------------------------------------------------
# mise - https://github.com/jdx/mise
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/mise.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# Bootstrap mise by installing configured language versions
@bootstrap:
    mise install golang
    mise install node
    mise install ruby
    mise install rust
    mise reshim
    # mise current
    # mise list

# update mise and install latest language versions
@upgrade:
    mise install
    mise reshim
