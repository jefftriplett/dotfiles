# shellcheck shell=bash

pip-update() {
    for version in $(pyenv versions --bare) ; do
        echo "Upgrading Python ${version}"
        pyenv shell "${version}"
        # pyenv which python
        PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade pip virtualenv virtualenvwrapper wheel > /dev/null 2>&1
    done

    # Update one-offs for our main "global" python
    version=3.9.5

    echo "Upgrading Global Python (${version})"
    pyenv shell $version
    pyenv which python

    echo "Upgrading pipx"
    PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade pipx > /dev/null 2>&1

    # To update everything under pipx
    # $ pipx upgrade-all
}

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
