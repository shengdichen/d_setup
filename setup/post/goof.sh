#!/usr/bin/env dash

. "../util.sh"

__office() {
    __l0() {
        __install arch "${@}" -- \
            zathura zathura-pdf-mupdf zathura-djvu zathura-ps \
            pdfarranger img2pdf
        dotfile -- d_zathura

        __install arch "${@}" -- \
            hunspell enchant \
            hunspell-en_us hunspell-en_gb hunspell-fr hunspell-de hunspell-it hunspell-ru hunspell-es_es
    }

    __l1() {
        __install arch "${@}" -- xournalpp
        dotfile -- d_xournalpp

        __install arch "${@}" -- \
            texlive texlive-lang biber libreoffice-fresh
        __install aurhelper "${@}" -- lyx bibtex-tidy
        dotfile -- d_lyx
    }

    local _level="${1}"
    shift
    if [ "${_level}" -ge 0 ]; then
        __l0 "${@}"
        if [ "${_level}" -ge 1 ]; then
            __l1 "${@}"
        fi
    fi
    unset -f __l0 __l1
}

__media() {
    __l0() {
        __install arch "${@}" -- \
            pulsemixer mpv \
            sox cmus mpd mpc ncmpc \
            imv yt-dlp ytfzf
        __install pipx -- tidal-dl
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

    __l1() {
        __install arch "${@}" -- \
            kdenlive handbrake
    }

    local _level="${1}"
    shift
    if [ "${_level}" -ge 0 ]; then
        __l0 "${@}"
        if [ "${_level}" -ge 1 ]; then
            __l1 "${@}"
        fi
    fi
    unset -f __l0 __l1
}

__browser() {
    __l0() {
        __install arch "${@}" -- \
            qutebrowser python-adblock tor
        service_start -- tor
        dotfile -- d_qutebrowser

        __install arch "${@}" -- chromium
    }

    __l1() {
        __install arch "${@}" -- \
            firefox-developer-edition w3m \
            mktorrent transmission-cli deluge-gtk
        __install aurhelper "${@}" -- firefox-esr-bin
    }

    __l2() {
        __install aurhelper "${@}" -- ungoogled-chromium-bin
    }

    local _level="${1}"
    shift
    if [ "${_level}" -ge 0 ]; then
        __l0 "${@}"
        if [ "${_level}" -ge 1 ]; then
            __l1 "${@}"
            if [ "${_level}" -ge 2 ]; then
                __l2 "${@}"
            fi
        fi
    fi
    unset -f __l0 __l1 __l2
}

__game() {
    __l1() {
        __install arch "${@}" -- \
            ppsspp tty-solitaire
    }

    __l2() {
        __install arch "${@}" -- steam
        __install aurhelper "${@}" -- pokerth

        __install arch "${@}" -- \
            wine-staging wine-gecko wine-mono \
            lutris
    }

    local _level="${1}"
    shift
    if [ "${_level}" -ge 1 ]; then
        __l1 "${@}"
        if [ "${_level}" -ge 2 ]; then
            __l2 "${@}"
        fi
    fi
    unset -f __l2
}

__social() {
    __l0() {
        __install arch "${@}" -- \
            neomutt notmuch fdm isync msmtp
        __install aurhelper "${@}" -- \
            protonmail-bridge-core
        dotfile -- d_mail
    }

    __l1() {
        __install aurhelper "${@}" -- mkinitcpio-firmware

        __install arch "${@}" -- signal-desktop
        __install aurhelper "${@}" -- teams-for-linux
    }

    case "${1}" in
        "0")
            shift
            __l0 "${@}"
            ;;
        "1")
            shift
            __l0 "${@}"
            __l1 "${@}"
            ;;
    esac
    unset -f __l0 __l1
}

main() {
    local _level="0"
    case "${1}" in
        "0" | "1" | "2")
            _level="${1}"
            shift
            ;;
    esac

    unset -f __l0 __l1
    __office "${_level}" "${@}"
    __media "${_level}" "${@}"
    __browser "${_level}" "${@}"
    __game "${_level}" "${@}"
    __social "${_level}" "${@}"

    unset -f __office __media __browser __game __social
}
main "${@}"
unset -f main
