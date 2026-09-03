# shellcheck shell=bash

# CMUX fix (part 1 of 2): silence background job control messages
# emitted by cmux's _cmux_send hooks (e.g. "[1]- Done ..."). Paired with
# the `set -m` below the starship init block. Remove both once cmux
# stops printing job-control notifications.
set +m

# Load ~/.bashrc.d/*.bash in name order. The number prefix is the load
# order; the OS-specific files guard themselves with a uname check.
for filename in "${HOME}"/.bashrc.d/*.bash; do
    if [[ -r "${filename}" ]]; then
        # shellcheck source=/dev/null
        source "${filename}"
    fi
done
unset filename

# tmux auto-attach disabled (function kept in 20-tmux.bash for re-enabling)
# if declare -F __tmux_autoattach >/dev/null; then
#     __tmux_autoattach
# fi

# OrbStack: Load command-line tools and integration if installed
if [[ -f ~/.orbstack/shell/init.bash ]]; then
    source ~/.orbstack/shell/init.bash
fi

# OpenClaw completion
if [[ -f "$HOME/.openclaw/completions/openclaw.bash" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.openclaw/completions/openclaw.bash"
fi

if command -v try &> /dev/null; then
    eval "$(try init ~//Projects/tries)"
fi

# CMUX fix: ensure cmux's bootstrap runs before starship initializes,
# otherwise starship's prompt clobbers cmux's shell integration.
if command -v starship > /dev/null; then
    # $- test: a non-interactive login shell (`bash -lc ...`, which the
    # remote attach commands and `projects create` both use) inherits
    # CMUX_SHELL_INTEGRATION but never loads cmux's shell integration, so
    # $PROMPT_COMMAND still names a _cmux_prompt_command that does not exist
    # here. Eval-ing it printed "command not found" onto the output of every
    # such command.
    if [[ -n "$CMUX_SHELL_INTEGRATION" && $- == *i* ]]; then
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
