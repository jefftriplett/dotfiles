# ----------------------------------------------------------------
# Python recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/claude.justfile"

python_310 := `pyenv latest 3.10`
python_311 := `pyenv latest 3.11`
python_312 := `pyenv latest 3.12`
python_313 := `pyenv latest 3.13`
python_39 := `pyenv latest 3.9`

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# bootstrap python environment with essential packages
@bootstrap:
    PIP_REQUIRE_VIRTUALENV=false python -m pip install \
            --disable-pip-version-check \
            --no-compile \
            --upgrade \
        pip uv

    python -m uv pip install \
            --system \
            --upgrade \
        virtualenv \
        virtualenvwrapper \
        wheel

@outdated:
    PIP_REQUIRE_VIRTUALENV=false python -m pip list --outdated

# install python packages using uv pip installer
@pip-install *ARGS:
    python -m uv pip install \
        --system \
        --upgrade \
        {{ ARGS }}

# uninstall python packages using uv pip installer
@pip-uninstall *ARGS:
    python -m uv pip uninstall \
        --system \
        {{ ARGS }}

# update python environment and pyenv settings
@update:
    just bootstrap
    just pyenv::update
    just pyenv::set-global

# ----------------------------------------------------------------
# UV recipes - https://docs.astral.sh/uv/
# ----------------------------------------------------------------

# install python versions using uv installer
@uv-python-install *ARGS:
    -uv python install {{ ARGS }} 3.13
    -uv python install {{ ARGS }} 3.12
    -uv python install {{ ARGS }} 3.11
    -uv python install {{ ARGS }} 3.10
    -uv python install {{ ARGS }} 3.9

# reinstall python versions using uv installer
@uv-python-reinstall *ARGS:
    just uv-python-install --reinstall

# install common python CLI tools using uv installer
@uv-tool-install *ARGS:
    -uv tool install --python {{ python_312 }} aider-install {{ ARGS }}
    -uv tool install --python {{ python_312 }} cogapp {{ ARGS }}
    -uv tool install --python {{ python_312 }} files-to-claude-xml {{ ARGS }}
    -uv tool install --python {{ python_312 }} grip {{ ARGS }}
    -uv tool install --python {{ python_312 }} justpath {{ ARGS }}
    -uv tool install --python {{ python_312 }} llm {{ ARGS }}
    -uv tool install --python {{ python_312 }} pyright {{ ARGS }}
    -uv tool install --python {{ python_312 }} rich-cli {{ ARGS }}
    -uv tool install --python {{ python_312 }} ruff-lsp {{ ARGS }}
    -uv tool install --python {{ python_312 }} ttok {{ ARGS }}
    -uv tool install --python {{ python_312 }} yt-dlp[default] {{ ARGS }}
