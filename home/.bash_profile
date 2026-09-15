# shellcheck shell=bash

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

if command -v starship > /dev/null; then
    eval "$(starship init bash)"
fi
