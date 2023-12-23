#!/usr/bin/env dash

. "../util.sh"

__base() {
    install "arch" \
        base base-devel pacman-contrib vi

    install "arch" \
        man-db man-pages \
        man-pages-fr man-pages-de man-pages-ru man-pages-es \
        man-pages-sv man-pages-it man-pages-pt_br man-pages-zh_tw

    install "arch" \
        linux linux-headers linux-docs linux-firmware \
        arch-install-scripts grub efibootmgr \
        lshw efibootmgr intel-ucode fwupd \
        s-tui smartmontools lsof \
        archlinux-keyring openssh gnupg pass pass-otp zbar

    install "arch" \
        tar bzip2 bzip3 gzip xz zstd p7zip unrar zip unzip \
        fuse3 fuse2 \
        exfatprogs nfs-utils dosfstools sshfs \
        android-file-transfer android-tools \
        pcmanfm-gtk3 gvfs gvfs-mtp gvfs-afc gvfs-gphoto2 \
        libimobiledevice ifuse

    install "arch" \
        networkmanager dhclient \
        networkmanager-openvpn networkmanager-openconnect nm-connection-editor \
        tor nyx \
        wget curl speedtest-cli rsync \
        traceroute mtr \
        openbsd-netcat nmap \
        whois
    service_start -- NetworkManager

    install "arch" \
        bluez bluez-utils \
        wireplumber \
        pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack \
        gstreamer gstreamer-vaapi gst-libav gst-plugins-base gst-plugins-good
    service_start -- bluetooth
}

__graphics() {
    install "arch" \
        vulkan-icd-loader lib32-vulkan-icd-loader vulkan-headers vulkan-tools

    install "arch" \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        intel-media-driver libva-intel-driver \
        intel-gpu-tools

    install "arch" \
        mesa lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk \
        libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau \
        radeontop

    install "arch" \
        nvtop
}

__desktop() {
    install "arch" \
        git stow
    clone_and_stow -- d_git

    clone_and_stow -- d_xdg

    install "arch" \
        zsh zsh-completions zsh-syntax-highlighting \
        neovim \
        tmux vifm fzf the_silver_searcher
    clone_and_stow --sub -- d_nvim
    clone_and_stow -- d_zsh d_tmux d_vifm

    install "arch" \
        adobe-source-code-pro-fonts \
        adobe-source-han-sans-otc-fonts \
        adobe-source-han-serif-otc-fonts \
        libertinus-font \
        ttf-fira-code terminus-font \
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji \
        font-manager
    clone_and_stow -- d_font shevska

    install "arch" \
        sway swaylock swaybg xdg-desktop-portal-wlr \
        alacritty foot \
        wl-clipboard xorg-xwayland \
        grim slurp wf-recorder capitaine-cursors light gammastep
    install "aur" -- wdisplays
    clone_and_stow -- d_sway d_foot

    install "arch" \
        fcitx5-im fcitx5-rime fcitx5-mozc \
        rime-double-pinyin rime-cantonese rime-wugniu
    clone_and_stow -- d_ime
}

main() {
    __base
    __graphics
    __desktop

    unset -f __base __graphics __desktop
}
main
unset -f main
