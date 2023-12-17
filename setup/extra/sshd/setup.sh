source "../../util.sh"

setup() {
    "$(__sudo)" cp "./sshd_config" "/etc/ssh/."
    systemctl enable --now sshd
}
setup
