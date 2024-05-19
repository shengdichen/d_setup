#!/usr/bin/env dash

. "../util.sh"

__gtk() {
    __theme() {
        __install arch -- materia-gtk-theme arc-gtk-theme
    }

    __icon() {
        # arc
        __install arch -- arc-icon-theme elementary-icon-theme

        # la capitaine
        __install aurhelper -- la-capitaine-icon-theme elementary-icon-theme gnome-icon-theme
    }

    __theme
    __icon
}

__kde() {
    # NOTE:
    #   qt5: lyx
    #   qt6: pcmanfm-qt

    __install aurhelper -- qt5ct-kde qt6ct-kde

    __install arch -- \
        materia-kde \
        oxygen oxygen5 \
        breeze breeze5
}

__gtk
__kde
