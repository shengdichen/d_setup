#!/usr/bin/env dash

. "../util.sh"

__sys() {
    __base() {
        __install arch "${@}" -- \
            base base-devel pacman-contrib vi moreutils opendoas

        __install arch "${@}" -- \
            man-db man-pages \
            man-pages-fr man-pages-de man-pages-ru man-pages-es \
            man-pages-sv man-pages-it man-pages-pt_br man-pages-zh_tw

        __install arch "${@}" -- \
            linux linux-headers linux-docs linux-firmware \
            arch-install-scripts sysfsutils grub efibootmgr \
            lshw intel-ucode fwupd \
            s-tui glmark2 mesa-utils lib32-mesa-utils \
            smartmontools lsof socat \
            archlinux-keyring openssh gnupg pass pass-otp zbar pwgen

        __install arch "${@}" -- \
            tar bzip2 bzip3 gzip xz zstd p7zip unrar zip unzip \
            fuse3 fuse2 \
            exfatprogs nfs-utils dosfstools sshfs \
            android-file-transfer android-tools \
            pcmanfm-gtk3 gvfs gvfs-mtp gvfs-afc gvfs-gphoto2 \
            libimobiledevice ifuse
    }

    __network() {
        __install arch "${@}" -- \
            networkmanager dhclient \
            networkmanager-openvpn networkmanager-openconnect nm-connection-editor \
            reflector \
            tor nyx \
            wget curl httpie speedtest-cli rsync \
            traceroute mtr \
            openbsd-netcat nmap \
            whois host bind
        service_start -- NetworkManager

        __install arch "${@}" -- \
            bluez bluez-utils \
            pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack \
            wireplumber helvum \
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

    __base "${@}"
    __network "${@}"
    __graphics "${@}"
    unset -f __base __network __graphics
}

__user() {
    __base() {
        __install arch "${@}" -- stow

        __install arch "${@}" -- git
        dotfile -- d_git

        __install arch "${@}" -- xdg-user-dirs
        dotfile -- d_xdg

        __install arch "${@}" -- \
            fzf the_silver_searcher ripgrep-all fd

        __install arch "${@}" -- \
            neovim tree-sitter-cli python-pynvim
        dotfile -- d_nvim

        __install arch "${@}" -- \
            zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions
        dotfile -- d_zsh

        __install arch "${@}" -- tmux
        dotfile -- d_tmux

        __install arch "${@}" -- clang vifm
        dotfile -- d_vifm
    }

    __desktop() {
        __install arch "${@}" -- glib2 # for gsettings
        __install arch "${@}" -- materia-gtk-theme
        __install arch "${@}" -- arc-icon-theme elementary-icon-theme
        __install arch "${@}" -- capitaine-cursors

        __install aurhelper "${@}" -- qt5ct-kde qt6ct-kde
        __install arch "${@}" -- materia-kde breeze breeze5

        __install arch "${@}" -- \
            adobe-source-code-pro-fonts \
            adobe-source-han-sans-otc-fonts \
            adobe-source-han-serif-otc-fonts \
            libertinus-font \
            ttf-fira-code terminus-font \
            noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji \
            font-manager
        dotfile -- d_font shevska

        __install arch "${@}" -- foot wezterm alacritty
        dotfile -- d_foot

        __install arch "${@}" -- \
            hyprland xdg-desktop-portal-hyprland \
            river sway swaylock swaybg xdg-desktop-portal-wlr \
            fuzzel wl-clipboard wev xorg-xwayland \
            grim slurp wf-recorder brightnessctl gammastep
        __install aur -- wdisplays
        dotfile -- d_sway
    }

    __ime() {
        __install arch "${@}" -- \
            fcitx5-im fcitx5-rime fcitx5-mozc \
            rime-double-pinyin rime-cantonese rime-wugniu
        dotfile -- d_ime
    }

    __base "${@}"
    __desktop "${@}"
    __ime "${@}"
    unset -f __base __desktop __ime
}

main() {
    # consume (sink) this: everything non-negotiable in this script
    case "${1}" in
        "0" | "1" | "2") shift ;;
    esac

    __sys "${@}"
    __user "${@}"
    unset -f __sys __user
}
main "${@}"
unset -f main
