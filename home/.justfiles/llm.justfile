# ----------------------
# AI/LLM tools recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/llm.justfile"

mod claude 'claude.justfile'
mod clawdbot 'clawdbot.justfile'
mod clawdhub 'clawdhub.justfile'
mod codex 'codex.justfile'
mod moltbot 'moltbot.justfile'
mod openclaw 'openclaw.justfile'
mod copilot 'copilot.justfile'
mod glm 'glm.justfile'
mod happy 'happy.justfile'
mod llm-cli 'llm-cli.justfile'
mod ollama 'ollama.justfile'
mod pi-coding-agent 'pi-coding-agent.justfile'

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list --list-submodules

# format all AI/LLM justfiles
@fmt:
    just --justfile {{ justfile }} --fmt
    just llm claude fmt
    just llm clawdhub fmt
    just llm codex fmt
    just llm copilot fmt
    just llm openclaw fmt
    just llm glm fmt
    just llm happy fmt
    just llm llm-cli fmt
    just llm ollama fmt
    just llm pi-coding-agent fmt

# check for outdated AI/LLM tools
outdated:
    #!/usr/bin/env bash
    echo "==> Checking npm packages..."
    npm outdated -g @github/copilot 2>/dev/null || true

    echo ""
    echo "==> Checking bun packages..."
    for pkg in @openai/codex clawdhub cc-x10ded happy-coder openclaw @mariozechner/pi-coding-agent; do
        installed=$(bun pm ls -g 2>/dev/null | grep "$pkg" | sed 's/.*@//' | head -1)
        latest=$(npm view "$pkg" version 2>/dev/null)
        if [ -n "$installed" ] && [ -n "$latest" ]; then
            if [ "$installed" != "$latest" ]; then
                echo "$pkg: $installed -> $latest (outdated)"
            else
                echo "$pkg: $installed (current)"
            fi
        fi
    done

    echo ""
    echo "==> Checking Claude Code..."
    command claude --version 2>/dev/null || echo "Claude Code not installed"

# upgrade all AI/LLM tools
@upgrade:
    -just llm claude upgrade
    -just llm clawdhub upgrade
    -just llm codex upgrade
    -just llm copilot upgrade
    -just llm glm upgrade
    -just llm happy upgrade
    -just llm llm-cli upgrade
    -just llm openclaw upgrade
    -just llm pi-coding-agent upgrade
