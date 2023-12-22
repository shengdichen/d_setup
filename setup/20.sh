#!/usr/bin/env dash

. "./util.sh"

__office() {
    install "arch" \
        zathura zathura-pdf-mupdf zathura-djvu zathura-ps \
        pdfarranger img2pdf
    clone_and_stow -- d_zathura

    install "arch" \
        hunspell enchant \
        hunspell-en_us hunspell-en_gb hunspell-fr hunspell-de hunspell-it hunspell-ru hunspell-es_es \
        texlive texlive-lang biber libreoffice-fresh xournalpp
    clone_and_stow -- d_xournalpp

    # obtain lyx (from cache or aur)
    clone_and_stow -- d_lyx

    install "arch" \
        fcitx5-im fcitx5-rime fcitx5-mozc \
        rime-double-pinyin rime-cantonese rime-wugniu
    clone_and_stow -- d_ime
}

__media() {
    install "arch" \
        pulsemixer mpv \
        sox cmus mpd mpc ncmpc \
        imv yt-dlp ytfzf
    install "pipx" \
        -- tidal-dl
    clone_and_stow -- d_mpv d_mpd d_cmus d_ncmpc

    local mpd_lib="${HOME}/.config/mpd/bin/lib/"
    # guarantee at least one (non-.gitignore) item under lib-directory
    if [ "$(find "${mpd_lib}" -maxdepth 1 | wc -l)" -le 2 ]; then
        ln -s "${HOME}/xdg/MDA/Aud/a" "${mpd_lib}"
        if ! pgrep mpd >/dev/null 2>&1; then mpd; fi
        for cmd in "update" "repeat" "single"; do
            mpc --host=admin@localhost "${cmd}"
        done
        mpc --host=admin@localhost volume 37
    fi

    install "arch" \
        firefox-developer-edition w3m \
        qutebrowser python-adblock \
        transmission-cli deluge-gtk
    install "aurhelper" \
        ungoogled-chromium-bin
}

__game() {
    install "arch" \
        steam

    install "arch" \
        wine-staging wine-gecko wine-mono \
        lutris
}

__social() {
    install "arch" \
        signal-desktop

    install "aurhelper" \
        teams-for-linux
}
