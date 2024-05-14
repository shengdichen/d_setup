#!/usr/bin/env dash

. "../util.sh"

__write_conf() {
    local _conf="/etc/systemd/logind.conf"
    if ! grep -q "^HandlePowerKey=suspend$" "${_conf}"; then
        "$(__sudo)" tee --append "${_conf}" <<STOP >/dev/null
HandleSuspendKey=suspend
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore

HandleHibernateKey=ignore
HandlePowerKey=suspend
STOP
    fi

    # calling |restart| will crash compositor (sway)
    systemctl kill -s HUP systemd-logind.service
}
__write_conf
