# shellcheck shell=bash

# CMUX fix (part 1 of 2): silence background job control messages
# emitted by cmux's _cmux_send hooks (e.g. "[1]- Done ..."). Paired with
# the `set -m` below the starship init block. Remove both once cmux
# stops printing job-control notifications.
set +m

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS=*

# CMUX fix: ensure cmux's bootstrap runs before starship initializes,
# otherwise starship's prompt clobbers cmux's shell integration.
if command -v starship > /dev/null; then
    if [[ -n "$CMUX_SHELL_INTEGRATION" ]]; then
        # Execute cmux's bootstrap NOW instead of waiting for first prompt
        eval "$PROMPT_COMMAND"
        # cmux has settled — now init starship on top
        eval "$(starship init bash)"
    else
        eval "$(starship init bash)"
    fi
fi

# CMUX fix: re-silence job control after cmux/starship init in case
# either toggled monitor mode back on. Paired with the `set +m` at the
# top of this file — both lines are part of the same cmux workaround.
# Remove together once cmux stops printing job-control notifications.
set +m

# CMUX fix (part 3): cmux's shell integration is sourced AFTER this file
# and re-enables monitor mode somewhere in its bootstrap. Prepending
# `set +m` to PROMPT_COMMAND forces monitor mode off on every prompt,
# which is what the user has been running manually to fix this.
PROMPT_COMMAND="set +m;${PROMPT_COMMAND}"

if command -v direnv > /dev/null; then
    eval "$(direnv hook bash)";
fi

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# eval "$(atuin init bash)"

# OpenClaw Completion
source "/Users/jefftriplett/.openclaw/completions/openclaw.bash"
