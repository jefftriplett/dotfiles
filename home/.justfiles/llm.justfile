# ----------------------------------------------------------------
# llm recipes - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

justfile := justfile_directory() + "/.justfiles/llm.justfile"

@_default:
    just --list

@_fmt:
    just --fmt --justfile {{ justfile }}

@install:
    llm install llm-claude
    llm install llm-ollama

@upgrade:
    llm install llm-claude
    llm install llm-ollama
