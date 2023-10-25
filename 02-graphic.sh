source "./util.sh"

function __base() {
    install "arch" \
        alacritty foot \
        tmux vifm neovim vi fzf the_silver_searcher

    install "arch" \
        sshfs exfatprogs dosfstools \
        pcmanfm-gtk3 gvfs gvfs-mtp gvfs-afc
}

function __wm() {
    install "arch" \
        wl-clipboard xorg-xwayland \
        sway swaylock swaybg xdg-desktop-portal-wlr \
        grim slurp wf-recorder capitaine-cursors light gammastep

    install "aur" \
        wdisplays

    install "arch" \
        adobe-source-code-pro-fonts \
        adobe-source-han-sans-otc-fonts \
        adobe-source-han-serif-otc-fonts \
        libertinus-font \
        ttf-fira-code \
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji \
        font-manager
}

function __office() {
    install "arch" \
        zathura zathura-pdf-mupdf zathura-djvu zathura-ps
}

function __media() {
    install "arch" \
        pulsemixer mpv \
        sox cmus mpd mpc ncmpc \
        imv yt-dlp ytfzf

    install "arch" \
        firefox-developer-edition chromium w3m \
        qutebrowser python-adblock \
        transmission-cli deluge-gtk

    install "aur" \
        wdisplays
}
