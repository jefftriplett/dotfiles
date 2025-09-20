# shellcheck shell=bash

# node/bun scripts
alias alex="bunx alex"
alias all-contributors-cli="bunx all-contributors-cli"
alias codeowners-enforcer="bunx codeowners-enforcer"
alias embedme="bunx embedme"
alias gitignore="bunx gitignore"
alias nanoprobe="bunx nanoprobe"
alias npkill="bunx npkill"
alias npm-check="bunx npm-check"
alias okimdone="bunx okimdone"
alias readme-md-generator="bunx readme-md-generator"
alias vmd="bunx vmd"

# setup AI/LLM/Mise aliases
alias claude-continue="mise run claude-continue"
alias claude="mise run claude"
alias copilot="copilot --allow-all"
alias copilot-continue="copilot --allow-all --resume"
alias git-commit-msg-auto="mise run llm:git-commit-msg-auto"
alias git-commit-msg="mise run llm:git-commit-msg"
alias vt-claude-continue="mise run vt-claude-continue"
alias vt-claude="mise run vt-claude"

# everything else
alias cat="bat -p"
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias gam="~/bin/gam/gam"
alias gist="gist -p"
alias got="git"
alias gt="gittower"
alias nw="~/node_modules/nwjs/nwjs.app/Contents/MacOS/nwjs"
alias outdated="brew update; brew outdated; brew cask outdated; mas outdated"
alias pip-outdated="PIP_REQUIRE_VIRTUALENV=false python -m pip list --outdated"
alias pycharm='open -na "PyCharm.app" --args "$@"'
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
