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
[group("config")]
@config:
    subl ~/Library/Application\ Support/Claude/claude_desktop_config.json

# install Claude Code CLI
[group("setup")]
@install:
    curl -fsSL https://claude.ai/install.sh | bash
    just --justfile {{ justfile }} version

# update Claude Code CLI to the latest version
[group("maintenance")]
@upgrade:
    command claude update
    just --justfile {{ justfile }} version

# see Claude Code API/CLI usage
[group("tools")]
@usage:
    bunx ccusage@latest

# display Claude Code CLI version
[group("utils")]
@version:
    command claude --version
