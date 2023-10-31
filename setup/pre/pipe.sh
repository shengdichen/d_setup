SCRIPT_DIR=$(dirname "$(realpath "${0}")")

function _base() {
    bash "${SCRIPT_DIR}/chroot.sh"

    umount -R /mnt
    reboot
}
_base
