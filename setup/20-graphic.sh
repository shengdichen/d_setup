source "./util.sh"

function __office() {
    install "arch" \
        zathura zathura-pdf-mupdf zathura-djvu zathura-ps \
        pdfarranger img2pdf
    clone_and_stow self d_zathura

    install "arch" \
        hunspell enchant \
        hunspell-en_us hunspell-en_gb hunspell-fr hunspell-de hunspell-it hunspell-ru hunspell-es_es \
        texlive texlive-lang biber libreoffice-fresh xournalpp
    clone_and_stow self d_xournalpp

    # obtain lyx (from cache or aur)

    install "arch" \
        fcitx5-im fcitx5-rime fcitx5-mozc \
        rime-double-pinyin rime-cantonese rime-wugniu
    clone_and_stow self d_ime
}

function __media() {
    install "arch" \
        pulsemixer mpv \
        sox cmus mpd mpc ncmpc \
        imv yt-dlp ytfzf
    clone_and_stow self d_mpd
    clone_and_stow self d_cmus
    clone_and_stow self d_ncmpc

    local mpd_lib="${HOME}/.config/mpd/bin/lib/"
    if (($(find "${mpd_lib}" -maxdepth 1 | wc -l) <= 2)); then
        ln -f "${HOME}/xdg/MDA/Aud/x" "${mpd_lib}"
        if ! pgrep mpd 1>/dev/null 2>&1; then
            mpd
        fi
        mpc --host=admin@localhost update
        mpc --host=admin@localhost repeat
        mpc --host=admin@localhost single
        mpc --host=admin@localhost volume 37
    fi

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
