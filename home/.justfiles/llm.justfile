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

@install:
    llm install llm-claude
    llm install llm-ollama

@upgrade:
    llm install llm-claude
    llm install llm-ollama
