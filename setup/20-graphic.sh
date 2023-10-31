source "./util.sh"

function __office() {
    install "arch" \
        zathura zathura-pdf-mupdf zathura-djvu zathura-ps \
        pdfarranger img2pdf

    install "arch" \
        hunspell enchant \
        hunspell-en_us hunspell-en_gb hunspell-fr hunspell-de hunspell-it hunspell-ru hunspell-es_es \
        texlive texlive-lang biber libreoffice-fresh xournalpp

    # obtain lyx (from cache or aur)

    install "arch" \
        fcitx5-im fcitx5-rime fcitx5-mozc \
        rime-double-pinyin rime-cantonese rime-wugniu
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
}

function __game() {
    install "arch" \
        steam

    install "arch" \
        wine-staging wine-gecko wine-mono \
        lutris
}
