#!/usr/bin/env dash

. "../util.sh"

__base() {
    __install arch "${@}" -- \
        base base-devel pacman-contrib vi moreutils

    __install arch "${@}" -- \
        man-db man-pages \
        man-pages-fr man-pages-de man-pages-ru man-pages-es \
        man-pages-sv man-pages-it man-pages-pt_br man-pages-zh_tw

    __install arch "${@}" -- \
        linux linux-headers linux-docs linux-firmware \
        arch-install-scripts sysfsutils grub efibootmgr \
        lshw efibootmgr intel-ucode fwupd \
        s-tui glmark2 mesa-utils lib32-mesa-utils \
        smartmontools lsof socat \
        archlinux-keyring openssh gnupg pass pass-otp zbar

    __install arch "${@}" -- \
        tar bzip2 bzip3 gzip xz zstd p7zip unrar zip unzip \
        fuse3 fuse2 \
        exfatprogs nfs-utils dosfstools sshfs \
        android-file-transfer android-tools \
        pcmanfm-gtk3 gvfs gvfs-mtp gvfs-afc gvfs-gphoto2 \
        libimobiledevice ifuse

    __install arch "${@}" -- \
        networkmanager dhclient \
        networkmanager-openvpn networkmanager-openconnect nm-connection-editor \
        tor nyx \
        wget curl speedtest-cli rsync \
        traceroute mtr \
        openbsd-netcat nmap \
        whois
    service_start -- NetworkManager

    __install arch "${@}" -- \
        bluez bluez-utils \
        wireplumber \
        pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack \
        gstreamer gstreamer-vaapi gst-libav gst-plugins-base gst-plugins-good
    service_start -- bluetooth
}

__graphics() {
    __install arch "${@}" -- \
        vulkan-icd-loader lib32-vulkan-icd-loader vulkan-headers vulkan-tools

    __install arch "${@}" -- \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        intel-media-driver libva-intel-driver \
        intel-gpu-tools

    __install arch "${@}" -- \
        mesa lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk \
        libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau \
        radeontop

    __install arch "${@}" -- \
        nvtop
}

__desktop() {
    __install arch "${@}" -- stow

    __install arch "${@}" -- git
    dotfile -- d_git

    __install arch "${@}" -- xdg-user-dirs
    dotfile -- d_xdg

    __install arch "${@}" -- \
        neovim tree-sitter-cli python-pynvim
    dotfile -- d_nvim

    __install arch "${@}" -- \
        zsh zsh-completions zsh-syntax-highlighting \
        tmux vifm fzf the_silver_searcher
    dotfile -- d_zsh d_tmux d_vifm

    __install arch "${@}" -- \
        adobe-source-code-pro-fonts \
        adobe-source-han-sans-otc-fonts \
        adobe-source-han-serif-otc-fonts \
        libertinus-font \
        ttf-fira-code terminus-font \
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji \
        font-manager
    dotfile -- d_font shevska

    __install arch "${@}" -- \
        sway swaylock swaybg xdg-desktop-portal-wlr \
        foot wezterm alacritty \
        wl-clipboard wev xorg-xwayland \
        grim slurp wf-recorder capitaine-cursors brightnessctl gammastep
    install aur -- wdisplays
    dotfile -- d_sway d_foot

    __install arch "${@}" -- \
        fcitx5-im fcitx5-rime fcitx5-mozc \
        rime-double-pinyin rime-cantonese rime-wugniu
    dotfile -- d_ime
}

main() {
    # consume (sink) this: everything non-negotiable in this script
    case "${1}" in
        "0" | "1" | "2")
            shift
            ;;
    esac

    __base "${@}"
    __graphics "${@}"
    __desktop "${@}"

    unset -f __base __graphics __desktop
}
main "${@}"
unset -f main
