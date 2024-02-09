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
    # need to repeat this several times to take effect
    for __ in $(seq 3); do
        # for current boot
        "$(__sudo)" modprobe -r "${MODULE}" && "$(__sudo)" modprobe "${MODULE}" "${_config}"
        sleep 1
    done
    # make permanent
    "$(__sudo)" tee "/etc/modprobe.d/${MODULE}.conf" <<STOP >/dev/null
options ${MODULE} ${_config}
STOP
}

__reload() {
    local _n_reloads=3
    for i in $(seq "${_n_reloads}"); do
        printf "reloading> attempt [%s/%s]\n" "${i}" "${_n_reloads}"
        "$(__sudo)" modprobe -r "${MODULE}" && "$(__sudo)" modprobe "${MODULE}"
        if [ "${i}" -ne "${_n_reloads}" ]; then
            sleep 5
        fi
    done
}

case "${1}" in
    "--incr")
        __increase_refreshrate
        ;;
    *)
        __reload
        ;;
esac
unset MODULE
unset -f __increase_refreshrate __reload
