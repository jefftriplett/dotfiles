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

# update Claude Code CLI to the latest version
@upgrade:
    # claude update
    claude install
    just --justfile {{ justfile }} version

# see Claude Code API/CLI usage
@usage:
    bunx ccusage@latest

# display Claude Code CLI version
@version:
    claude --version
