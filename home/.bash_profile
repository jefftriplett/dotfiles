## tab completions
set completion-ignore-case On

for comp in \
    ~/.exports \
    ~/.aliases \
    ~/.github \
    /usr/local/Library/Contributions/brew_bash_completion.sh \
    /usr/local/etc/bash_completion.d/git-completion.bash \
    /usr/local/etc/bash_completion.d/tmux
    #/usr/local/bin/virtualenvwrapper.sh
do
    [[ -e $comp ]] && source $comp
done

## history
shopt -s histappend

# pyenv
if which pyenv > /dev/null; then
    eval "$(pyenv init -)";
fi

if which pyenv-virtualenv-init > /dev/null; then
    eval "$(pyenv virtualenv-init -)";
fi

# rbenv
if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

## virtualenv/pip

# pip bash completion start
_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip
# pip bash completion end

ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/id_dsa
