#!/usr/bin/env dash

. "${HOME}/.local/lib/util.sh"

PORTAL_BASE="xdg-desktop-portal"

__kill() {
    __f() {
        if systemctl --user --quiet is-active -- "${1}"; then
            systemctl --user stop -- "${1}"
            printf "kill> %s [systemctl]\n" "${1}"
            return
        fi
        if __pkill "/usr/lib/${1}"; then
            printf "kill> %s [pkill]\n" "${1}"
            return
        fi

        printf "kill> already dead, skipping [%s]\n" "${1}"
    }

    __f "${PORTAL_BASE}"
    for _p in "hyprland" "gtk"; do
        __f "${PORTAL_BASE}-${_p}"
    done
}

__launch() {
    # REF:
    #   https://wiki.hyprland.org/hyprland-wiki/pages/Useful-Utilities/Hyprland-desktop-portal/

    local _base="/usr/lib/${PORTAL_BASE}"
    for _p in "hyprland" "gtk"; do
        __nohup "${_base}-${_p}"
    done
    __nohup "${_base}"
}

__main() {
    __kill
    __launch
}
__main
