#!/usr/bin/env dash

. "../../util.sh"

CONF="/etc/doas.conf"

# REF:
#   https://wiki.archlinux.org/title/Doas#Configuration

__setup() {
    if [ ! -e "${CONF}" ]; then
        "$(__sudo)" cp "./doas.conf" "/etc/."

        "$(__sudo)" chown -c root:root "${CONF}"
        "$(__sudo)" chmod -c 0400 "${CONF}"
    fi
}

__check() {
    if ! "$(__sudo)" doas -C "${CONF}"; then
        priintf "doas> config error\n\n"
        exit 3
    fi
}

__setup && __check
