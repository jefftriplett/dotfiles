for filename in "${HOME}"/.{bash_exports,bash_aliases,bash_functions,bash_secrets}; do
    if [[ -r "${filename}" ]] ; then
        source "${filename}"
    fi
done
unset filename

# Detect and load OS specific settigs
unamestr=$(uname)
if [[ "${unamestr}" == 'Darwin' ]]; then
    # shellcheck source=~/.osx
    source "${HOME}/.bash_osx"
elif [[ "${unamestr}" == 'Linux' ]]; then
    # shellcheck source=~/.linux
    source "${HOME}/.bash_linux"
fi
