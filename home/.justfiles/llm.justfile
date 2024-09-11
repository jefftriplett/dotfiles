# ----------------------------------------------------------------
# llm - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

@_default:
    just --list

@install:
    llm install llm-claude
    llm install llm-ollama

@upgrade:
    llm install llm-claude
    llm install llm-ollama
