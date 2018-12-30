
for file in ~/.{exports,aliases,functions,secrets}; do
    [ -r "${file}" ] && source "${file}"
done
unset file


# Detect and load OS specific settigs
platform='unknown'
unamestr=$(uname)
if [[ "${unamestr}" == 'Linux' ]]; then
   source ~/.linux
elif [[ "${unamestr}" == 'Darwin' ]]; then
   source ~/.osx
fi
