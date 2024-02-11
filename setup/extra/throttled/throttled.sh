#!/usr/bin/env dash

. "../../util.sh"

__base() {
    __install arch -- throttled

    service_start -- throttled
}

__set_conf() {
    echo "Select profile"
    "$(__sudo)" cp \
        "$(find . -maxdepth 1 -type f | grep "\.conf$" | fzf --height="37%")" \
        "/etc/throttled.conf"
}

__monitor() {
    "$(__sudo)" "/usr/lib/throttled/throttled.py" --monitor
}

__main() {
    case "${1}" in
        "setup")
            __base
            __set_conf
            __monitor
            ;;
        *)
            __monitor
            ;;
    esac
    unset -f __base __set_conf __monitor
}
__main "${@}"
unset -f __main
