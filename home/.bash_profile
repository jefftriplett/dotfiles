# shellcheck shell=bash

# shellcheck source=/dev/null
for filename in "${HOME}"/.{bash_exports,bash_aliases,bash_functions,bash_secrets,docker_alias}; do
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

# OrbStack: Load command-line tools and integration if installed
if [[ -f ~/.orbstack/shell/init.bash ]]; then
    source ~/.orbstack/shell/init.bash
fi

# OpenClaw completion
if [[ -f "$HOME/.openclaw/completions/openclaw.bash" ]]; then
    source "$HOME/.openclaw/completions/openclaw.bash"
fi

if command -v try &> /dev/null; then
    eval "$(try init ~//Projects/tries)"
fi
