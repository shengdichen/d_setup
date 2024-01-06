#!/usr/bin/env dash

. "../util.sh"

__write() {
    cat <<STOP >/etc/vconsole.conf
KEYMAP=us
FONT=ter-v${1:-24}b
STOP

    systemctl restart systemd-vconsole-setup
}

__write 32
unset -f __write
