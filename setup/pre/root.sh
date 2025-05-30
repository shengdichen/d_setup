#!/usr/bin/env dash

SCRIPT_NAME="$(basename "${0}")"
MNT="/mnt"
EFI_MOUNT="/boot/efi"

__check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        printf "Must be executed as root, exiting\n"
        printf "\n"
        exit 3
    fi
}

__download() {
    curl -L -O "shengdichen.xyz/install/${1}"
}

__start() {
    printf "%s> START\n" "${1}"
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
    printf "\n"
    printf -- "----------%s----------\n" "${msg}"
    printf "\n"
}

__confirm() {
    printf "\n"
    while true; do
        printf "%s> [C]onfirm; [q]uit " "${1}"
        local input=""
        read -r input
        if [ "${input}" = "q" ] || [ "${input}" = "Q" ]; then
            printf "Exiting\n"
            printf "\n"
            exit 3
        elif [ "${input}" = "c" ] || [ "${input}" = "C" ] || [ -z "${input}" ]; then
            clear
            return
        else
            printf "Huh, [%s]?\n" "${input}"
            printf "\n"
        fi
    done
}

__is_installed() {
    pacman -Qi "${1}" >/dev/null 2>&1
}

__update() {
    __start "pacman-update"

    while true; do
        if ! pacman -Syy >/dev/null; then
            printf "pacman-update failed, retrying\n"
            sleep 1
        else
            break
        fi
    done

    while true; do
        # packages to test mirror availability
        if ! pacman -S --noconfirm base archlinux-keyring >/dev/null; then
            __separator
            printf "the current default (pacman-)mirror is likely offline or outdated "
            printf "(select another per reordering)\n"
            __continue

            local _mirrorlist="/etc/pacman.d/mirrorlist"
            if command -v nvim; then
                nvim "${_mirrorlist}"
            elif command -v vim; then
                vim "${_mirrorlist}"
            else
                vi "${_mirrorlist}"
            fi

            killall gpg-agent
            rm -rf /etc/pacman.d/gnupg/

            # we do want to see outputs now
            pacman -Syy
            __install base archlinux-keyring

            pacman-key --init
            pacman-key --populate
        else
            break
        fi
    done

    __separator
    __confirm "pacman-update"
}

__install() {
    if [ "${1}" = "--" ]; then shift; fi
    __start "pacman-[${*}]"

    __f() {
        if ! __is_installed "${1}"; then
            while true; do
                if ! pacman -S --noconfirm "${1}" >/dev/null; then
                    printf "pacman-install> [%s] failed\n" "${1}"
                    __update
                else
                    break
                fi
            done
        fi
    }

    for _package in "${@}"; do
        __f "${_package}"
    done
}

__lsblk() {
    lsblk -o PATH,LABEL,FSTYPE,SIZE,MOUNTPOINTS
}

__run_in_chroot() {
    if [ "${#}" -gt 0 ]; then
        arch-chroot "${MNT}" sh "${@}"
    else
        arch-chroot "${MNT}"
    fi
}

__passwd() {
    local _user="${1:-root}"

    # re-password only if no password has been set
    if [ ! "$(passwd --status "${_user}" | awk '{print $2}')" = "P" ]; then
        while true; do
            printf "[%s]-passwd> " "${_user}"
            if passwd "${_user}"; then break; fi
            printf "\n"
        done
    fi
}

partitioning_standard() {
    if ! efibootmgr >/dev/null; then
        printf "Not in EFI mode, exiting\n"
        exit 3
    fi
    __install fzf
    clear

    __start "partitioning - standard"

    local disk
    local input
    while true; do
        printf "select (full) disk for partitioning\n"
        printf "\n"
        disk="$(__lsblk | fzf --reverse --height=30% | awk '{ print $1 }')"
        printf "[%s] for partitioning: [c]onfirm; [r]etry (default) " "${disk}"
        read -r input
        if [ "${input}" = "c" ] || [ "${input}" = "C" ]; then
            break
        fi
        clear
    done
    printf "\n\n"

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
    mount "${disk}${part_delimiter}2" "${MNT}"
    mount --mkdir "${disk}${part_delimiter}1" "${MNT}/${EFI_MOUNT}"

    __separator
    __lsblk
    __continue
}

partitioning_check() {
    if ! mount | grep " on ${MNT}" >/dev/null; then
        printf "parition and mount to %s first " "${MNT}"
        printf "(try running this script with |part| as argument for standard partitioning)\n"
        printf "\n"
        printf "exiting\n"
        printf "\n"
        exit 3
    fi
}

check_network() {
    __start "network"

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
    if ! pacstrap -K "${MNT}" \
        base base-devel dash vi neovim less \
        linux-zen linux-lts linux-firmware bash-completion; then
        printf "Installation failed, bad internet maybe?\n"
        printf "\n"
        exit 3
    fi
    __separator
    __confirm "pacstrap"

    __start "fstab"
    local fstab="${MNT}/etc/fstab"
    genfstab -U "${MNT}" >"${fstab}"
    __separator
    __lsblk
    __separator
    cat "${fstab}"
    __confirm "fstab"
}

pre_chroot() {
    __check_root

    partitioning_check
    check_network
    sync_time
    bulk_work
}

transition_to_post() {
    cp -f "${SCRIPT_NAME}" "${MNT}/."

    case "${1}" in
        "-m" | "--manual")
            __start "to-chroot"

            printf "Run\n"
            printf "    # sh %s post\n" "${SCRIPT_NAME}"
            printf "in now-to-be chroot.\n"
            printf "\n"

            __separator
            __confirm "to-chroot"
            __run_in_chroot
            ;;
        *)
            __run_in_chroot "${SCRIPT_NAME}" post
            ;;
    esac
}

base() {
    __start "chroot.base"
    . /usr/share/bash-completion/bash_completion

    __passwd "root"
    ln -sf /usr/share/zoneinfo/Europe/Vaduz /etc/localtime
    hwclock --systohc

    __separator
    __confirm "chroot.base"
}

localization() {
    __start "localization"

    if ! locale -a | grep "^sv_SE.utf8$" >/dev/null; then
        cat <<STOP >>/etc/locale.gen
zh_CN.UTF-8 UTF-8
en_US.UTF-8 UTF-8
de_DE.UTF-8 UTF-8
de_CH.UTF-8 UTF-8

fr_FR.UTF-8 UTF-8
fr_CH.UTF-8 UTF-8
zh_HK.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
es_ES.UTF-8 UTF-8
es_AR.UTF-8 UTF-8
it_IT.UTF-8 UTF-8
it_CH.UTF-8 UTF-8

ru_RU.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8
ar_EG.UTF-8 UTF-8
pt_BR.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
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
    local _hname="shc.machine"
    if [ ! -f "${hostname_file}" ]; then
        printf "Hostname: "
        read -r _hname
        printf "%s\n" "${_hname}" >"${hostname_file}"
    fi

    cat <<STOP >/etc/hosts
127.0.0.1 localhost
127.0.0.1 ${_hname}
::1 localhost
STOP

    __install networkmanager dhclient
    cat <<STOP >/etc/NetworkManager/conf.d/dhcp-client.conf
[main]
dhcp=dhclient
STOP
    systemctl enable NetworkManager.service

    __separator
    __confirm "network"
}

boot() {
    __start "boot"

    __install grub efibootmgr

    local grub_dir="/boot/grub" bootloader_name="MAIN"
    if [ ! -d "${grub_dir}" ]; then
        mkinitcpio -P
        clear

        grub-install \
            --target=x86_64-efi \
            --efi-directory="${EFI_MOUNT}" \
            --bootloader-id="${bootloader_name}"
        printf "\n\n"
        grub-mkconfig -o "${grub_dir}/grub.cfg"
    fi

    __separator ""
    efibootmgr
    __confirm "boot"
}

pacman_extra() {
    __blackarch() {
        __start "blackarch"

        # REF:
        #   https://www.blackarch.org/downloads.html#install-repo
        local _blackarch="strap.sh"
        curl -O "https://blackarch.org/${_blackarch}"
        if ! (chmod +x "${_blackarch}" && ./"${_blackarch}"); then
            printf "blackarch> failed, exiting"
            exit 3
        fi

        __separator
        rm "${_blackarch}"
        __confirm "blackarch"
    }

    __zfs() {
        __start "zfs"

        # REF:
        #   https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
        local _archzfs_key="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
        if ! (
            pacman-key --recv-keys "${_archzfs_key}" &&
                pacman-key --finger "${_archzfs_key}" &&
                pacman-key --lsign-key "${_archzfs_key}"
        ); then
            printf "blackarch> failed, exiting"
            exit 3
        fi

        __separator
        __confirm "zfs"
    }

    __conf_takeover() {
        __start "pacman-extra"

        local conf="pacman.conf"
        local conf_back="${conf}.pacnew"

        __download "${conf}"

        if [ ! -f "/etc/${conf_back}" ]; then
            mv "/etc/${conf}" "/etc/${conf_back}"
        fi
        cp -f "./${conf}" "/etc/."
        rm "./${conf}"

        clear

        pacman -Syyu --noconfirm
        printf "\n\n"
        pacman -Fyy

        __separator
        __confirm "pacman-extra"
    }

    __blackarch
    __zfs
    __conf_takeover
}

multiuser() {
    __visudo() {
        __start "visudo"
        # previous version := ...(ALL:ALL)...
        # newer version := ...(ALL)...
        if ! grep "^%wheel ALL=(.*ALL) ALL$" /etc/sudoers; then
            printf "[visudo] uncomment |%%wheel ALL=(ALL) ALL|: " && read -r _
            EDITOR=nvim visudo
        fi
        __separator
        __confirm "visudo"
    }

    __birth() {
        local _me="shc" _rank="god" _home="main"

        __start "birth-${_me}"
        __install zsh zsh-completions zsh-syntax-highlighting
        if ! id "${_me}" >/dev/null 2>&1; then
            useradd -m -d "/home/${_home}" -G wheel -s /bin/zsh "${_me}"
            groupmod -n "${_rank}" "${_me}"

            __passwd "${_me}"
            printf "%s is born " ${_me}
        else
            printf "%s is already alive " ${_me}
        fi

        rm "/home/${_home}/.bash"*

        local _script="user.sh"
        __download "${_script}"
        chown "${_me}:${_rank}" "${_script}"
        mv -f "${_script}" "/home/${_home}/."

        __separator
        printf "personal setup-script for [%s] ready, run after (re)log-in" "${_me}"
        printf "\n"
        __confirm "birth-${_me}"
    }

    __visudo
    __birth
}

post_chroot() {
    __check_root

    base
    localization
    network
    boot
    pacman_extra
    multiuser

    __separator
    rm "${SCRIPT_NAME}"
    __confirm "post-chroot"
}

cleanup() {
    __start "cleanup"

    __separator ""
    printf "Installation complete; will now reboot\n"
    __confirm "cleanup"

    rm "${SCRIPT_NAME}"
    umount -R "${MNT}"
    reboot
}

case "${1}" in
    "update")
        __update
        ;;
    "part")
        partitioning_standard
        ;;
    "pre")
        pre_chroot
        ;;
    "transition")
        shift
        transition_to_post "${1}"
        ;;
    "post")
        post_chroot
        ;;
    "pipe")
        pre_chroot
        transition_to_post
        cleanup
        ;;
    *)
        printf "huh? what is [%s]? (try 'pipe' for full install)\n" "${1}"
        printf "\n"
        exit 3
        ;;
esac
