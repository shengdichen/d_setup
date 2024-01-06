#!/usr/bin/env dash

. "../util.sh"

__install() {
    install "arch" \
        ethtool tlp acpi

    service_start -- tlp
}

set_threshold() {
    local choice
    local low="low" default="default" high="high" custom="custom"
    if [ "${#}" -eq 0 ]; then
        printf "select profile, |custom| to specify manually:\n"
        choice="$(printf "%s\n%s\n%s\n%s" "${low}" "${default}" "${high}" "${custom}" | fzf --reverse --height="33%")"
    else
        choice="${1}"
    fi

    local threshold
    case "${choice}" in
        "${low}")
            threshold=59
            ;;
        "${default}")
            threshold=79
            ;;
        "${high}")
            threshold=93
            ;;
        "${custom}")
            while true; do
                printf "charge threshold: " && read -r threshold
                if [ "${threshold}" -gt 9 ] && [ "${threshold}" -lt 99 ]; then
                    break
                else
                    printf "invalid threshold, try again\n\n"
                fi
            done
            ;;
    esac

    for bat in $(find "/sys/class/power_supply/" -maxdepth 1 -printf "%P\n" | grep "^BAT"); do
        "$(__sudo)" tlp setcharge "${threshold}" $((threshold + 1)) "${bat}"
    done
}

__install
printf "\n"
set_threshold "${@}"
