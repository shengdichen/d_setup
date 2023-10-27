source "./util.sh"

function __install() {
    install "arch" \
        "neomutt" "notmuch" "fdm" "isync" "msmtp"

    install "aur" \
        "protonmail-bridge-bin"
}

function __dot() {
    local base="d_mail"

    (cd "$(dot_dir)" && clone_and_stow "$(clone_url github ${base})" "${base}")
}

function __extra() {
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

function main() {
    __install
    __dot

    unfunction __install __dot
}
main
unfunction main
