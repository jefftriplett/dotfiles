# ----------------------
# Claude Desktop recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/claude.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# open Claude Desktop configuration file in Sublime Text
@config:
    subl ~/Library/Application\ Support/Claude/claude_desktop_config.json

# update Claude Code CLI to the latest version
@upgrade:
    npm install -g @anthropic-ai/claude-code
