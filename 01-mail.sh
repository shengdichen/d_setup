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

function __dot_dir() {
    echo "$(dot_dir)/d_mail/"
}

function create_box() {
    function __f() {
        local maildir=false dirs
        while (( ${#} > 0 )); do
            case "${1}" in
                "-m" )
                    maildir=true
                    shift ;;
                "--" )
                    dirs=("${@:2}")
                    break
            esac
        done

        for d in "${dirs[@]}"; do
            mkdir -p "${d}"
            chmod 700 "${d}"
            if "${maildir}"; then
                for maild in "cur" "new"; do
                    mkdir -p "${d}/${maild}"
                done
            fi
        done
    }

    local boxes_raw=() boxes_maildir=() box_dir
    box_dir="$(__dot_dir)/.local/share/mail/"

    for d in "eth" "gmail" "outlook"; do
        boxes_raw+=("${box_dir}/raw/${d}")
    done
    __f -- "${boxes_raw[@]}"

    for d in "xyz/.INBOX" "xyz/.Sent"; do
        boxes_maildir+=("${box_dir}/raw/${d}")
    done
    for d in "draft" "hold" "trash" "x"; do
        boxes_maildir+=("${box_dir}/all/.${d}")
    done
    __f -m -- "${boxes_maildir[@]}"

    unset -f __f
}

function fdm_conf() {
    chmod 600 "$(__dot_dir)/.config/fdm/config"
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
