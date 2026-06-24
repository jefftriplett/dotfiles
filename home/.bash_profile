# shellcheck shell=bash

# CMUX fix (part 1 of 2): silence background job control messages
# emitted by cmux's _cmux_send hooks (e.g. "[1]- Done ..."). Paired with
# the `set -m` below the starship init block. Remove both once cmux
# stops printing job-control notifications.
set +m

# shellcheck source=/dev/null
for filename in "${HOME}"/.{bash_exports,bash_tmux,bash_aliases,bash_functions,bash_secrets,docker_alias}; do
    if [[ -r "${filename}" ]] ; then
        source "${filename}"
    fi
done
unset filename

# Detect and load OS specific settigs
unamestr=$(uname)
if [[ "${unamestr}" == 'Darwin' ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bash_osx"
elif [[ "${unamestr}" == 'Linux' ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bash_linux"
fi

# tmux auto-attach disabled (function kept in .bash_tmux for re-enabling)
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
