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
mod copilot 'copilot.justfile'
mod glm 'glm.justfile'
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
    just llm clawdbot fmt
    just llm clawdhub fmt
    just llm codex fmt
    just llm copilot fmt
    just llm glm fmt
    just llm llm-cli fmt
    just llm ollama fmt
    just llm pi-coding-agent fmt

# upgrade all AI/LLM tools
@upgrade:
    just llm claude upgrade
    just llm clawdbot upgrade
    just llm clawdhub upgrade
    just llm codex upgrade
    just llm copilot upgrade
    just llm glm upgrade
    just llm llm-cli upgrade
    just llm pi-coding-agent upgrade
