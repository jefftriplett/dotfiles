## tab completions
set completion-ignore-case On

for comp in \
    ~/.exports \
    ~/.aliases \
    ~/.github \
    ~/.secrets \
    /usr/local/Library/Contributions/brew_bash_completion.sh \
    /usr/local/etc/bash_completion.d/git-completion.bash
    #/usr/local/etc/bash_completion.d/tmux
    #/usr/local/bin/virtualenvwrapper.sh
do
    [[ -e $comp ]] && source $comp
done

## history
shopt -s histappend

# rbenv
if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

# python settings

# pyenv settings
if which pyenv > /dev/null; then
    eval "$(pyenv init -)";
    eval "$(pyenv virtualenv-init -)"
    pyenv virtualenvwrapper_lazy
fi


## pip bash completion start
_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip
## pip bash completion end

# python settings end


if which direnv > /dev/null; then
    eval "$(direnv hook bash)";
fi


# command-not-found-init settings
if brew command command-not-found-init > /dev/null; then
    eval "$(brew command-not-found-init)";
fi

# add ssh keys
ssh-add ~/.ssh/id_rsa &> /dev/null
ssh-add ~/.ssh/id_dsa &> /dev/null
ssh-add ~/.ssh/id_ed25519 &> /dev/null

## itermocil autocompletion
if which itermocil > /dev/null; then
    complete -W "$(itermocil --list)" itermocil
fi
