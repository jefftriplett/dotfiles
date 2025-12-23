# ----------------------
# GLM (Claude GLM) recipes
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

# install Claude GLM CLI
@install:
    # bun install -g claude-glm-installer
    bun install -g claude-glm-alt-installer
    just --justfile {{ justfile }} version

# update Claude GLM CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    # bun install -g claude-glm-installer
    bun install -g claude-glm-alt-installer
    just --justfile {{ justfile }} version

# show available Claude GLM aliases
@usage:
    echo "ccg              # Claude Code with GLM-4.6 (latest)"
    echo "ccg45            # Claude Code with GLM-4.5"
    echo "ccf              # Claude Code with GLM-4.5-Air (faster)"
    echo "cc               # Regular Claude Code"

# display Claude GLM CLI version
@version:
    command claude-glm --version
