# ----------------------
# CCX (Claude Code with alternative models) recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/glm.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# install ccx CLI
@install:
    bun install -g cc-x10ded@latest
    just --justfile {{ justfile }} version

# uninstall ccx CLI
@uninstall:
    bun remove -g cc-x10ded

# update ccx CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    bun install -g cc-x10ded@latest
    just --justfile {{ justfile }} version

# show available ccx model usage
@usage:
    echo "ccx                           # Interactive model selection"
    echo "ccx --model=glm-4.7           # GLM-4.7 (default)"
    echo "ccx --model=glm-4.6           # GLM-4.6"
    echo "ccx --model=glm-4.5           # GLM-4.5"
    echo "ccx --model=glm-4.5-air       # GLM-4.5-Air (faster)"
    echo "ccx --model=MiniMax-M2.1      # MiniMax-M2.1"
    echo "ccx --model=gpt-4o            # OpenAI GPT-4o"
    echo "ccx --model=gemini-2.0-flash  # Google Gemini 2.0"
    echo "ccx --list                    # Show all available models"
    echo "ccx setup                     # Configure API keys"

# display ccx CLI version
@version:
    ccx --version
