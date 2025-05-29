# ----------------------------------------------------------------
# mise - https://github.com/jdx/mise
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/mise.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

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

# update mise to the latest version
@upgrade:
    mise install
    mise reshim
