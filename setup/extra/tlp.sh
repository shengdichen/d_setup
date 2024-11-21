#!/usr/bin/env dash

. "../util.sh"

SYS_POWERSUPPLY="/sys/class/power_supply"

__base() {
    __install arch -- \
        ethtool tlp acpi

    # REF:
    #   https://linrunner.de/tlp/installation/arch.html
    service_start -- tlp
    systemctl enable --now -- NetworkManager-dispatcher.service
    systemctl mask -- systemd-rfkill.service systemd-rfkill.socket
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

__calc() {
    printf "%s \n" "${1}" | bc -l
}

__status_one() {
    local _bat="${1}"

    __battery_id() {
        local _battery_id
        _battery_id=$(($(printf "%s" "${_bat}" | tail -c "+4") + 1))
        printf "b%s> " "${_battery_id}"
    }

    # NOTE:
    #   unit: muWh
    local _capacity_now _capacity_full _capacity_factory
    _capacity_now="$(cat "${SYS_POWERSUPPLY}/${_bat}/energy_now")"
    _capacity_full="$(cat "${SYS_POWERSUPPLY}/${_bat}/energy_full")"
    _capacity_factory="$(cat "${SYS_POWERSUPPLY}/${_bat}/energy_full_design")"

    local _power
    _power="$(cat "${SYS_POWERSUPPLY}/${_bat}/power_now")" # muW

    __health() {
        local _n_cycles _perc
        _n_cycles="$(cat "${SYS_POWERSUPPLY}/${_bat}/cycle_count")"
        _perc="$(__calc "100 * ${_capacity_full} / ${_capacity_factory}")"
        _wh="$(__calc "${_capacity_full} / (10 ^ 6)")"

        printf "health: %.1fWh, %s->%.2f%%" "${_wh}" "${_n_cycles}" "${_perc}"
    }

    __perc() {
        local _perc
        _perc="$(__calc "100 * ${_capacity_now} / ${_capacity_full}")"

        printf "%.3f%%" "${_perc}"
    }

    __in_use() {
        [ "${_power}" -ne 0 ]
    }

    __powerdraw() {
        local _power_watt
        _power_watt="$(__calc "${_power} / (10 ^ 6)")"
        printf "%.3fW" "${_power_watt}"
    }

    __time_to_empty() {
        local _time
        _time="$(__calc "60 * ${_capacity_now} / ${_power}")"

        local _perc_per_ten
        _perc_per_ten="$(__calc "100 * (1/6) * ${_power} / ${_capacity_full}")"

        printf "(%.1fmin; %.1f%%/10min)" "${_time}" "${_perc_per_ten}"
    }

    __threshold() {
        local _threshold_start="${SYS_POWERSUPPLY}/${_bat}/charge_start_threshold"
        local _threshold_stop="${SYS_POWERSUPPLY}/${_bat}/charge_stop_threshold"

        if [ -e "${_threshold_start}" ] && [ -e "${_threshold_stop}" ]; then
            printf " [%s%%-%s%%]" "$(cat "${_threshold_start}")" "$(cat "${_threshold_stop}")"
        fi
    }

    __time_to_full() {
        local _threshold_file="${SYS_POWERSUPPLY}/${_bat}/charge_stop_threshold"
        local _capacity_target
        if [ -e "${_threshold_file}" ]; then
            _capacity_target="$(__calc "($(cat "${_threshold_file}") / 100) * ${_capacity_full}")"
        else
            _capacity_target="${_capacity_full}"
        fi

        local _time
        _time="$(__calc "60 * (${_capacity_target} - ${_capacity_now}) / ${_power}")"

        local _perc_per_ten
        _perc_per_ten="$(__calc "100 * (1/6) * ${_power} / ${_capacity_full}")"

        printf "(%.1fmin; %.1f%%/10min)" "${_time}" "${_perc_per_ten}"
    }

    local _ac=""
    if [ "$(cat "${SYS_POWERSUPPLY}/AC/online")" = "1" ]; then
        _ac="yes"
    fi
    if [ "${_ac}" ]; then
        printf "AC/"
    else
        printf "BAT/"
    fi

    __battery_id
    case "$(cat "${SYS_POWERSUPPLY}/${_bat}/status")" in
        "Not charging")
            printf "==%s" "$(__perc)"
            if [ "${_ac}" ]; then
                __threshold
            fi
            ;;
        "Charging")
            __perc
            __threshold
            if ! __in_use; then
                printf "  (updating powerdraw)"
            else
                printf "  @+%s" "$(__powerdraw)"
                printf " ~%s" "$(__time_to_full)"
            fi
            ;;
        "Discharging")
            __perc
            if ! __in_use; then
                printf "  (updating powerdraw)"
            else
                printf "  @-%s" "$(__powerdraw)"
                printf " ~%s" "$(__time_to_empty)"
            fi
            ;;
    esac
    printf "  // %s" "$(__health)"
}

__status() {
    if [ ! -e "${SYS_POWERSUPPLY}/AC" ]; then
        printf "power> desktop\n"
        return
    fi

    find "${SYS_POWERSUPPLY}" -mindepth 1 -printf "%P\n" | sort -n | grep "^BAT" | while read -r _bat; do
        __status_one "${_bat}"
        printf "\n"
    done
}

case "${1}" in
    "set")
        shift
        __base
        set_threshold "${@}"
        ;;
    *)
        __status
        ;;
esac
