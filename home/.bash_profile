
for filename in "${HOME}"/.{exports,aliases,functions,secrets}; do
    if [[ -r "${filename}" ]] ; then
        source "${filename}"
    fi
done
unset filename

# Detect and load OS specific settigs
unamestr=$(uname)
if [[ "${unamestr}" == 'Darwin' ]]; then
    # shellcheck source=~/.osx
    source "${HOME}/.osx"
elif [[ "${unamestr}" == 'Linux' ]]; then
    # shellcheck source=~/.linux
    source "${HOME}/.linux"
fi
