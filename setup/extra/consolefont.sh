#!/usr/bin/env dash

. "../util.sh"

__write() {
    local _locale="us" _size="24"
    local _conf="/etc/vconsole.conf"

    case "${1}" in
        "-s" | "--size")
            _size="${2}"
            shift
            ;;
    esac

    "$(__sudo)" tee "${_conf}" <<STOP >/dev/null
KEYMAP=${_locale}
FONT=ter-v${_size}b
STOP

    systemctl restart systemd-vconsole-setup
}

__write "${@}"
unset -f __write
