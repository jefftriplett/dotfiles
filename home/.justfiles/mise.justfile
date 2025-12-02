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

# bootstrap mise by installing configured language versions
@bootstrap:
    mise install golang
    mise install node
    mise install ruby
    mise install rust
    mise reshim
    # mise current
    # mise list

# install latest language versions and refresh shims
@upgrade:
    mise install
    mise reshim
