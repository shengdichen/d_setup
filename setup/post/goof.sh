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

        __install arch "${@}" -- \
            texlive texlive-lang biber libreoffice-fresh
        __install arch "${@}" -- \
            texlab perl-yaml-tiny perl-file-homedir
        __install aurhelper "${@}" -- bibtex-tidy

        __install aurhelper "${@}" -- lyx
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
            imv yt-dlp ytfzf mkvtoolnix-cli
        __install pipx -- tidal-dl
        dotfile -- d_mpv
    }

    __l1() {
        __install arch "${@}" -- \
            easyeffects audacity \
            calf lsp-plugins zam-plugins mda.lv2 \
            timidity++

        __install arch "${@}" -- \
            cmatrix asciiquarium \
            toilet \
            cowsay lolcat
        __install aurhelper "${@}" -- bullshit fortune-mod-off

        __install arch "${@}" -- blanket

        __install arch "${@}" -- \
            v4l2loopback-dkms v4l-utils obs-studio \
            kdenlive handbrake

        __install arch "${@}" -- \
            niri xdg-desktop-portal-gnome xdg-desktop-portal-gtk
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

        __install arch "${@}" -- chromium firefox-developer-edition
    }

    __l1() {
        __install arch "${@}" -- \
            w3m \
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
            bsd-games ppsspp tty-solitaire
        __install pipx -- term2048
    }

    __l2() {
        __install aurhelper "${@}" -- pokerth

        __install arch "${@}" -- steam
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
        # REF:
        #   https://wiki.archlinux.org/title/Isync#Using_XOAUTH2
        __install aurhelper "${@}" -- cyrus-sasl-xoauth2-git
        __install aurhelper "${@}" -- protonmail-bridge-core
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
