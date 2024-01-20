#!/usr/bin/env dash

make_media() {
    local iso="archlinux-x86_64.iso"
    if [ ! -f ${iso} ]; then
        curl -LO "https://geo.mirror.pkgbuild.com/iso/latest/${iso}"
    fi

    while true; do
        echo "select (full) disk for making installation"
        disk="$(lsblk -o PATH,FSTYPE,SIZE,MOUNTPOINTS | fzf --reverse --height=30% | awk '{ print $1 }')"
        local input
        printf "[%s] for making: retry (default); [c]onfirm " "${disk}"
        read -r input
        if [ "${input}" = "c" ]; then
            break
        fi
        clear
    done

    sudo dd if=./"${iso}" of="${disk}" bs=4M status=progress oflag=sync
}

push_to_xyz() {
    local \
        profile="ssh_xyz" \
        script_root="domains/shengdichen.xyz/public_html/install"

    ssh "${profile}" mkdir -p ${script_root}
    for f in "00.sh" "01.sh" "02.sh" "pacman.conf" "pacman.conf.pacnew"; do
        scp \
            "./${f}" \
            "${profile}:${script_root}/."
    done

    echo "Done! Obtain with:"
    echo "\$ curl -LO shengdichen.xyz/install/0[0|1|2].sh"
}

case "${1}" in
    "make")
        make_media
        ;;
    *)
        push_to_xyz
        ;;
esac
unset -f make_media push_to_xyz
