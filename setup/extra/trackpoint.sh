#!/usr/bin/env dash

. "../util.sh"

__increase_refreshrate() {
    # REF:
    #   https://wiki.archlinux.org/title/Lenovo_ThinkPad_T480#TrackPoint_and_Touchpad

    local _module="psmouse"
    if systool -v -m "${_module}" | grep -q "synaptics_intertouch.*\"1\""; then
        return
    fi

    local _config="synaptics_intertouch=1"
    # need to repeat this several times to take effect
    for __ in $(seq 3); do
        # for current boot
        "$(__sudo)" modprobe -r "${_module}" && "$(__sudo)" modprobe "${_module}" "${_config}"
        sleep 1
    done
    # make permanent
    "$(__sudo)" tee "/etc/modprobe.d/${_module}.conf" <<STOP >/dev/null
options ${_module} ${_config}
STOP
}

__increase_refreshrate
unset -f __increase_refreshrate
