#!/usr/bin/env dash

__install() {
    pacman -S --needed --noconfirm -- docker
    paru -S --needed --noconfirm -- docker-desktop
}

__configure() {
    __group() {
        if id | grep -q "groups=.*\(docker\)"; then
            return
        fi
        local _user
        _user="$(id -u -n)"
        printf "docker> adding user [%s] to docker group..." "${_user}"
        sudo usermod -a -G "docker" -- "${_user}"
        printf ", done!\n"
    }

    __service() {
        systemctl enable --now -- docker.socket
        systemctl --user disable -- docker-desktop
    }

    __group
    __service
}

__install
__configure
