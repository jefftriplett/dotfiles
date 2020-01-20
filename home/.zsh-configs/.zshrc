export PATH=/usr/local/bin:$PATH

# Include the custom prompts.
fpath=("$HOME/.zsh-configs/.zprompts" "$fpath[@]")

autoload -Uz colors compinit promptinit
colors
compinit
promptinit

# Make sure the prompts will take subsitutions.
setopt prompt_subst

# Add menu-select style completions
zstyle ':completion:*' menu select
# Try to add completions for aliases.
setopt COMPLETE_ALIASES
# Allow `sudo ...` to try to provide completions as well.
zstyle ':completion::complete:*' gain-privileges 1

# Enable incremental history.
HISTFILE=~/.zsh-configs/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

bindkey -v
bindkey '^R' history-incremental-search-backward


eval "$(direnv hook zsh)"
