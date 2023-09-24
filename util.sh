function dot_dir() {
    echo "$HOME/dot/dot"
}

function install() {
    local SUDO=""
    if (( "$EUID" != 0 )); then
        SUDO=sudo
    fi

    case "$1" in
        "arch")
            "${SUDO}" pacman -S --needed "${@:2}"
            ;;
        *)
            "${SUDO}" pacman -S --needed "${@:2}"
            ;;
    esac
}

function clone_url() {
    case "$1" in
        "github" | "GH" )
            echo "git@github.com:shengdichen/$2.git"
            ;;
    esac
}

function clone_and_stow() {
    local remote="$1"
    local local="$2"

    if [[ ! -d ${local} ]]; then
        git clone "${remote}" "${local}"
    fi

    if [[ -d ${local} ]]; then  # cater for failed cloning
        stow -R --target="${HOME}" --ignore="\.git.*" "${local}"
        echo "Stowing completed"
    fi
}

function fetch_and_stow() {
    local local="$1"
    (
        cd "${local}" || exit
        git fetch && git merge main
        stow --restow "$1"
    )
}
