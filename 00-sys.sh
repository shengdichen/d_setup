source "./util.sh"

function base() {
    install "arch" \
        base base-devel pacman-contrib \
        vi neovim \
        man-db man-pages \
        man-pages-fr man-pages-de man-pages-ru man-pages-es \
        man-pages-sv man-pages-it man-pages-pt_br man-pages-zh_tw

    # fs
    install "arch" \
        exfatprogs \
        linux linux-headers linux-docs \
        linux-lts linux-lts-headers linux-lts-docs \
        linux-firmware intel-ucode \
        fwupd arch-install-scripts
}

pacman -S --needed \
    mesa vulkan-intel lib32-vulkan-intel \
    vulkan-headers vulkan-tools intel-gpu-tools
pacman -S --needed \
    efibootmgr tlp acpi ethtool smartmontools lsof lshw \
    openssh nfs-utils sshfs gnupg pass pass-otp zbar \
    tar bzip2 bzip3 gzip xz zstd p7zip unrar zip unzip

# systemctl enable tlp && systemctl start tlp
# sudo tlp setcharge 59 60 BAT0
pacman -S --needed \
    networkmanager \
    networkmanager-openvpn networkmanager-openconnect nm-connection-editor \
    tor nyx \
    wget curl speedtest-cli
# systemctl start tor
pacman -S --needed \
    bluez bluez-utils \
    wireplumber \
    pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack \
    gstreamer gstreamer-vaapi gst-libav gst-plugins-base gst-plugins-good

# pacman.conf {{{
# 0. enable multilib

# 1. zfs {{{
# 1. copy over /etc/pacman.conf
# arch-zfs
# accept key from: https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs
# # pacman-key --recv-keys DDF7DB817396A49B2A2723F7403BD972F75D9D76
# $ pacman-key --finger DDF7DB817396A49B2A2723F7403BD972F75D9D76
# # pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
# install kernel with script from
# # zsh prv/zfs/zen/

# add ignorepackage: /etc/pacman.conf
#IgnorePkg=linux-zen
#IgnorePkg=linux-zen-headers

# // update grub to also realize the newly installed zen-kernel
# grub-mkconfig -o /boot/grub/grub.cfg
# }}}

# 2. blackarch {{{
# 0. remove legacy blackarch block in /etc/pacman.conf
# 1. install blackarch
#   https://www.blackarch.org/downloads.html#install-repo
# }}}
# }}}

# 2. simplify /etc/fstab {{{
# a. rename root-parition
# # sudo e2label /dev/sda<ROOT> "ROOT"
# NOTE:
#   1. the label will NOT showup until remounting partition, in the case of a root partition: until reboot
#   2. verify with |$ blkid|

# b. swapfile

# c. edit /etc/fstab
#       LABEL=ROOT / ext4 rw,relatime 0 1
#       /SWAP none swap defaults 0 0
# }}}
