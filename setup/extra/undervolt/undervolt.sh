#!/usr/bin/env dash

. "../../util.sh"

__install() {
    install "pipx" undervolt

    service_start -- throttled
}

__install
unset -f __install
