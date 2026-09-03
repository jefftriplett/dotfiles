# shellcheck shell=bash

# inspired by: https://philna.sh/blog/2019/01/10/how-to-start-a-node-js-project/
function python-project {
    git init
    npx license "$(npm get init.license)" -o "$(npm get init.author.name)" > LICENSE
    npx gitignore python
    npx covgen "$(npm get init.author.email)"
    # npm init -y
    # TODO: Build a reasonable pip-init script...
    git add -A
    git commit -m ":sparkles: Initial commit"
}
