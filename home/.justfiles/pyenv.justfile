# ----------------------------------------------------------------
# pyenv recipes - https://github.com/pyenv/pyenv
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/pyenv.justfile"
python_310 := `pyenv latest 3.10`
python_311 := `pyenv latest 3.11`
python_312 := `pyenv latest 3.12`
python_313 := `pyenv latest 3.13`
python_39 := `pyenv latest 3.9`

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# set global python versions in pyenv
[private]
@set-global:
    pyenv global \
        {{ python_312 }} \
        {{ python_311 }} \
        {{ python_310 }} \
        {{ python_39 }}

# update pyenv itself to latest version
[private]
@update:
    # just pyenv::upgrade

# upgrade python and update pyenv configuration
@upgrade +ARGS="--skip-existing":
    just pyenv::upgrade-all {{ ARGS }}
    just python::update

# install or upgrade all python versions managed by pyenv
@upgrade-all +ARGS="--skip-existing":
    -pyenv install {{ ARGS }} 3.13:latest
    -pyenv install {{ ARGS }} 3.12:latest
    -pyenv install {{ ARGS }} 3.11:latest
    -pyenv install {{ ARGS }} 3.10:latest
    -pyenv install {{ ARGS }} 3.9:latest

    just pyenv::set-global
