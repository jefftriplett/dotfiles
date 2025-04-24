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

# upgrade all installed LLM plugins with --force-reinstall
@force-reinstall:
    just --justfile {{ justfile }} install --force-reinstall

# install LLM plugins with optional arguments
@install *ARGS:
    # llm install --force-reinstall llm-gpt4all
    llm install {{ ARGS }} llm-uv-tool
    llm install {{ ARGS }} llm-anthropic
    llm install {{ ARGS }} llm-claude
    llm install {{ ARGS }} llm-docs
    llm install {{ ARGS }} llm-fragments-github
    llm install {{ ARGS }} llm-gemini
    llm install {{ ARGS }} llm-hacker-news
    llm install {{ ARGS }} llm-jina-reader
    llm install {{ ARGS }} llm-ollama
    llm install {{ ARGS }} llm-openai-plugin

# open LLM templates directory in Sublime Text
@path:
    subl "`llm templates path`"

# upgrade all installed LLM plugins
@upgrade:
    just --justfile {{ justfile }} install --upgrade
    # npm install -g @anthropic-ai/claude-code
    # npm install -g @openai/codex
