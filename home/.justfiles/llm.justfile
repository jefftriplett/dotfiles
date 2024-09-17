# ----------------------------------------------------------------
# llm recipes - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

justfile := justfile_directory() + "/.justfiles/llm.justfile"

[private]
@default:
    just --list --justfile {{ justfile }}

[private]
@fmt:
    just --fmt --justfile {{ justfile }}

@install:
    llm install llm-claude
    llm install llm-ollama

@upgrade:
    llm install llm-claude
    llm install llm-ollama
