# shellcheck shell=bash

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS="*"

if [[ -r "${HOME}/.bashrc.d/20-tmux.bash" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc.d/20-tmux.bash"
fi

if command -v starship > /dev/null; then
    eval "$(starship init bash)"
fi

if command -v direnv > /dev/null; then
    eval "$(direnv hook bash)";

    if declare -F __tmux_autoattach >/dev/null; then
        __tmux_autoattach
    fi
fi

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# eval "$(atuin init bash)"

# OpenClaw Completion
source "/Users/jefftriplett/.openclaw/completions/openclaw.bash"
