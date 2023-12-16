SCRIPT_NAME="$(basename "${0}")"

__check_root() {
    if ((EUID != 0)); then
        echo "Must be executed as root, exiting"
        exit 3
    fi
}
__check_root

pacman_setup() {
    if ! pacman -Syy; then
        echo "pacman -Syy failed, bad internet maybe?"
        echo "relaunch when ready"
    fi
    printf "[pacman.refresh] DONE " && read -r && clear

    printf "[pacman.zfs] START " && read -r
    # REF:
    #   https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
    local _archzfs_key="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
    pacman-key --recv-keys "${_archzfs_key}"
    pacman-key --finger "${_archzfs_key}"
    pacman-key --lsign-key "${_archzfs_key}"
    printf "[pacman.zfs] DONE " && read -r && clear

    printf "[pacman.blackarch] START " && read -r
    # REF:
    #   https://www.blackarch.org/downloads.html#install-repo
    local _blackarch="strap.sh"
    curl -O "https://blackarch.org/${_blackarch}"
    chmod +x "${_blackarch}"
    ./"${_blackarch}"
    rm "${_blackarch}"
    printf "[pacman.blackarch] DONE " && read -r && clear

    local conf="pacman.conf"
    if [ ! -f "./${conf}" ]; then
        curl -L -O "shengdichen.xyz/install/${conf}"
    fi
    cp "./${conf}" "/etc/."
    rm "./${conf}"
    clear

    printf "reload pacman when ready: " && read -r
    pacman -Syy
    pacman -Fyy
    pacman -Syu
}

birth() {
    local _me="shc"

    if ! id "${_me}" >/dev/null 2>&1; then
        pacman -S --needed zsh zsh-completions zsh-syntax-highlighting

        useradd -m -d /home/main -G wheel -s /bin/zsh "${_me}"
        groupmod -n god "${_me}"

        printf "[%s] " ${_me}
        passwd "${_me}"
        printf "%s is born " ${_me}
    else
        printf "%s is already alive" ${_me}
    fi
    read -r && clear

    printf "[visudo] uncomment |%%wheel ALL=(ALL) ALL| " && read -r
    EDITOR=nvim visudo
    printf "[visudo] DONE " && read -r && clear
}

cleanup() {
    rm "${SCRIPT_NAME}"
    true >"${HOME}/.bash_history"
    echo "Setup complete, switch user when ready"
}

pacman_setup
birth
cleanup
unset -f __check_root pacman_setup birth cleanup
