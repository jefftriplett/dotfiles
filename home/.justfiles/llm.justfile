# ----------------------------------------------------------------
# llm recipes - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/llm.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

@install *ARGS:
    llm install {{ ARGS }} llm-claude
    # llm install {{ ARGS }} llm-ollama

@path:
    subl "`llm templates path`"

@upgrade:
    just --justfile {{ justfile }} install --upgrade
