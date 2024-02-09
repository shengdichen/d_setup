#!/usr/bin/env dash

. "../../util.sh"

__base() {
    __install pipx -- undervolt

    service_start -- throttled
}

__base
unset -f __install
