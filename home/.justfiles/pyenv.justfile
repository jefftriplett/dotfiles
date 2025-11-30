# ----------------------------------------------------------------
# pyenv recipes - https://github.com/pyenv/pyenv
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/pyenv.justfile"
python_311 := `pyenv latest 3.11`
python_312 := `pyenv latest 3.12`
python_313 := `pyenv latest 3.13`
python_314 := `pyenv latest 3.14`

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
        {{ python_313 }} \
        {{ python_314 }} \
        {{ python_311 }}

# upgrade all python versions managed by pyenv
[group("maintenance")]
@upgrade +ARGS="--skip-existing":
    just pyenv::upgrade-all {{ ARGS }}

# install or upgrade all python versions managed by pyenv
[group("maintenance")]
@upgrade-all +ARGS="--skip-existing":
    -pyenv install {{ ARGS }} 3.14:latest
    -pyenv install {{ ARGS }} 3.13:latest
    -pyenv install {{ ARGS }} 3.12:latest
    -pyenv install {{ ARGS }} 3.11:latest

    just pyenv::set-global
