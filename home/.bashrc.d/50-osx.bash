# shellcheck shell=bash

# macOS only
[[ "$(uname)" == "Darwin" ]] || return 0

####################
# bash completions #
####################

set completion-ignore-case On

if type brew &>/dev/null
then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [ -f "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
    # shellcheck source=/dev/null
    . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  fi
fi

################
# bash history #
################

shopt -s histappend

###########################
# starship - custom shell #
###########################

if command -v starship > /dev/null; then
    eval "$(starship init bash)"
fi

###################
# direnv settings #
###################

if command -v direnv > /dev/null; then
    eval "$(direnv hook bash)";
fi

###################################
# command-not-found-init settings #
###################################

HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
# shellcheck source=/dev/null
if [ -f "$HB_CNF_HANDLER" ]; then
    source "$HB_CNF_HANDLER";
fi

################
# add ssh keys #
################

ssh-add -k &> /dev/null

# turned off to avoid ".python-version" conflicts with UV
if command -v mise > /dev/null 2>&1; then
    eval "$(mise activate bash)";
fi

if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init bash)";
fi
