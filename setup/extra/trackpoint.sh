#!/usr/bin/env dash

. "../util.sh"

MODULE="psmouse"

__increase_refreshrate() {
    # REF:
    #   https://wiki.archlinux.org/title/Lenovo_ThinkPad_T480#TrackPoint_and_Touchpad

    if systool -v -m "${MODULE}" | grep -q "synaptics_intertouch.*\"1\""; then
        return
    fi

    local _config="synaptics_intertouch=1"
    # make permanent
    "$(__sudo)" tee "/etc/modprobe.d/${MODULE}.conf" <<STOP >/dev/null
options ${MODULE} ${_config}
STOP
}

__reload() {
    local _n_reloads=1 _time_sleep=5
    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            "--n-reloads")
                _n_reloads="${2}"
                shift && shift
                ;;
            "--time-sleep")
                _time_sleep="${2}"
                shift && shift
                ;;
            *)
                exit 3
                ;;
        esac
    done

    for i in $(seq "${_n_reloads}"); do
        printf "reloading> attempt [%s/%s]\n" "${i}" "${_n_reloads}"
        "$(__sudo)" modprobe -r "${MODULE}" && "$(__sudo)" modprobe "${MODULE}"
        if [ "${i}" -ne "${_n_reloads}" ]; then
            sleep "${_time_sleep}"
        fi
    done
}

case "${1}" in
    "--incr")
        __increase_refreshrate
        __reload --n-reloads 1
        ;;
    *)
        __reload
        ;;
esac
unset MODULE
unset -f __increase_refreshrate __reload
