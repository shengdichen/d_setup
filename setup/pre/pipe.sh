#!/usr/bin/env dash

SCRIPT_DIR=$(dirname "$(realpath "${0}")")

_pacman_conf() {
    # REF:
    #   https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
    local _archzfs_key="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
    pacman-key --recv-keys "${_archzfs_key}"
    pacman-key --finger "${_archzfs_key}"
    pacman-key --lsign-key "${_archzfs_key}"

    # REF:
    #   https://www.blackarch.org/downloads.html#install-repo
    local _blackarch="strap.sh"
    curl -O "https://blackarch.org/${_blackarch}"
    chmod +x "${_blackarch}"
    ./"${_blackarch}"
    rm "${_blackarch}"

    cp "./pacman.conf" "/etc/."
    pacman -Syy
    pacman -Fyy
}

_base() {
    bash "${SCRIPT_DIR}/chroot.sh"

    umount -R /mnt
    reboot
}
