####################
# bash completions #
####################

set completion-ignore-case On

for comp in \
    ~/.exports \
    ~/.aliases \
    ~/.asdf/asdf.sh \
    ~/.asdf/completions/asdf.bash \
    ~/.dockerfunc \
    ~/.github \
    ~/.secrets
do
    [[ -e $comp ]] && source $comp
done

# auto-load bash_completion.d
if [ -d /usr/local/etc/bash_completion.d ]; then
    for F in "/usr/local/etc/bash_completion.d/"*; do
        if [ -f "${F}" ]; then
            source "${F}";
        fi
    done
fi

################
# bash history #
################

shopt -s histappend

#################
# Ruby settings #
#################

if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

###################
# Python settings #
###################

# pyenv settings
if which pyenv > /dev/null; then
    eval "$(pyenv init -)";
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

###################
# direnv settings #
###################

if which direnv > /dev/null; then
    eval "$(direnv hook bash)";
fi

###################################
# command-not-found-init settings #
###################################

if brew command command-not-found-init > /dev/null 2>&1; then
    eval "$(brew command-not-found-init)";
fi

################
# add ssh keys #
################

ssh-add -k &> /dev/null

## itermocil autocompletion
# if which itermocil > /dev/null; then
#     complete -W "$(itermocil --list)" itermocil
# fi

# TODO: move over the homebrew cask google-cloud-sdk
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
# source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '${HOME}/Downloads/google-cloud-sdk/path.bash.inc' ]; then
#     source '${HOME}/Downloads/google-cloud-sdk/path.bash.inc'
# fi

# # The next line enables shell command completion for gcloud.
# if [ -f '${HOME}/Downloads/google-cloud-sdk/completion.bash.inc' ]; then
#     source '${HOME}/Downloads/google-cloud-sdk/completion.bash.inc'
# fi

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '${HOME}/google-cloud-sdk/path.bash.inc' ]; then source '${HOME}/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
# if [ -f '${HOME}/google-cloud-sdk/completion.bash.inc' ]; then source '${HOME}/google-cloud-sdk/completion.bash.inc'; fi

###################
# iTerm2 settings #
###################

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

function iterm2_print_user_vars {
    iterm2_set_user_var badge $USER_BADGE
}

##############################################
# command line management for Google G Suite #
##############################################

alias gam="/Users/jefftriplett/bin/gam/gam"

#########################
# What did I just type? #
#########################

eval $(thefuck --alias)
