# shellcheck shell=bash

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS=*

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"
