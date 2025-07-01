# ----------------------------------------------------------------
# llm recipes - https://llm.datasette.io/
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/llm.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# upgrade all installed LLM plugins with --force-reinstall
@force-reinstall:
    just --justfile {{ justfile }} install --force-reinstall

# install LLM plugins with optional arguments
@install *ARGS:
    # llm install --force-reinstall llm-gpt4all
    llm install {{ ARGS }} \
        llm-anthropic \
        llm-claude \
        llm-docs \
        llm-fragments-github \
        llm-gemini \
        llm-hacker-news \
        llm-jina-reader \
        llm-ollama \
        llm-openai-plugin \
        llm-pdf-to-images \
        llm-uv-tool

# open LLM templates directory in Sublime Text
@path:
    subl "`llm templates path`"

# upgrade all installed LLM plugins
@upgrade:
    just --justfile {{ justfile }} install --upgrade
