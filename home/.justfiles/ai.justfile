# ----------------------
# AI/LLM tools recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/ai.justfile"

mod claude 'claude.justfile'
mod clawdbot 'clawdbot.justfile'
mod codex 'codex.justfile'
mod copilot 'copilot.justfile'
mod glm 'glm.justfile'
mod llm 'llm.justfile'
mod ollama 'ollama.justfile'
mod pi-coding-agent 'pi-coding-agent.justfile'

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list --list-submodules

# format all AI/LLM justfiles
@fmt:
    just --justfile {{ justfile }} --fmt
    just ai claude fmt
    just ai clawdbot fmt
    just ai codex fmt
    just ai copilot fmt
    just ai glm fmt
    just ai llm fmt
    just ai ollama fmt
    just ai pi-coding-agent fmt

# upgrade all AI/LLM tools
@upgrade:
    just ai claude upgrade
    just ai clawdbot upgrade
    just ai codex upgrade
    just ai copilot upgrade
    just ai glm upgrade
    just ai llm upgrade
    just ai pi-coding-agent upgrade
