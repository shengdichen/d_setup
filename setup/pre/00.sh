#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"
MNT="/mnt"
EFI_MOUNT="/boot/efi"

__check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Must be executed as root, exiting"
        exit 3
    fi
}

__start() {
    printf "%s> START" "${1}"
    printf "\n"
}

__continue() {
    printf "\n"
    printf "Continue: "
    read -r _
    clear
}

__separator() {
    local msg=""
    if [ -n "${1}" ]; then
        msg=" ${1} "
    fi
    echo
    echo "----------${msg}----------"
    echo
}

__confirm() {
    printf "\n"
    while true; do
        printf "%s> [C]onfirm; [q]uit " "${1}"
        local input=""
        read -r input
        if [ "${input}" = "q" ] || [ "${input}" = "Q" ]; then
            printf "Exiting"
            exit 3
        elif [ "${input}" = "c" ] || [ "${input}" = "C" ] || [ -z "${input}" ]; then
            clear
            return
        else
            echo "Huh, ${input}?"
        fi
    done
}

__is_installed() {
    pacman -Qi "${1}" >/dev/null 2>&1
}

__run_in_chroot() {
    arch-chroot "${MNT}" sh "${@}"
}

partitioning_vbox() {
    if ! efibootmgr; then
        echo "Not in EFI mode, exiting"
        exit 3
    fi
    pacman -Syy
    pacman -S --needed fzf
    __continue

    local disk
    while true; do
        echo "select (full) disk for partitioning"
        disk="$(lsblk -o PATH,FSTYPE,SIZE,MOUNTPOINTS | fzf --reverse --height=30% | awk '{ print $1 }')"
        local input
        printf "[%s] for partitioning: retry (default); [c]onfirm " "${disk}"
        read -r input
        if [ "${input}" = "c" ]; then
            break
        fi
        clear
    done

    local part_delimiter=""
    case "${disk}" in
        "/dev/nvme"*)
            part_delimiter="p"
            ;;
    esac

    parted "${disk}" mklabel gpt

    local efi_size="512MB" efi_part="efi"
    parted "${disk}" mkpart "${efi_part}" fat32 "1MB" "${efi_size}"
    parted "${disk}" set 1 esp on
    mkfs.fat -F 32 "${disk}${part_delimiter}1"

    parted "${disk}" mkpart "root" ext4 "${efi_size}" 100%
    mkfs.ext4 "${disk}${part_delimiter}2"
    e2label "${disk}${part_delimiter}2" "ROOT"

    # MUST mount /mnt before sub-mountpoints (e.g., /mnt/efi)
    local mnt_base="/mnt"
    mount "${disk}${part_delimiter}2" "${mnt_base}"
    mount --mkdir "${disk}${part_delimiter}1" "${mnt_base}/${EFI_MOUNT}"

    __separator
    lsblk
    __continue
}

partitioning() {
    __start "partitioning"

    if ! mount | grep " on /mnt" >/dev/null; then
        echo "parition and mount to /mnt first, exiting"
        exit 3
    fi

    __separator
    lsblk
    __confirm "partitioning"
}

check_network() {
    __start "networking"

    __separator
    ping -c 3 shengdichen.xyz
    __confirm "network"
}

sync_time() {
    __start "time"

    local date_pattern="Date: " time_curr
    time_curr="$(
        curl -s --head http://google.com |
            grep "^${date_pattern}" |
            sed "s/${date_pattern}//g"
    )"
    printf "set-time-to> %s\n" "${time_curr}"

    date -s "${time_curr}" >/dev/null
    hwclock -w --utc

    __separator
    timedatectl
    __confirm "time"
}

bulk_work() {
    __start "pacstrap"
    pacman -Syy
    pacman -S archlinux-keyring
    pacstrap -K /mnt \
        base base-devel dash vi neovim less \
        linux-zen linux-lts linux-firmware bash-completion

    __separator
    if ! arch-chroot /mnt pacman -Q | grep linux-zen >/dev/null; then
        echo "Installation failed, bad internet maybe?"
        exit 3
    fi
    __confirm "pacstrap"

    __start "fstab"
    local fstab="/mnt/etc/fstab"
    genfstab -U /mnt >"${fstab}"
    __separator
    lsblk
    echo
    cat "${fstab}"
    __confirm "fstab"
}

transition_to_post() {
    clear
    __start "in-chroot"

    cp -f "${SCRIPT_NAME}" "${MNT}/."

    printf "Ready to chroot: automatic setup (default); [m]anual: "
    local input
    read -r input
    echo

    if [ "${input}" = "m" ]; then
        echo "Run"
        echo "    # sh ${SCRIPT_NAME} post"
        echo "in chroot."
        echo
        printf "Ready when you are: "
        read -r _
        arch-chroot /mnt
    else
        arch-chroot /mnt sh "${SCRIPT_NAME}" post
    fi
}

base() {
    __start "chroot.base"
    . /usr/share/bash-completion/bash_completion

    local pack_keyring="archlinux-keyring"
    if ! pacman -S "${pack_keyring}"; then
        rm -rf /etc/pacman.d/gnupg
        pacman-key --init
        pacman-key --populate
        pacman -S "${pack_keyring}"
    fi

    clear

    # re-password only if needed
    if [ ! "$(passwd --status | awk '{print $2}')" = "P" ]; then
        while true; do
            printf "[root] "
            if passwd; then break; fi
            echo
        done
    fi

    ln -sf /usr/share/zoneinfo/Europe/Vaduz /etc/localtime
    hwclock --systohc

    __separator
    __confirm "chroot.base"

}

localization() {
    __start "localization"

    if ! locale -a | grep "sv_SE.utf8" >/dev/null; then
        cat <<STOP >/etc/locale.gen
en_US.UTF-8 UTF-8

fr_CH.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
ar_EG.UTF-8 UTF-8
es_ES.UTF-8 UTF-8

de_CH.UTF-8 UTF-8
de_DE.UTF-8 UTF-8
zh_HK.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8

it_CH.UTF-8 UTF-8
it_IT.UTF-8 UTF-8
pt_BR.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8
STOP
        locale-gen
    fi

    cat <<STOP >/etc/locale.conf
LANG=en_US.UTF-8
STOP

    __separator
    __confirm "localization"
}

network() {
    __start "network"

    local hostname_file="/etc/hostname"
    if [ ! -f "${hostname_file}" ]; then
        local _hname
        printf "Hostname: "
        read -r _hname
        echo "${_hname}" >"${hostname_file}"
    fi

    cat <<STOP >/etc/hosts
127.0.0.1 localhost
::1 localhost
STOP

    clear

    if ! __is_installed networkmanager; then
        pacman -S networkmanager dhclient
        cat <<STOP >/etc/NetworkManager/conf.d/dhcp-client.conf
[main]
dhcp=dhclient
STOP
        systemctl enable NetworkManager.service
    fi

    __separator ""
    __confirm "network"
}

boot() {
    __start "boot"

    if ! __is_installed grub; then
        pacman -S grub efibootmgr
    fi

    local grub_dir="/boot/grub"
    if [ ! -d "${grub_dir}" ]; then
        clear
        mkinitcpio -P
        clear

        grub-install \
            --target=x86_64-efi \
            --efi-directory="${EFI_MOUNT}" \
            --bootloader-id=MAIN

        grub-mkconfig -o "${grub_dir}/grub.cfg"
    fi

    __separator ""
    efibootmgr
    __confirm "boot"
}

post_chroot() {
    base
    localization
    network
    boot

    rm "${SCRIPT_NAME}"
    __separator ""
    echo "All done here in chroot."
    __confirm "chroot"
}
# }}}

cleanup() {
    curl -L -O "shengdichen.xyz/install/01.sh"
    mv -f 01.sh "/mnt/."
    echo
    printf "01-stage> ready when you are: "
    read -r _ && clear
    if ! arch-chroot /mnt sh 01.sh; then
        echo "Installation complete; run"
        echo "    # sh 01.sh"
        echo "after rebooting."
        printf "Ready when you are: "
        read -r _
    fi
    rm "${SCRIPT_NAME}"
    umount -R /mnt
    reboot
}

case "${1}" in
    "vbox")
        partitioning_vbox
        ;;
    "pre")
        __check_root
        partitioning
        check_network
        sync_time
        bulk_work
        ;;
    "transition")
        transition_to_post
        ;;
    "post")
        post_chroot
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        pre_chroot
        transition_to_post
        cleanup
        ;;
esac
