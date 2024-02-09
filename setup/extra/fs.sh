#!/usr/bin/env dash

. "../util.sh"

__swapfile() {
    if ! __is_root; then
        printf "run as root, exiting\n"
        exit 3
    fi

    local _size=32 _target="/SWAP"
    if [ ! -e "${_target}" ]; then
        dd if=/dev/zero of="${_target}" bs=1M count="${_size}k" status=progress
        chmod 0600 "${_target}"
        mkswap -U clear "${_target}"
        printf "\n\n"
    fi

    if ! swapon -s | grep -q "^${_target}"; then
        swapon "${_target}"
    fi

    local _fstab="/etc/fstab"
    if ! grep -q " none swap " "${_fstab}"; then
        cat <<STOP >>"${_fstab}"
${_target} none swap defaults 0 0

STOP
    fi
}

__swapfile_edit() {
    # 1. rename root-parition
    # # sudo e2label /dev/sda<ROOT> "ROOT"
    # NOTE:
    #   1. the label will NOT showup until remounting partition, in the case of a root partition: until reboot
    #   2. verify with |$ blkid|

    # 2. swapfile

    # 3. edit /etc/fstab
    #       LABEL=ROOT / ext4 rw,relatime 0 1
    #       /SWAP none swap defaults 0 0

    return
}

case "${1}" in
    "swapfile")
        __swapfile
        ;;
    *)
        printf "huh? what is [%s]\n" "${1}"
        ;;
esac
unset -f __swapfile
