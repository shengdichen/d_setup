#!/usr/bin/env dash

. "../../util.sh"

setup() {
    "$(__sudo)" cp "./sshd_config" "/etc/ssh/."

    if __yes_or_no "service-sshd"; then
        service_start -- sshd
    fi
}
setup
unset -f setup
