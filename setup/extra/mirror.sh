#!/usr/bin/env dash

FILE_MIRROR="/etc/pacman.d/mirrorlist"

__update() {
    # REF:
    #   https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements

    local _countries
    case "${1}" in
        "asia")
            _countries="hk,jp"
            ;;
        *)
            _countries="se,fr,fi"
            ;;
    esac

    sudo reflector \
        --save "${FILE_MIRROR}" \
        --latest 10 \
        --protocol https \
        \
        --country "${_countries}"
}
__update "${@}"
