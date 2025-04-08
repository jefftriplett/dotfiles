# ----------------------------------------------------------------
# llm recipes - https://llm.datasette.io/
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

# install LLM plugins with optional arguments
@install *ARGS:
    # llm install {{ ARGS }} llm-ollama
    llm install {{ ARGS }} llm-anthropic
    llm install {{ ARGS }} llm-claude
    llm install {{ ARGS }} llm-fragments-github
    llm install {{ ARGS }} llm-gemini
    llm install {{ ARGS }} llm-hacker-news
    llm install {{ ARGS }} llm-openai-plugin

# open LLM templates directory in Sublime Text
@path:
    subl "`llm templates path`"

# upgrade all installed LLM plugins
@upgrade:
    just --justfile {{ justfile }} install --upgrade
