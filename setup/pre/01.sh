#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"

__check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Must be executed as root, exiting"
        exit 3
    fi
}
__check_root

pacman_zfs() {
    printf "[pacman.zfs] START " && read -r _
    # REF:
    #   https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
    local _archzfs_key="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
    pacman-key --recv-keys "${_archzfs_key}"
    pacman-key --finger "${_archzfs_key}"
    pacman-key --lsign-key "${_archzfs_key}"
    printf "[pacman.zfs] DONE " && read -r _ && clear
}

pacman_blackarch() {
    printf "[pacman.blackarch] START " && read -r _
    # REF:
    #   https://www.blackarch.org/downloads.html#install-repo
    local _blackarch="strap.sh"
    curl -O "https://blackarch.org/${_blackarch}"
    chmod +x "${_blackarch}"
    ./"${_blackarch}"
    rm "${_blackarch}"
    printf "[pacman.blackarch] DONE " && read -r _ && clear
}

pacman_conf_takeover() {
    local conf="pacman.conf"
    local conf_back="${conf}.pacnew"

    if [ ! -f "./${conf}" ]; then
        curl -L -O "shengdichen.xyz/install/${conf}"
    fi

    if [ ! -f "/etc/${conf_back}" ]; then
        mv "/etc/${conf}" "/etc/${conf_back}"
    fi
    cp "./${conf}" "/etc/."
    rm "./${conf}"
    clear
}

pacman_setup() {
    if [ ! -f /etc/pacman.conf.pacnew ]; then
        # create backup if needed
        cp -f /etc/pacman.conf /etc/pacman.conf.pacnew
    else
        # restore from backup
        cp -f /etc/pacman.conf.pacnew /etc/pacman.conf
    fi

    local pack_keyring="archlinux-keyring"
    if ! pacman -Syu; then
        if ! pacman -S "${pack_keyring}"; then
            rm -rf /etc/pacman.d/gnupg
            pacman-key --init
            pacman-key --populate
            pacman -S "${pack_keyring}"
        fi
    fi
    printf "[pacman.prework] DONE " && read -r _
    clear

    pacman_blackarch
    pacman_zfs
    pacman_conf_takeover

    printf "[pacman.reload] START: " && read -r _
    pacman -Syu
    pacman -Fyy
    printf "[pacman.reload] DONE " && read -r _
    clear
}

birth() {
    local _me="shc" _rank="god" _home="main"

    pacman -S --needed zsh zsh-completions zsh-syntax-highlighting
    clear

    if ! id "${_me}" >/dev/null 2>&1; then
        useradd -m -d "/home/${_home}" -G wheel -s /bin/zsh "${_me}"
        groupmod -n "${_rank}" "${_me}"

        while true; do
            printf "[%s] " ${_me}
            if passwd "${_me}"; then break; fi
            echo
        done
        printf "%s is born " ${_me}
    else
        printf "%s is already alive " ${_me}
    fi
    read -r _ && clear

    # previous version := ...(ALL:ALL)...
    # newer version := ...(ALL)...
    if ! grep "^%wheel ALL=(.*ALL) ALL$" /etc/sudoers; then
        printf "[visudo] uncomment |%%wheel ALL=(ALL) ALL|: " && read -r _
        EDITOR=nvim visudo
        clear
        printf "[visudo] DONE " && read -r _ && clear
    fi

    rm "/home/${_home}/.bash"*

    curl -L -O "shengdichen.xyz/install/02.sh"
    chown "${_me}:${_rank}" 02.sh
    mv -f 02.sh "/home/${_home}/."
}

cleanup() {
    rm "${SCRIPT_NAME}"
    true >"${HOME}/.bash_history"

    echo
    echo "Setup complete, switch user and run:"
    echo "    \$ sh 02.sh"
    echo
    printf "Ready: "
    read -r _
}

pacman_setup
birth
cleanup
unset -f __check_root pacman_setup birth cleanup
