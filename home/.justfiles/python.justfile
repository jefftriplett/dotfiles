# ----------------------------------------------------------------
# Python recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export

justfile := justfile_directory() + "/.justfiles/python.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# bootstrap python: uv-managed interpreters, `python` on PATH, and CLI tools
@bootstrap:
    just --justfile {{ justfile }} uv-python-install
    uv python install --default 3.14
    just --justfile {{ justfile }} uv-tool-install

# update python environment
@upgrade:
    just --justfile {{ justfile }} uv-pip-upgrade
    just --justfile {{ justfile }} uv-tool-upgrade

# ----------------------------------------------------------------
# UV recipes - https://docs.astral.sh/uv/
# ----------------------------------------------------------------

# install python packages using uv pip installer
@uv-pip-install *ARGS:
    uv pip install \
        --system \
        --upgrade \
        {{ ARGS }}

# update python versions using uv installer
@uv-pip-upgrade *ARGS:
    uv python upgrade {{ ARGS }}

# uninstall python packages using uv pip installer
@uv-pip-uninstall *ARGS:
    uv pip uninstall \
        --system \
        {{ ARGS }}

# install python versions using uv installer
@uv-python-install *ARGS:
    -uv python install {{ ARGS }} 3.14
    -uv python install {{ ARGS }} 3.13
    -uv python install {{ ARGS }} 3.12
    -uv python install {{ ARGS }} 3.11
    -uv python install {{ ARGS }} 3.10

# reinstall python versions using uv installer
@uv-python-reinstall *ARGS:
    just --justfile {{ justfile }} uv-python-install --reinstall {{ ARGS }}

# install common python CLI tools using uv installer
@uv-tool-install *ARGS:
    -uv tool install --python 3.12 aider-install {{ ARGS }}
    -uv tool install --python 3.14 batrachian-toad {{ ARGS }}
    -uv tool install --python 3.12 claude-code-transcripts {{ ARGS }}
    -uv tool install --python 3.12 cogapp {{ ARGS }}
    -uv tool install --python 3.12 em-keyboard {{ ARGS }}
    -uv tool install --python 3.12 files-to-claude-xml {{ ARGS }}
    -uv tool install --python 3.12 grip {{ ARGS }}
    -uv tool install --python 3.12 justpath {{ ARGS }}
    -uv tool install --python 3.12 llm {{ ARGS }}
    -uv tool install --python 3.12 pyright {{ ARGS }}
    -uv tool install --python 3.12 rich-cli {{ ARGS }}
    -uv tool install --python 3.12 rodney {{ ARGS }}
    -uv tool install --python 3.12 ruff-lsp {{ ARGS }}
    -uv tool install --python 3.12 ttok {{ ARGS }}
    -uv tool install --python 3.12 yt-dlp[default] {{ ARGS }}

# upgrade common python CLI tools using uv installer
@uv-tool-upgrade:
    just --justfile {{ justfile }} uv-tool-install --upgrade
