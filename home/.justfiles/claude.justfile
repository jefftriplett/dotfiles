# ----------------------
# Claude Desktop recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/claude.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# open Claude Desktop configuration file in Sublime Text
@config:
    subl ~/Library/Application\ Support/Claude/claude_desktop_config.json

# install Claude Code CLI
@install:
    curl -fsSL https://claude.ai/install.sh | bash
    just --justfile {{ justfile }} version

# update Claude Code CLI to the latest version
@upgrade:
    command claude update
    just --justfile {{ justfile }} version

# see Claude Code API/CLI usage
@usage:
    bunx ccusage@latest

# display Claude Code CLI version
@version:
    command claude --version
