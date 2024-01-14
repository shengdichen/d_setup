#!/usr/bin/env dash

. "../util.sh"

__explicit() {
    install "aur" \
        aic94xx-firmware ast-firmware wd719x-firmware upd72020x-fw
}

__monopoly() {
    install "aurhelper" \
        mkinitcpio-firmware
}

case "${1}" in
    "explicit")
        __explicit
        ;;
    *)
        __monopoly
        ;;
esac
unset -f __explicit __monopoly
