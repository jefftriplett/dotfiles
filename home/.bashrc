# shellcheck shell=bash

# CMUX fix (part 1 of 2): silence background job control messages
# emitted by cmux's _cmux_send hooks (e.g. "[1]- Done ..."). Paired with
# the `set -m` below the starship init block. Remove both once cmux
# stops printing job-control notifications.
set +m

# CMUX fix (part 0): scrub a stale $PROMPT_COMMAND inherited from a parent
# shell. cmux-bash-integration.bash prepends "_cmux_prompt_command;" to
# PROMPT_COMMAND once it defines that function, then exports PROMPT_COMMAND
# to seed new shells before un-exporting it; if that unexport does not take,
# a later shell inherits the already-built string — call and all — without
# ever running the integration that defines the function. Every hook setup
# below (mise, direnv, starship) only ever prepends onto $PROMPT_COMMAND, so
# without this the dead call stays baked in and fires on every prompt for
# the life of the shell, surviving even a re-source of this file.
if [[ -n "$PROMPT_COMMAND" ]] && ! declare -F _cmux_prompt_command > /dev/null; then
    PROMPT_COMMAND="${PROMPT_COMMAND//_cmux_prompt_command;/}"
    PROMPT_COMMAND="${PROMPT_COMMAND//;_cmux_prompt_command/}"
    PROMPT_COMMAND="${PROMPT_COMMAND//_cmux_prompt_command/}"
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS="*"

if [[ -r "${HOME}/.bashrc.d/20-tmux.bash" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc.d/20-tmux.bash"
fi

# CMUX fix: ensure cmux's bootstrap runs before starship initializes,
# otherwise starship's prompt clobbers cmux's shell integration.
if command -v starship > /dev/null; then
    # $- test mirrors .bash_profile: a non-interactive shell inherits
    # CMUX_SHELL_INTEGRATION but never loads cmux's shell integration, so
    # $PROMPT_COMMAND names a _cmux_prompt_command that does not exist here.
    # The function check covers the same gap for an interactive shell that
    # inherited the export without cmux actually running: cmux's own
    # bootstrap exports PROMPT_COMMAND to seed a new shell, then un-exports
    # it once done, but that export can outlive the unexport and keep
    # leaking into shells that never sourced the real integration.
    if [[ -n "$CMUX_SHELL_INTEGRATION" && $- == *i* ]] && declare -F _cmux_prompt_command > /dev/null; then
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

    if declare -F __tmux_autoattach >/dev/null; then
        __tmux_autoattach
    fi
fi

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# eval "$(atuin init bash)"

# OpenClaw Completion
source "/Users/jefftriplett/.openclaw/completions/openclaw.bash"
