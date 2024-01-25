#!/usr/bin/env dash

main() {
    local _level="0"
    case "${1}" in
        "0" | "1" | "2")
            _level="${1}"
            shift
            ;;
    esac

    "./base.sh" "${@}"
    "./dev.sh" "${_level}" "${@}"
    "./goof.sh" "${_level}" "${@}"
}
main "${@}"
unset -f main
