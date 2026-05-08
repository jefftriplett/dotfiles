# shellcheck shell=bash

# TEMPORARY WORKAROUND (cmux): silence background job control messages
# emitted by cmux's _cmux_send hooks (e.g. "[1]- Done ..."). Remove this
# once cmux stops printing job-control notifications.
set +m

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS=*

if command -v starship > /dev/null; then
    eval "$(starship init bash)";
fi

if command -v direnv > /dev/null; then
    eval "$(direnv hook bash)";
fi

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# eval "$(atuin init bash)"

# OpenClaw Completion
source "/Users/jefftriplett/.openclaw/completions/openclaw.bash"
