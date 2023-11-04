source "./util.sh"

function __base() {
    install "arch" \
        base base-devel pacman-contrib \
        vi neovim \

    install "arch" \
        man-db man-pages \
        man-pages-fr man-pages-de man-pages-ru man-pages-es \
        man-pages-sv man-pages-it man-pages-pt_br man-pages-zh_tw

    install "arch" \
        linux linux-headers linux-docs \
        linux-lts linux-lts-headers linux-lts-docs \
        linux-firmware

    install "arch" \
        lshw efibootmgr intel-ucode fwupd arch-install-scripts

    install "arch" \
        openssh gnupg pass pass-otp zbar \
        tar bzip2 bzip3 gzip xz zstd p7zip unrar zip unzip

    install "arch" \
        s-tui ethtool smartmontools lsof \
        fuse3 fuse2 \
        exfatprogs nfs-utils dosfstools sshfs \
        android-file-transfer android-tools \
        pcmanfm-gtk3 gvfs gvfs-mtp gvfs-afc

    install "arch" \
        networkmanager \
        networkmanager-openvpn networkmanager-openconnect nm-connection-editor \
        tor nyx \
        wget curl speedtest-cli rsync

    install "arch" \
        bluez bluez-utils \
        wireplumber \
        pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack \
        gstreamer gstreamer-vaapi gst-libav gst-plugins-base gst-plugins-good

    install "arch" \
        tlp acpi
    service_start -- tlp
}

function __graphics() {
    install "arch" \
        mesa vulkan-intel lib32-vulkan-intel \
        vulkan-headers vulkan-tools intel-gpu-tools

    install "arch" \
        vulkan-radeon lib32-vulkan-radeon \
        libva-mesa-driver lib32-libva-mesa-driver \
        mesa-vdpau lib32-mesa-vdpau \
        radeontop

    install "arch" \
        amdvlk lib32-amdvlk
}

function __desktop() {
    install "arch" \
        adobe-source-code-pro-fonts \
        adobe-source-han-sans-otc-fonts \
        adobe-source-han-serif-otc-fonts \
        libertinus-font \
        ttf-fira-code \
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji \
        font-manager
    clone_and_stow -- self d_font

    local _shevska="shevska"
    (
        cd "$(dot_dir)" || exit 3
        clone_and_stow --no-stow -- self "${_shevska}"
        cd "${_shevska}" && "${SHELL}" setup.sh
    )

    install "arch" \
        alacritty foot \
        tmux vifm neovim vi fzf the_silver_searcher
    clone_and_stow -- self d_foot
    clone_and_stow -- self d_tmux
    clone_and_stow -- self d_vifm

    install "arch" \
        wl-clipboard xorg-xwayland \
        sway swaylock swaybg xdg-desktop-portal-wlr \
        grim slurp wf-recorder capitaine-cursors light gammastep
    clone_and_stow -- self d_sway
    install "aur" \
        wdisplays
}

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

function main() {
    __base
    __graphics
    __desktop

    unset -f __base __graphics __desktop
}
main
unset -f main
