__check_root() {
    if ((EUID != 0)); then
        echo "Must be executed as root, exiting"
        exit 3
    fi
}
__check_root

__separator() {
    echo "---------- ${1} ----------"
}

__confirm() {
    printf "%s> confirm (default); [q]uit " "${1}"

    local input=""
    read -r input
    if [ "${input}" = "q" ] || [ "${input}" = "Q" ]; then
        printf "Exiting"
        exit 3
    fi
}

# pre {{{
partitioning() {
    echo "1. paritioning MUST be done manually"
    echo "HINT for efi-system: (1 efi ~ 200MB, 1 system-disk: as much as possibe)"

    __confirm "partitioning"
    printf "\n"
}

partitioning_vbox() {
    __separator "vbox-start"
    local disk="/dev/sda" efi_size="512MB"
    parted "${disk}" mklabel gpt

    parted "${disk}" mkpart "efi" fat32 "1MB" "${efi_size}"
    parted "${disk}" set 1 esp on
    mkfs.fat -F 32 "${disk}1"

    parted "${disk}" mkpart "root" ext4 "${efi_size}" 100%
    mkfs.ext4 "${disk}2"
    e2label "${disk}2" "ROOT"

    # MUST mount /mnt before sub-mountpoints (e.g., /mnt/efi)
    mount "${disk}2" /mnt
    mount --mkdir "${disk}1" /mnt/efi

    __separator "vbox-end"
    echo
    lsblk
    __confirm "partitioning"
}

check_network() {
    echo "2. check internet connection, [ping] right now"
    ping -c 3 shengdichen.xyz
    echo
    __confirm "network"
}

sync_time() {
    local date_pattern="Date: " time_curr
    time_curr="$(
        curl -s --head http://google.com |
            grep "^${date_pattern}" |
            sed "s/${date_pattern}//g"
    )"
    printf "set-time-to> %s\n" "${time_curr}"

    date -s "${time_curr}" >/dev/null
    hwclock -w --utc
}

bulk_work() {
    pacstrap -K /mnt \
        base base-devel vi neovim \
        linux linux-firmware bash-completion

    genfstab -U /mnt >>/mnt/etc/fstab
}

pre_chroot() {
    __separator "before_proceeding"

    partitioning
    check_network
    sync_time
    bulk_work
}
# }}}

# post {{{
function base() {
    source /usr/share/bash-completion/bash_completion
    passwd

    ln -sf /usr/share/zoneinfo/Europe/Vaduz /etc/localtime
    hwclock --systohc
}

function locale() {
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

    cat <<STOP >/etc/locale.conf
LANG=en_US.UTF-8
STOP
}

function network() {
    local _hname
    printf "Hostname: "
    read -r _hname
    echo "${_hname}" >/etc/hostname

    cat <<STOP >/etc/hosts
127.0.0.1 localhost
::1 localhost
STOP

    pacman -S networkmanager dhclient
    cat <<STOP >/etc/NetworkManager/conf.d/dhcp-client.conf
[main]
dhcp=dhclient
STOP
    systemctl enable NetworkManager.service
}

function boot() {
    mkinitcpio -P
    pacman -S grub efibootmgr

    local _boot_dir="/boot"
    grub-install \
        --target=x86_64-efi \
        --efi-directory="${_boot_dir}/" \
        --bootloader-id=MAIN
    grub-mkconfig -o "${_boot_dir}/grub/grub.cfg"
}

function post_chroot() {
    base
    locale
    network
    boot
}
# }}}

case "${1}" in
    "vbox")
        partitioning_vbox
        ;;
    "pre")
        pre_chroot
        ;;
    "post")
        post_chroot
        ;;
    *)
        # arch-chroot /mnt
        # post_chroot
        # exit
        echo "Huh, which mode? [pre] or [post]"
        ;;
esac

# vim: foldmethod=marker
