if ((EUID != 0)); then
    echo "Must be executed as root, exiting"
    exit 3
fi

# pre {{{
function sync_time() {
    local date_pattern="Date: "
    date -s "$(
        curl -s --head http://google.com |
            grep "^${date_pattern}" |
            sed "s/${date_pattern}//g"
    )"
    hwclock -w --utc
}

function pre_chroot() {
    sync_time

    pacstrap -K /mnt \
        base base-devel vi neovim \
        linux linux-firmware bash-completion
    genfstab -U /mnt >>/mnt/etc/fstab
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

pre_chroot
arch-chroot /mnt
post_chroot
exit

# vim: foldmethod=marker
