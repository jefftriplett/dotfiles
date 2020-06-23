# shellcheck shell=bash

pip-update() {
    for version in $(pyenv versions --bare) ; do
        echo "Upgrading Python ${version}"
        pyenv shell "${version}"
        # pyenv which python
        PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade pip virtualenv virtualenvwrapper wheel > /dev/null 2>&1
    done

    # Update one-offs for our main "global" python
    version=3.7.7

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

###########################
# Docker Helper Functions #
###########################

dcleanup(){
    local containers
    mapfile -t containers < <(docker ps -aq 2>/dev/null)
    docker rm "${containers[@]}" 2>/dev/null
    local volumes
    mapfile -t volumes < <(docker ps --filter status=exited -q 2>/dev/null)
    docker rm -v "${volumes[@]}" 2>/dev/null
    local images
    mapfile -t images < <(docker images --filter dangling=true -q 2>/dev/null)
    docker rmi "${images[@]}" 2>/dev/null
}

del_stopped(){
    local name=$1
    local state
    state=$(docker inspect --format "{{.State.Running}}" "$name" 2>/dev/null)

    if [[ "$state" == "false" ]]; then
        docker rm "$name"
    fi
}

relies_on(){
    for container in "$@"; do
        local state
        state=$(docker inspect --format "{{.State.Running}}" "$container" 2>/dev/null)

        if [[ "$state" == "false" ]] || [[ "$state" == "" ]]; then
            echo "$container is not running, starting it for you."
            $container
        fi
    done
}

###################
# My Applications #
###################

plex(){
    del_stopped plex-cli

    docker run --restart=always -d \
        --name=plex-cli \
        -e VERSION=latest \
        -m 500m \
        -v /Users/jefftriplett/.virtualenvs/plex/src/data/config:/config \
        -v /Users/jefftriplett/.virtualenvs/plex/src/data/data:/data \
        -v /Users/jefftriplett/.virtualenvs/plex/src/data/transcode:/transcode \
        -p 1900:1900/udp \
        -p 5353:5353/udp \
        -p 32400:32400 \
        -p 32400:32400/udp \
        -p 32469:32469 \
        -p 32469:32469/udp \
        linuxserver/plex
        # --net=host \
}


chrome_docker(){
    # add flags for proxy if passed
    local proxy=
    local map
    local args=$*
    if [[ "$1" == "tor" ]]; then
        relies_on torproxy

        map="MAP * ~NOTFOUND , EXCLUDE torproxy"
        proxy="socks5://torproxy:9050"
        args="https://check.torproject.org/api/ip ${*:2}"
    fi

    del_stopped chrome

    # one day remove /etc/hosts bind mount when effing
    # overlay support inotify, such bullshit
    docker run -d \
        --memory 3gb \
        -v /etc/localtime:/etc/localtime:ro \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e "DISPLAY=unix${DISPLAY}" \
        -v "${HOME}/Downloads:/root/Downloads" \
        -v "${HOME}/Pictures:/root/Pictures" \
        -v "${HOME}/Torrents:/root/Torrents" \
        -v "${HOME}/.chrome:/data" \
        -v /dev/shm:/dev/shm \
        -v /etc/hosts:/etc/hosts \
        --security-opt seccomp:/etc/docker/seccomp/chrome.json \
        --device /dev/snd \
        --device /dev/dri \
        --device /dev/video0 \
        --device /dev/usb \
        --device /dev/bus/usb \
        --group-add audio \
        --group-add video \
        --name chrome \
        "${DOCKER_REPO_PREFIX}/chrome" --user-data-dir=/data \
        --proxy-server="$proxy" \
        --host-resolver-rules="$map" "$args"
}
