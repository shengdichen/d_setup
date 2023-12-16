source "../util.sh"

function set_threshold() {
    local threshold
    case "${1}" in
        "low")
            threshold=59
            ;;
        "default")
            threshold=79
            ;;
        "high")
            threshold=93
            ;;
        *)
            threshold="${1}"
            ;;
    esac

    for bat in $(find "/sys/class/power_supply/" -maxdepth 1 -printf "%P\n" | grep "^BAT"); do
        "$(__sudo)" tlp setcharge "${threshold}" $((threshold + 1)) "${bat}"
    done
}

service_start -- tlp
set_threshold default
