#!/usr/bin/env dash

. "../util.sh"

__office() {
    __l0() {
        install arch -- \
            zathura zathura-pdf-mupdf zathura-djvu zathura-ps \
            pdfarranger img2pdf
        dotfile -- d_zathura

        install arch -- \
            hunspell enchant \
            hunspell-en_us hunspell-en_gb hunspell-fr hunspell-de hunspell-it hunspell-ru hunspell-es_es
    }

    __l1() {
        install arch -- xournalpp
        dotfile -- d_xournalpp

        install arch -- \
            texlive texlive-lang biber libreoffice-fresh
        install aurhelper -- lyx
        dotfile -- d_lyx
    }

    __l0
    if [ "${#}" -gt 0 ]; then
        if [ "${1}" -gt 0 ]; then
            __l1
        fi
    fi
    unset -f __l0 __l1
}

__media() {
    install arch -- \
        pulsemixer mpv \
        sox cmus mpd mpc ncmpc \
        imv yt-dlp ytfzf
    install pipx -- tidal-dl
    dotfile -- d_mpv d_mpd d_cmus d_ncmpc

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
}

__browser() {
    __l0() {
        install arch -- \
            qutebrowser python-adblock tor
        service_start -- tor
        dotfile -- d_qutebrowser

        install arch -- chromium
    }

    __l1() {
        install arch -- \
            firefox-developer-edition w3m \
            transmission-cli deluge-gtk
    }

    __l2() {
        install aurhelper -- ungoogled-chromium-bin
    }

    __l0
    if [ "${#}" -gt 0 ]; then
        if [ "${1}" -gt 0 ]; then
            __l1
            if [ "${1}" -gt 1 ]; then
                __l2
            fi
        fi
    fi
    unset -f __l0 __l1 __l2
}

__game() {
    __l2() {
        install arch -- steam

        install arch -- \
            wine-staging wine-gecko wine-mono \
            lutris
    }

    if [ "${#}" -gt 0 ]; then
        if [ "${1}" -gt 0 ]; then
            if [ "${1}" -gt 1 ]; then
                __l2
            fi
        fi
    fi
    unset -f __l2
}

__social() {
    __l0() {
        install arch -- \
            neomutt notmuch fdm isync msmtp
        install aurhelper -- \
            protonmail-bridge-core
        dotfile -- d_mail
    }

    __l1() {
        install aurhelper -- mkinitcpio-firmware

        install arch -- signal-desktop
        install aurhelper -- teams-for-linux
    }

    __l0
    if [ "${#}" -gt 0 ]; then
        if [ "${1}" -gt 0 ]; then
            __l1
        fi
    fi
    unset -f __l0 __l1
}

main() {
    __office "${@}"
    __media "${@}"
    __browser "${@}"
    __game "${@}"
    __social "${@}"

    unset -f __office __media __browser __game __social
}
main "${@}"
unset -f main
