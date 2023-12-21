#!/usr/bin/env dash

. "./util.sh"

__install() {
    install "arch" \
        "neomutt" "notmuch" "fdm" "isync" "msmtp"

    install "aurhelper" \
        "protonmail-bridge-core"

    clone_and_stow -- self d_mail
}

__dot_dir() {
    echo "$(dot_dir)/d_mail/"
}

__create_box() {
    __f() {
        local maildir=""
        if [ "${1}" = "--maildir" ]; then
            maildir="yes"
            shift
        fi
        local target="${1}"

        mkdir -p "${target}"
        chmod 700 "${target}"
        if [ "${maildir}" ]; then
            for maild in "cur" "new"; do
                mkdir -p "${target}/${maild}"
            done
        fi
    }

    local mailbox_root
    mailbox_root="$(__dot_dir)/.local/share/mail/"

    for d in "eth" "gmail" "outlook"; do
        __f "${mailbox_root}/raw/${d}"
    done

    for d in "xyz/.INBOX" "xyz/.Sent"; do
        __f --maildir "${mailbox_root}/raw/${d}"
    done
    for d in "draft" "hold" "trash" "x"; do
        __f --maildir "${mailbox_root}/all/.${d}"
    done

    unset -f __f
}

__fdm_conf() {
    chmod 600 "$(__dot_dir)/.config/fdm/config"
}

__extra() {
    # 0. manually setup protonbridge:
    #   login;
    #   Settings:
    #       Automatic updates: off
    #       Open on startup: off
    #       Collect usage diagnostics: off

    #   exit
    # 1. get password files (TODO: move to |pass| to skip this step)

    # 2. get mails
    mbsync --all

    # 3. import notmuch
    #   3.1 export (old machine)
    #   $ notmuch dump --output=notmuch.dump
    #   3.2 init (new machine)
    #   $ notmuch new
    #   3.2 import (new machine)
    #   $ notmuch restore --input=notmuch.dump
}

main() {
    __install
    __create_box
    __fdm_conf

    unset -f __install __dot_dir __create_box __fdm_conf
}
main
unset -f main
